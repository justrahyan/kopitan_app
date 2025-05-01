import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:kopitan_app/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuDetailPage extends StatefulWidget {
  final String name;
  final String price;
  final String imagePath;

  const MenuDetailPage({
    super.key,
    required this.name,
    required this.price,
    required this.imagePath,
  });

  @override
  State<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends State<MenuDetailPage> {
  String selectedTemp = 'Dingin';
  String selectedSize = 'Sedang';
  int quantity = 1;

  int get priceInt => int.parse(widget.price.replaceAll(RegExp(r'[^0-9]'), ''));

  @override
  Widget build(BuildContext context) {
    int totalPrice = priceInt * quantity;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                widget.imagePath.startsWith('http')
                    ? Image.network(
                      widget.imagePath,
                      width: double.infinity,
                      height: 350,
                      fit: BoxFit.cover,
                    )
                    : Image.asset(
                      widget.imagePath,
                      width: double.infinity,
                      height: 350,
                      fit: BoxFit.cover,
                    ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Gula Aren',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                      Text(
                        'Rp. ${widget.price}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildSectionLabel("Suhu", "pilih 1"),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTempOption('Dingin')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTempOption('Panas')),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildSectionLabel("Ukuran", "pilih 1"),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildSizeOption('Kecil'),
                      const SizedBox(width: 10),
                      _buildSizeOption('Sedang'),
                      const SizedBox(width: 10),
                      _buildSizeOption('Besar'),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            _buildBottomBar(totalPrice),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, String subtitle) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTempOption(String temp) {
    bool isSelected = selectedTemp == temp;
    String imagePath =
        'assets/images/${temp == 'Dingin' ? (isSelected ? 'ice-active.png' : 'ice-unactive.png') : (isSelected ? 'hot-active.png' : 'hot-unactive.png')}';

    return GestureDetector(
      onTap: () => setState(() => selectedTemp = temp),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xfff3f3f3),
          border: Border.all(
            color: isSelected ? xprimaryColor : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Image.asset(imagePath, width: 35, height: 35),
            const SizedBox(height: 8),
            Text(
              temp,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeOption(String size) {
    bool isSelected = selectedSize == size;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedSize = size),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : const Color(0xfff3f3f3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? xprimaryColor : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              size,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(int totalPrice) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          // Quantity
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                _buildQtyButton(Icons.remove, () {
                  if (quantity > 1) setState(() => quantity--);
                }),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '$quantity',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                _buildQtyButton(Icons.add, () => setState(() => quantity++)),
              ],
            ),
          ),
          const SizedBox(width: 15),
          // Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: xprimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(
                HugeIcons.strokeRoundedShoppingCartAdd01,
                color: Colors.white,
              ),
              label: Text(
                'Rp. ${NumberFormat('#,###', 'id_ID').format(totalPrice)}',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _submitOrder() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    final order = {
      'userId': user.uid,
      'name': widget.name,
      'price': priceInt,
      'quantity': quantity,
      'totalPrice': priceInt * quantity,
      'temperature': selectedTemp,
      'size': selectedSize,
      'imagePath': widget.imagePath,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('orders').add(order);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil ditambahkan')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan pesanan: $e')));
    }
  }
}
