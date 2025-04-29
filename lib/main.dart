import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ Wajib untuk Firebase
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart'; // ✅ File hasil flutterfire configure
import 'package:kopitan_app/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ Wajib sebelum pakai async plugin
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
    );
  }
}
