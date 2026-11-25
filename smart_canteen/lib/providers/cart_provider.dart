import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/menu_model.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItemModel> _items = {};

  List<CartItemModel> get items => _items.values.toList();

  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.qty);

  int get totalHarga => _items.values.fold(0, (sum, item) => sum + item.subtotal);

  bool get isEmpty => _items.isEmpty;

  // Mengelompokkan item berdasarkan standId untuk multi-stand split order
  Map<String, List<CartItemModel>> get itemsGroupedByStand {
    final Map<String, List<CartItemModel>> grouped = {};
    for (final item in _items.values) {
      grouped.putIfAbsent(item.menu.standId, () => []).add(item);
    }
    return grouped;
  }

  // Menambah menu ke keranjang
  void addItem(MenuModel menu, {int qty = 1, String catatan = ''}) {
    if (!menu.canOrder) return;

    if (_items.containsKey(menu.id)) {
      final existing = _items[menu.id]!;
      final newQty = existing.qty + qty;
      // Jangan melebihi stok yang ada
      existing.qty = newQty <= menu.stock ? newQty : menu.stock;
      if (catatan.isNotEmpty) {
        existing.catatan = catatan;
      }
    } else {
      _items[menu.id] = CartItemModel(
        menu: menu,
        qty: qty <= menu.stock ? qty : menu.stock,
        catatan: catatan,
      );
    }
    notifyListeners();
  }

  // Tambah jumlah qty suatu item
  void increaseQty(String menuId) {
    if (!_items.containsKey(menuId)) return;
    final item = _items[menuId]!;
    if (item.qty < item.menu.stock && item.qty < 20) {
      item.qty += 1;
      notifyListeners();
    }
  }

  // Kurangi jumlah qty suatu item
  void decreaseQty(String menuId) {
    if (!_items.containsKey(menuId)) return;
    final item = _items[menuId]!;
    if (item.qty > 1) {
      item.qty -= 1;
      notifyListeners();
    } else {
      removeItem(menuId);
    }
  }

  // Hapus item dari keranjang
  void removeItem(String menuId) {
    if (_items.containsKey(menuId)) {
      _items.remove(menuId);
      notifyListeners();
    }
  }

  // Perbarui catatan per item
  void updateNote(String menuId, String note) {
    if (_items.containsKey(menuId)) {
      _items[menuId]!.catatan = note;
      notifyListeners();
    }
  }

  // Kosongkan keranjang belanja
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
