import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitan_app/colors.dart';
import 'package:kopitan_app/pages/app_main_screen.dart';
import 'package:kopitan_app/pages/menu_screen.dart';

class KopitanHomeScreen extends StatefulWidget {
  const KopitanHomeScreen({super.key});

  @override
  State<KopitanHomeScreen> createState() => _KopitanHomeScreenState();
}

class _KopitanHomeScreenState extends State<KopitanHomeScreen> {
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
                _buildHeaderSection(),
                const SizedBox(height: 20),
                _buildRecommendationSection(),
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

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/kopitan_banner.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
            Transform.translate(
              offset: Offset(0, -30), // Naik 30px biar nempel banner
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10), // padding keseluruhan
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .center, // centerkan tulisan & tombol
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hi, Muhammad Rahyan Noorfauzan",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Jl. Perintis Kemerdekaan No.18 Sulawesi Selatan, Telkomas, Indonesia",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          height: 45,
                          width: 70,
                          decoration: BoxDecoration(
                            color: xprimaryColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Order",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
      ), // tambahkan padding di sini
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rekomendasi Spesial untuk Anda',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildRecommendationCard(
                  'Coffee Aren Latte',
                  'Buy One Get One Coffee',
                  'Rp. 20.000',
                  'assets/images/menu/menu-1.jpg',
                ),
                _buildRecommendationCard(
                  'Triple Shot Espresso',
                  'Mix & Match!!',
                  'Rp. 25.000',
                  'assets/images/menu/menu-2.jpg',
                ),
                _buildRecommendationCard(
                  'Cappucino',
                  'Green Tea Jumbo 1L',
                  'Rp. 15.000',
                  'assets/images/menu/menu-3.jpg',
                ),
                _buildRecommendationCard(
                  'Bubble Tea',
                  'Mix & Match!!',
                  'Rp. 18.000',
                  'assets/images/menu/menu-4.jpg',
                ),
                _buildRecommendationCard(
                  'Aren Latte',
                  'Green Tea Jumbo 1L',
                  'Rp. 18.000',
                  'assets/images/menu/menu-5.jpg',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
    String title,
    String subtitle,
    String price,
    String imagePath,
  ) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Text(price, style: GoogleFonts.poppins(color: Colors.black)),
        ],
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
            children: [
              Text(
                'Coffee',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              GestureDetector(
                onTap: () {
                  // Gunakan Navigator untuk mengubah index di KopitanAppMainScreen
                  final parentState =
                      context
                          .findAncestorStateOfType<KopitanAppMainScreenState>();
                  if (parentState != null) {
                    parentState.setState(() {
                      parentState.indexMenu =
                          1; // Angka 1 sesuai dengan index menu di bottom nav
                    });
                  }
                },
                child: const Text(
                  'Semua',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
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
