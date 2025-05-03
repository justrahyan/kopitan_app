import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kopitan_app/colors.dart';
import 'package:kopitan_app/models/menu_item_model.dart';
import 'package:kopitan_app/pages/menu_detail_screen.dart';
import 'package:kopitan_app/pages/profile_screen.dart';
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
                  children: [
                    _buildHeader(),
                    _buildCategorySection("Coffee"),
                    _buildCategorySection("Non Coffee"),
                    _buildCategorySection("Freezy"),
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
      children: [
        Image.asset(
          "assets/images/kopitan_banner.png",
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Positioned(
          bottom: 0,
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const KopitanProfileScreen(),
                            ),
                          );
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

  Widget _buildCategorySection(String category) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header kategori + tombol "Semua"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              GestureDetector(
                onTap: () {
                  final mainState =
                      context
                          .findAncestorStateOfType<KopitanAppMainScreenState>();
                  mainState?.switchToMenuTab(category);
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
            stream:
                FirebaseFirestore.instance
                    .collection('menus')
                    .where('category', isEqualTo: category)
                    .limit(4)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("Menu tidak tersedia");
              }

              final menuList =
                  snapshot.data!.docs.map((doc) {
                    return MenuItemModel.fromFirestore(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                  }).toList();

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: menuList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 3 / 4,
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
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 5),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child:
                                  menu.imageUrl.startsWith('http')
                                      ? Image.network(
                                        menu.imageUrl,
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
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
