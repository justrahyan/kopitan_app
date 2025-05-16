import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kopitan_app/colors.dart';

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
      // Kompres gambar sebelum upload
      final compressedImage = await compressImage(File(picked.path));
      setState(() => _selectedImage = compressedImage);
      await _uploadToImgur(compressedImage);
    }
  }

  Future<File> compressImage(File file) async {
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path, // Gunakan absolute path
        file.path + '_compressed.jpg', // Output path
        quality: 70, // Kualitas 0-100 (70 cukup optimal)
      );
      if (result == null) {
        throw Exception("Gagal mengompres gambar");
      }
      return File(result.path);
    } catch (e) {
      print("Error saat kompresi: $e");
      return file; // Jika gagal, kembalikan file asli
    }
  }

  bool _isUploading = false;

  Future<void> _uploadToImgur(File imageFile) async {
    setState(() => _isUploading = true);
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      const clientId = '2982e95b7871a36';
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
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isUploading = false);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tambah Menu Baru'),
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.black,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      _isUploading
                          ? Center(child: CircularProgressIndicator())
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                _selectedImage != null
                                    ? Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    )
                                    : Icon(
                                      Icons.add_photo_alternate,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: xprimaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Simpan Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
