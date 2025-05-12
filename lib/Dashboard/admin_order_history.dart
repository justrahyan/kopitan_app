import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_launcher_icons/main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitan_app/colors.dart';
import 'package:hugeicons/hugeicons.dart';

class AdminOrderHistoryPage extends StatefulWidget {
  const AdminOrderHistoryPage({super.key});

  @override
  State<AdminOrderHistoryPage> createState() => _AdminOrderHistoryPageState();
}

class _AdminOrderHistoryPageState extends State<AdminOrderHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
    }
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

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
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
      appBar: AppBar(
        title: const Text('Riwayat Orderan'),
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.black,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: xprimaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: xprimaryColor,
          tabs: const [Tab(text: 'Riwayat'), Tab(text: 'Laporan')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDate(context, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(_selectedStartDate) == ''
                                        ? 'Tanggal Awal'
                                        : _formatDate(_selectedStartDate),
                                  ),
                                  const Icon(HugeIcons.strokeRoundedCalendar03),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDate(context, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(_selectedEndDate) == ''
                                        ? 'Tanggal Akhir'
                                        : _formatDate(_selectedEndDate),
                                  ),
                                  const Icon(HugeIcons.strokeRoundedCalendar03),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _filterStartDate = _selectedStartDate;
                            _filterEndDate = _selectedEndDate;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: xprimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Tampilkan',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
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

                    final filteredOrders =
                        docs.where((doc) {
                          final status = doc['status'];
                          if (status != 'completed') return false;
                          if (_filterStartDate != null &&
                              _filterEndDate != null) {
                            final timestamp =
                                (doc['timestamp'] as Timestamp).toDate();
                            return timestamp.isAfter(
                                  _filterStartDate!.subtract(
                                    const Duration(days: 1),
                                  ),
                                ) &&
                                timestamp.isBefore(
                                  _filterEndDate!.add(const Duration(days: 1)),
                                );
                          }
                          return true;
                        }).toList();

                    if (filteredOrders.isEmpty) {
                      return const Center(child: Text('Tidak ada riwayat.'));
                    }

                    return ListView.builder(
                      itemCount: filteredOrders.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final data =
                            filteredOrders[index].data()
                                as Map<String, dynamic>;
                        final items = List<Map<String, dynamic>>.from(
                          data['items'] ?? [],
                        );
                        final timestamp =
                            (data['timestamp'] as Timestamp).toDate();
                        final dateFormatted = DateFormat(
                          'dd MMM yyyy, HH:mm',
                        ).format(timestamp);
                        final status = data['status'] ?? '';
                        final totalAmount = data['totalAmount'] ?? 0;
                        final orderId =
                            data['orderId']?.toString() ?? 'ORDER-000';
                        final formattedOrderId =
                            orderId.length >= 3
                                ? orderId.substring(orderId.length - 3)
                                : orderId;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.white,
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateFormatted,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ...items
                                        .take(3)
                                        .map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              child: Image.asset(
                                                item['imagePath'] ?? '',
                                                width: 45,
                                                height: 45,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                    if (items.length > 3)
                                      Container(
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
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Rp ${NumberFormat('#,###', 'id_ID').format(totalAmount)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${items.length} items',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          const Center(child: Text('Kosong')),
        ],
      ),
    );
  }
}
