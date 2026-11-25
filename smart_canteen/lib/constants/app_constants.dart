class AppConstants {
  // Roles
  static const String roleSiswa = 'siswa';
  static const String rolePenjual = 'penjual';

  // Firestore Collections
  static const String colUsers = 'users';
  static const String colStands = 'stands';
  static const String colMenus = 'menus';
  static const String colOrders = 'orders';
  static const String colCounters = 'counters';
  static const String colDevices = 'devices';
  static const String colNotifications = 'notifications';

  // Order Statuses
  static const String statusMenunggu = 'menunggu';
  static const String statusDiproses = 'diproses';
  static const String statusSiapDiambil = 'siap_diambil';
  static const String statusSelesai = 'selesai';
  static const String statusDibatalkan = 'dibatalkan';

  // Order Status Labels (Bahasa Indonesia)
  static const Map<String, String> statusLabels = {
    statusMenunggu: 'Menunggu',
    statusDiproses: 'Diproses',
    statusSiapDiambil: 'Siap Diambil',
    statusSelesai: 'Selesai',
    statusDibatalkan: 'Dibatalkan',
  };

  // Payment Method
  static const String paymentTunaiSaatAmbil = 'tunai_saat_ambil';
  static const String paymentMethodLabel = 'Tunai saat Pengambilan (COD)';

  // Menu Categories
  static const List<String> menuCategories = [
    'Semua',
    'Makanan Berat',
    'Camilan',
    'Minuman',
  ];

  static const List<String> editableCategories = [
    'Makanan Berat',
    'Camilan',
    'Minuman',
  ];
}
