import 'package:flutter/material.dart';
import 'package:kopitan_app/colors.dart';

class KopitanMenuScreen extends StatefulWidget {
  const KopitanMenuScreen({super.key});

  @override
  State<KopitanMenuScreen> createState() => Kopitan_MenuScreenState();
}

class Kopitan_MenuScreenState extends State<KopitanMenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildCoffeeSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoffeeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Coffee',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'Semua',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
            children: [
              _buildCoffeeItem(
                'Gula Aren',
                'Rp. 15.000',
                'assets/images/menu/menu-1.jpg',
              ),
              _buildCoffeeItem(
                'Americano',
                'Rp. 15.000',
                'assets/images/menu/menu-2.jpg',
              ),
              _buildCoffeeItem(
                'Latte',
                'Rp. 18.000',
                'assets/images/menu/menu-3.jpg',
              ),
              _buildCoffeeItem(
                'Berry Smoothie',
                'Rp. 20.000',
                'assets/images/menu/menu-4.jpg',
              ),
              _buildCoffeeItem(
                'Gula Aren',
                'Rp. 15.000',
                'assets/images/menu/menu-5.jpg',
              ),
              _buildCoffeeItem(
                'Americano',
                'Rp. 15.000',
                'assets/images/menu/menu-6.jpg',
              ),
              _buildCoffeeItem(
                'Latte',
                'Rp. 18.000',
                'assets/images/menu/menu-7.jpg',
              ),
              _buildCoffeeItem(
                'Berry Smoothie',
                'Rp. 20.000',
                'assets/images/menu/menu-8.jpg',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoffeeItem(String name, String price, String imagePath) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: xprimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(price, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
