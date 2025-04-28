import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:kopitan_app/colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:google_fonts/google_fonts.dart';

class KopitanProfileScreen extends StatefulWidget {
  const KopitanProfileScreen({super.key});

  @override
  State<KopitanProfileScreen> createState() => _KopitanProfileScreenState();
}

class _KopitanProfileScreenState extends State<KopitanProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.black,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.asset(
                      'assets/images/menu/menu-1.jpg',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Muhammad Rahyan Noorfauzan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'muh_rahyan@gmail.com',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      HugeIcons.strokeRoundedPencilEdit02,
                      color: xprimaryColor,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Settings Section
            const Text(
              'Pengaturan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              HugeIcons.strokeRoundedCircleLock01,
              'Ubah Kata Sandi',
            ),
            _buildSettingItem(
              HugeIcons.strokeRoundedGlobe02,
              'Preferensi Bahasa',
            ),
            _buildSettingItem(
              HugeIcons.strokeRoundedNotification02,
              'Notifikasi',
            ),
            _buildSettingItem(HugeIcons.strokeRoundedLocation09, 'Alamat Anda'),
            const SizedBox(height: 24),
            // Privacy Section
            const Text(
              'Pengaturan Privasi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              HugeIcons.strokeRoundedSecurityLock,
              'Kelola Privasi',
            ),
            const SizedBox(height: 24),
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: xsecondaryColor, // secondary color kamu
                  padding:
                      EdgeInsets
                          .zero, // Biar padding kita atur sendiri di child
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ), // Tambah padding manual
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Keluar',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const Icon(
                        HugeIcons.strokeRoundedLogout01,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF9F9F9),
    );
  }

  Widget _buildSettingItem(IconData icon, String title) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: xprimaryColor),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(height: 1),
      ],
    );
  }
}
