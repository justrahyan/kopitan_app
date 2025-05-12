import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'manage_menu_list_page.dart';

class SelectMenuCategoryPage extends StatelessWidget {
  const SelectMenuCategoryPage({super.key});

  final List<String> categories = const ['Coffee', 'Non Coffee', 'Freezy'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Daftar Menu'),
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.black,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('menus').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allMenus = snapshot.data!.docs;

          // Hitung jumlah item per kategori
          Map<String, int> categoryCounts = {};
          for (var category in categories) {
            categoryCounts[category] =
                allMenus.where((doc) => doc['category'] == category).length;
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children:
                  categories.map((category) {
                    final count = categoryCounts[category] ?? 0;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ManageMenuListPage(category: category),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7F2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$count item',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          );
        },
      ),
    );
  }
}
