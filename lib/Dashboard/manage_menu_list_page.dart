import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitan_app/Dashboard/edit_menu_page.dart';
import 'package:kopitan_app/colors.dart';
import 'add_menu_page.dart';
import 'package:intl/intl.dart';

class ManageMenuListPage extends StatelessWidget {
  final String category;
  const ManageMenuListPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final normalizedCategory = category.toLowerCase();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Daftar Menu $category'),
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

          final filteredDocs =
              docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final cat = (data['category'] ?? '').toString().toLowerCase();
                return cat == normalizedCategory;
              }).toList();

          if (filteredDocs.isEmpty) {
            return const Center(
              child: Text('Belum ada menu dalam kategori ini.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = data['name'] ?? 'Tanpa Nama';
              final imageUrl = data['imageUrl'] ?? '';
              final stock = data['stock'] ?? 0;
              final price = data['price'] ?? 0;

              Widget imageWidget;
              if (imageUrl.startsWith('http')) {
                // Gambar dari internet (Imgur)
                imageWidget = Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 80,
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 80),
                );
              } else {
                // Gambar dari lokal asset
                imageWidget = Image.asset(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 80),
                );
              }

              // Tambahkan return di sini untuk mengembalikan GestureDetector
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => EditMenuPage(
                                menuId: doc.id,
                                existingData: data,
                              ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // Gambar produk
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imageWidget,
                          ),
                          const SizedBox(width: 16),
                          // Informasi produk (nama dan harga)
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
                                  'Rp ${NumberFormat('#,###', 'id_ID').format(price)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Kontrol stok di sebelah kanan
                          Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  stock == 1
                                      ? IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () async {
                                          final confirm = await showDialog<
                                            bool
                                          >(
                                            context: context,
                                            builder:
                                                (context) => AlertDialog(
                                                  title: const Text(
                                                    'Hapus Menu',
                                                  ),
                                                  content: const Text(
                                                    'Apakah Anda yakin ingin menghapus menu ini?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      child: const Text(
                                                        'Batal',
                                                      ),
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                    ),
                                                    TextButton(
                                                      child: const Text(
                                                        'Hapus',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                          );

                                          if (confirm == true) {
                                            await FirebaseFirestore.instance
                                                .collection('menus')
                                                .doc(doc.id)
                                                .delete();
                                          }
                                        },
                                      )
                                      : IconButton(
                                        icon: const Icon(Icons.remove),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          if (stock > 0) {
                                            FirebaseFirestore.instance
                                                .collection('menus')
                                                .doc(doc.id)
                                                .update({'stock': stock - 1});
                                          }
                                        },
                                      ),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$stock',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      FirebaseFirestore.instance
                                          .collection('menus')
                                          .doc(doc.id)
                                          .update({'stock': stock + 1});
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Stok',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Label Rekomendasi
                  if (data['isRecommended'] == true)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Rekomendasi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: xprimaryColor,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddMenuPage(category: category)),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
