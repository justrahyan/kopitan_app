import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kopitan_app/Dashboard/admin_order_history.dart';
import 'package:kopitan_app/colors.dart';
import 'dart:math';
// Import package untuk notifikasi
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminOrderListPage extends StatefulWidget {
  const AdminOrderListPage({super.key});

  @override
  State<AdminOrderListPage> createState() => _AdminOrderListPageState();
}

class _AdminOrderListPageState extends State<AdminOrderListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, String> _previousStatusMap = {};

  // Inisialisasi FlutterLocalNotificationsPlugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Simpan ID dokumen pesanan yang sudah dinotifikasi
  Set<String> _notifiedOrderIds = {};

  // Flag untuk menandai apakah kita baru mulai mendengarkan pesanan
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Inisialisasi notifikasi
    _initNotifications();

    // Mulai listen ke pesanan baru
    _loadNotifiedOrderIds().then((_) {
      // Mulai listen ke pesanan baru setelah loaded notified orders
      _listenForNewOrders();
    });
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

  Future<void> _loadNotifiedOrderIds() async {
    final prefs = await SharedPreferences.getInstance();
    final notifiedOrders = prefs.getStringList('notified_order_ids') ?? [];
    _notifiedOrderIds = Set<String>.from(notifiedOrders);
  }

  Future<void> _saveNotifiedOrderIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('notified_order_ids', _notifiedOrderIds.toList());
  }

  Future<void> _savePreviousStatus(String orderId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('previous_status_$orderId', status);
  }

  // Inisialisasi pengaturan notifikasi
  Future<void> _initNotifications() async {
    // Pengaturan untuk Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Pengaturan untuk iOS
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Gabungkan pengaturan untuk semua platform
    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // Inisialisasi plugin dengan pengaturan
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Menampilkan notifikasi pesanan baru
  Future<void> _showNewOrderNotification(
    String orderId,
    String customerName,
    String documentId,
  ) async {
    // Periksa apakah pesanan ini sudah pernah dinotifikasi
    if (_notifiedOrderIds.contains(documentId)) {
      // Pesanan sudah pernah dinotifikasi, jangan tampilkan notifikasi lagi
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'new_order_channel',
          'Notifikasi Pesanan Baru',
          channelDescription: 'Notifikasi saat ada pesanan baru masuk',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          icon: '@drawable/icon_app',
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Generate ID unik untuk notifikasi (bisa menggunakan hash dari document ID)
    final notificationId = documentId.hashCode;

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      'Pesanan Baru Masuk!',
      'Pesanan #$orderId dari $customerName menunggu konfirmasi',
      platformChannelSpecifics,
    );

    // Tandai pesanan ini sudah dinotifikasi
    _notifiedOrderIds.add(documentId);

    // Simpan ke SharedPreferences
    _saveNotifiedOrderIds();
  }

  // Listen untuk pesanan baru yang masuk
  void _listenForNewOrders() {
    // Dapatkan daftar pesanan awal untuk perbandingan
    FirebaseFirestore.instance
        .collection('order_history')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .get()
        .then((snapshot) {
          // Tandai semua pesanan yang ada sebagai sudah diketahui
          for (var doc in snapshot.docs) {
            _notifiedOrderIds.add(doc.id);
          }

          // Simpan ke SharedPreferences
          _saveNotifiedOrderIds();

          // Set _isFirstLoad menjadi false setelah mendapatkan daftar awal
          _isFirstLoad = false;
        });

    // Stream listener untuk pesanan baru dengan status pending
    FirebaseFirestore.instance
        .collection('order_history')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          // Jika masih dalam proses loading awal, jangan kirim notifikasi
          if (_isFirstLoad) {
            return;
          }

          // Periksa apakah ada dokumen baru
          for (var doc in snapshot.docChanges) {
            // Hanya perhatikan dokumen yang baru ditambahkan
            if (doc.type == DocumentChangeType.added) {
              final data = doc.doc.data();
              if (data != null) {
                final orderId = data['orderId']?.toString() ?? 'ORDER-XXX';
                final userName = data['userName'] ?? 'Pelanggan';

                // Tampilkan notifikasi
                _showNewOrderNotification(
                  orderId.length >= 3
                      ? orderId.substring(orderId.length - 3)
                      : orderId,
                  userName,
                  doc.doc.id, // Gunakan ID dokumen untuk tracking
                );
              }
            }
          }
        });
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                  IconButton(
                    icon: Image.asset(
                      'assets/images/history-primary.png',
                      width: 28,
                      height: 28,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminOrderHistoryPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: xprimaryColor,
              labelColor: xprimaryColor,
              // labelStyle: const TextStyle(fontSize: 12),
              unselectedLabelColor: Colors.black,
              tabs: const [
                Tab(text: 'Order Masuk'),
                Tab(text: 'Proses'),
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
    // Mendapatkan waktu tengah malam hari ini
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

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

        // Filter pesanan berdasarkan status dan tanggal (hanya tampilkan pesanan hari ini)
        final orders =
            docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = (data['timestamp'] as Timestamp).toDate();

              // Cek apakah pesanan pada hari ini (atau setelah tengah malam)
              final isToday =
                  timestamp.isAfter(startOfToday) ||
                  (timestamp.year == startOfToday.year &&
                      timestamp.month == startOfToday.month &&
                      timestamp.day == startOfToday.day);

              // Hanya tampilkan pesanan dengan status yang sesuai dan dari hari ini
              return statuses.contains(data['status']) && isToday;
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
                side: BorderSide(
                  color: Colors.grey.shade300, // warna border
                  width: 1, // ketebalan border
                ),
              ),
              color: Colors.white,
              elevation: 0,
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
                    // Item images dengan indikator +
                    Stack(
                      children: [
                        Row(
                          children: [
                            ...items.take(3).map((item) {
                              final imagePath =
                                  item['imagePath'] as String? ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child:
                                      imagePath.isNotEmpty
                                          ? (imagePath.startsWith('http')
                                              ? Image.network(
                                                imagePath,
                                                width: 45,
                                                height: 45,
                                                fit: BoxFit.cover,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return _buildDefaultImage(45);
                                                },
                                              )
                                              : Image.asset(
                                                imagePath,
                                                width: 45,
                                                height: 45,
                                                fit: BoxFit.cover,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return _buildDefaultImage(45);
                                                },
                                              ))
                                          : _buildDefaultImage(45),
                                ),
                              );
                            }).toList(),
                          ],
                        ),

                        if (items.length > 3)
                          Positioned(
                            left: 130, // Posisi setelah 3 item
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: xprimaryColor.withOpacity(0.8),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '+${items.length - 3}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Total & Action Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildActionButton(String status, String docId) {
    if (status == 'ready') {
      return ElevatedButton(
        onPressed: () => _showKodeValidationSheet(context, docId),
        style: ElevatedButton.styleFrom(
          backgroundColor: xprimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Masukkan Kode',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

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
      default:
        return const SizedBox(); // Tidak ada tombol untuk status lainnya
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
    final Map<String, dynamic> updates = {'status': newStatus};

    // Jika status baru adalah 'ready', generate kode 4 digit dan set codeUsed ke false
    if (newStatus == 'ready') {
      final random = Random();
      final pickupCode = (1000 + random.nextInt(9000)).toString();

      updates['pickupCode'] = pickupCode;
      updates['codeUsed'] = false;
    }

    await FirebaseFirestore.instance
        .collection('order_history')
        .doc(docId)
        .update(updates);
  }

  void _showKodeValidationSheet(BuildContext context, String docId) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Validasi Kode Pickup',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Masukkan Kode',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final doc =
                          await FirebaseFirestore.instance
                              .collection('order_history')
                              .doc(docId)
                              .get();

                      if (doc['pickupCode'] == controller.text &&
                          doc['codeUsed'] == false) {
                        await FirebaseFirestore.instance
                            .collection('order_history')
                            .doc(docId)
                            .update({'status': 'completed', 'codeUsed': true});

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Kode valid! Status diubah ke selesai.',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kode salah atau sudah digunakan.'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: xprimaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Validasi'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
