import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'package:kopitan_app/pages/splash_screen.dart';
import 'package:kopitan_app/pages/profile_screen.dart';
import 'package:kopitan_app/pages/menu_screen.dart';
import 'package:kopitan_app/pages/login_screen.dart'; // tambahkan ini jika belum

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      home: const SplashScreen(),
      routes: {
        '/profile': (context) => const KopitanProfileScreen(),
        '/login': (context) => const LoginScreen(), // pastikan halaman ini ada
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/menu') {
          final category = settings.arguments as String? ?? '';
          return MaterialPageRoute(
            builder: (_) => KopitanMenuScreen(initialCategory: category),
          );
        }
        return null;
      },
    );
  }
}
