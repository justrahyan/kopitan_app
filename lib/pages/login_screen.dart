import 'package:flutter/material.dart';
import 'package:kopitan_app/pages/auth_service.dart';
import 'package:kopitan_app/pages/admin_dashboard_screen.dart';
import 'package:kopitan_app/pages/register_screen.dart';
import 'package:kopitan_app/pages/app_main_screen.dart'; // <- ini bottom nav utama
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'assets/images/logo-kopitan-primary.png',
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Masuk Akun',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                _buildTextField(_emailController, 'Email'),
                const SizedBox(height: 16),
                _buildTextField(
                  _passwordController,
                  'Kata Sandi',
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: const Color(0xFFB87544),
                          onChanged: (bool? value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                        const Text('Ingat Saya'),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Lupa Sandi?',
                        style: TextStyle(color: Color(0xFFB87544)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB87544),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _login,
                    child: const Text(
                      'Masuk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text(
                    'Belum punya akun? Daftar',
                    style: TextStyle(color: Colors.brown),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan kata sandi harus diisi.')),
      );
      return;
    }

    User? user = await _authService.loginUser(email, password);

    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        String role = userDoc.get('role');

        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const KopitanAppMainScreen()),
          );
        }
      } catch (e) {
        print('Firestore error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengambil data user dari database.'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login gagal. Periksa email dan kata sandi.'),
        ),
      );
    }
  }
}
