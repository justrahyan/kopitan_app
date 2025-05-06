import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitan_app/colors.dart';

class OrderStatusPage extends StatefulWidget {
  final String? orderId;

  const OrderStatusPage({super.key, this.orderId});

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
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

          final doc = snapshot.data!.docs.first;
          final orderData = doc.data() as Map<String, dynamic>;

          final String orderId = orderData['orderId'] ?? 'Unknown';
          final String paymentMethod = orderData['paymentMethod'] ?? 'Unknown';
          final int totalAmount = orderData['totalAmount'] ?? 0;
          final List<dynamic> items = orderData['items'] ?? [];
          final Timestamp timestamp = orderData['timestamp'] ?? Timestamp.now();
          final String status = orderData['status'] ?? 'processing';

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
                customerName = userData['full_name'] ?? 'Customer';
              }

              return Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          color: xthirdColor,
                          padding: const EdgeInsets.only(top: 20, bottom: 20),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildProgressStep(
                                      icon: "refresh",
                                      label: 'Sedang\nDiproses',
                                      active: status == 'processing',
                                      isFirst: true,
                                      isCompleted:
                                          status == 'ready' ||
                                          status == 'completed',
                                    ),
                                    _buildProgressLine(
                                      isActive:
                                          status == 'ready' ||
                                          status == 'completed',
                                    ),
                                    _buildProgressStep(
                                      icon: "package",
                                      label: 'Siap\nDi-Pickup',
                                      active: status == 'ready',
                                      isCompleted: status == 'completed',
                                    ),
                                    _buildProgressLine(
                                      isActive: status == 'completed',
                                    ),
                                    _buildProgressStep(
                                      icon: "check_circle",
                                      label: 'Pesanan\nSelesai',
                                      active: status == 'completed',
                                      isLast: true,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Nomor Order',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                _formatOrderId(orderId),
                                style: const TextStyle(
                                  fontSize: 46,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -40),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Card(
                              color: Colors.white,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Text(
                                      _getStatusMessage(status),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _getStatusDescription(status),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Card(
                            color: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _buildSectionHeader(
                                  'Detail Pesanan',
                                  DateFormat(
                                    'dd MMM yyyy, HH:mm',
                                  ).format(timestamp.toDate()),
                                ),
                                _buildInfoRow(
                                  icon: Icons.person_outline,
                                  label: 'Nama Pelanggan',
                                  value: customerName,
                                ),
                                _buildInfoRow(
                                  icon: Icons.location_on_outlined,
                                  label: 'Pickup di',
                                  value: 'Perintis Kemerdekaan',
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Card(
                            color: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _buildSectionHeader(
                                  'Pesanan',
                                  'Total ${items.length} items',
                                ),
                                ...items.map(
                                  (item) => _buildOrderItemTile(
                                    name: item['name'] ?? 'Unknown Item',
                                    desc:
                                        '${item['temperature'] ?? '-'}, ${item['size'] ?? '-'}',
                                    price: currencyFormat.format(
                                      item['totalPrice'] ?? 0,
                                    ),
                                    quantity: item['quantity'] ?? 1,
                                    imagePath: item['imagePath'] ?? '',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Card(
                            color: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _buildSectionHeader(
                                  'Detail Pembayaran',
                                  DateFormat(
                                    'dd MMM yyyy, HH:mm',
                                  ).format(timestamp.toDate()),
                                ),
                                _buildPaymentInfoRow(
                                  label: 'Total Pesanan',
                                  value: currencyFormat.format(totalAmount),
                                ),
                                _buildPaymentInfoRow(
                                  label: 'Transaksi ID',
                                  value: orderId.substring(orderId.length - 6),
                                ),
                                _buildPaymentMethodRow(
                                  paymentMethod: paymentMethod,
                                  value: currencyFormat.format(totalAmount),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _formatOrderId(String orderId) {
    if (orderId.length > 3) {
      return orderId.substring(orderId.length - 3);
    }
    return orderId;
  }

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

    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      query = FirebaseFirestore.instance
          .collection('order_history')
          .where('orderId', isEqualTo: widget.orderId);
    }

    return query.snapshots();
  }

  Widget _buildProgressStep({
    required String icon,
    required String label,
    bool active = false,
    bool isCompleted = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    Color circleColor;
    Color iconColor;
    Color textColor;

    if (isCompleted) {
      circleColor = xprimaryColor;
      iconColor = Colors.white;
      textColor = Colors.black;
    } else if (active) {
      circleColor = xprimaryColor;
      iconColor = Colors.white;
      textColor = Colors.black;
    } else {
      circleColor = Colors.white;
      iconColor = Colors.grey;
      textColor = Colors.grey;
    }

    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleColor,
            border: Border.all(
              color: active || isCompleted ? xprimaryColor : Colors.grey,
              width: 2,
            ),
          ),
          child: Icon(_getIconData(icon), color: iconColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: textColor,
            fontWeight:
                active || isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine({bool isActive = false}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? xprimaryColor : Colors.grey[300],
      ),
    );
  }

  IconData _getIconData(String icon) {
    switch (icon) {
      case 'refresh':
        return Icons.refresh;
      case 'package':
        return Icons.inventory_2_outlined;
      case 'check_circle':
        return Icons.check_circle_outline;
      default:
        return Icons.circle_outlined;
    }
  }

  Widget _buildSectionHeader(String title, String trailingText) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            trailingText,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.orangeAccent),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemTile({
    required String name,
    required String desc,
    required String price,
    required int quantity,
    required String imagePath,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:
                imagePath.isNotEmpty
                    ? Image.asset(
                      imagePath,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultImage();
                      },
                    )
                    : _buildDefaultImage(),
          ),
          const SizedBox(width: 12),
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
                  desc,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
            ),
            child: Text(
              'x$quantity',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.brown[200],
      child: const Center(child: Icon(Icons.coffee, color: Colors.brown)),
    );
  }

  Widget _buildPaymentInfoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodRow({
    required String paymentMethod,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _getPaymentMethodLogo(paymentMethod),
              ),
              const SizedBox(width: 12),
              Text(
                paymentMethod.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _getPaymentMethodLogo(String paymentMethod) {
    IconData iconData;

    switch (paymentMethod.toLowerCase()) {
      case 'qris':
        iconData = Icons.qr_code;
        break;
      case 'cash':
        iconData = Icons.money;
        break;
      case 'credit_card':
        iconData = Icons.credit_card;
        break;
      default:
        iconData = Icons.payment;
    }

    return Icon(iconData, size: 24);
  }
}
