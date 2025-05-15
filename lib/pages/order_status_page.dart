import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitan_app/colors.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kopitan_app/services/notification_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class OrderStatusPage extends StatefulWidget {
  final String? orderId;

  const OrderStatusPage({super.key, this.orderId});

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class SwipeToUseCodeWidget extends StatefulWidget {
  final VoidCallback onCodeUsed;
  final String orderId;
  final BuildContext parentContext;
  final bool swiped;

  const SwipeToUseCodeWidget({
    required this.onCodeUsed,
    required this.orderId,
    required this.parentContext,
    required this.swiped,
  });

  @override
  State<SwipeToUseCodeWidget> createState() => _SwipeToUseCodeWidgetState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );
  bool codeUsed = false;
  bool codeSwiped = false;
  String _previousStatus = '';

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
        // Handle notification tap
        final String? payload = notificationResponse.payload;
        if (payload != null) {
          debugPrint('Notification payload: $payload');
        }
      },
    );
  }

  Future<void> _showStatusNotification(String status, String orderId) async {
    if (!NotificationPreference.getNotificationStatus()) return;
    if (_previousStatus == status) return;

    // Update the previous status
    setState(() {
      _previousStatus = status;
    });

    // Define the notification details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'order_status_channel',
          'Order Status Notifications',
          channelDescription: 'Notifications for order status updates',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF9A534F), // xprimaryColor
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    // Create notification content based on status
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
        return; // Don't show notification for unknown status
    }

    // Show the notification
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
    _initNotifications();
    // Store the initial order ID to check for status changes on the same order
    _loadPreviousStatus();
  }

  void _loadPreviousStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final orderId = widget.orderId ?? '';
    setState(() {
      _previousStatus = prefs.getString('previous_status_$orderId') ?? '';
    });
  }

  void _savePreviousStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    final orderId = widget.orderId ?? '';
    prefs.setString('previous_status_$orderId', status);
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

  Widget _buildProgressLine({bool isActive = false, double topPadding = 0.0}) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.only(top: topPadding),
        child: Container(
          height: 2,
          color: isActive ? xprimaryColor : Colors.grey[300],
        ),
      ),
    );
  }

  Widget _buildOrderIdentifier(String status, String orderId) {
    switch (status) {
      case 'processing':
        return Column(
          children: [
            const Text(
              'Nomor Order',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            Text(
              _formatOrderId(orderId),
              style: const TextStyle(fontSize: 46, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
          ],
        );
      case 'ready':
        return Column(
          children: [
            Image.asset(
              'assets/images/status/siap-pickup.png',
              width: 300,
              fit: BoxFit.cover,
            ),
          ],
        );
      case 'completed':
        return Image.asset(
          'assets/images/status/selesai.png',
          width: 210,
          fit: BoxFit.cover,
        );
      default:
        return Column(
          children: [
            const Text(
              'Nomor Order',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            Text(
              _formatOrderId(orderId),
              style: const TextStyle(fontSize: 46, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
          ],
        );
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
                    ? (imagePath.toString().startsWith('https')
                        ? Image.network(
                          imagePath,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultImage();
                          },
                        )
                        : Image.asset(
                          imagePath,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultImage();
                          },
                        ))
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

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showStatusNotification(status, orderId);
            _savePreviousStatus(status);
          });

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
                  // Main scrollable content
                  SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: status == 'ready' ? 120 : 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            color: xthirdColor,
                            padding: const EdgeInsets.only(top: 20, bottom: 0),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        topPadding: 25,
                                      ),
                                      _buildProgressStep(
                                        icon: "package",
                                        label: 'Siap\nDi-Pickup',
                                        active: status == 'ready',
                                        isCompleted: status == 'completed',
                                      ),
                                      _buildProgressLine(
                                        isActive: status == 'completed',
                                        topPadding: 25,
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
                                const SizedBox(height: 48),
                                _buildOrderIdentifier(status, orderId),
                              ],
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: Card(
                                  color: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color:
                                          Colors.grey.shade300, // warna border
                                      width: 1, // ketebalan border
                                    ),
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
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Card(
                              color: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.grey.shade300, // warna border
                                  width: 1, // ketebalan border
                                ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Card(
                              color: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.grey.shade300, // warna border
                                  width: 1, // ketebalan border
                                ),
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
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.grey.shade300, // warna border
                                  width: 1, // ketebalan border
                                ),
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
                                    value: orderId.substring(
                                      orderId.length - 6,
                                    ),
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
                  ),

                  // Swipe to use code muncul hanya jika status = 'ready'
                  if (status == 'ready')
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SwipeToUseCodeWidget(
                          orderId: orderId,
                          onCodeUsed: () => setState(() => codeSwiped = true),
                          parentContext: context,
                          swiped: codeSwiped,
                        ),
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

  Widget _buildDefaultImage() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.brown[200],
      child: const Center(child: Icon(Icons.coffee, color: Colors.brown)),
    );
  }

  Widget _getPaymentMethodLogo(String paymentMethod) {
    Widget iconData;

    switch (paymentMethod.toLowerCase()) {
      case 'qris':
        iconData = Image.asset('assets/images/pembayaran/qris.png', width: 52);
        break;
      case 'gopay':
        iconData = Image.asset('assets/images/pembayaran/gopay.png', width: 52);
        break;
      case 'dana':
        iconData = Image.asset('assets/images/pembayaran/dana.png', width: 52);
        break;
      default:
        iconData = Icon(
          Icons.payment,
          size: 24, // Atur ukuran ikon default
        );
    }

    return iconData;
  }
}

