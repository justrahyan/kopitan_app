import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kopitan_app/colors.dart';
import 'package:kopitan_app/models/menu_item_model.dart';
import 'package:kopitan_app/pages/menu_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KopitanMenuScreen extends StatefulWidget {
  const KopitanMenuScreen({super.key});

  @override
  State<KopitanMenuScreen> createState() => _KopitanMenuScreenState();
}

class _KopitanMenuScreenState extends State<KopitanMenuScreen> {
  String selectedCategory = 'Coffee';
  String userName = "";
  String userAddress = "";
  final List<String> categories = ['Coffee', 'Non Coffee', 'Freezy'];

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
          userName = doc['full_name'] ?? '';
          userAddress =
              doc.data()!.containsKey('address') ? doc['address'] : '';
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildUserInfo(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCategoryTabs(),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildMenuByCategory(selectedCategory)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 209, 132, 77),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userName.isEmpty ? 'Loading...' : userName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            child: Text(
              userAddress.isNotEmpty ? userAddress : 'Tambahkan alamat',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Row(
      children:
          categories.map((category) {
            final isSelected = selectedCategory == category;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = category;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected ? xprimaryColor : Colors.grey,
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

  Widget _buildMenuByCategory(String category) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('menus')
              .where('category', isEqualTo: category)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Menu tidak tersedia"));
        }

        final menuList =
            snapshot.data!.docs.map((doc) {
              return MenuItemModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
            }).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            itemCount: menuList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final menu = menuList[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
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
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child:
                              menu.imageUrl.startsWith('http')
                                  ? Image.network(
                                    menu.imageUrl,
                                    fit: BoxFit.cover,
                                  )
                                  : Image.asset(
                                    menu.imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              menu.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
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
          ),
        );
      },
    );
  }
}
