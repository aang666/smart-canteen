# 🍱 Smart Canteen — Aplikasi Pemesanan Kantin Sekolah Bebas Antre

[![Build & Release Android APK](https://github.com/aang666/smart-canteen/actions/workflows/build_apk.yml/badge.svg)](https://github.com/aang666/smart-canteen/actions/workflows/build_apk.yml)
[![Latest Release](https://img.shields.io/github/v/release/aang666/smart-canteen?color=orange&label=Download%20APK)](https://github.com/aang666/smart-canteen/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%26%20Auth-FFCA28?logo=firebase)](https://firebase.google.com)

**Smart Canteen** adalah aplikasi pemesanan makanan dan minuman di kantin sekolah berbasis mobile (Android & Web) yang dirancang untuk mengatasi antrean panjang saat jam istirahat sekolah. Aplikasi ini mendukung sistem **multi-stand (split order)**, pelacakan antrean real-time, dan pembayaran tunai saat pengambilan (Cash on Delivery).

---

## 📱 Unduh Aplikasi (Siap Pakai)
Siapapun dapat langsung mengunduh dan menginstal aplikasi di ponsel Android tanpa perlu login ke GitHub:

👉 **[Unduh File APK Terbaru (smart-canteen.apk)](https://github.com/aang666/smart-canteen/releases/latest)**

---

## ✨ Fitur Utama

### 1. 🎓 Siswa (Pembeli)
- **Registrasi & Autentikasi**: Mendaftar akun siswa dengan nama lengkap, kelas, email, dan kata sandi.
- **Katalog Menu Real-time**: Menjelajahi menu kantin dengan filter kategori (*Makanan Berat*, *Camilan*, *Minuman*) dan pencarian instan.
- **Validasi Stok Otomatis**: Menu dengan stok kosong atau berstatus tidak aktif dinonaktifkan secara otomatis sehingga mencegah *overselling*.
- **Keranjang Belanja Fleksibel**: Mengatur kuantitas item, menambahkan catatan khusus per menu (misal: *"jangan terlalu pedas"*), dan ringkasan total belanja.
- **Checkout COD**: Pembayaran tunai saat pengambilan di stand kantin (*tunai_saat_ambil*) tanpa memerlukan gateway pembayaran rumit.
- **Nomor Antrean & Pelacakan Status Real-time**: Setiap pesanan mendapatkan nomor antrean dengan status bertahap:
  `Menunggu` ➔ `Diproses` ➔ `Siap Diambil` ➔ `Selesai`.
- **Notifikasi Pesanan**: Notifikasi otomatis saat pesanan sudah siap untuk diambil di stand.

### 2. 🏪 Penjual (Pengelola Stand)
- **Pendaftaran Stand Baru**: Penjual dapat mendaftar dengan identitas pemilik, nama stand kantin, dan deskripsi toko.
- **Dashboard Pesanan Khusus**: Penjual hanya melihat dan mengelola pesanan yang ditujukan ke stand miliknya sendiri.
- **Manajemen Status Pesanan**: Mengubah status antrean secara bertahap (*Menunggu* ➔ *Diproses* ➔ *Siap Diambil* ➔ *Selesai*).
- **Kelola Menu & Stok**: Menambah menu baru, memperbarui informasi, mengatur stok sisa, mengunggah foto menu, dan mengaktifkan/menonaktifkan ketersediaan menu.

### 3. 🔄 Multi-Stand / Split-Order
- Siswa dapat memesan menu dari beberapa stand berbeda dalam satu keranjang belanja.
- Saat checkout, sistem secara atomik **memecah keranjang menjadi pesanan terpisah per stand** (*split order*).
- Setiap stand mendapatkan nomor antrean dan kartu pesanan mandiri, sementara siswa dapat memantau progres masing-masing stand secara terpisah.

---

## 🛠️ Arsitektur & Teknologi

| Komponen | Teknologi | Keterangan |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart SDK ^3.14) | Desain responsif Material 3 |
| **State Management** | Provider | Mengelola state keranjang belanja (`CartProvider`) |
| **Autentikasi** | Firebase Authentication | Email & Password untuk Siswa dan Penjual |
| **Database** | Cloud Firestore | Real-time streams & Atomic Transactions checkout |
| **Hosting Gambar** | ImgBB REST API | Penyimpanan cloud untuk gambar menu |
| **Notifikasi** | Flutter Local Notifications & FCM | Pemberitahuan status pesanan siap diambil |
| **CI / CD** | GitHub Actions | Otomatisasi build & rilis APK ke GitHub Releases |

---

## 👥 Akun Demo untuk Pengujian

### 👨‍🍳 Akun Penjual Stand Bawaan (Password: `password123`)
| Akun | Stand | Kode Stand |
| :--- | :--- | :---: |
| `penjual1@kantin.com` | Stand Barokah | **A** |
| `penjual2@kantin.com` | Bakso & Mie Mas Doni | **B** |
| `penjual3@kantin.com` | Dapur Maknyus Bu Ani | **C** |
| `penjual4@kantin.com` | Corner Snack & Toast | **D** |
| `penjual5@kantin.com` | Fresh Drinks & Boba | **E** |

*(Penjual baru juga dapat mendaftar langsung lewat tombol **Daftar** di aplikasi).*

---

## 🚀 Cara Menjalankan Proyek Secara Lokal

### Prasyarat:
- Flutter SDK (3.24+ disarankan)
- Git

### 1. Clone Repository
```bash
git clone https://github.com/aang666/smart-canteen.git
cd smart-canteen/smart_canteen
```

### 2. Pasang Dependensi
```bash
flutter pub get
```

### 3. Jalankan Mode Web (Bisa dibuka di browser HP / PC tanpa Android SDK)
```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```
Buka browser di alamat `http://localhost:8080` (atau IP lokal Anda di browser ponsel).

### 4. Build File APK (Jika Android SDK terpasang)
```bash
flutter build apk --release
```

---

## 🧪 Pengujian Otomatis
Proyek ini dilengkapi pengujian unit otomatis untuk memverifikasi kriteria fungsionalitas sistem:
```bash
flutter test test/lkpd_criteria_test.dart
```

---

## 📂 Struktur Direktori

```text
smart_canteen/
├── lib/
│   ├── constants/       # Konstanta tema, warna, dan status pesanan
│   ├── models/          # Model data (User, Stand, Menu, Order, CartItem)
│   ├── providers/       # State management (CartProvider)
│   ├── screens/
│   │   ├── auth/        # Login, Register (Siswa & Penjual), AuthGate
│   │   ├── common/      # Access denied, Profile missing
│   │   ├── seller/      # Dashboard, Kelola Menu, Profil Penjual
│   │   └── student/     # Katalog, Keranjang, Tracking Pesanan, Profil Siswa
│   ├── services/        # AuthService, MenuService, OrderService, StorageService
│   ├── utils/          # Formatter mata uang dan tanggal
│   └── widgets/        # Komponen UI (MenuCard, CustomButton, StatusBadge, dll.)
├── firestore.rules      # Keamanan dan aturan akses database Cloud Firestore
└── .github/workflows/   # Pipeline GitHub Actions CI/CD (Build & Release APK)
```

---
*Dikembangkan untuk Uji Kompetensi Keahlian (UKK) Rekayasa Perangkat Lunak (RPL).*
