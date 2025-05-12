import 'package:flutter/material.dart';
import 'package:kopitan_app/colors.dart';
import 'package:kopitan_app/Dashboard/admin_home_screen.dart';
import 'package:kopitan_app/Dashboard/admin_order_screen.dart';
import 'package:kopitan_app/Dashboard/admin_profile_screen.dart';
import '../dashboard/select_menu_category.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int indexMenu = 0;

  final List<Map<String, dynamic>> menu = [
    {
      'iconActive': 'assets/images/home-primary.png',
      'iconInactive': 'assets/images/home-secondary.png',
      'screen': const AdminHomeScreen(),
    },
    {
      'iconActive': 'assets/images/receipt-primary.png',
      'iconInactive': 'assets/images/receipt-secondary.png',
      'screen': AdminOrderListPage(),
    },
    {
      'iconActive': 'assets/images/drink-primary.png',
      'iconInactive': 'assets/images/drink-secondary.png',
      'screen': const SelectMenuCategoryPage(),
    },
    {
      'iconActive': 'assets/images/user-primary.png',
      'iconInactive': 'assets/images/user-secondary.png',
      'screen': AdminProfileScreen(),
    },
  ];

  /// Untuk pindah tab biasa (misalnya saat klik alamat)
  void switchToTab(int index) {
    setState(() {
      indexMenu = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: menu[indexMenu]['screen'],
      backgroundColor: Colors.white,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: List.generate(menu.length, (index) {
            bool isActive = index == indexMenu;
            final item = menu[index];

            return Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    indexMenu = index;
                  });
                },
                child: SizedBox(
                  height: 70,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      Image.asset(
                        isActive ? item['iconActive'] : item['iconInactive'],
                        width: 26,
                        height: 26,
                      ),
                      if (isActive) const SizedBox(height: 7),
                      if (isActive)
                        Container(
                          height: 5,
                          width: 10,
                          decoration: BoxDecoration(
                            color: xprimaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
