import 'menu_model.dart';

class CartItemModel {
  final MenuModel menu;
  int qty;
  String catatan;

  CartItemModel({
    required this.menu,
    this.qty = 1,
    this.catatan = '',
  });

  int get subtotal => menu.harga * qty;

  Map<String, dynamic> toOrderItemMap() {
    return {
      'menuId': menu.id,
      'namaMenu': menu.namaMenu,
      'hargaSatuan': menu.harga,
      'qty': qty,
      'catatan': catatan.trim(),
      'subtotal': subtotal,
    };
  }

  CartItemModel copyWith({
    MenuModel? menu,
    int? qty,
    String? catatan,
  }) {
    return CartItemModel(
      menu: menu ?? this.menu,
      qty: qty ?? this.qty,
      catatan: catatan ?? this.catatan,
    );
  }
}
