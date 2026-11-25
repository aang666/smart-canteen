import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersCol =>
      _db.collection(AppConstants.colOrders);

  // ===========================================================================
  // PEMESANAN / CHECKOUT (Transaksi Atomik ACID Firestore Langsung)
  // Menjamin penghitungan harga fresh dari database, pengurangan stok atomik,
  // pencegahan stok negatif, pembuatan nomor antrean berurutan, dan split-order
  // per stand tanpa memerlukan langganan berbayar (Blaze) Firebase Functions.
  // ===========================================================================
  Future<Map<String, dynamic>> placeOrder({
    required List<CartItemModel> items,
  }) async {
    // 1. Validasi keranjang di sisi klien
    if (items.isEmpty) {
      throw Exception('Keranjang belanja Anda masih kosong.');
    }

    // Jalankan transaksi atomik Firestore
    return placeOrderDirectFirestoreTransaction(items: items);
  }

  // ===========================================================================
  // METODE 2: TRANSAKSI FIRESTORE LOKAL (Native Dart runTransaction)
  // Digunakan untuk telaah arsitektur transaksi ACID langsung di klien Dart.
  // ===========================================================================
  Future<Map<String, dynamic>> placeOrderDirectFirestoreTransaction({
    required List<CartItemModel> items,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Silakan login terlebih dahulu.');

    if (items.isEmpty) throw Exception('Keranjang tidak boleh kosong.');

    // Kelompokkan item berdasarkan menuId untuk mencegah race condition item duplikat
    final Map<String, int> groupedQty = {};
    final Map<String, String> groupedNotes = {};
    for (final item in items) {
      final id = item.menu.id;
      groupedQty[id] = (groupedQty[id] ?? 0) + item.qty;
      if (item.catatan.isNotEmpty) {
        groupedNotes[id] = item.catatan;
      }
    }

    final dateKey = DateFormat('yyyyMMdd').format(DateTime.now());

    // Jalankan Firestore Transaction ACID
    return _db.runTransaction<Map<String, dynamic>>((transaction) async {
      // -------------------------------------------------------------
      // FASE 1: BACA SEMUA DOKUMEN TERLEBIH DAHULU (ALL READS FIRST)
      // -------------------------------------------------------------

      // 1. Baca profil pemesan
      final userRef = _db.collection(AppConstants.colUsers).doc(user.uid);
      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) throw Exception('Profil pengguna tidak ditemukan.');
      final userData = userSnap.data()!;
      if (userData['role'] != AppConstants.roleSiswa) {
        throw Exception('Hanya akun siswa yang diizinkan memesan.');
      }

      // 2. Baca seluruh snapshot menu dari database secara langsung
      // PENTING: Jangan percaya harga dari keranjang/client! Ambil harga fresh dari server.
      final menuRefs = <DocumentReference<Map<String, dynamic>>>[];
      final menuSnaps = <DocumentSnapshot<Map<String, dynamic>>>[];
      final uniqueStandIds = <String>{};

      for (final menuId in groupedQty.keys) {
        final ref = _db.collection(AppConstants.colMenus).doc(menuId);
        menuRefs.add(ref);
        final snap = await transaction.get(ref);
        if (!snap.exists) throw Exception('Salah satu menu tidak ditemukan di database.');
        menuSnaps.add(snap);
        uniqueStandIds.add(snap.data()?['standId'] as String? ?? 'stand_utama');
      }

      // 3. Baca dokumen stand dan counter nomor antrean masing-masing stand
      final standDataMap = <String, Map<String, dynamic>>{};
      final counterRefMap = <String, DocumentReference<Map<String, dynamic>>>{};
      final counterSnapMap = <String, DocumentSnapshot<Map<String, dynamic>>>{};

      for (final standId in uniqueStandIds) {
        final sRef = _db.collection(AppConstants.colStands).doc(standId);
        final sSnap = await transaction.get(sRef);
        standDataMap[standId] = sSnap.data() ?? {
          'standCode': 'A',
          'namaStand': 'Kantin Utama',
          'penjualId': '',
        };

        final cRef = _db.collection(AppConstants.colCounters).doc('counter_${standId}_$dateKey');
        counterRefMap[standId] = cRef;
        counterSnapMap[standId] = await transaction.get(cRef);
      }

      // -------------------------------------------------------------
      // FASE 2: VALIDASI BISNIS & HITUNG ULANG TOTAL DENGAN HARGA ASLI
      // -------------------------------------------------------------
      final standItemsMap = <String, List<Map<String, dynamic>>>{};
      final standTotalMap = <String, int>{};

      for (int i = 0; i < menuSnaps.length; i++) {
        final snap = menuSnaps[i];
        final menuData = snap.data()!;
        final menuId = snap.id;
        final requestedQty = groupedQty[menuId]!;

        final isAvailable = menuData['isAvailable'] as bool? ?? false;
        final currentStock = (menuData['stock'] as num?)?.toInt() ?? 0;
        final dbPrice = (menuData['harga'] as num?)?.toInt() ?? 0; // Harga asli database
        final standId = menuData['standId'] as String? ?? 'stand_utama';
        final namaMenu = menuData['namaMenu'] as String? ?? 'Menu';

        // Validasi ketersediaan dan stok
        if (!isAvailable) {
          throw Exception('Menu "$namaMenu" saat ini sedang dinonaktifkan.');
        }
        if (currentStock < requestedQty) {
          throw Exception('Stok untuk "$namaMenu" tidak mencukupi (Tersisa: $currentStock, diminta: $requestedQty).');
        }

        final subtotal = dbPrice * requestedQty;

        standItemsMap.putIfAbsent(standId, () => []).add({
          'menuId': menuId,
          'namaMenu': namaMenu,
          'hargaSatuan': dbPrice,
          'qty': requestedQty,
          'catatan': groupedNotes[menuId] ?? '',
          'subtotal': subtotal,
        });

        standTotalMap[standId] = (standTotalMap[standId] ?? 0) + subtotal;

        // Potong stok secara atomik
        transaction.update(menuRefs[i], {
          'stock': currentStock - requestedQty,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // -------------------------------------------------------------
      // FASE 3: PENULISAN DOKUMEN PESANAN & NOMOR ANTREAN (ALL WRITES)
      // -------------------------------------------------------------
      final masterOrderId = 'grp_${dateKey}_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final createdOrders = <Map<String, dynamic>>[];

      for (final standId in standItemsMap.keys) {
        final standInfo = standDataMap[standId]!;
        final standCode = standInfo['standCode'] as String? ?? 'A';
        final counterSnap = counterSnapMap[standId]!;
        final counterRef = counterRefMap[standId]!;

        final lastNumber = (counterSnap.data()?['lastNumber'] as num?)?.toInt() ?? 0;
        final nextNumber = lastNumber + 1;
        final orderNumber = '$standCode-${nextNumber.toString().padLeft(3, '0')}';

        // Perbarui counter harian stand
        transaction.set(counterRef, {
          'standId': standId,
          'standCode': standCode,
          'lastNumber': nextNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Buat dokumen order
        final newOrderRef = _ordersCol.doc();
        final orderPayload = {
          'masterOrderId': masterOrderId,
          'orderNumber': orderNumber,
          'standId': standId,
          'namaStand': standInfo['namaStand'] ?? 'Kantin',
          'penjualId': standInfo['penjualId'] ?? '',
          'siswaId': user.uid,
          'namaSiswa': userData['nama'] ?? 'Siswa',
          'kelasSiswa': userData['kelas'] ?? '',
          'items': standItemsMap[standId]!,
          'totalHarga': standTotalMap[standId]!,
          'paymentMethod': AppConstants.paymentTunaiSaatAmbil,
          'status': AppConstants.statusMenunggu,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        transaction.set(newOrderRef, orderPayload);

        createdOrders.add({
          'orderId': newOrderRef.id,
          'orderNumber': orderNumber,
          'standId': standId,
          'totalHarga': standTotalMap[standId]!,
        });
      }

      return {
        'masterOrderId': masterOrderId,
        'orders': createdOrders,
      };
    });
  }

  // Stream pesanan milik siswa yang sedang login
  Stream<List<OrderModel>> getMyOrdersStream(String uid) {
    return _ordersCol
        .where('siswaId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      // Urutkan di klien agar tidak terhalang pembuatan composite index
      list.sort((a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0)
          .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
      return list;
    });
  }

  // Stream pesanan masuk untuk dashboard penjual khusus stand miliknya
  Stream<List<OrderModel>> getSellerOrdersStream({
    required String standId,
    String? statusFilter,
  }) {
    Query<Map<String, dynamic>> query = _ordersCol.where('standId', isEqualTo: standId);

    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'Semua') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      // Urutkan di klien (FIFO/Terbaru) agar instan tampil tanpa menunggu index
      list.sort((a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0)
          .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
      return list;
    });
  }

  // Update status pesanan oleh penjual (menunggu -> diproses -> siap_diambil -> selesai)
  Future<void> updateOrderStatus({
    required String orderId,
    required String nextStatus,
  }) async {
    await _ordersCol.doc(orderId).update({
      'status': nextStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
