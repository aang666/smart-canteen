import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../common/access_denied_screen.dart';
import '../common/profile_missing_screen.dart';
import '../seller/seller_shell.dart';
import '../student/student_shell.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Sedang memeriksa status login
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = authSnapshot.data;

        // Belum login -> Tampilkan Layar Login
        if (user == null) {
          return const LoginScreen();
        }

        // Sudah login -> Baca dokumen profil dari Firestore
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(AppConstants.colUsers)
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (profileSnapshot.hasError) {
              return const ProfileMissingScreen();
            }

            if (!profileSnapshot.hasData || !profileSnapshot.data!.exists) {
              return const ProfileMissingScreen();
            }

            final data = profileSnapshot.data!.data();
            final role = data?['role'] as String?;

            if (role == AppConstants.roleSiswa) {
              return const StudentShell();
            }

            if (role == AppConstants.rolePenjual) {
              return const SellerShell();
            }

            return const AccessDeniedScreen();
          },
        );
      },
    );
  }
}
