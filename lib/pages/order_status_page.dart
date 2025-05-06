import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class OrderStatusPage extends StatefulWidget {
  final String? orderId;

  const OrderStatusPage({super.key, this.orderId});

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8E8C9),
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getOrderQuery(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Pesanan tidak ditemukan'));
          }

          // Get the latest order
          final doc = snapshot.data!.docs.first;
          final orderData = doc.data() as Map<String, dynamic>;

          // Extract order details
          final String orderId = orderData['orderId'] ?? 'Unknown';
          final String paymentMethod = orderData['paymentMethod'] ?? 'Unknown';
          final int totalAmount = orderData['totalAmount'] ?? 0;
          final List<dynamic> items = orderData['items'] ?? [];
          final Timestamp timestamp = orderData['timestamp'] ?? Timestamp.now();
          final String status = orderData['status'] ?? 'processing';

          // Get user data
          return FutureBuilder<DocumentSnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(orderData['userId'])
                    .get(),
            builder: (context, userSnapshot) {
              String customerName = 'Customer';
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                customerName =
                    userData['name'] ?? userData['firstName'] ?? 'Customer';
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Progress bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStep(
                          icon: Icons.loop,
                          label: 'Sedang Diproses',
                          active: status == 'processing',
                        ),
                        _buildStep(
                          icon: Icons.inventory_2_outlined,
                          label: 'Siap\nDi-Pickup',
                          active: status == 'ready' || status == 'completed',
                        ),
                        _buildStep(
                          icon: Icons.check_circle_outline,
                          label: 'Pesanan\nSelesai',
                          active: status == 'completed',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Nomor Order', style: TextStyle(fontSize: 16)),
                    Text(
                      _formatOrderId(orderId),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                _getStatusMessage(status),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getStatusDescription(status),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildSectionTitle('Detail Pesanan'),
                    _buildInfoTile('Nama Pelanggan', customerName),
                    _buildInfoTile(
                      'Tanggal Order',
                      DateFormat(
                        'dd MMM yyyy, HH:mm',
                      ).format(timestamp.toDate()),
                    ),
                    _buildInfoTile('Pickup di', 'Perintis Kemerdekaan'),
                    _buildSectionTitle('Pesanan'),
                    ...items
                        .map(
                          (item) => _buildItemTile(
                            name: item['name'] ?? 'Unknown Item',
                            desc:
                                '${item['temperature'] ?? '-'}, ${item['size'] ?? '-'} (x${item['quantity']})',
                            price: currencyFormat.format(
                              item['totalPrice'] ?? 0,
                            ),
                            imagePath: item['imagePath'] ?? '',
                          ),
                        )
                        .toList(),
                    _buildSectionTitle('Detail Pembayaran'),
                    _buildInfoTile(
                      'Total Pesanan',
                      currencyFormat.format(totalAmount),
                    ),
                    _buildInfoTile('Transaksi ID', orderId),
                    _buildInfoTile('Metode Pembayaran', paymentMethod),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper method to get formatted order ID (showing just last 4 digits)
  String _formatOrderId(String orderId) {
    if (orderId.length > 8) {
      return orderId.substring(orderId.length - 8);
    }
    return orderId;
  }

  // Helper method to get status message
  String _getStatusMessage(String status) {
    switch (status) {
      case 'processing':
        return 'Pesanan Diterima';
      case 'ready':
        return 'Pesanan Siap Diambil';
      case 'completed':
        return 'Pesanan Selesai';
      default:
        return 'Pesanan Diterima';
    }
  }

  // Helper method to get status description
  String _getStatusDescription(String status) {
    switch (status) {
      case 'processing':
        return 'Mohon tunggu sebentar untuk memberi waktu ke staff kami dalam menyiapkan pesanan kamu yah';
      case 'ready':
        return 'Pesanan kamu sudah siap! Silakan ambil di outlet kami';
      case 'completed':
        return 'Terima kasih telah berbelanja di Kopitan!';
      default:
        return 'Mohon tunggu sebentar untuk memberi waktu ke staff kami dalam menyiapkan pesanan kamu yah';
    }
  }

  // Helper method to get order query
  Stream<QuerySnapshot> _getOrderQuery() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    Query query = FirebaseFirestore.instance
        .collection('order_history')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(1);

    // If orderId is provided, filter by that instead
    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      query = FirebaseFirestore.instance
          .collection('order_history')
          .where('orderId', isEqualTo: widget.orderId);
    }

    return query.snapshots();
  }

  Widget _buildStep({
    required IconData icon,
    required String label,
    bool active = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: active ? Colors.brown : Colors.grey, size: 32),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.black : Colors.grey,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[200],
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildItemTile({
    required String name,
    required String desc,
    required String price,
    required String imagePath,
  }) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child:
            imagePath.isNotEmpty && imagePath.startsWith('assets')
                ? Image.asset(
                  imagePath,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.brown[200],
                      child: const Center(
                        child: Icon(Icons.coffee, color: Colors.brown),
                      ),
                    );
                  },
                )
                : imagePath.isNotEmpty && imagePath.startsWith('http')
                ? Image.network(
                  imagePath,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.brown[200],
                      child: const Center(
                        child: Icon(Icons.coffee, color: Colors.brown),
                      ),
                    );
                  },
                )
                : Container(
                  width: 50,
                  height: 50,
                  color: Colors.brown[200],
                  child: const Center(
                    child: Icon(Icons.coffee, color: Colors.brown),
                  ),
                ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(desc),
      trailing: Text(
        price,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
