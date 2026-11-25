import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

initializeApp();

const db = getFirestore();
const REGION = "asia-southeast2";
const TIME_ZONE = "Asia/Jakarta";

type CartInput = {
  menuId: string;
  standId?: string;
  namaStand?: string;
  qty: number;
  catatan?: string;
};

function getJakartaDateKey(): string {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: TIME_ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date());

  const year = parts.find((p) => p.type === "year")?.value ?? "0000";
  const month = parts.find((p) => p.type === "month")?.value ?? "00";
  const day = parts.find((p) => p.type === "day")?.value ?? "00";
  return `${year}${month}${day}`;
}

export const placeOrder = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Silakan login terlebih dahulu.");
  }

  const uid = request.auth.uid;
  const profileRef = db.collection("users").doc(uid);
  const profileSnap = await profileRef.get();

  if (!profileSnap.exists || profileSnap.data()?.role !== "siswa") {
    throw new HttpsError("permission-denied", "Hanya akun siswa yang dapat memesan.");
  }

  const rawItems = request.data?.items;
  if (!Array.isArray(rawItems) || rawItems.length === 0 || rawItems.length > 30) {
    throw new HttpsError("invalid-argument", "Keranjang belanja tidak valid.");
  }

  // Satukan menu yang sama agar stok dihitung dengan benar
  const grouped = new Map<string, { qty: number; catatan: string }>();
  for (const raw of rawItems as CartInput[]) {
    const menuId = String(raw.menuId ?? "").trim();
    const qty = Number(raw.qty);
    const catatan = String(raw.catatan ?? "").trim().slice(0, 120);

    if (!menuId || !Number.isInteger(qty) || qty < 1 || qty > 20) {
      throw new HttpsError("invalid-argument", "Jumlah atau menu tidak valid.");
    }

    const current = grouped.get(menuId);
    const nextQty = (current?.qty ?? 0) + qty;
    if (nextQty > 20) {
      throw new HttpsError("invalid-argument", "Jumlah satu menu maksimal 20.");
    }
    grouped.set(menuId, {
      qty: nextQty,
      catatan: catatan || current?.catatan || "",
    });
  }

  const menuEntries = [...grouped.entries()];
  const dateKey = getJakartaDateKey();
  const student = profileSnap.data()!;
  const masterOrderId = `grp_${dateKey}_${Date.now().toString().slice(-6)}`;

  return db.runTransaction(async (transaction) => {
    // 1. Baca seluruh menu yang dipesan (ALL READS FIRST)
    const menuSnapshots = [];
    const menuRefs = [];

    for (const [menuId] of menuEntries) {
      const menuRef = db.collection("menus").doc(menuId);
      menuRefs.push(menuRef);
      menuSnapshots.push(await transaction.get(menuRef));
    }

    // Identifikasi stand-stand unik dari menu yang dipesan
    const uniqueStandIds = new Set<string>();
    for (const snap of menuSnapshots) {
      if (!snap.exists) {
        throw new HttpsError("not-found", "Salah satu menu tidak ditemukan.");
      }
      const mData = snap.data()!;
      uniqueStandIds.add(String(mData.standId ?? "stand_utama"));
    }

    // 2. Baca dokumen stand dan counter nomor antrean masing-masing stand
    const standDataMap = new Map<string, { standCode: string; namaStand: string; penjualId: string }>();
    const counterSnapMap = new Map<string, FirebaseFirestore.DocumentSnapshot>();
    const counterRefMap = new Map<string, FirebaseFirestore.DocumentReference>();

    for (const standId of uniqueStandIds) {
      const standRef = db.collection("stands").doc(standId);
      const standSnap = await transaction.get(standRef);
      const standInfo = standSnap.exists ? standSnap.data() : null;

      standDataMap.set(standId, {
        standCode: String(standInfo?.standCode ?? "A"),
        namaStand: String(standInfo?.namaStand ?? "Kantin Utama"),
        penjualId: String(standInfo?.penjualId ?? ""),
      });

      const counterRef = db.collection("counters").doc(`counter_${standId}_${dateKey}`);
      counterRefMap.set(standId, counterRef);
      counterSnapMap.set(standId, await transaction.get(counterRef));
    }

    // 3. Validasi stok dan kelompokkan item per stand
    const standItemsMap = new Map<string, { items: Array<Record<string, unknown>>; total: number }>();

    for (let i = 0; i < menuEntries.length; i++) {
      const [menuId, cartItem] = menuEntries[i];
      const menuSnap = menuSnapshots[i];
      const menu = menuSnap.data()!;
      const standId = String(menu.standId ?? "stand_utama");
      const stock = Number(menu.stock ?? 0);
      const harga = Number(menu.harga ?? 0);

      if (menu.isAvailable !== true || !Number.isInteger(stock) || stock < cartItem.qty) {
        throw new HttpsError("failed-precondition", `Stok ${menu.namaMenu ?? "menu"} tidak cukup.`);
      }
      if (!Number.isSafeInteger(harga) || harga < 0) {
        throw new HttpsError("failed-precondition", "Harga menu tidak valid.");
      }

      const subtotal = harga * cartItem.qty;

      if (!standItemsMap.has(standId)) {
        standItemsMap.set(standId, { items: [], total: 0 });
      }
      const standGroup = standItemsMap.get(standId)!;
      standGroup.total += subtotal;
      standGroup.items.push({
        menuId,
        namaMenu: String(menu.namaMenu ?? "Menu"),
        hargaSatuan: harga,
        qty: cartItem.qty,
        catatan: cartItem.catatan,
        subtotal,
      });

      // Potong stok
      transaction.update(menuRefs[i], {
        stock: stock - cartItem.qty,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    // 4. Buat dokumen pesanan terpisah untuk tiap stand (ALL WRITES)
    const createdOrders: Array<{ orderId: string; orderNumber: string; standId: string; totalHarga: number }> = [];

    for (const [standId, group] of standItemsMap.entries()) {
      const standMeta = standDataMap.get(standId)!;
      const counterSnap = counterSnapMap.get(standId)!;
      const counterRef = counterRefMap.get(standId)!;

      const nextNumber = Number(counterSnap.data()?.lastNumber ?? 0) + 1;
      const orderNumber = `${standMeta.standCode}-${String(nextNumber).padStart(3, "0")}`;

      transaction.set(counterRef, {
        standId,
        standCode: standMeta.standCode,
        lastNumber: nextNumber,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });

      const orderRef = db.collection("orders").doc();
      transaction.create(orderRef, {
        masterOrderId,
        orderNumber,
        standId,
        namaStand: standMeta.namaStand,
        penjualId: standMeta.penjualId,
        siswaId: uid,
        namaSiswa: String(student.nama ?? "Siswa"),
        kelasSiswa: String(student.kelas ?? ""),
        items: group.items,
        totalHarga: group.total,
        paymentMethod: "tunai_saat_ambil",
        status: "menunggu",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      createdOrders.push({
        orderId: orderRef.id,
        orderNumber,
        standId,
        totalHarga: group.total,
      });
    }

    return {
      masterOrderId,
      orders: createdOrders,
    };
  });
});

// Mengambil token perangkat pengguna beserta DocumentReference untuk pembersihan otomatis
async function getDeviceTokensWithRefs(uid: string): Promise<Array<{ token: string; ref: FirebaseFirestore.DocumentReference }>> {
  const devicesSnap = await db.collection("users").doc(uid).collection("devices").get();
  const results: Array<{ token: string; ref: FirebaseFirestore.DocumentReference }> = [];

  for (const doc of devicesSnap.docs) {
    const token = doc.data()?.token;
    if (typeof token === "string" && token.length > 0) {
      results.push({ token, ref: doc.ref });
    }
  }

  return results;
}

// Mengirim FCM Multicast dan membersihkan token mati/unregistered secara otomatis
async function sendPushNotification(
  tokenDocs: Array<{ token: string; ref: FirebaseFirestore.DocumentReference }>,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<void> {
  if (tokenDocs.length === 0) return;

  const tokens = tokenDocs.map((t) => t.token);

  // FCM Multicast menerima hingga 500 token per batch pemanggilan
  for (let start = 0; start < tokens.length; start += 500) {
    const tokenBatch = tokens.slice(start, start + 500);
    const docBatch = tokenDocs.slice(start, start + 500);

    const response = await getMessaging().sendEachForMulticast({
      tokens: tokenBatch,
      notification: { title, body },
      data,
      android: {
        priority: "high",
        notification: {
          channelId: "smart_canteen_orders",
          sound: "default",
        },
      },
    });

    // PEMBERSIHAN TOKEN KEDALUWARSA / MATI OTOMATIS:
    // Jika token sudah di-uninstall atau invalid, hapus dari database agar tidak membebani query selanjutnya
    const staleTokenDeletions: Promise<FirebaseFirestore.WriteResult>[] = [];
    response.responses.forEach((res, index) => {
      if (!res.success && res.error) {
        const errCode = res.error.code;
        if (
          errCode === "messaging/registration-token-not-registered" ||
          errCode === "messaging/invalid-registration-token"
        ) {
          staleTokenDeletions.push(docBatch[index].ref.delete());
        }
      }
    });

    if (staleTokenDeletions.length > 0) {
      await Promise.all(staleTokenDeletions);
    }
  }
}

// ---------------------------------------------------------------------------
// TRIGGER 1: NOTIFIKASI PESANAN BARU UNTUK PENJUAL
// Terpicu ketika dokumen /orders/{orderId} baru berhasil dibuat
// ---------------------------------------------------------------------------
export const notifySellerOnNewOrder = onDocumentCreated(
  { document: "orders/{orderId}", region: REGION },
  async (event) => {
    const order = event.data?.data();
    if (!order) return;

    let targetSellerUid = String(order.penjualId ?? "");

    // Validasi role penerima: pastikan akun tujuan benar-benar ber-role 'penjual'
    if (targetSellerUid) {
      const sellerProfile = await db.collection("users").doc(targetSellerUid).get();
      if (!sellerProfile.exists || sellerProfile.data()?.role !== "penjual") {
        return;
      }
    } else {
      // Fallback jika penjualId belum spesifik: cari penjual yang mengelola stand ini
      const standId = String(order.standId ?? "");
      const standSnap = await db.collection("stands").doc(standId).get();
      targetSellerUid = String(standSnap.data()?.penjualId ?? "");
    }

    if (!targetSellerUid) return;

    const tokens = await getDeviceTokensWithRefs(targetSellerUid);
    await sendPushNotification(
      tokens,
      "Pesanan Baru Masuk! 🍱",
      `Antrean ${String(order.orderNumber)} (${String(order.namaSiswa)} - ${String(order.kelasSiswa)}). Segera siapkan pesanan.`,
      {
        type: "new_order",
        orderId: event.params.orderId,
        orderNumber: String(order.orderNumber),
        standId: String(order.standId ?? ""),
      },
    );
  },
);

// ---------------------------------------------------------------------------
// TRIGGER 2: NOTIFIKASI PESANAN SIAP DIAMBIL UNTUK SISWA
// Terpicu ketika status pesanan berubah menjadi 'siap_diambil'
// ---------------------------------------------------------------------------
export const notifyStudentWhenReady = onDocumentUpdated(
  { document: "orders/{orderId}", region: REGION },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Filter ketat: Kirim HANYA saat status benar-benar berpindah ke 'siap_diambil'
    if (before.status === after.status || after.status !== "siap_diambil") return;

    const studentUid = String(after.siswaId ?? "");
    if (!studentUid) return;

    // Validasi role penerima: pastikan akun pemesan adalah 'siswa'
    const studentProfile = await db.collection("users").doc(studentUid).get();
    if (!studentProfile.exists || studentProfile.data()?.role !== "siswa") {
      return;
    }

    const tokens = await getDeviceTokensWithRefs(studentUid);
    await sendPushNotification(
      tokens,
      "Pesanan Siap Diambil! 🔔",
      `Pesanan ${String(after.orderNumber)} di ${String(after.namaStand)} sudah siap. Silakan ambil di meja stand dan bayar tunai.`,
      {
        type: "order_ready",
        orderId: event.params.orderId,
        orderNumber: String(after.orderNumber),
        standId: String(after.standId ?? ""),
      },
    );
  },
);
