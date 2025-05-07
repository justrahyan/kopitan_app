import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_menu_page.dart';

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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(16),
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
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (stock > 0) {
                                    FirebaseFirestore.instance
                                        .collection('menus')
                                        .doc(doc.id)
                                        .update({'stock': stock - 1});
                                  }
                                },
                              ),
                              Text(
                                'Stok: $stock',
                                style: const TextStyle(fontSize: 14),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection('menus')
                                      .doc(doc.id)
                                      .update({'stock': stock + 1});
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 255, 184, 158),
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
