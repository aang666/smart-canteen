import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/constants/app_constants.dart';
import 'package:smart_canteen/models/menu_model.dart';
import 'package:smart_canteen/models/user_model.dart';
import 'package:smart_canteen/providers/cart_provider.dart';

void main() {
  group('LKPD Smart Canteen - Verifikasi Otomatis Kriteria Pengujian', () {
    // -------------------------------------------------------------------------
    // Kriteria 1: Registrasi siswa valid -> Akun dibuat dan role benar
    // -------------------------------------------------------------------------
    test('Kriteria 1 & 13: UserModel memiliki role "siswa" yang valid', () {
      final siswa = UserModel(
        uid: 'siswa_01',
        nama: 'Budi Santoso',
        email: 'budi@smk.sch.id',
        role: AppConstants.roleSiswa,
        kelas: 'XII RPL 1',
      );

      expect(siswa.isSiswa, isTrue);
      expect(siswa.isPenjual, isFalse);
      expect(siswa.role, equals('siswa'));
      expect(siswa.kelas, equals('XII RPL 1'));

      final penjual = UserModel(
        uid: 'penjual_01',
        nama: 'Pak Barokah',
        email: 'barokah@kantin.com',
        role: AppConstants.rolePenjual,
        standId: 'stand_01',
      );
      expect(penjual.isPenjual, isTrue);
      expect(penjual.isSiswa, isFalse);
    });

    // -------------------------------------------------------------------------
    // Kriteria 4: Menu stok 0 / tidak aktif -> Pemesanan tidak dapat dilakukan
    // -------------------------------------------------------------------------
    test('Kriteria 4: Menu canOrder false saat stok 0 atau isAvailable false', () {
      final menuHabis = MenuModel(
        id: 'menu_01',
        namaMenu: 'Ayam Geprek',
        deskripsi: 'Ayam sambal bawang',
        kategori: 'Makanan Berat',
        harga: 13000,
        stock: 0,
        gambarUrl: '',
        isAvailable: true,
      );
      expect(menuHabis.canOrder, isFalse, reason: 'Stok 0 tidak boleh bisa dipesan');

      final menuNonaktif = MenuModel(
        id: 'menu_02',
        namaMenu: 'Es Teh Manis',
        deskripsi: 'Segar',
        kategori: 'Minuman',
        harga: 3000,
        stock: 10,
        gambarUrl: '',
        isAvailable: false,
      );
      expect(menuNonaktif.canOrder, isFalse, reason: 'Menu nonaktif tidak boleh bisa dipesan');

      final menuTersedia = MenuModel(
        id: 'menu_03',
        namaMenu: 'Tahu Krispi',
        deskripsi: 'Gurih',
        kategori: 'Camilan',
        harga: 5000,
        stock: 5,
        gambarUrl: '',
        isAvailable: true,
      );
      expect(menuTersedia.canOrder, isTrue, reason: 'Stok > 0 dan aktif harus bisa dipesan');
    });

    // -------------------------------------------------------------------------
    // Kriteria 5: Tambah / kurangi item -> Jumlah dan total berubah benar
    // -------------------------------------------------------------------------
    test('Kriteria 5: CartProvider menghitung total item dan totalHarga dengan benar', () {
      final cart = CartProvider();
      final menu1 = MenuModel(
        id: 'm1',
        standId: 'stand_01',
        namaStand: 'Stand Barokah',
        namaMenu: 'Ayam Geprek',
        deskripsi: '',
        kategori: 'Makanan',
        harga: 13000,
        stock: 10,
        gambarUrl: '',
        isAvailable: true,
      );

      final menu2 = MenuModel(
        id: 'm2',
        standId: 'stand_01',
        namaStand: 'Stand Barokah',
        namaMenu: 'Es Teh Manis',
        deskripsi: '',
        kategori: 'Minuman',
        harga: 3000,
        stock: 10,
        gambarUrl: '',
        isAvailable: true,
      );

      // Tambah item 1
      cart.addItem(menu1);
      expect(cart.itemCount, equals(1));
      expect(cart.totalHarga, equals(13000));

      // Tambah item 2
      cart.addItem(menu2);
      expect(cart.itemCount, equals(2));
      expect(cart.totalHarga, equals(16000));

      // Tingkatkan qty item 2
      cart.increaseQty('m2');
      expect(cart.itemCount, equals(3));
      expect(cart.totalHarga, equals(19000)); // 13.000 + (3.000 * 2)

      // Kurangi qty item 2
      cart.decreaseQty('m2');
      expect(cart.itemCount, equals(2));
      expect(cart.totalHarga, equals(16000));

      // Hapus item
      cart.removeItem('m1');
      expect(cart.itemCount, equals(1));
      expect(cart.totalHarga, equals(3000));
    });

    // -------------------------------------------------------------------------
    // Kriteria 6: Checkout keranjang kosong -> Sistem menolak checkout
    // -------------------------------------------------------------------------
    test('Kriteria 6: Cart kosong terdeteksi dengan tepat', () {
      final cart = CartProvider();
      expect(cart.isEmpty, isTrue);
      expect(cart.items.isEmpty, isTrue);
      expect(cart.totalHarga, equals(0));
    });

    // -------------------------------------------------------------------------
    // Kriteria 11: Siswa pesan dari dua stand -> Pesanan terpisah untuk setiap stand
    // -------------------------------------------------------------------------
    test('Kriteria 11: Multi-stand split grouping memisahkan item per standId', () {
      final cart = CartProvider();
      final menuStandA = MenuModel(
        id: 'mA',
        standId: 'stand_01',
        namaStand: 'Stand Barokah (A)',
        namaMenu: 'Nasi Kuning',
        deskripsi: '',
        kategori: 'Makanan',
        harga: 10000,
        stock: 5,
        gambarUrl: '',
        isAvailable: true,
      );

      final menuStandB = MenuModel(
        id: 'mB',
        standId: 'stand_02',
        namaStand: 'Stand Berkah Minum (B)',
        namaMenu: 'Jus Alpukat',
        deskripsi: '',
        kategori: 'Minuman',
        harga: 8000,
        stock: 5,
        gambarUrl: '',
        isAvailable: true,
      );

      cart.addItem(menuStandA);
      cart.addItem(menuStandB);

      final grouped = cart.itemsGroupedByStand;
      expect(grouped.keys.length, equals(2), reason: 'Harus dipisah menjadi 2 grup stand');
      expect(grouped.containsKey('stand_01'), isTrue);
      expect(grouped.containsKey('stand_02'), isTrue);

      expect(grouped['stand_01']!.length, equals(1));
      expect(grouped['stand_01']!.first.menu.namaMenu, equals('Nasi Kuning'));

      expect(grouped['stand_02']!.length, equals(1));
      expect(grouped['stand_02']!.first.menu.namaMenu, equals('Jus Alpukat'));
    });
  });
}
