import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kopitan_app/Dashboard/admin_order_history.dart';
import 'package:kopitan_app/colors.dart';
import 'dart:math';
// Import package untuk notifikasi
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AdminOrderListPage extends StatefulWidget {
  const AdminOrderListPage({super.key});

  @override
  State<AdminOrderListPage> createState() => _AdminOrderListPageState();
}

class _AdminOrderListPageState extends State<AdminOrderListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Inisialisasi FlutterLocalNotificationsPlugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Simpan ID dokumen pesanan terakhir untuk tracking pesanan baru
  List<String> _lastOrderIds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Inisialisasi notifikasi
    _initNotifications();

    // Mulai listen ke pesanan baru
    _listenForNewOrders();
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
  ) async {
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

    await flutterLocalNotificationsPlugin.show(
      0,
      'Pesanan Baru Masuk!',
      'Pesanan #$orderId dari $customerName menunggu konfirmasi',
      platformChannelSpecifics,
    );
  }

  // Listen untuk pesanan baru yang masuk
  void _listenForNewOrders() {
    // Dapatkan daftar pesanan awal untuk perbandingan
    FirebaseFirestore.instance
        .collection('order_history')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get()
        .then((snapshot) {
          _lastOrderIds = snapshot.docs.map((doc) => doc.id).toList();
        });

    // Stream listener untuk pesanan baru dengan status pending
    FirebaseFirestore.instance
        .collection('order_history')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          // Periksa apakah ada dokumen baru
          for (var doc in snapshot.docs) {
            if (!_lastOrderIds.contains(doc.id)) {
              // Ini adalah pesanan baru
              final data = doc.data();
              final orderId = data['orderId']?.toString() ?? 'ORDER-XXX';
              final userName = data['userName'] ?? 'Pelanggan';

              // Tampilkan notifikasi
              _showNewOrderNotification(
                orderId.length >= 3
                    ? orderId.substring(orderId.length - 3)
                    : orderId,
                userName,
              );

              // Tambahkan ID ini ke daftar yang sudah diketahui
              _lastOrderIds.add(doc.id);
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

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Tidak ada data'));
        }

        final docs = snapshot.data!.docs;

        // Filter pesanan berdasarkan status dan tanggal (hanya tampilkan pesanan hari ini)
        final orders =
            docs.where((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>;

                // Cek status
                final status = data['status'] as String?;
                if (status == null || !statuses.contains(status)) {
                  return false;
                }

                // Cek timestamp
                final timestampRaw = data['timestamp'];
                if (timestampRaw == null) return false;

                DateTime timestamp;
                if (timestampRaw is Timestamp) {
                  timestamp = timestampRaw.toDate();
                } else {
                  return false;
                }

                // Cek apakah pesanan hari ini
                final isToday =
                    timestamp.isAfter(startOfToday) ||
                    (timestamp.year == startOfToday.year &&
                        timestamp.month == startOfToday.month &&
                        timestamp.day == startOfToday.day);

                return isToday;
              } catch (e) {
                print('Error memproses dokumen: $e');
                return false;
              }
            }).toList();

        if (orders.isEmpty) {
          return const Center(child: Text('Belum ada pesanan.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            try {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;

              // Penanganan data item yang aman
              List<Map<String, dynamic>> items = [];
              try {
                final itemsRaw = data['items'];
                if (itemsRaw != null && itemsRaw is List) {
                  items = List<Map<String, dynamic>>.from(
                    itemsRaw.map(
                      (item) => item is Map<String, dynamic> ? item : {},
                    ),
                  );
                }
              } catch (e) {
                print('Error memproses items: $e');
              }

              // Penanganan timestamp yang aman
              DateTime timestamp = DateTime.now();
              try {
                final timestampRaw = data['timestamp'];
                if (timestampRaw is Timestamp) {
                  timestamp = timestampRaw.toDate();
                }
              } catch (e) {
                print('Error memproses timestamp: $e');
              }

              final dateFormatted = DateFormat(
                'dd MMM yyyy, HH:mm',
              ).format(timestamp);
              final status = data['status'] as String? ?? '';
              final totalAmount =
                  (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
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
                                    child: _buildSafeImage(imagePath),
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
            } catch (e) {
              print('Error rendering order item: $e');
              return const SizedBox.shrink(); // Return empty widget on error
            }
          },
        );
      },
    );
  }

  Widget _buildSafeImage(String imagePath) {
    try {
      return Image.asset(
        imagePath,
        width: 45,
        height: 45,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 45,
            height: 45,
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.image_not_supported,
              size: 20,
              color: Colors.grey,
            ),
          );
        },
      );
    } catch (e) {
      print('Error loading image: $e');
      return Container(
        width: 45,
        height: 45,
        color: Colors.grey.shade300,
        child: const Icon(Icons.error, size: 20, color: Colors.grey),
      );
    }
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
