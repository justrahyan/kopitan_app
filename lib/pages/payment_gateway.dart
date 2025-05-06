import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PaymentGateway {
  static Future<void> processPayment({
    required BuildContext context,
    required String paymentMethod,
    required int totalAmount,
    required List<DocumentSnapshot> orderItems,
  }) async {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(milliseconds: 300));
    if (context.mounted) Navigator.pop(context);

    switch (paymentMethod) {
      case 'GoPay':
        return _showPaymentSheet(
          context,
          'GoPay',
          totalAmount,
          currencyFormat,
          orderItems,
          Colors.blue,
        );
      case 'OVO':
        return _showPaymentSheet(
          context,
          'OVO',
          totalAmount,
          currencyFormat,
          orderItems,
          Colors.purple,
        );
      case 'QRIS':
        return _showPaymentSheet(
          context,
          'QRIS',
          totalAmount,
          currencyFormat,
          orderItems,
          Colors.green.shade700,
        );
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Metode pembayaran tidak valid')),
        );
    }
  }

  static Future<void> _showPaymentSheet(
    BuildContext context,
    String method,
    int totalAmount,
    NumberFormat currencyFormat,
    List<DocumentSnapshot> orderItems,
    Color color,
  ) async {
    final nextOrderId = await _getNextOrderId();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => _buildPaymentSheet(
            context,
            method,
            nextOrderId,
            totalAmount,
            currencyFormat,
            orderItems,
            color,
          ),
    );
  }

  static Future<String> _getNextOrderId() async {
    final docRef = FirebaseFirestore.instance
        .collection('setting')
        .doc('order_counter');
    final snapshot = await docRef.get();

    int lastOrderNumber = 0;
    if (snapshot.exists) {
      lastOrderNumber = snapshot.data()?['lastOrderNumber'] ?? 0;
    }

    int nextOrderNumber = lastOrderNumber + 1;
    await docRef.set({'lastOrderNumber': nextOrderNumber});

    return nextOrderNumber.toString().padLeft(3, '0'); // format like "001"
  }

  static Widget _buildPaymentSheet(
    BuildContext context,
    String method,
    String orderId,
    int totalAmount,
    NumberFormat currencyFormat,
    List<DocumentSnapshot> orderItems,
    Color color,
  ) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nomor Antrian: #$orderId',
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                'Total: ${currencyFormat.format(totalAmount)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handlePaymentSuccess(
                    context,
                    method,
                    orderId,
                    totalAmount,
                    orderItems,
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: color),
                child: const Text(
                  'Simulasi Pembayaran Berhasil',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handlePaymentCancelled(context);
                },
                child: const Text('Batal'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _handlePaymentSuccess(
    BuildContext context,
    String paymentMethod,
    String orderId,
    int totalAmount,
    List<DocumentSnapshot> orderItems,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesi login habis. Silakan login kembali.'),
            ),
          );
        }
        return;
      }

      final transactionData = {
        'userId': user.uid,
        'orderId': orderId,
        'paymentMethod': paymentMethod,
        'totalAmount': totalAmount,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'items':
            orderItems.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'name': data['name'] ?? 'Unknown',
                'quantity': data['quantity'] ?? 1,
                'unitPrice': data['totalPrice'] ~/ (data['quantity'] ?? 1),
                'totalPrice': data['totalPrice'],
                'temperature': data['temperature'] ?? '-',
                'size': data['size'] ?? '-',
                'imagePath': data['imagePath'] ?? '',
              };
            }).toList(),
      };

      final batch = FirebaseFirestore.instance.batch();
      final transactionRef =
          FirebaseFirestore.instance
              .collection('order_history')
              .doc(); // gunakan auto-ID Firestore
      batch.set(transactionRef, transactionData);
      for (final doc in orderItems) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pesanan #$orderId berhasil dibuat dengan metode $paymentMethod.',
                    ),
                    Text(
                      'Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(totalAmount)}',
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  static void _handlePaymentCancelled(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pembayaran dibatalkan')));
  }
}
