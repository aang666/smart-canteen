import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class ProfileMissingScreen extends StatelessWidget {
  const ProfileMissingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_off_rounded,
                  size: 72,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Profil Tidak Ditemukan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Data profil akun Anda belum terdaftar di database Firestore. Silakan hubungi pengelola kantin atau daftar kembali.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Keluar Akun',
                  backgroundColor: AppColors.error,
                  onPressed: () => AuthService().logout(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
