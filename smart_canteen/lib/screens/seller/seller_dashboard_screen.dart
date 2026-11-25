import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/status_badge.dart';

class SellerDashboardScreen extends StatefulWidget {
  final String standId;
  final String namaStand;

  const SellerDashboardScreen({
    super.key,
    required this.standId,
    required this.namaStand,
  });

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> with SingleTickerProviderStateMixin {
  final _orderService = OrderService();
  late TabController _tabController;

  final _statusTabs = [
    {'label': 'Menunggu', 'key': AppConstants.statusMenunggu},
    {'label': 'Diproses', 'key': AppConstants.statusDiproses},
    {'label': 'Siap Diambil', 'key': AppConstants.statusSiapDiambil},
    {'label': 'Selesai', 'key': AppConstants.statusSelesai},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String orderId, String nextStatus, String actionName) async {
    try {
      await _orderService.updateOrderStatus(orderId: orderId, nextStatus: nextStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status berhasil diubah: $actionName'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard Antrean Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.namaStand, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _statusTabs.map((t) => Tab(text: t['label'])).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statusTabs.map((tab) {
          return StreamBuilder<List<OrderModel>>(
            stream: _orderService.getSellerOrdersStream(
              standId: widget.standId,
              statusFilter: tab['key'],
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Gagal memuat pesanan: ${snapshot.error}'));
              }

              final orders = snapshot.data ?? [];

              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada pesanan berstatus "${tab['label']}"',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _buildSellerOrderCard(order);
                },
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSellerOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Nomor Antrean & Waktu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.orderNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.namaSiswa,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        Text(
                          '${order.kelasSiswa.isNotEmpty ? order.kelasSiswa : "Siswa"} • ${DateFormatter.formatTime(order.createdAt)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                StatusBadge(status: order.status, isCompact: true),
              ],
            ),
            const Divider(height: 16),

            // Daftar Makanan & Catatan Khusus
            ...order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.qty}x  ${item.namaMenu}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          CurrencyFormatter.format(item.subtotal),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (item.catatan.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Catatan: "${item.catatan}"',
                          style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              );
            }),
            const Divider(height: 16),

            // Total Pembayaran COD
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Pembayaran (COD):', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(
                  CurrencyFormatter.format(order.totalHarga),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tombol Aksi Status
            _buildActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    if (order.status == AppConstants.statusMenunggu) {
      return ElevatedButton.icon(
        onPressed: () => _updateStatus(order.id, AppConstants.statusDiproses, 'Sedang Diproses'),
        icon: const Icon(Icons.soup_kitchen_rounded, size: 18),
        label: const Text('Mulai Diproses / Masak'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.statusDiproses,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(42),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    if (order.status == AppConstants.statusDiproses) {
      return ElevatedButton.icon(
        onPressed: () => _updateStatus(order.id, AppConstants.statusSiapDiambil, 'Siap Diambil'),
        icon: const Icon(Icons.notifications_active_rounded, size: 18),
        label: const Text('Pesanan Siap Diambil (Kirim Notifikasi)'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.statusSiapDiambil,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(42),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    if (order.status == AppConstants.statusSiapDiambil) {
      return ElevatedButton.icon(
        onPressed: () => _updateStatus(order.id, AppConstants.statusSelesai, 'Pesanan Selesai'),
        icon: const Icon(Icons.check_circle_rounded, size: 18),
        label: const Text('Serahkan Pesanan & Terima Uang Tunai'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(42),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
