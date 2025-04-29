import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:kopitan_app/colors.dart';

class MenuDetailPage extends StatefulWidget {
  final String name;
  final String price;
  final String imagePath;

  const MenuDetailPage({
    Key? key,
    required this.name,
    required this.price,
    required this.imagePath,
  }) : super(key: key);

  @override
  State<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends State<MenuDetailPage> {
  String selectedTemp = 'Dingin'; // Default
  String selectedSize = 'Sedang'; // Default
  int quantity = 1;

  int get priceInt => int.parse(widget.price.replaceAll(RegExp(r'[^0-9]'), ''));

  @override
  Widget build(BuildContext context) {
    int totalPrice = priceInt * quantity;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Image and Back Button
            Stack(
              children: [
                Image.asset(
                  widget.imagePath,
                  width: double.infinity,
                  height: 350,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Price - side by side
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Gula Aren',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                      Text(
                        'Rp. ${widget.price}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),

                  // === Suhu ===
                  Row(
                    children: [
                      Text(
                        'Suhu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'pilih 1',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Temperature options in a row with proper width
                  Row(
                    children: [
                      Expanded(
                        child: _buildTempOption('Dingin', double.infinity),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildTempOption('Panas', double.infinity),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),

                  // === Ukuran ===
                  Row(
                    children: [
                      Text(
                        'Ukuran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'pilih 1',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Size options in a row
                  Row(
                    children: [
                      _buildSizeOption('Kecil'),
                      SizedBox(width: 10),
                      _buildSizeOption('Sedang'),
                      SizedBox(width: 10),
                      _buildSizeOption('Besar'),
                    ],
                  ),
                ],
              ),
            ),

            // Push everything up to make room for the bottom controls
            Spacer(),

            // === Bottom Quantity and Order Button ===
            Container(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Quantity selector
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            icon: Icon(Icons.remove, size: 20),
                            onPressed: () {
                              if (quantity > 1) {
                                setState(() {
                                  quantity--;
                                });
                              }
                            },
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Colors.grey.shade300),
                              right: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Text(
                            quantity.toString(),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            icon: Icon(Icons.add, size: 20),
                            onPressed: () {
                              setState(() {
                                quantity++;
                              });
                            },
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 15),

                  // Order button - expand to fill remaining space
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final orderData = {
                          'name': widget.name,
                          'price': priceInt,
                          'totalPrice': priceInt * quantity,
                          'quantity': quantity,
                          'imagePath': widget.imagePath,
                          'temperature': selectedTemp,
                          'size': selectedSize,
                        };

                        Navigator.pop(context, orderData);
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: xprimaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(
                        HugeIcons.strokeRoundedShoppingCartAdd01,
                        color: Colors.white,
                        size: 24,
                      ),
                      label: Text(
                        'Rp. ${NumberFormat('#,###', 'id_ID').format(totalPrice)}',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTempOption(String temp, double width) {
    bool isSelected = selectedTemp == temp;
    String imagePath =
        'assets/images/' +
        (temp == 'Dingin'
            ? (isSelected ? 'ice-active.png' : 'ice-unactive.png')
            : (isSelected ? 'hot-active.png' : 'hot-unactive.png'));

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTemp = temp;
        });
      },
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Color(0xfff3f3f3),
          border: Border.all(
            color: isSelected ? xprimaryColor : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          // <--- ubah jadi Column
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 35, height: 35),
            SizedBox(height: 8),
            Text(
              temp,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
        onTap: () {
          setState(() {
            selectedSize = size;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Color(0xfff3f3f3),
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
}
