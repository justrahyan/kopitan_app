import 'package:flutter/material.dart';
import 'package:kopitan_app/colors.dart';
import 'package:kopitan_app/models/icon_model.dart';
import 'package:kopitan_app/pages/home_screen.dart';
import 'package:kopitan_app/pages/menu_screen.dart';
// import 'package:kopitan_app/pages/order_screen.dart';
// import 'package:kopitan_app/pages/profile_screen.dart';

class KopitanAppMainScreen extends StatefulWidget {
  const KopitanAppMainScreen({super.key});

  @override
  State<KopitanAppMainScreen> createState() => KopitanAppMainScreenState();
}

class KopitanAppMainScreenState extends State<KopitanAppMainScreen> {
  int indexMenu = 0;
  final List<Widget> _screens = [
    const KopitanHomeScreen(),
    const KopitanMenuScreen(),
    // const OrderScreen(),
    // const ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[indexMenu],
      backgroundColor: Colors.white,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: List.generate(menu.length, (index) {
            Map items = menu[index];
            bool isActive = index == indexMenu;
            return Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    indexMenu = index;
                  });
                },
                child: SizedBox(
                  height: 70,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 20),
                      Image.asset(
                        isActive ? items['iconActive'] : items['iconInactive'],
                        width: 32,
                        height: 32,
                      ),
                      if (isActive) SizedBox(height: 7),
                      if (isActive)
                        Container(
                          height: 5,
                          width: 10,
                          decoration: BoxDecoration(
                            color: xprimaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
