import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:kopitan_app/colors.dart';
import 'package:kopitan_app/pages/login_screen.dart';

class KopitanProfileScreen extends StatefulWidget {
  const KopitanProfileScreen({super.key});

  @override
  State<KopitanProfileScreen> createState() => _KopitanProfileScreenState();
}

class _KopitanProfileScreenState extends State<KopitanProfileScreen> {
  String fullName = '';
  String email = '';
  String address = '';
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          fullName = data?['full_name'] ?? '';
          email = data?['email'] ?? '';
          address = data?['address'] ?? '';
        });
        _addressController.text = address;
      }
    }
  }

  Future<void> _updateAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'address': _addressController.text.trim()},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alamat berhasil diperbarui')),
        );
        _loadUserData();
      }
    }
  }

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
            _buildProfileHeader(),
            const SizedBox(height: 24),
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
            _buildAlamatItem(),
            const SizedBox(height: 24),
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
            _buildLogoutButton(),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF9F9F9),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5),
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
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildAlamatItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(
            HugeIcons.strokeRoundedLocation09,
            color: xprimaryColor,
          ),
          title: TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              hintText: 'Tambahkan alamat...',
              border: InputBorder.none,
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.save, color: xprimaryColor),
            onPressed: _updateAddress,
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: xsecondaryColor,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Keluar',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Icon(
                HugeIcons.strokeRoundedLogout01,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
