import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/cart_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/custom_button.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback onExploreMenu;
  final VoidCallback onOrderSuccess;

  const CartScreen({
    super.key,
    required this.onExploreMenu,
    required this.onOrderSuccess,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _orderService = OrderService();
  bool _isLoading = false;

  Future<void> _handleCheckout(CartProvider cart) async {
    if (cart.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _orderService.placeOrder(items: cart.items);
      
      // Ambil daftar pesanan yang berhasil dibuat
      final rawOrders = result['orders'] as List<dynamic>? ?? [];
      final orderNumbers = rawOrders
          .map((o) => (o as Map)['orderNumber']?.toString() ?? '')
          .where((no) => no.isNotEmpty)
          .join(', ');

      if (mounted) {
        cart.clearCart();

        // Tampilkan dialog konfirmasi sukses
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Column(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 54),
                  SizedBox(height: 12),
                  Text(
                    'Pesanan Berhasil!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nomor antrean Anda:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      orderNumbers.isNotEmpty ? orderNumbers : 'Antrean Baru',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Silakan pantau status pesanan dan siapkan uang pas saat mengambil makanan di kantin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
              actions: [
                CustomButton(
                  text: 'Lihat Antrean Saya',
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    widget.onOrderSuccess();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Gagal membuat pesanan: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showNoteDialog(BuildContext context, CartItemModel item, CartProvider cart) {
    final noteController = TextEditingController(text: item.catatan);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Catatan untuk ${item.menu.namaMenu}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: noteController,
            maxLength: 120,
            decoration: const InputDecoration(
              hintText: 'Contoh: Jangan terlalu pedas, kuah dipisah...',
              hintStyle: TextStyle(fontSize: 13),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                cart.updateNote(item.menu.id, noteController.text.trim());
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Keranjang Belanja', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              if (cart.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Kosongkan Keranjang?'),
                      content: const Text('Semua item di keranjang akan dihapus.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                        TextButton(
                          onPressed: () {
                            cart.clearCart();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Kosongkan', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Hapus Semua', style: TextStyle(color: AppColors.error, fontSize: 13)),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Keranjang Belanja Kosong',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pilih makanan atau minuman lezat dari kantin sekarang.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      child: CustomButton(
                        text: 'Jelajahi Menu ➔',
                        onPressed: widget.onExploreMenu,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final groupedByStand = cart.itemsGroupedByStand;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // Tokopedia / Shopee Grouped by Store
                    ...groupedByStand.entries.map((entry) {
                      final standItems = entry.value;
                      final standName = standItems.first.menu.namaStand;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Stand
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.storefront_rounded, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    standName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.border),

                            // Daftar item di stand ini
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: standItems.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, indent: 14, endIndent: 14),
                              itemBuilder: (context, idx) {
                                final item = standItems[idx];
                                return _buildCartItemTile(context, item, cart);
                              },
                            ),
                          ],
                        ),
                      );
                    }),

                    // Rincian Pembayaran
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ringkasan Pesanan',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total (${cart.itemCount} item)', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              Text(CurrencyFormatter.format(cart.totalHarga), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Biaya Layanan', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              Text('Gratis', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Metode Pembayaran', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              Text('💵 Tunai (COD)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(
                                CurrencyFormatter.format(cart.totalHarga),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Total Tagihan', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                          Text(
                            CurrencyFormatter.format(cart.totalHarga),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: 'Pesan Sekarang (COD)',
                          isLoading: _isLoading,
                          onPressed: () => _handleCheckout(cart),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItemTile(BuildContext context, CartItemModel item, CartProvider cart) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: item.menu.gambarUrl.isNotEmpty
                      ? Image.network(
                          item.menu.gambarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.restaurant, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.restaurant, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Nama & Harga Satuan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.menu.namaMenu,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(item.menu.harga),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Stepper Qty (- [qty] +)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => cart.decreaseQty(item.menu.id),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(Icons.remove, size: 14, color: AppColors.textPrimary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '${item.qty}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (item.qty < item.menu.stock) {
                          cart.increaseQty(item.menu.id);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Maksimal stok tercapai'), duration: Duration(seconds: 1)),
                          );
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(Icons.add, size: 14, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Tombol Catatan Khusus
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showNoteDialog(context, item, cart),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_note_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      item.catatan.isNotEmpty ? 'Catatan: ${item.catatan}' : '+ Tulis catatan (cth: tidak pedas)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: item.catatan.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted,
                        fontStyle: item.catatan.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
