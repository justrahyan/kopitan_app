import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitan_app/colors.dart';
import 'package:kopitan_app/pages/app_main_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kopitan_app/pages/payment_success_page.dart';
import 'package:kopitan_app/services/notification_preference.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage>
    with WidgetsBindingObserver {
  String selectedPaymentMethod = 'Pilih Metode Pembayaran';
  String selectedPaymentIcon = '';
  bool _isPaymentInProgress = false;
  String? _currentOrderId;
  bool _isEditMode = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  @override
  void initState() {
    super.initState();
    // Register observer to detect when app comes back to foreground
    WidgetsBinding.instance.addObserver(this);
    _initNotifications();
  }

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

  Future<void> _showPaymentSuccessNotification(String orderId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final isNotificationOn = doc['isNotificationOn'] ?? true;
      NotificationPreference.setNotification(isNotificationOn);

      if (!NotificationPreference.getNotificationStatus()) return;

      const androidDetails = AndroidNotificationDetails(
        'payment_channel',
        'Payment Notifications',
        channelDescription: 'Notifications for payment status',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFF9A534F),
        icon: '@mipmap/ic_launcher',
      );

      const details = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        2,
        'Pembayaran Berhasil',
        'Pesanan #$orderId berhasil dikonfirmasi. Terima kasih telah berbelanja!',
        details,
      );
    }
  }

  @override
  void dispose() {
    // Remove observer when page is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Called when app state changes (background to foreground)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isPaymentInProgress) {
      // App came back to foreground while payment was in progress
      _checkPaymentStatus();
    }
  }

  Future<void> deleteOrderItem(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(docId).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item berhasil dihapus')));
    } catch (e) {
      print('Error deleting order item: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal menghapus item')));
    }
  }

  // Toggle edit mode
  void toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  Future<void> saveOrderToHistory({
    required String orderId,
    required int totalAmount,
    required String paymentMethod,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // First, get all current orders to combine into a complete order history
      final orderSnapshot =
          await FirebaseFirestore.instance
              .collection('orders')
              .where('userId', isEqualTo: user.uid)
              .get();

      // Extract order items
      final List<Map<String, dynamic>> orderItems = [];
      for (final doc in orderSnapshot.docs) {
        final data = doc.data();
        orderItems.add({
          'name': data['name'] ?? 'Unknown Item',
          'temperature': data['temperature'] ?? '-',
          'size': data['size'] ?? '-',
          'quantity': data['quantity'] ?? 1,
          'unitPrice': data['totalPrice'] ~/ (data['quantity'] ?? 1),
          'totalPrice': data['totalPrice'] ?? 0,
          'imagePath': data['imagePath'] ?? '',
        });
      }

      // Save to order_history collection
      await FirebaseFirestore.instance.collection('order_history').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Pengguna',
        'orderId': orderId,
        'items': orderItems,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Order saved to history successfully!');
    } catch (e) {
      print('Error saving order to history: $e');
    }
  }

  Future<void> clearUserOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> reduceMenuStock(List<Map<String, dynamic>> orderItems) async {
    // Get a reference to the menus collection
    final menusRef = FirebaseFirestore.instance.collection('menus');

    // For each ordered item, find the corresponding menu item and reduce its stock
    for (var item in orderItems) {
      final String itemName = item['name'];
      final int quantity = item['quantity'];

      // Query to find the menu with matching name
      final menuQuery = await menusRef.where('name', isEqualTo: itemName).get();

      if (menuQuery.docs.isNotEmpty) {
        for (var menuDoc in menuQuery.docs) {
          final currentStock = menuDoc.data()['stock'] ?? 0;

          // Ensure stock doesn't go below zero
          final newStock =
              currentStock >= quantity ? currentStock - quantity : 0;

          // Update the stock in Firestore
          await menuDoc.reference.update({'stock': newStock});
          print('Updated stock for $itemName: $currentStock -> $newStock');
        }
      } else {
        print('Menu item not found: $itemName');
      }
    }
  }

  Future<void> handleTransactionSuccess() async {
    final String orderId =
        _currentOrderId ?? "ORDER-${DateTime.now().millisecondsSinceEpoch}";

    // Get order items before clearing them
    final user = FirebaseAuth.instance.currentUser;
    List<Map<String, dynamic>> orderItems = [];

    if (user != null) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('orders')
              .where('userId', isEqualTo: user.uid)
              .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        orderItems.add({
          'name': data['name'] ?? 'Unknown Item',
          'quantity': data['quantity'] ?? 1,
        });
      }
    }

    await saveOrderToHistory(
      orderId: orderId,
      totalAmount: await calculateTotalPrice(),
      paymentMethod: selectedPaymentMethod,
    );

    // Reduce stock for each ordered item
    await reduceMenuStock(orderItems);

    await clearUserOrders();

    await _showPaymentSuccessNotification(orderId);

    if (!context.mounted) return; // mencegah error jika context tidak tersedia

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessPage(orderId: orderId),
      ),
    );
  }

  Future<int> calculateTotalPrice() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .get();

    int total = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      total += (data['totalPrice'] as int? ?? 0);
    }
    return total;
  }

  // Check payment status with Midtrans API
  Future<void> _checkPaymentStatus() async {
    if (_currentOrderId == null) return;

    try {
      final String serverKey = 'SB-Mid-server-Ka569NR2WZQrEina14y4Ng9j';
      final String basicAuth =
          'Basic ' + base64Encode(utf8.encode('$serverKey:'));

      final url = Uri.parse(
        'https://api.sandbox.midtrans.com/v2/${_currentOrderId}/status',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': basicAuth},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transactionStatus = data['transaction_status'];

        // Handle different payment statuses
        if (transactionStatus == 'settlement' ||
            transactionStatus == 'capture' ||
            transactionStatus == 'accept') {
          // Payment is successful
          _isPaymentInProgress = false;
          await handleTransactionSuccess();
        } else if (transactionStatus == 'pending') {
          // Payment still pending, do nothing yet
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pembayaran masih dalam proses')),
          );
        } else {
          // Payment failed or canceled
          _isPaymentInProgress = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pembayaran gagal atau dibatalkan')),
          );
        }
      }
    } catch (e) {
      print('Error checking payment status: $e');
      // Try again later or let user manually check
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memeriksa status pembayaran')),
      );
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('Silakan login terlebih dahulu')),
      );
    }

    Future<String?> createMidtransTransaction({
      required int amount,
      required String orderId,
      required String paymentType, // gopay / qris / ovo
    }) async {
      final String serverKey =
          'SB-Mid-server-Ka569NR2WZQrEina14y4Ng9j'; // dari Midtrans
      final String basicAuth =
          'Basic ' + base64Encode(utf8.encode('$serverKey:'));

      final url = Uri.parse(
        'https://app.sandbox.midtrans.com/snap/v1/transactions',
      );

      String firstName = 'Pengguna';
      String email = user.email ?? 'email@example.com';

      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          firstName =
              userData['name'] ??
              userData['full_name'] ??
              user.displayName ??
              'Pengguna';
          // Use the email from Firestore if available, otherwise use the one from auth
          email = userData['email'] ?? user.email ?? 'email@example.com';
        } else if (user.displayName != null) {
          // If no user document but user has a display name
          firstName = user.displayName!;
        }
      } catch (e) {
        print('Error retrieving user data: $e');
        // Fallback to auth user data
        firstName = user.displayName ?? 'Pengguna';
      }

      final body = {
        "transaction_details": {"order_id": orderId, "gross_amount": amount},
        "enabled_payments": [paymentType],
        "customer_details": {"first_name": firstName, "email": email},
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['redirect_url']; // Gunakan WebView atau buka browser
      } else {
        print('Gagal buat transaksi: ${response.body}');
        return null;
      }
    }

    void launchPayment(String url) async {
      try {
        final uri = Uri.parse(url);
        _isPaymentInProgress = true; // Mark payment as in progress
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          _isPaymentInProgress = false; // Reset if launch fails
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak bisa membuka link pembayaran')),
          );
        }
      } catch (e) {
        _isPaymentInProgress = false; // Reset if error occurs
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }

    void showPaymentMethodsBottomSheet() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Metode Pembayaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section Title: E-Wallet
                    const Text(
                      'E-Wallet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // GoPay Option
                    InkWell(
                      onTap: () {
                        this.setState(() {
                          selectedPaymentMethod = 'GoPay';
                          selectedPaymentIcon =
                              'assets/images/pembayaran/gopay.png';
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.asset(
                                'assets/images/pembayaran/gopay.png',
                                width: 32,
                                height: 32,
                                errorBuilder:
                                    (context, error, stackTrace) => const Icon(
                                      Icons.account_balance_wallet,
                                      color: Colors.blue,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'GoPay',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Radio<String>(
                              value: 'GoPay',
                              groupValue: selectedPaymentMethod,
                              onChanged: (value) {
                                this.setState(() {
                                  selectedPaymentMethod = value!;
                                  selectedPaymentIcon =
                                      'assets/images/pembayaran/gopay.png';
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // OVO Option
                    InkWell(
                      onTap: () {
                        this.setState(() {
                          selectedPaymentMethod = 'OVO';
                          selectedPaymentIcon =
                              'assets/images/pembayaran/ovo.png';
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.asset(
                                'assets/images/pembayaran/ovo.png',
                                width: 32,
                                height: 32,
                                errorBuilder:
                                    (context, error, stackTrace) => const Icon(
                                      Icons.account_balance_wallet,
                                      color: Colors.purple,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'OVO',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Radio<String>(
                              value: 'OVO',
                              groupValue: selectedPaymentMethod,
                              onChanged: (value) {
                                this.setState(() {
                                  selectedPaymentMethod = value!;
                                  selectedPaymentIcon =
                                      'assets/images/pembayaran/ovo.png';
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section Title: Lainnya
                    const Text(
                      'Lainnya',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // QRIS Option
                    InkWell(
                      onTap: () {
                        this.setState(() {
                          selectedPaymentMethod = 'QRIS';
                          selectedPaymentIcon =
                              'assets/images/pembayaran/qris.png';
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.asset(
                                'assets/images/pembayaran/qris.png',
                                width: 32,
                                height: 32,
                                errorBuilder:
                                    (context, error, stackTrace) => const Icon(
                                      Icons.qr_code,
                                      color: Colors.black,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'QRIS',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Radio<String>(
                              value: 'QRIS',
                              groupValue: selectedPaymentMethod,
                              onChanged: (value) {
                                this.setState(() {
                                  selectedPaymentMethod = value!;
                                  selectedPaymentIcon =
                                      'assets/images/pembayaran/qris.png';
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Checkout'),
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.black,
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('orders')
                .where('userId', isEqualTo: user.uid)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Keranjang kosong'));
          }

          final orders = snapshot.data!.docs;

          final totalPrice = orders.fold(0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return sum + (data['totalPrice'] as int);
          });

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Order',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        // Add button (existing functionality)
                        GestureDetector(
                          onTap: () {
                            // Close the current checkout page first
                            Navigator.pop(context);

                            // Find the main screen state and switch to menu tab
                            final navigatorState = Navigator.of(
                              context,
                              rootNavigator: true,
                            );
                            navigatorState.popUntil((route) => route.isFirst);

                            // Use Future.delayed to ensure we're back at the main screen before switching tabs
                            // Use Future.delayed to ensure we're back at the main screen before switching tabs
                            Future.delayed(
                              const Duration(milliseconds: 100),
                              () {
                                final mainScreenState =
                                    navigatorState.context
                                        .findAncestorStateOfType<
                                          KopitanAppMainScreenState
                                        >();
                                if (mainScreenState != null) {
                                  mainScreenState.switchToTab(
                                    1,
                                  ); // Switch to menu tab (index 1)
                                }
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.add, color: Colors.blue, size: 20),
                                SizedBox(width: 4),
                                Text(
                                  'Tambah',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final doc = orders[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};

                    final imagePath = data['imagePath'] ?? '';
                    final name = data['name'] ?? 'Tanpa Nama';
                    final temperature = data['temperature'] ?? '-';
                    final size = data['size'] ?? '-';
                    final quantity = data['quantity'] ?? 1;
                    final itemTotal = data['totalPrice'] ?? 0;
                    final unitPrice = quantity > 0 ? itemTotal ~/ quantity : 0;

                    void updateQuantity(int newQuantity) {
                      if (newQuantity < 1) return; // minimum quantity 1
                      final newTotal = unitPrice * newQuantity;
                      FirebaseFirestore.instance
                          .collection('orders')
                          .doc(doc.id)
                          .update({
                            'quantity': newQuantity,
                            'totalPrice': newTotal,
                          });
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.all(
                              Radius.circular(100),
                            ),
                            child:
                                imagePath.toString().startsWith('https')
                                    ? Image.network(
                                      imagePath,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return _buildDefaultImage();
                                      },
                                    )
                                    : Image.asset(
                                      imagePath,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return _buildDefaultImage();
                                      },
                                    ),
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
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$temperature, $size',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currencyFormat.format(itemTotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              quantity == 1
                                  ? IconButton(
                                    onPressed: () => deleteOrderItem(doc.id),
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    splashRadius: 20,
                                  )
                                  : IconButton(
                                    onPressed:
                                        () => updateQuantity(quantity - 1),
                                    icon: const Icon(Icons.remove),
                                    splashRadius: 20,
                                  ),
                              Text('$quantity'),
                              IconButton(
                                onPressed: () => updateQuantity(quantity + 1),
                                icon: const Icon(Icons.add),
                                splashRadius: 20,
                              ),
                            ],
                          ),

                          if (_isEditMode)
                            IconButton(
                              onPressed: () => deleteOrderItem(doc.id),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              splashRadius: 20,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: showPaymentMethodsBottomSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            if (selectedPaymentIcon.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Image.asset(
                                  selectedPaymentIcon,
                                  width: 32,
                                  height: 32,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(Icons.payment, size: 32),
                                ),
                              ),
                            if (selectedPaymentIcon.isEmpty)
                              const Icon(Icons.payment, color: Colors.grey),
                            if (selectedPaymentIcon.isEmpty)
                              const SizedBox(width: 12),
                            Text(
                              selectedPaymentMethod,
                              style: TextStyle(
                                fontWeight:
                                    selectedPaymentMethod ==
                                            'Pilih Metode Pembayaran'
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                color:
                                    selectedPaymentMethod ==
                                            'Pilih Metode Pembayaran'
                                        ? Colors.grey.shade700
                                        : Colors.black,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currencyFormat.format(totalPrice),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed:
                          _isPaymentInProgress
                              ? null // Disable button if payment is in progress
                              : () async {
                                if (selectedPaymentMethod ==
                                    'Pilih Metode Pembayaran') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Pilih metode pembayaran terlebih dahulu',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                // Create a unique order ID
                                _currentOrderId =
                                    "ORDER-${DateTime.now().millisecondsSinceEpoch}";

                                final redirectUrl =
                                    await createMidtransTransaction(
                                      amount: totalPrice,
                                      orderId: _currentOrderId!,
                                      paymentType:
                                          selectedPaymentMethod.toLowerCase(),
                                    );

                                if (redirectUrl != null) {
                                  launchPayment(redirectUrl);
                                  // Payment check will happen when app comes back to foreground
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Gagal memulai pembayaran'),
                                    ),
                                  );
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: xprimaryColor,
                      ),
                      child:
                          _isPaymentInProgress
                              ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Proses Pembayaran...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                              : const Text(
                                'Konfirmasi Pesanan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                    if (_isPaymentInProgress)
                      TextButton(
                        onPressed: _checkPaymentStatus,
                        child: const Text('Saya sudah membayar'),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
