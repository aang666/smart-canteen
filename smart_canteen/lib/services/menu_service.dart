import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/menu_model.dart';
import '../models/stand_model.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _menuCol =>
      _db.collection(AppConstants.colMenus);

  CollectionReference<Map<String, dynamic>> get _standCol =>
      _db.collection(AppConstants.colStands);

  // Stream daftar seluruh stand kantin aktif
  Stream<List<StandModel>> getStandsStream() {
    return _standCol
        .where('isOpen', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => StandModel.fromFirestore(doc)).toList();
    });
  }

  // Stream katalog menu aktif untuk siswa (bisa filter kategori atau stand)
  Stream<List<MenuModel>> getAvailableMenusStream({String? kategori, String? standId}) {
    Query<Map<String, dynamic>> query = _menuCol.where('isAvailable', isEqualTo: true);

    if (standId != null && standId.isNotEmpty && standId != 'Semua') {
      query = query.where('standId', isEqualTo: standId);
    }

    if (kategori != null && kategori != 'Semua' && kategori.isNotEmpty) {
      query = query.where('kategori', isEqualTo: kategori);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => MenuModel.fromFirestore(doc)).toList();
    });
  }

  // Stream semua menu milik satu stand tertentu (untuk penjual)
  // Urutkan di klien agar tidak terhalang composite index yang belum siap
  Stream<List<MenuModel>> getMenusByStandStream(String standId) {
    return _menuCol
        .where('standId', isEqualTo: standId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => MenuModel.fromFirestore(doc)).toList();
      list.sort((a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0)
          .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
      return list;
    });
  }

  // Stream semua menu (fallback jika standId belum spesifik)
  Stream<List<MenuModel>> getAllMenusStream() {
    return _menuCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MenuModel.fromFirestore(doc)).toList();
    });
  }

  // Tambah menu baru oleh penjual
  Future<String> addMenu(MenuModel menu) async {
    final docRef = await _menuCol.add(menu.toMap());
    return docRef.id;
  }

  // Update data menu
  Future<void> updateMenu(MenuModel menu) async {
    await _menuCol.doc(menu.id).update(menu.toMap());
  }

  // Ubah stok langsung oleh penjual
  Future<void> updateStock(String menuId, int newStock) async {
    await _menuCol.doc(menuId).update({
      'stock': newStock,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Aktifkan / Nonaktifkan ketersediaan menu
  Future<void> toggleAvailability(String menuId, bool isAvailable) async {
    await _menuCol.doc(menuId).update({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Hapus menu oleh penjual
  Future<void> deleteMenu(String menuId) async {
    await _menuCol.doc(menuId).delete();
  }
}
