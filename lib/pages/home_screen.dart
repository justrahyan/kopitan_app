import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kopitan_app/colors.dart';
import 'package:kopitan_app/models/menu_item_model.dart';
import 'package:kopitan_app/pages/menu_detail_screen.dart';
import 'package:kopitan_app/widgets/order_bar_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitan_app/pages/app_main_screen.dart'; // <- penting

class KopitanHomeScreen extends StatefulWidget {
  const KopitanHomeScreen({super.key});

  @override
  State<KopitanHomeScreen> createState() => _KopitanHomeScreenState();
}

class _KopitanHomeScreenState extends State<KopitanHomeScreen> {
  String userName = "";
  String? userAddress;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists && mounted) {
        setState(() {
          userName = doc['full_name'];
          userAddress = doc.data()?['address'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildRekomendasiSection(),
                    const SizedBox(height: 24),
                    _buildMenuTerbaruSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: const OrderBarWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Image.asset(
          "assets/images/kopitan_banner.png",
          height: 300,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Positioned(
          bottom: -20,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hi, $userName",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          final mainState =
                              context
                                  .findAncestorStateOfType<
                                    KopitanAppMainScreenState
                                  >();
                          mainState?.switchToTab(3);
                        },
                        child: Text(
                          userAddress?.isNotEmpty == true
                              ? userAddress!
                              : "Tambahkan alamat",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color:
                                userAddress?.isNotEmpty == true
                                    ? Colors.grey
                                    : Colors.red,
                            fontStyle:
                                userAddress?.isNotEmpty == true
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: xprimaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Order",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRekomendasiSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Menu Rekomendasi",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('menus')
                    .where('isRecommended', isEqualTo: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Tidak ada menu rekomendasi'));
              }

              final menuList =
                  snapshot.data!.docs
                      .map((doc) {
                        return MenuItemModel.fromFirestore(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        );
                      })
                      .where((menu) => menu.stock > 0)
                      .toList();

              return SizedBox(
                height: 200,
                child: ListView.builder(
                  clipBehavior: Clip.none,
                  scrollDirection: Axis.horizontal,
                  itemCount: menuList.length,
                  itemBuilder: (context, index) {
                    final menu = menuList[index];
                    return Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => MenuDetailPage(
                                    name: menu.name,
                                    price: 'Rp. ${menu.price}',
                                    imagePath: menu.imageUrl,
                                  ),
                            ),
                          );
                          if (result == true) setState(() {});
                        },
                        child: _buildMenuCard(menu),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTerbaruSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Menu",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  final mainState =
                      context
                          .findAncestorStateOfType<KopitanAppMainScreenState>();
                  mainState?.switchToTab(
                    1,
                  ); // asumsikan tab 1 adalah MenuScreen
                },
                child: const Text(
                  "Semua",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('menus').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Tidak ada menu'));
              }

              final menuList =
                  snapshot.data!.docs
                      .where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        // Filter menu yang tidak direkomendasikan
                        return data['isRecommended'] == null ||
                            data['isRecommended'] == false;
                      })
                      .map((doc) {
                        return MenuItemModel.fromFirestore(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        );
                      })
                      .toList();

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: menuList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 6 / 5,
                ),
                itemBuilder: (context, index) {
                  final menu = menuList[index];
                  return GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => MenuDetailPage(
                                name: menu.name,
                                price: 'Rp. ${menu.price}',
                                imagePath: menu.imageUrl,
                              ),
                        ),
                      );
                      if (result == true) setState(() {});
                    },
                    child: _buildMenuCard(menu),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(MenuItemModel menu) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade300, // warna border
          width: 1, // ketebalan border
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(5),
              ),
              child:
                  menu.imageUrl.startsWith('http')
                      ? Image.network(
                        'https://i.imgur.com/96J5PIt.jpeg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                      : Image.asset(
                        menu.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Rp. ${menu.price}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
