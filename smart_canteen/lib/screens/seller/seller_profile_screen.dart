import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/stand_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class SellerProfileScreen extends StatelessWidget {
  final String standId;

  const SellerProfileScreen({
    super.key,
    required this.standId,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Belum login')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Penjual & Stand', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colUsers)
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnap) {
          final profile = (userSnap.hasData && userSnap.data!.exists)
              ? UserModel.fromFirestore(userSnap.data!)
              : null;

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.colStands)
                .doc(standId)
                .snapshots(),
            builder: (context, standSnap) {
              final stand = (standSnap.hasData && standSnap.data!.exists)
                  ? StandModel.fromFirestore(standSnap.data!)
                  : null;

              final namaPenjual = profile?.nama ?? user.displayName ?? 'Penjual';
              final namaStand = stand?.namaStand ?? 'Stand Kantin';
              final standCode = stand?.standCode ?? 'A';
              final isOpen = stand?.isOpen ?? true;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stand Card Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                          child: const Icon(Icons.storefront_rounded, size: 38, color: AppColors.secondary),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          namaStand,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Kode Antrean: $standCode-xxx',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Saklar Buka / Tutup Stand
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: const Text('Status Operasional Stand', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: Text(
                        isOpen ? 'Stand sedang BUKA menerima pesanan' : 'Stand sedang TUTUP',
                        style: TextStyle(fontSize: 12, color: isOpen ? AppColors.success : AppColors.error, fontWeight: FontWeight.w600),
                      ),
                      value: isOpen,
                      activeColor: AppColors.success,
                      onChanged: (val) {
                        FirebaseFirestore.instance
                            .collection(AppConstants.colStands)
                            .doc(standId)
                            .update({'isOpen': val, 'updatedAt': FieldValue.serverTimestamp()});
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Detail Penjual
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
                        const Text('Informasi Pengelola', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Divider(height: 20),
                        _buildInfoRow('Nama Pengelola', namaPenjual, Icons.person_outline),
                        const SizedBox(height: 12),
                        _buildInfoRow('Email Akun', user.email ?? '-', Icons.email_outlined),
                        const SizedBox(height: 12),
                        _buildInfoRow('Peran Akun', 'Penjual / Pengelola Stand', Icons.badge_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Logout
                  CustomButton(
                    text: 'Keluar dari Akun',
                    icon: Icons.logout_rounded,
                    backgroundColor: AppColors.error,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Keluar Akun?'),
                          content: const Text('Anda akan keluar dari sesi penjual.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                AuthService().logout();
                              },
                              child: const Text('Keluar', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }
}
