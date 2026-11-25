import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../services/messaging_service.dart';
import 'manage_menu_screen.dart';
import 'seller_dashboard_screen.dart';
import 'seller_profile_screen.dart';

class SellerShell extends StatefulWidget {
  const SellerShell({super.key});

  @override
  State<SellerShell> createState() => _SellerShellState();
}

class _SellerShellState extends State<SellerShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Daftarkan token perangkat penjual untuk menerima pesanan masuk
    MessagingService().registerDeviceToken();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Belum login')));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final profile = (snapshot.hasData && snapshot.data!.exists)
            ? UserModel.fromFirestore(snapshot.data!)
            : null;

        final standId = profile?.standId?.isNotEmpty == true ? profile!.standId! : 'stand_01';

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(AppConstants.colStands)
              .doc(standId)
              .snapshots(),
          builder: (context, standSnap) {
            final standData = standSnap.data?.data();
            final namaStand = standData?['namaStand'] as String? ?? 'Stand Kantin';

            final screens = [
              SellerDashboardScreen(standId: standId, namaStand: namaStand),
              ManageMenuScreen(standId: standId, namaStand: namaStand),
              SellerProfileScreen(standId: standId),
            ];

            return Scaffold(
              body: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.pending_actions_outlined),
                    selectedIcon: Icon(Icons.pending_actions_rounded),
                    label: 'Pesanan Masuk',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.restaurant_menu_outlined),
                    selectedIcon: Icon(Icons.restaurant_menu_rounded),
                    label: 'Kelola Menu',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.storefront_outlined),
                    selectedIcon: Icon(Icons.storefront_rounded),
                    label: 'Profil Stand',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
