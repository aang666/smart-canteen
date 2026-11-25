import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/menu_model.dart';
import '../../services/menu_service.dart';
import '../../utils/currency_formatter.dart';
import 'menu_form_screen.dart';

class ManageMenuScreen extends StatelessWidget {
  final String standId;
  final String namaStand;

  const ManageMenuScreen({
    super.key,
    required this.standId,
    required this.namaStand,
  });

  void _showQuickStockDialog(BuildContext context, MenuModel menu, MenuService service) {
    final controller = TextEditingController(text: menu.stock.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ubah Stok: ${menu.namaMenu}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Jumlah Stok Baru',
            suffixText: 'porsi',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(controller.text.trim());
              if (newStock != null && newStock >= 0) {
                service.updateStock(menu.id, newStock);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, MenuModel menu, MenuService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Menu?'),
        content: Text('Apakah Anda yakin ingin menghapus "${menu.namaMenu}" dari katalog?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              service.deleteMenu(menu.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuService = MenuService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Kelola Menu • $namaStand', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Menu'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MenuFormScreen(standId: standId, namaStand: namaStand),
            ),
          );
        },
      ),
      body: StreamBuilder<List<MenuModel>>(
        stream: menuService.getMenusByStandStream(standId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat menu: ${snapshot.error}'));
          }

          final menus = snapshot.data ?? [];

          if (menus.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant_menu_rounded, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  const Text('Belum Ada Menu di Stand Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Tekan tombol "Tambah Menu" di bawah untuk mulai berjualan.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
            itemCount: menus.length,
            itemBuilder: (context, index) {
              final menu = menus[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail Foto
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: menu.gambarUrl.isNotEmpty
                              ? Image.network(menu.gambarUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200, child: const Icon(Icons.restaurant)))
                              : Container(color: Colors.grey.shade200, child: const Icon(Icons.restaurant)),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Info Menu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    menu.namaMenu,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                Switch(
                                  value: menu.isAvailable,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) => menuService.toggleAvailability(menu.id, val),
                                ),
                              ],
                            ),
                            Text(
                              CurrencyFormatter.format(menu.harga),
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13),
                            ),
                            const SizedBox(height: 6),

                            Row(
                              children: [
                                // Badge Stok dengan Tombol Ubah Cepat
                                InkWell(
                                  onTap: () => _showQuickStockDialog(context, menu, menuService),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: menu.stock > 0 ? AppColors.primary.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.inventory_2_outlined, size: 12, color: menu.stock > 0 ? AppColors.primary : AppColors.error),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Stok: ${menu.stock}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: menu.stock > 0 ? AppColors.primary : AppColors.error,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.edit, size: 10, color: AppColors.textSecondary),
                                      ],
                                    ),
                                  ),
                                ),
                                const Spacer(),

                                // Tombol Edit
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MenuFormScreen(
                                          standId: standId,
                                          namaStand: namaStand,
                                          existingMenu: menu,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // Tombol Hapus
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                  onPressed: () => _confirmDelete(context, menu, menuService),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
