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
  int currentIndex = 0;

  final List<Map<String, dynamic>> menu = [
    {'icon': Icons.home, 'label': 'Beranda', 'screen': const AdminHomeScreen()},
    {
      'icon': Icons.receipt_long,
      'label': 'Pesanan',
      'screen': const AdminOrderListPage(),
    },
    {
      'icon': Icons.fastfood,
      'label': 'Tambah Menu',
      'screen': const SelectMenuCategoryPage(),
    },
    {
      'icon': Icons.person,
      'label': 'Akun',
      'screen': const AdminProfileScreen(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: menu[currentIndex]['screen'],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: List.generate(menu.length, (index) {
            final isActive = index == currentIndex;
            final item = menu[index];

            return Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    currentIndex = index;
                  });
                },
                child: SizedBox(
                  height: 70,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      Icon(
                        item['icon'],
                        color: isActive ? xprimaryColor : Colors.grey,
                        size: 28,
                      ),
                      if (isActive) const SizedBox(height: 6),
                      if (isActive)
                        Container(
                          height: 4,
                          width: 12,
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
