import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitan_app/widgets/common_button.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        height: size.height,
        width: size.width,
        child: Stack(
          children: [
            SizedBox.expand(
              child: Image.asset(
                "assets/images/splash_screen.png",
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              bottom: 45,
              right: 0,
              left: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Mulai Hari dengan Kopi Terbaik.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Dari espresso hingga latte favoritmu, kami siap menemani harimu dengan satu klik.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 50),
                    CommonButton(title: "Mulai Sekarang", onTab: () {}),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
