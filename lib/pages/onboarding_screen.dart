import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitan_app/pages/login_screen.dart';
import 'package:kopitan_app/widgets/common_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _logoOffsetAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _logoOffsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -2.3),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 300), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxHeight < 600;

          return Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.asset(
                  "assets/images/splash_screen.png",
                  fit: BoxFit.cover,
                ),
              ),

              // Logo animasi tengah
              Center(
                child: SlideTransition(
                  position: _logoOffsetAnimation,
                  child: Image.asset(
                    'assets/images/logo-kopitan-white.png',
                    width: size.width * 0.28,
                    height: size.width * 0.28,
                  ),
                ),
              ),

              // Konten bawah
              Positioned(
                left: 24,
                right: 24,
                bottom: safePadding.bottom + 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Mulai Hari dengan Kopi Terbaik.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: isSmall ? 22 : 28,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Dari espresso hingga latte favoritmu, kami siap menemani harimu dengan satu klik.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: isSmall ? 13 : 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 36),
                    CommonButton(
                      title: "Mulai Sekarang",
                      onTab: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