class _SwipeToUseCodeWidgetState extends State<SwipeToUseCodeWidget> {
  double _dragExtent = 0.0;
  final double _maxDrag = 260.0;
  bool _revealed = false;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta!;
      if (_dragExtent < 0) _dragExtent = 0;
      if (_dragExtent > _maxDrag) _dragExtent = _maxDrag;
    });
  }

  void _handleDragEnd(DragEndDetails details) async {
    final screenWidth = MediaQuery.of(context).size.width;
    if (_dragExtent > screenWidth * 0.6) {
      setState(() {
        _revealed = true;
      });
      widget.onCodeUsed();

      // Show notification when code is revealed
      await _showPickupCodeNotification();

      final prefs = await SharedPreferences.getInstance();
      final revealedKey = 'revealed_pickup_${widget.orderId}';
      prefs.setBool(revealedKey, true);
    } else {
      setState(() {
        _dragExtent = 0;
      });
    }
  }

  Future<void> _showPickupCodeNotification() async {
    if (!NotificationPreference.getNotificationStatus()) return;
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'pickup_code_channel',
          'Pickup Code Notifications',
          channelDescription: 'Notifications for pickup code reveal',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF9A534F), // xprimaryColor
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      3, // Unique ID for this notification type
      'Kode Pickup Siap Digunakan',
      'Kode pickup Anda telah siap digunakan. Tunjukkan kepada barista untuk mengambil pesanan.',
      details,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadRevealedStatus();
  }

  void _loadRevealedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final revealedKey = 'revealed_pickup_${widget.orderId}';
    final revealed = prefs.getBool(revealedKey) ?? false;
    setState(() {
      _revealed = revealed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = xprimaryColor.withOpacity(0.7);
    final foregroundColor = xprimaryColor;
    final fullWidth =
        MediaQuery.of(context).size.width - 32; // padding 16 left + right

    if (_revealed || widget.swiped) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: xprimaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _showBottomSheet,
          child: Text(
            'Kode Siap Digunakan',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Background text
          Container(
            height: 56,
            width: fullWidth,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Swipe untuk tampilkan kode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Swipe foreground with animated icon
          GestureDetector(
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  height: 56,
                  width: _dragExtent.clamp(56, fullWidth),
                  decoration: BoxDecoration(
                    color: foregroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                // Moving Icon
                Positioned(
                  left: (_dragExtent.clamp(
                    16,
                    fullWidth - 40,
                  )), // move icon along drag
                  top: 14,
                  child: const Icon(
                    Icons.arrow_right_alt,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: widget.parentContext,
      builder:
          (_) => FutureBuilder<QuerySnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('order_history')
                    .where('orderId', isEqualTo: widget.orderId)
                    .limit(1)
                    .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Data pesanan tidak ditemukan.',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              final doc = snapshot.data!.docs.first;
              final code = doc['pickupCode'] ?? '0000';

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Kode Pickup', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 16),
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tunjukkan kode ini ke barista saat pengambilan di kasir.',
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: xprimaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Selesai'),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
