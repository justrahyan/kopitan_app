import 'package:flutter/material.dart';

class KopitanAppMainScreen extends StatefulWidget {
  const KopitanAppMainScreen({super.key});

  @override
  State<KopitanAppMainScreen> createState() => KopitanAppMainScreenState();
}

class KopitanAppMainScreenState extends State<KopitanAppMainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),
        // child: Row(children: List.generate(menu.length, generator)),
      ),
    );
  }
}
