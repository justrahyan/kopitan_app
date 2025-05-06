import 'package:flutter/material.dart';
import 'package:kopitan_app/colors.dart';
import 'package:kopitan_app/pages/admin_order_screen.dart';
import 'package:kopitan_app/pages/admin_profile_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            color: xprimaryColor,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logo-kopitan-primary.png',
                      height: 50,
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KOPITAN',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Tempat Kongkow Kongkow',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminProfileScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Hai, Selamat Datang Admin!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Lokasi Toko',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _infoCard(title: 'Transaksi Hari ini', value: '0'),
                    const SizedBox(width: 16),
                    _infoCard(title: 'Penjualan Kotor Hari ini', value: 'Rp 0'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Fitur Cepat
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fitur Cepat',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _iconButton(
                        icon: Icons.history,
                        label: 'Riwayat',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminOrderListPage(),
                            ),
                          );
                        },
                      ),
                      _iconButton(
                        icon: Icons.receipt_long,
                        label: 'Pesanan',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminOrderListPage(),
                            ),
                          );
                        },
                      ),
                      _iconButton(
                        icon: Icons.person,
                        label: 'Akun',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Info
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Info',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: xprimaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Perhatikan Jaga Kebersihan Toko ini dan juga ramah senyum ke pada pelanggan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _infoCard({required String title, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFFF3EAE1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.brown),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _iconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: xprimaryColor, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
