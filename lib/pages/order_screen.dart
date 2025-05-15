import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kopitan_app/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:kopitan_app/pages/app_main_screen.dart';
import 'package:kopitan_app/services/notification_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_status_page.dart';

class KopitanOrderScreen extends StatefulWidget {
  const KopitanOrderScreen({super.key});

  @override
  State<KopitanOrderScreen> createState() => _KopitanOrderScreenState();
}

class _KopitanOrderScreenState extends State<KopitanOrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, String> _previousStatusMap = {};
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (
        NotificationResponse notificationResponse,
      ) {
        final String? payload = notificationResponse.payload;
        if (payload != null) {
          debugPrint('Notification payload: $payload');
        }
      },
    );
  }

  Future<void> _showStatusNotification(String status, String orderId) async {
    if (!NotificationPreference.getNotificationStatus()) return;
    final previousStatus = _previousStatusMap[orderId] ?? '';

    if (previousStatus == status) return;

    _previousStatusMap[orderId] = status;
    await _savePreviousStatus(orderId, status);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'order_status_channel',
          'Order Status Notifications',
          channelDescription: 'Notifications for order status updates',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          icon: '@drawable/icon_app',
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    String title, body;
    int notificationId;

    switch (status) {
      case 'processing':
        title = 'Pesanan Diterima';
        body =
            'Pesanan #${_formatOrderId(orderId)} Anda sedang diproses. Mohon tunggu sebentar.';
        notificationId = 0;
        break;
      case 'ready':
        title = 'Pesanan Siap Diambil';
        body =
            'Pesanan #${_formatOrderId(orderId)} Anda siap untuk diambil. Silakan ambil di outlet kami.';
        notificationId = 1;
        break;
      case 'completed':
        title = 'Pesanan Selesai';
        body =
            'Pesanan #${_formatOrderId(orderId)} Anda telah selesai. Terima kasih telah berbelanja di Kopitan!';
        notificationId = 2;
        break;
      default:
        return;
    }

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      details,
      payload: 'order_id:$orderId',
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initNotifications();
    _loadAllPreviousStatuses();
  }

  Future<void> _loadAllPreviousStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (var key in keys) {
      if (key.startsWith('previous_status_')) {
        final orderId = key.replaceFirst('previous_status_', '');
        final status = prefs.getString(key) ?? '';
        _previousStatusMap[orderId] = status;
      }
    }
  }

  Future<void> _savePreviousStatus(String orderId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('previous_status_$orderId', status);
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
      stream: _getOrdersStream(),
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
                    setState(() {});
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

        final filteredOrders =
            allOrders.where((doc) {
              final orderData = doc.data() as Map<String, dynamic>;
              final String status = orderData['status'] ?? 'pending';

              if (isActive) {
                return status == 'pending' ||
                    status == 'processing' ||
                    status == 'ready';
              } else {
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

  Stream<QuerySnapshot> _getOrdersStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('order_history')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
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
    final String status = orderData['status'] ?? 'pending';
    final int totalAmount = orderData['totalAmount'] ?? 0;
    final List<dynamic> items = orderData['items'] ?? [];

    String statusText;
    switch (status) {
      case 'pending':
        statusText = 'Menunggu Konfirmasi';
        break;
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
        statusText = 'Menunggu Konfirmasi';
    }

    _showStatusNotification(status, orderId);

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.grey.shade300, // warna border
            width: 1, // ketebalan border
          ),
        ),
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

  String _formatOrderId(String orderId) {
    final parts = orderId.split('-');
    if (parts.length == 2) {
      final numberPart = parts[1];
      if (numberPart.length >= 3) {
        return numberPart.substring(numberPart.length - 3);
      }
    }
    return 'XXX';
  }

  Widget _buildItemImages(List<dynamic> items) {
    if (items.isEmpty) return const SizedBox();

    const int maxImagesToShow = 2;
    final List<Widget> imageWidgets = [];

    for (int i = 0; i < items.length && i < maxImagesToShow; i++) {
      final item = items[i];
      final String imagePath = item['imagePath'] ?? '';

      imageWidgets.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child:
                imagePath.isNotEmpty
                    ? (imagePath.toString().startsWith('https')
                        ? Image.network(
                          imagePath,
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultImage(55);
                          },
                        )
                        : Image.asset(
                          imagePath,
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultImage(55);
                          },
                        ))
                    : _buildDefaultImage(55),
          ),
        ),
      );
    }

    if (items.length > maxImagesToShow) {
      final int extraItems = items.length - maxImagesToShow;
      imageWidgets.add(
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: xprimaryColor,
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
      );
    }

    return Row(children: imageWidgets);
  }

  Widget _buildDefaultImage(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey.shade300,
      child: const Icon(
        Icons.image_not_supported,
        size: 20,
        color: Colors.grey,
      ),
    );
  }
}
