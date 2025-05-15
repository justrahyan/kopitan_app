import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitan_app/Dashboard/edit_menu_page.dart';

class RecommendedMenuPage extends StatelessWidget {
  const RecommendedMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Menu Rekomendasi'),
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.black,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('menus').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          final recommendedDocs =
              docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['isRecommended'] == true;
              }).toList();

          if (recommendedDocs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 100, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum Ada Menu Rekomendasi',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Silakan tambahkan menu rekomendasi di halaman edit menu',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recommendedDocs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // Tambahkan informasi di bagian atas
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Tambah menu rekomendasi dari halaman edit menu',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }

              final doc = recommendedDocs[index - 1];
              final data = doc.data() as Map<String, dynamic>;

              final name = data['name'] ?? 'Tanpa Nama';
              final imageUrl = data['imageUrl'] ?? '';
              final stock = data['stock'] ?? 0;
              final price = data['price'] ?? 0;
              final category = data['category'] ?? 'Tidak Berkategori';

              Widget imageWidget;
              if (imageUrl.startsWith('http')) {
                imageWidget = Image.network(
                  imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 100,
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 100),
                );
              } else {
                imageWidget = Image.asset(
                  imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 100),
                );
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              EditMenuPage(menuId: doc.id, existingData: data),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade300, // warna border
                      width: 1, // ketebalan border
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageWidget,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kategori: $category',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${NumberFormat('#,###', 'id_ID').format(price)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.brown,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory,
                                  size: 16,
                                  color: stock > 0 ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  stock > 0 ? 'Tersedia' : 'Habis',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        stock > 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Rekomendasi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }
}
