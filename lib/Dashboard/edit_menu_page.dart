import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kopitan_app/colors.dart';

class EditMenuPage extends StatefulWidget {
  final String menuId;
  final Map<String, dynamic> existingData;

  const EditMenuPage({
    super.key,
    required this.menuId,
    required this.existingData,
  });

  @override
  State<EditMenuPage> createState() => _EditMenuPageState();
}

class _EditMenuPageState extends State<EditMenuPage> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  bool isRecommended = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.existingData['name']);
    priceController = TextEditingController(
      text: widget.existingData['price'].toString(),
    );
    isRecommended = widget.existingData['isRecommended'] ?? false;
  }

  void saveChanges() async {
    final newName = nameController.text.trim();
    final newPrice = int.tryParse(priceController.text.trim()) ?? 0;

    await FirebaseFirestore.instance
        .collection('menus')
        .doc(widget.menuId)
        .update({
          'name': newName,
          'price': newPrice,
          'isRecommended': isRecommended,
        });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Menu berhasil diperbarui')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Menu"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nama Menu"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Harga"),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Rekomendasikan Menu",
                  style: TextStyle(fontSize: 16),
                ),
                Switch(
                  value: isRecommended,
                  activeColor: xprimaryColor,
                  onChanged: (val) {
                    setState(() {
                      isRecommended = val;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: xprimaryColor,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                "Simpan",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
