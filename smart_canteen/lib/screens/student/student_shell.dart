import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../services/messaging_service.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'my_orders_screen.dart';
import 'student_profile_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Minta izin notifikasi dan daftarkan token perangkat siswa
    MessagingService().registerDeviceToken();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onOpenCart: () {
          setState(() {
            _currentIndex = 1;
          });
        },
      ),
      CartScreen(
        onExploreMenu: () {
          setState(() {
            _currentIndex = 0;
          });
        },
        onOrderSuccess: () {
          setState(() {
            _currentIndex = 2; // Buka tab Pesanan Saya
          });
        },
      ),
      MyOrdersScreen(
        onExploreMenu: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      const StudentProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, child) {
          final cartCount = cart.itemCount;

          return NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront_rounded),
                label: 'Menu',
              ),
              NavigationDestination(
                icon: cartCount > 0
                    ? Badge(
                        label: Text('$cartCount'),
                        backgroundColor: AppColors.secondary,
                        child: const Icon(Icons.shopping_bag_outlined),
                      )
                    : const Icon(Icons.shopping_bag_outlined),
                selectedIcon: cartCount > 0
                    ? Badge(
                        label: Text('$cartCount'),
                        backgroundColor: AppColors.secondary,
                        child: const Icon(Icons.shopping_bag_rounded),
                      )
                    : const Icon(Icons.shopping_bag_rounded),
                label: 'Keranjang',
              ),
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Pesanan',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          );
        },
      ),
    );
  }
}
