import 'package:flutter/material.dart';
import 'package:kopitan_app/pages/home_page.dart';
import 'package:kopitan_app/pages/splash_screen.dart'; // Tambahkan import ini

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kopitan Plus',
      home: SplashScreen(), // Panggil halaman yang tadi kita buat
    );
  }
}
