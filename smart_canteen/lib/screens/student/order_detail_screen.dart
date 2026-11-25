import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/order_model.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/status_badge.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colOrders)
          .doc(order.id)
          .snapshots(),
      builder: (context, snapshot) {
        final currentOrder = (snapshot.hasData && snapshot.data!.exists)
            ? OrderModel.fromFirestore(snapshot.data!)
            : order;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Detail Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Hero Card Nomor Antrean & Info Stand
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              currentOrder.namaStand,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        StatusBadge(status: currentOrder.status, isCompact: true),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Nomor Antrean Anda',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentOrder.orderNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusInstruction(currentOrder.status),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Timeline Stepper Status Pesanan (GoFood / ShopeeFood Style)
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
                      'Status Pesanan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    _buildStepper(currentOrder.status),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Rincian Item Pesanan
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Daftar Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          DateFormatter.formatTimestamp(currentOrder.createdAt),
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    ...currentOrder.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.qty}x  ${item.namaMenu}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(item.subtotal),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                              ],
                            ),
                            if (item.catatan.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 3.0),
                                child: Text(
                                  'Catatan: "${item.catatan}"',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran (COD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          CurrencyFormatter.format(currentOrder.totalHarga),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Stand Lain dalam Pesanan Ini (Multi-Stand Linked Orders)
              if (currentOrder.masterOrderId.isNotEmpty) ...[
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection(AppConstants.colOrders)
                      .where('masterOrderId', isEqualTo: currentOrder.masterOrderId)
                      .snapshots(),
                  builder: (context, linkedSnap) {
                    final linkedDocs = linkedSnap.data?.docs ?? [];
                    final otherOrders = linkedDocs
                        .map((d) => OrderModel.fromFirestore(d))
                        .where((o) => o.id != currentOrder.id)
                        .toList();

                    if (otherOrders.isEmpty) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.link_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 6),
                              const Text(
                                'Stand Lain dalam Pesanan Ini',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...otherOrders.map((other) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(other.namaStand, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                      Text('Antrean: ${other.orderNumber}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  StatusBadge(status: other.status, isCompact: true),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ],

              // 5. Catatan Pengambilan
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tunjukkan layar nomor antrean ini ke penjual stand saat mengambil pesanan dan bayar menggunakan uang pas.',
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepper(String status) {
    final steps = [
      {'key': AppConstants.statusMenunggu, 'title': 'Menunggu', 'desc': 'Pesanan terkirim ke stand'},
      {'key': AppConstants.statusDiproses, 'title': 'Diproses', 'desc': 'Makanan sedang dimasak/disiapkan'},
      {'key': AppConstants.statusSiapDiambil, 'title': 'Siap Diambil', 'desc': 'Silakan ambil di meja stand'},
      {'key': AppConstants.statusSelesai, 'title': 'Selesai', 'desc': 'Sudah diambil & dibayar tunai'},
    ];

    int currentIndex = 0;
    if (status == AppConstants.statusDiproses) currentIndex = 1;
    if (status == AppConstants.statusSiapDiambil) currentIndex = 2;
    if (status == AppConstants.statusSelesai) currentIndex = 3;

    return Column(
      children: List.generate(steps.length, (idx) {
        final step = steps[idx];
        final isDone = idx <= currentIndex;
        final isCurrent = idx == currentIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.primary : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text('${idx + 1}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ),
                ),
                if (idx < steps.length - 1)
                  Container(
                    width: 2,
                    height: 32,
                    color: idx < currentIndex ? AppColors.primary : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['title']!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                        color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      step['desc']!,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  String _getStatusInstruction(String status) {
    switch (status) {
      case AppConstants.statusMenunggu:
        return 'Pesanan sedang menunggu konfirmasi penjual.';
      case AppConstants.statusDiproses:
        return 'Penjual sedang menyiapkan pesanan Anda.';
      case AppConstants.statusSiapDiambil:
        return 'PESANAN SUDAH SIAP! Segera ambil di meja stand.';
      case AppConstants.statusSelesai:
        return 'Pesanan telah selesai diserahkan.';
      default:
        return 'Memproses pesanan...';
    }
  }
}
