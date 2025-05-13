import 'package:flutter/material.dart';
import 'package:kopitan_app/colors.dart';
import 'dart:async';
import 'order_status_page.dart';

class PaymentSuccessPage extends StatefulWidget {
  final String orderId;
  const PaymentSuccessPage({super.key, required this.orderId});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  late Timer _timer;
  int _secondsRemaining = 5;

  @override
  void initState() {
    super.initState();

    // Use a simple countdown timer to show progress
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer.cancel();
        // Make sure we're still mounted before navigating
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderStatusPage(orderId: widget.orderId),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    // Always cancel timers in dispose to prevent memory leaks
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pembayaran Berhasil'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Terima kasih telah melakukan pembayaran.'),
            const SizedBox(height: 20),
            Text(
              'Menuju halaman detail pesanan dalam $_secondsRemaining detik...',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                _timer.cancel();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => OrderStatusPage(orderId: widget.orderId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: xprimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
              ),
              child: const Text('Lihat Detail Pesanan Sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}
