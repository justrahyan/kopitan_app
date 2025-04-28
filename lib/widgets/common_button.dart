import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitan_app/colors.dart';

class CommonButton extends StatelessWidget {
  final String title;
  final VoidCallback onTab;
  const CommonButton({super.key, required this.title, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        onTap: onTab,
        child: SizedBox(
          height: 45,
          width: double.infinity,
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: xprimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
