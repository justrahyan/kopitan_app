import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:kopitan_app/main.dart';

class PaymentGateway {
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    await FirebaseFirestore.instance.enablePersistence();
    runApp(MyApp());
  }

  static Future<void> processPayment({
    required BuildContext context,
    required String paymentMethod,
    required int totalAmount,
    required List<DocumentSnapshot> orderItems,
  }) async {
    // Format currency
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Show loading indicator with shorter delay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Reduced delay for better UX
    await Future.delayed(const Duration(milliseconds: 300));

    // Dismiss loading dialog
    if (context.mounted) Navigator.pop(context);

    // Show payment method specific UI
    switch (paymentMethod) {
      case 'GoPay':
        return _showGopayPayment(
          context,
          totalAmount,
          currencyFormat,
          orderItems,
        );
      case 'OVO':
        return _showOvoPayment(
          context,
          totalAmount,
          currencyFormat,
          orderItems,
        );
      case 'QRIS':
        return _showQrisPayment(
          context,
          totalAmount,
          currencyFormat,
          orderItems,
        );
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Metode pembayaran tidak valid')),
        );
    }
  }

  static Future<void> _showGopayPayment(
    BuildContext context,
    int totalAmount,
    NumberFormat currencyFormat,
    List<DocumentSnapshot> orderItems,
  ) async {
    // Generate random transaction ID
    final transactionId = 'GP-${DateTime.now().millisecondsSinceEpoch}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Gopay Logo and text
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'assets/images/pembayaran/gopay.png',
                              width: 24,
                              height: 24,
                              errorBuilder:
                                  (context, error, stackTrace) => const Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.blue,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'GoPay',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Close button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Transaction details
                  Text(
                    'ID Transaksi: $transactionId',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${currencyFormat.format(totalAmount)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // QR Code Container (simulated)
                  Container(
                    height: 200,
                    width: 200,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_2, size: 100),
                        const SizedBox(height: 10),
                        Text(
                          'Scan dengan Aplikasi Gojek',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Timer text
                  const Text(
                    'Pembayaran akan berakhir dalam',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const Text(
                    '15:00',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),

                  const Spacer(),

                  // Simulate Payment button (for development) - Optimized
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handlePaymentSuccess(
                        context,
                        'GoPay',
                        transactionId,
                        totalAmount,
                        orderItems,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Simulasi Pembayaran Berhasil',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Cancel button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handlePaymentCancelled(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Batal'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> _showOvoPayment(
    BuildContext context,
    int totalAmount,
    NumberFormat currencyFormat,
    List<DocumentSnapshot> orderItems,
  ) async {
    // Generate random transaction ID
    final transactionId = 'OVO-${DateTime.now().millisecondsSinceEpoch}';
    // Simulate OVO phone number
    const phoneNumber = '08123456789';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // OVO Logo and text
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'assets/images/pembayaran/ovo.png',
                              width: 24,
                              height: 24,
                              errorBuilder:
                                  (context, error, stackTrace) => const Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.purple,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'OVO',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Close button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Transaction details
                  Text(
                    'ID Transaksi: $transactionId',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${currencyFormat.format(totalAmount)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Phone number confirmation
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nomor OVO',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              phoneNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Implement change number functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Fitur ganti nomor belum tersedia',
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Ganti'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Instructions
                  const Text(
                    'Instruksi:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Anda akan menerima notifikasi di aplikasi OVO',
                  ),
                  const Text('2. Buka aplikasi OVO dan konfirmasi pembayaran'),

                  const Spacer(),

                  // Simulate Payment button (for development) - Optimized
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handlePaymentSuccess(
                        context,
                        'OVO',
                        transactionId,
                        totalAmount,
                        orderItems,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Simulasi Pembayaran Berhasil',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Cancel button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handlePaymentCancelled(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Batal'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> _showQrisPayment(
    BuildContext context,
    int totalAmount,
    NumberFormat currencyFormat,
    List<DocumentSnapshot> orderItems,
  ) async {
    // Generate random transaction ID
    final transactionId = 'QRIS-${DateTime.now().millisecondsSinceEpoch}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // QRIS Logo and text
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'assets/images/pembayaran/qris.png',
                              width: 24,
                              height: 24,
                              errorBuilder:
                                  (context, error, stackTrace) => const Icon(
                                    Icons.qr_code,
                                    color: Colors.black,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'QRIS',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Close button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Transaction details
                  Text(
                    'ID Transaksi: $transactionId',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${currencyFormat.format(totalAmount)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // QR Code Container (bigger for QRIS)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.qr_code_2, size: 180),
                          const SizedBox(height: 20),
                          Text(
                            'Scan dengan aplikasi e-wallet atau mobile banking',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Supported apps icons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Didukung oleh: ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.account_balance,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 5),
                      Icon(Icons.wallet, size: 18, color: Colors.grey.shade700),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.credit_card,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Timer text
                  const Text(
                    'Pembayaran akan berakhir dalam',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const Text(
                    '15:00',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),

                  const SizedBox(height: 20),

                  // Simulate Payment button (for development) - Optimized
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handlePaymentSuccess(
                        context,
                        'QRIS',
                        transactionId,
                        totalAmount,
                        orderItems,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Simulasi Pembayaran Berhasil',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Cancel button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handlePaymentCancelled(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Batal'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> _handlePaymentSuccess(
    BuildContext context,
    String paymentMethod,
    String transactionId,
    int totalAmount,
    List<DocumentSnapshot> orderItems,
  ) async {
    // Show loading indicator with a shorter loading time
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
          ),
    );

    try {
      // Prepare data before any async operations
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (context.mounted) {
          Navigator.pop(context); // Remove loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesi login habis. Silakan login kembali.'),
            ),
          );
        }
        return;
      }

      // Prepare transaction data
      final transactionData = {
        'userId': user.uid,
        'transactionId': transactionId,
        'paymentMethod': paymentMethod,
        'totalAmount': totalAmount,
        'status': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
        'items':
            orderItems.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'name': data['name'] ?? 'Unknown Item',
                'quantity': data['quantity'] ?? 1,
                'unitPrice':
                    data['quantity'] != null && data['quantity'] > 0
                        ? (data['totalPrice'] ?? 0) ~/ data['quantity']
                        : 0,
                'totalPrice': data['totalPrice'] ?? 0,
                'options':
                    data['temperature'] != null && data['size'] != null
                        ? {
                          'temperature': data['temperature'],
                          'size': data['size'],
                        }
                        : {},
              };
            }).toList(),
      };

      // Perform database operations with minimal delay
      // Shorter delay for simulation (in a real app, this would be the actual transaction processing)
      await Future.delayed(const Duration(milliseconds: 800));

      // Perform all Firestore operations in a single batch
      final batch = FirebaseFirestore.instance.batch();

      // 1. Add the transaction record
      final transactionRef = FirebaseFirestore.instance
          .collection('transactions')
          .doc(transactionId);
      batch.set(transactionRef, transactionData);

      // 2. Delete the order items
      for (var doc in orderItems) {
        batch.delete(doc.reference);
      }

      // Execute batch operations
      await batch.commit();

      // Remove loading indicator
      if (context.mounted) {
        Navigator.pop(context);
      } else {
        return; // Exit if context is no longer valid
      }

      // Show success dialog - only if context is still valid
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pembayaran Berhasil',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Transaksi $transactionId telah berhasil dibayar menggunakan $paymentMethod',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context); // Pop back to main screen
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      // Handle error
      if (context.mounted) {
        Navigator.pop(context); // Remove loading indicator
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  static void _handlePaymentCancelled(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pembayaran dibatalkan')));
  }
}
