import 'package:flutter/material.dart';
import 'package:kopitan_app/colors.dart';
import 'package:kopitan_app/widgets/admin_home_screen.dart'; // sesuaikan path ini
import 'package:kopitan_app/pages/admin_order_screen.dart';
import 'package:kopitan_app/pages/admin_profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int currentIndex = 0;

  final List<Map<String, dynamic>> menu = [
    {
      'iconActive': 'assets/images/home-primary.png',
      'iconInactive': 'assets/images/home-secondary.png',
      'label': 'Beranda',
      'screen': const AdminHomeScreen(),
    },
    {
      'iconActive': 'assets/images/receipt-primary.png',
      'iconInactive': 'assets/images/receipt-secondary.png',
      'label': 'Pesanan',
      'screen': const AdminOrderListPage(),
    },
    {
      'iconActive': 'assets/images/user-primary.png',
      'iconInactive': 'assets/images/user-secondary.png',
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
            bool isActive = index == currentIndex;
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
