import 'package:flutter/material.dart';
import 'package:kopitan_app/pages/home_screen.dart';
import 'package:kopitan_app/pages/onboarding_screen.dart'; // Tambahkan import ini
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitan_app/pages/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      debugShowCheckedModeBanner: false,
      title: 'Kopitan Plus',
      home: SplashScreen(), // Panggil halaman yang tadi kita buat
    );
  }
}
