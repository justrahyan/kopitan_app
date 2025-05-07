import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kopitan_app/colors.dart';

class AdminOrderListPage extends StatefulWidget {
  const AdminOrderListPage({super.key});

  @override
  State<AdminOrderListPage> createState() => _AdminOrderListPageState();
}

class _AdminOrderListPageState extends State<AdminOrderListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo-kopitan-primary.png',
                    height: 50,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'KOPITAN',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Tempat Kongkow Kongkow'),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _deleteYesterdayCompletedOrders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Hapus Pesanan Selesai Kemarin',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.brown,
              labelColor: Colors.brown,
              unselectedLabelColor: Colors.black,
              tabs: const [
                Tab(text: 'Pesanan Masuk'),
                Tab(text: 'Sedang Di Proses'),
                Tab(text: 'Selesai'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(['pending']),
                  _buildOrderList(['processing', 'ready']),
                  _buildOrderList(['completed']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<String> statuses) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('order_history')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final orders =
            docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return statuses.contains(data['status']);
            }).toList();

        if (orders.isEmpty) {
          return const Center(child: Text('Belum ada pesanan.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final doc = orders[index];
            final data = doc.data() as Map<String, dynamic>;
            final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
            final timestamp = (data['timestamp'] as Timestamp).toDate();
            final dateFormatted = DateFormat(
              'dd MMM yyyy, HH:mm',
            ).format(timestamp);
            final status = data['status'] ?? '';
            final totalAmount = data['totalAmount'] ?? 0;
            final orderId = data['orderId']?.toString() ?? 'ORDER-000';
            final formattedOrderId =
                orderId.length >= 3
                    ? orderId.substring(orderId.length - 3)
                    : orderId;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order ID & status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#$formattedOrderId',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _statusText(status),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormatted,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    // Item images
                    Row(
                      children:
                          items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: Image.asset(
                                  item['imagePath'] ?? '',
                                  width: 45,
                                  height: 45,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Total & Action Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rp ${NumberFormat('#,###', 'id_ID').format(totalAmount)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${items.length} items',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        _buildActionButton(status, doc.id),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton(String status, String docId) {
    String label = '';
    String nextStatus = '';

    switch (status) {
      case 'pending':
        label = 'Konfirmasi Pesanan';
        nextStatus = 'processing';
        break;
      case 'processing':
        label = 'Siap Pick Up';
        nextStatus = 'ready';
        break;
      case 'ready':
        label = 'Selesaikan';
        nextStatus = 'completed';
        break;
      default:
        return const SizedBox();
    }

    return ElevatedButton(
      onPressed: () => _updateStatus(docId, nextStatus),
      style: ElevatedButton.styleFrom(
        backgroundColor: xprimaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pesanan Masuk';
      case 'processing':
        return 'Diproses';
      case 'ready':
        return 'Siap Di-Pickup';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  void _updateStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('order_history')
        .doc(docId)
        .update({'status': newStatus});
  }

  void _deleteYesterdayCompletedOrders() async {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    final snapshot =
        await FirebaseFirestore.instance
            .collection('order_history')
            .where('status', isEqualTo: 'completed')
            .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final timestamp = (data['timestamp'] as Timestamp).toDate();
      final isYesterday =
          timestamp.year == yesterday.year &&
          timestamp.month == yesterday.month &&
          timestamp.day == yesterday.day;

      if (isYesterday) {
        await FirebaseFirestore.instance
            .collection('order_history')
            .doc(doc.id)
            .delete();
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pesanan selesai kemarin berhasil dihapus')),
    );
  }
}
