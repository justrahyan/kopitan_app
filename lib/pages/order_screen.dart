import 'package:flutter/material.dart';
import 'package:kopitan_app/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:kopitan_app/pages/app_main_screen.dart';
import 'order_status_page.dart';

class KopitanOrderScreen extends StatefulWidget {
  const KopitanOrderScreen({super.key});

  @override
  State<KopitanOrderScreen> createState() => _KopitanOrderScreenState();
}

class _KopitanOrderScreenState extends State<KopitanOrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Tab Bar
            Container(
              padding: const EdgeInsets.only(top: 10),
              child: TabBar(
                controller: _tabController,
                indicatorColor: xprimaryColor,
                labelColor: xprimaryColor,
                unselectedLabelColor: Colors.black,
                tabs: const [
                  Tab(text: 'Sedang Berlangsung'),
                  Tab(text: 'Selesai'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersTab(isActive: true),
                  _buildOrdersTab(isActive: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab({required bool isActive}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getOrdersStream(isActive),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Refresh the state to try again
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: xprimaryColor,
                  ),
                  child: const Text(
                    'Refresh',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        final allOrders = snapshot.data?.docs ?? [];

        // Filter orders by status in the code instead of in the query
        final filteredOrders =
            allOrders.where((doc) {
              final orderData = doc.data() as Map<String, dynamic>;
              final String status = orderData['status'] ?? 'processing';

              if (isActive) {
                // Active orders: processing or ready
                return status == 'processing' || status == 'ready';
              } else {
                // Completed orders
                return status == 'completed';
              }
            }).toList();

        if (filteredOrders.isEmpty) {
          return _buildEmptyOrderView();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final orderData =
                filteredOrders[index].data() as Map<String, dynamic>;
            return _buildOrderCard(
              orderId: orderData['orderId'] ?? 'Unknown',
              orderDoc: filteredOrders[index],
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getOrdersStream(bool isActive) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    try {
      // First approach: just filter by userId and handle filtering by status in code
      // This avoids the need for a compound index
      return FirebaseFirestore.instance
          .collection('order_history')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots();
    } catch (e) {
      print('Error getting orders: $e');
      return Stream.empty();
    }
  }

  Widget _buildEmptyOrderView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/shop-icon.png', width: 100, height: 100),
          const SizedBox(height: 16),
          const Text(
            'Kopimu Masih Kosong!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to menu page or wherever users can place orders
              final mainState =
                  context.findAncestorStateOfType<KopitanAppMainScreenState>();
              mainState?.switchToMenuTab('Semua');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: xprimaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Pesan Sekarang',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard({
    required String orderId,
    required DocumentSnapshot orderDoc,
  }) {
    final orderData = orderDoc.data() as Map<String, dynamic>;
    final Timestamp timestamp = orderData['timestamp'] ?? Timestamp.now();
    final String dateTime = DateFormat(
      'dd MMM yyyy, HH:mm',
    ).format(timestamp.toDate());
    final String status = orderData['status'] ?? 'processing';
    final int totalAmount = orderData['totalAmount'] ?? 0;
    final List<dynamic> items = orderData['items'] ?? [];

    // Generate status display text
    String statusText;
    switch (status) {
      case 'processing':
        statusText = 'Sedang Diproses';
        break;
      case 'ready':
        statusText = 'Siap Di-Pickup';
        break;
      case 'completed':
        statusText = 'Pesanan Selesai';
        break;
      default:
        statusText = 'Sedang Diproses';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderStatusPage(orderId: orderId),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kiri: Order Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${_formatOrderId(orderId)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateTime,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    _buildItemImages(items),
                  ],
                ),
              ),
              // Kanan: Status dan Total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    statusText,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    currencyFormat.format(totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${items.length} items',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to show a compact version of the order ID
  String _formatOrderId(String orderId) {
    if (orderId.length > 3) {
      return orderId.substring(orderId.length - 3);
    }
    return orderId;
  }

  // Method to display item images with +X more if needed
  Widget _buildItemImages(List<dynamic> items) {
    if (items.isEmpty) {
      return const SizedBox();
    }

    const int maxImagesToShow = 2;
    final int totalItems = items.length;
    final List<Widget> imageWidgets = [];

    // Add images for the first maxImagesToShow items
    for (int i = 0; i < totalItems && i < maxImagesToShow; i++) {
      final item = items[i];
      final String imagePath = item['imagePath'] ?? '';

      imageWidgets.add(
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child:
                imagePath.isNotEmpty
                    ? Image.asset(
                      imagePath,
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultImage();
                      },
                    )
                    : _buildDefaultImage(),
          ),
        ),
      );
    }

    // Add "+X more" circle if there are more items than we're showing
    if (totalItems > maxImagesToShow) {
      final int extraItems = totalItems - maxImagesToShow;
      imageWidgets.add(
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: xprimaryColor.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '+$extraItems',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: imageWidgets);
  }

  Widget _buildDefaultImage() {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.brown[200],
        shape: BoxShape.circle,
      ),
      child: const Center(child: Icon(Icons.coffee, color: Colors.brown)),
    );
  }
}
