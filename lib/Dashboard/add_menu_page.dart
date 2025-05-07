import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMenuPage extends StatefulWidget {
  final String category;
  const AddMenuPage({super.key, required this.category});

  @override
  State<AddMenuPage> createState() => _AddMenuPageState();
}

class _AddMenuPageState extends State<AddMenuPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  File? _selectedImage;
  String? _uploadedImageUrl;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
      await _uploadToImgur(File(picked.path));
    }
  }

  Future<void> _uploadToImgur(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    const clientId = '2982e95b7871a36'; // Ganti dengan Client-ID kamu
    final response = await http.post(
      Uri.parse('https://api.imgur.com/3/image'),
      headers: {'Authorization': 'Client-ID $clientId'},
      body: {'image': base64Image, 'type': 'base64'},
    );

    final jsonResponse = json.decode(response.body);
    if (jsonResponse['success']) {
      setState(() {
        _uploadedImageUrl = jsonResponse['data']['link'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal upload gambar: ${jsonResponse['data']['error']}',
          ),
        ),
      );
    }
  }

  void _saveMenu() async {
    if (_formKey.currentState!.validate() && _uploadedImageUrl != null) {
      try {
        await FirebaseFirestore.instance.collection('menus').add({
          'name': nameController.text,
          'price': int.parse(priceController.text),
          'imageUrl': _uploadedImageUrl,
          'stock': int.parse(stockController.text),
          'category': widget.category,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu berhasil ditambahkan')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan menu: $e')));
      }
    } else if (_uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan upload gambar terlebih dahulu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Menu Baru')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child:
                    _selectedImage != null
                        ? Image.file(_selectedImage!, height: 180)
                        : Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.add_photo_alternate,
                            size: 60,
                          ),
                        ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Menu'),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stok Awal'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveMenu,
                child: const Text('Simpan Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
