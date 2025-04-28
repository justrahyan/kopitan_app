import 'package:flutter/material.dart';
import 'package:kopitan_app/pages/app_main_screen.dart';
import 'package:kopitan_app/pages/home_screen.dart';
import 'package:kopitan_app/pages/menu_screen.dart';
import 'package:kopitan_app/pages/order_screen.dart';
import 'package:kopitan_app/pages/profile_screen.dart';

final menu = [
  {
    'iconActive': 'assets/images/home-primary.png',
    'iconInactive': 'assets/images/home-secondary.png',
    'destination': const KopitanHomeScreen(),
  },
  {
    'iconActive': 'assets/images/drink-primary.png',
    'iconInactive': 'assets/images/drink-secondary.png',
    'destination': const KopitanMenuScreen(),
  },
  {
    'iconActive': 'assets/images/receipt-primary.png',
    'iconInactive': 'assets/images/receipt-secondary.png',
    'destination': const KopitanOrderScreen(),
  },
  {
    'iconActive': 'assets/images/user-primary.png',
    'iconInactive': 'assets/images/user-secondary.png',
    'destination': const KopitanProfileScreen(),
  },
];
