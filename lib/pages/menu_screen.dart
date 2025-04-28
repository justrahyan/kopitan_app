import 'package:flutter/material.dart';
import 'package:kopitan_app/colors.dart';

class KopitanMenuScreen extends StatefulWidget {
  const KopitanMenuScreen({super.key});

  @override
  State<KopitanMenuScreen> createState() => _KopitanMenuScreenState();
}

class _KopitanMenuScreenState extends State<KopitanMenuScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _coffeeKey = GlobalKey();
  final GlobalKey _nonCoffeeKey = GlobalKey();
  final GlobalKey _freezyKey = GlobalKey();

  String selectedCategory = 'Coffee';

  void scrollToSection(GlobalKey key) {
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildUserInfo(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyCategoryTabs(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.only(top: 40, left: 15, right: 15),
                child: _buildCategoryTabs(),
              ),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: _buildSectionTitle('Coffee', key: _coffeeKey),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            sliver: _buildMenuGrid([
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
            ]),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 40)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: _buildSectionTitle('Non Coffee', key: _nonCoffeeKey),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            sliver: _buildMenuGrid([
              _buildCoffeeItem(
                'Berry Smoothie',
                'Rp. 20.000',
                'assets/images/menu/menu-4.jpg',
              ),
              _buildCoffeeItem(
                'Mango Juice',
                'Rp. 18.000',
                'assets/images/menu/menu-5.jpg',
              ),
              _buildCoffeeItem(
                'Chocolate',
                'Rp. 20.000',
                'assets/images/menu/menu-6.jpg',
              ),
            ]),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 40)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: _buildSectionTitle('Freezy', key: _freezyKey),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            sliver: _buildMenuGrid([
              _buildCoffeeItem(
                'Freezy Choco',
                'Rp. 22.000',
                'assets/images/menu/menu-7.jpg',
              ),
              _buildCoffeeItem(
                'Freezy Strawberry',
                'Rp. 22.000',
                'assets/images/menu/menu-8.jpg',
              ),
            ]),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Muhammad Rahyan Noorfauzan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            'Jl. Perintis Kemerdekaan No.18 Sulawesi Selatan, Indonesia',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    List<String> categories = ['Coffee', 'Non Coffee', 'Freezy'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children:
          categories.map((category) {
            final isSelected = selectedCategory == category;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = category;
                });

                if (category == 'Coffee') {
                  scrollToSection(_coffeeKey);
                } else if (category == 'Non Coffee') {
                  scrollToSection(_nonCoffeeKey);
                } else if (category == 'Freezy') {
                  scrollToSection(_freezyKey);
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? xprimaryColor : Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isSelected)
                      Container(height: 3, width: 20, color: xprimaryColor),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSectionTitle(String title, {required GlobalKey key}) {
    return Container(
      key: key,
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  SliverGrid _buildMenuGrid(List<Widget> items) {
    return SliverGrid(
      delegate: SliverChildListDelegate(items),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.7,
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
            padding: const EdgeInsets.all(8),
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

// Sticky Header Class
class _StickyCategoryTabs extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyCategoryTabs({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 80;

  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
