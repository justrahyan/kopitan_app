import 'package:flutter/material.dart';
import 'package:kopitan_app/colors.dart';

class KopitanOrderScreen extends StatefulWidget {
  const KopitanOrderScreen({super.key});

  @override
  State<KopitanOrderScreen> createState() => _KopitanOrderScreenState();
}

class _KopitanOrderScreenState extends State<KopitanOrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool hasOrder = true; // Ganti ini ke false untuk testing tampilan kosong

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            // Tab Bar
            Container(
              padding: const EdgeInsets.only(top: 10),
              child: TabBar(
                controller: _tabController,
                indicatorColor: xprimaryColor,
                labelColor: xprimaryColor,
                unselectedLabelColor: Colors.black,
                tabs: const [
                  Tab(text: 'Sedang Berlangsung'),
                  Tab(text: 'Selesai'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildOrderList(), _buildOrderList()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    if (!hasOrder) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/shop-icon.png', width: 100, height: 100),
            const SizedBox(height: 16),
            const Text(
              'Kopimu Masih Kosong!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: xprimaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Pesan Sekarang',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } else {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOrderCard(
            orderId: '#023',
            dateTime: '18 Mar 2025, 12:00',
            status: 'Sedang Diproses',
            total: 'Rp. 80.000',
            itemCount: 2,
            images: [
              'assets/images/menu/menu-1.jpg',
              'assets/images/menu/menu-1.jpg',
            ],
          ),
          _buildOrderCard(
            orderId: '#049',
            dateTime: '18 Mar 2025, 12:00',
            status: 'Siap Di-Pickup',
            total: 'Rp. 18.000',
            itemCount: 1,
            images: ['assets/images/menu/menu-1.jpg'],
          ),
          _buildOrderCard(
            orderId: '#007',
            dateTime: '18 Mar 2025, 12:00',
            status: 'Siap Di-Pickup',
            total: 'Rp. 80.000',
            itemCount: 2,
            images: [
              'assets/images/menu/menu-1.jpg',
              'assets/images/menu/menu-1.jpg',
            ],
          ),
        ],
      );
    }
  }

  Widget _buildOrderCard({
    required String orderId,
    required String dateTime,
    required String status,
    required String total,
    required int itemCount,
    required List<String> images,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kiri: Order Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateTime,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children:
                        images
                            .map(
                              (img) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: Image.asset(
                                    img,
                                    width: 55,
                                    height: 55,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
            // Kanan: Status dan Total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  status,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Text(
                  total,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$itemCount items',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
