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

  int getAdjustedPrice() {
    int adjustedPrice = priceInt;

    // Penyesuaian berdasarkan suhu
    if (selectedTemp == 'Panas') {
      adjustedPrice += 2000;
    }

    // Penyesuaian berdasarkan ukuran
    if (selectedSize == 'Kecil') {
      adjustedPrice -= 2000;
    } else if (selectedSize == 'Besar') {
      adjustedPrice += 3000;
    }

    return adjustedPrice;
  }

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    int totalPrice = getAdjustedPrice() * quantity;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        widget.imagePath.startsWith('http')
                            ? Image.network(
                              widget.imagePath,
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/no-image.png',
                                  width: double.infinity,
                                  height: 280,
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                            : Image.asset(
                              widget.imagePath,
                              width: double.infinity,
                              height: 280,
                              fit: BoxFit.cover,
                            ),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.black,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      softWrap: true,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Gula Aren',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                currencyFormat.format(priceInt),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSectionLabel("Suhu", "pilih 1"),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            children: [
                              _buildTempOption('Dingin'),
                              _buildTempOption('Panas'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSectionLabel("Ukuran", "pilih 1"),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            children: [
                              _buildSizeOption('Kecil'),
                              _buildSizeOption('Sedang'),
                              _buildSizeOption('Besar'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(child: _buildBottomBar(totalPrice)),
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTempOption(String temp) {
    bool isSelected = selectedTemp == temp;
    String imagePath =
        'assets/images/${temp == 'Dingin' ? (isSelected ? 'ice-active.png' : 'ice-unactive.png') : (isSelected ? 'hot-active.png' : 'hot-unactive.png')}';

    return GestureDetector(
      onTap: () {
        if (!mounted) return;
        setState(() => selectedTemp = temp);
      },
      child: Container(
        width: (MediaQuery.of(context).size.width - 52) / 2,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xfff3f3f3),
          border: Border.all(
            color: isSelected ? xprimaryColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(imagePath, width: 30, height: 30),
            const SizedBox(height: 6),
            Text(temp, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeOption(String size) {
    bool isSelected = selectedSize == size;
    double itemWidth = (MediaQuery.of(context).size.width - 64) / 3;

    return GestureDetector(
      onTap: () {
        if (!mounted) return;
        setState(() => selectedSize = size);
      },
      child: Container(
        width: itemWidth,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xfff3f3f3),
          border: Border.all(
            color: isSelected ? xprimaryColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            size,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.black87,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(int totalPrice) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                _buildQtyButton(Icons.remove, () {
                  if (quantity > 1) {
                    if (!mounted) return;
                    setState(() => quantity--);
                  }
                }),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '$quantity',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                _buildQtyButton(Icons.add, () {
                  if (!mounted) return;
                  setState(() => quantity++);
                }),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            fit: FlexFit.tight,
            child: ElevatedButton.icon(
              onPressed: _submitOrder,
              icon: const Icon(
                HugeIcons.strokeRoundedShoppingCartAdd01,
                color: Colors.white,
              ),
              label: Text(
                currencyFormat.format(totalPrice),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: xprimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
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
      'price': getAdjustedPrice(),
      'totalPrice': getAdjustedPrice() * quantity,
      'quantity': quantity,
      'temperature': selectedTemp,
      'size': selectedSize,
      'imagePath': widget.imagePath,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('orders').add(order);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil ditambahkan')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan pesanan: $e')));
    }
  }
}
