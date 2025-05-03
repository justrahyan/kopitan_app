import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_apps/device_apps.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitan_app/colors.dart';
import 'package:kopitan_app/pages/app_main_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kopitan_app/pages/payment_success_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../widgets/order_bar_widget.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String selectedPaymentMethod = 'Pilih Metode Pembayaran';
  String selectedPaymentIcon = '';

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

    // Fungsi untuk memeriksa apakah aplikasi tertentu terpasang
    Future<bool> isAppInstalled(
      String androidPackageName,
      String iosUrlScheme,
    ) async {
      if (Theme.of(context).platform == TargetPlatform.android) {
        // Cek menggunakan device_apps package
        try {
          // Import package
          // import 'package:device_apps/device_apps.dart';

          bool isInstalled = await DeviceApps.isAppInstalled(
            androidPackageName,
          );
          print('App $androidPackageName installed: $isInstalled');
          return isInstalled;
        } catch (e) {
          print('Error checking app installation: $e');

          // Fallback: coba cek dengan deeplink
          try {
            // Untuk GoPay gunakan URI untuk deeplink
            if (androidPackageName == 'com.gojek.app') {
              final Uri uri = Uri.parse('gojek://');
              return await canLaunchUrl(uri);
            }
            // Untuk OVO
            else if (androidPackageName == 'ovo.id') {
              final Uri uri = Uri.parse('ovo://');
              return await canLaunchUrl(uri);
            }
          } catch (e) {
            print('Deeplink check failed: $e');
          }
          return false;
        }
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        final Uri uri = Uri.parse(iosUrlScheme);
        return await canLaunchUrl(uri);
      }
      return false;
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

    Future<void> handleTransactionSuccess() async {
      await clearUserOrders();

      if (!context.mounted)
        return; // mencegah error jika context tidak tersedia
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PaymentSuccessPage()),
      );
    }

    // Dialog konfirmasi untuk verifikasi status pembayaran setelah kembali dari aplikasi
    void showPaymentConfirmationDialog() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Konfirmasi Pembayaran'),
            content: const Text('Apakah pembayaran sudah berhasil?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Belum, Coba Lagi'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Ya, Berhasil'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await handleTransactionSuccess();
                },
              ),
            ],
          );
        },
      );
    }

    // Fungsi untuk membuka aplikasi pembayaran atau fallback ke browser jika tidak terpasang
    Future<void> openPaymentApp(String paymentType, String redirectUrl) async {
      bool appInstalled = false;
      Uri directAppUri;

      if (paymentType == 'gopay') {
        // URL scheme untuk GoPay
        appInstalled = await isAppInstalled('com.gojek.app', 'gojek://');
        // URL scheme untuk deep link ke GoPay
        directAppUri = Uri.parse('gojek://gopay/merchanttransfer');
      } else if (paymentType == 'ovo') {
        // URL scheme untuk OVO
        appInstalled = await isAppInstalled('ovo.id', 'ovo://');
        // URL scheme untuk deep link ke OVO
        directAppUri = Uri.parse('ovo://');
      } else {
        // QRIS atau metode lain langsung gunakan URL Midtrans
        launchUrl(Uri.parse(redirectUrl), mode: LaunchMode.externalApplication);
        return;
      }

      // Coba buka aplikasi jika terpasang
      if (appInstalled) {
        try {
          // Tambahkan parameter ke deeplink jika tersedia dari Midtrans
          await launchUrl(directAppUri);

          // Tampilkan dialog untuk mengonfirmasi pembayaran setelah kembali dari aplikasi
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              showPaymentConfirmationDialog();
            }
          });
        } catch (e) {
          // Fallback ke URL Midtrans jika deep link gagal
          await launchUrl(
            Uri.parse(redirectUrl),
            mode: LaunchMode.externalApplication,
          );
        }
      } else {
        // Jika aplikasi tidak terpasang, gunakan URL Midtrans biasa
        await launchUrl(
          Uri.parse(redirectUrl),
          mode: LaunchMode.externalApplication,
        );

        // Tampilkan informasi tentang aplikasi yang tidak terpasang
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Aplikasi ${paymentType.toUpperCase()} tidak terdeteksi. Menggunakan browser untuk pembayaran.',
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
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
      String email = user?.email ?? 'email@example.com';

      if (user != null) {
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
                userData['firstName'] ??
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
        // Cek apakah ada actions spesifik untuk GoPay/OVO
        if (data['payment_type'] == 'gopay' && data['actions'] != null) {
          // Untuk GoPay, biasanya berisi deep link ke aplikasi
          for (final action in data['actions']) {
            if (action['name'] == 'deeplink-redirect') {
              return action['url']; // Deep link URL untuk GoPay
            }
          }
        }

        return data['redirect_url']; // Gunakan WebView atau buka browser
      } else {
        print('Gagal buat transaksi: ${response.body}');
        return null;
      }
    }

    // Fungsi untuk menangani pembayaran
    void processPayment(int totalPrice) async {
      String paymentType = '';

      // Sesuaikan format payment type untuk Midtrans
      switch (selectedPaymentMethod) {
        case 'GoPay':
          paymentType = 'gopay';
          break;
        case 'OVO':
          paymentType = 'ovo';
          break;
        case 'QRIS':
          paymentType = 'qris';
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Silakan pilih metode pembayaran')),
          );
          return;
      }

      // Tunjukkan loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final orderId = "ORDER-${DateTime.now().millisecondsSinceEpoch}";
      final redirectUrl = await createMidtransTransaction(
        amount: totalPrice,
        orderId: orderId,
        paymentType: paymentType,
      );

      // Tutup loading dialog
      Navigator.of(context).pop();

      if (redirectUrl != null) {
        // Buka aplikasi pembayaran atau browser tergantung pada metode pembayaran
        await openPaymentApp(paymentType, redirectUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memulai pembayaran. Silakan coba lagi.'),
          ),
        );
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
                        Future.delayed(const Duration(milliseconds: 100), () {
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
                        });
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
                                imagePath.toString().startsWith('http')
                                    ? Image.network(
                                      imagePath,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    )
                                    : Image.asset(
                                      imagePath,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
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
                              IconButton(
                                onPressed: () => updateQuantity(quantity - 1),
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
                      onPressed: () => processPayment(totalPrice),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: xprimaryColor,
                      ),
                      child: const Text(
                        'Konfirmasi Pesanan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
