import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitan_app/colors.dart';
import 'package:kopitan_app/pages/app_main_screen.dart';
import 'package:kopitan_app/pages/payment_gateway.dart';

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
                    const Text(
                      'E-Wallet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    paymentOption(
                      icon: 'assets/images/pembayaran/gopay.png',
                      label: 'GoPay',
                    ),
                    const SizedBox(height: 10),
                    paymentOption(
                      icon: 'assets/images/pembayaran/ovo.png',
                      label: 'OVO',
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Lainnya',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    paymentOption(
                      icon: 'assets/images/pembayaran/qris.png',
                      label: 'QRIS',
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
              // HEADER
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
                        Navigator.pop(context);
                        final navigatorState = Navigator.of(
                          context,
                          rootNavigator: true,
                        );
                        navigatorState.popUntil((route) => route.isFirst);
                        Future.delayed(const Duration(milliseconds: 100), () {
                          final mainScreenState =
                              navigatorState.context
                                  .findAncestorStateOfType<
                                    KopitanAppMainScreenState
                                  >();
                          if (mainScreenState != null) {
                            mainScreenState.switchToTab(1);
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

              // LIST ORDER
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

                    void updateQuantity(int newQty) {
                      if (newQty < 1) return;
                      FirebaseFirestore.instance
                          .collection('orders')
                          .doc(doc.id)
                          .update({
                            'quantity': newQty,
                            'totalPrice': unitPrice * newQty,
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
                            borderRadius: BorderRadius.circular(100),
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
                              ),
                              Text('$quantity'),
                              IconButton(
                                onPressed: () => updateQuantity(quantity + 1),
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // FOOTER
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
                          selectedPaymentMethod == 'Pilih Metode Pembayaran'
                              ? null
                              : () {
                                // Cache all necessary data from the widget tree
                                final currentContext = context;
                                final currentPaymentMethod =
                                    selectedPaymentMethod;
                                final currentTotalPrice = totalPrice;
                                final currentOrders =
                                    List<QueryDocumentSnapshot>.from(orders);

                                // Use a separate function to handle async code
                                _processPayment(
                                  context: currentContext,
                                  paymentMethod: currentPaymentMethod,
                                  totalAmount: currentTotalPrice,
                                  orderItems: currentOrders,
                                );
                              },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor:
                            selectedPaymentMethod == 'Pilih Metode Pembayaran'
                                ? Colors.grey
                                : xprimaryColor,
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

  // Separate method to handle the async payment process
  Future<void> _processPayment({
    required BuildContext context,
    required String paymentMethod,
    required int totalAmount,
    required List<QueryDocumentSnapshot> orderItems,
  }) async {
    try {
      await PaymentGateway.processPayment(
        context: context,
        paymentMethod: paymentMethod,
        totalAmount: totalAmount,
        orderItems: orderItems,
      );
    } catch (e) {
      // Handle error safely
      if (mounted) {
        // Check if the widget is still in the tree
        Navigator.pop(context); // Remove loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Widget paymentOption({required String icon, required String label}) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedPaymentMethod = label;
          selectedPaymentIcon = icon;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
                icon,
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.account_balance_wallet);
                },
              ),
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            Radio<String>(
              value: label,
              groupValue: selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  selectedPaymentMethod = value!;
                  selectedPaymentIcon = icon;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
