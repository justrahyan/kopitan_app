import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:hugeicons/hugeicons.dart';
import 'package:kopitan_app/colors.dart';
import 'package:open_file/open_file.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({Key? key}) : super(key: key);

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final List<Map<String, String>> _reportPeriods = [];

  @override
  void initState() {
    super.initState();
    _generatePeriods();
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'Mengunduh laporan...',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateReport(String month, String year) async {
    try {
      _showLoadingDialog(context);
      // Konversi bulan dan tahun ke DateTime
      final startDate = DateTime(int.parse(year), _monthToInt(month), 1);
      final endDate = DateTime(int.parse(year), _monthToInt(month) + 1, 1);

      print('Generating report for $month $year');
      print('Start date: $startDate');
      print('End date: $endDate');

      // Ambil data dari Firestore berdasarkan rentang tanggal
      final snapshot =
          await FirebaseFirestore.instance
              .collection('order_history')
              .where('timestamp', isGreaterThanOrEqualTo: startDate)
              .where('timestamp', isLessThan: endDate)
              .get();

      print('Documents found: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data di bulan ini')),
        );
        return;
      }

      final filteredDocs = snapshot.docs.where((doc) => doc.exists).toList();

      print('Filtered documents: ${filteredDocs.length}');

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          build:
              (context) => [
                pw.Text(
                  'Laporan Penjualan Bulan $month $year',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                ...filteredDocs.map((doc) {
                  try {
                    final data = doc.data() as Map<String, dynamic>;

                    // Format timestamp untuk ditampilkan
                    String dateFormatted = "N/A";
                    try {
                      final timestampRaw = data['timestamp'];
                      if (timestampRaw is Timestamp) {
                        final date = timestampRaw.toDate();
                        dateFormatted = DateFormat(
                          'dd MMM yyyy, HH:mm',
                        ).format(date);
                      }
                    } catch (e) {
                      print('Error formatting date: $e');
                    }

                    return pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Order ID: ${data['orderId'] ?? 'N/A'}'),
                        pw.Text('Tanggal: $dateFormatted'),
                        pw.Text('Nama User: ${data['userName'] ?? 'N/A'}'),
                        pw.Text(
                          'Total: Rp ${NumberFormat('#,###', 'id_ID').format(data['totalAmount'] ?? 0)}',
                        ),
                        pw.Text('Metode: ${data['paymentMethod'] ?? 'N/A'}'),
                        pw.Text('Status: ${data['status'] ?? 'N/A'}'),
                        pw.Divider(),
                      ],
                    );
                  } catch (e) {
                    print('Error rendering document: $e');
                    return pw.SizedBox();
                  }
                }).toList(),

                // Tambahkan ringkasan di bagian bawah
                pw.SizedBox(height: 20),
                pw.Text(
                  'Ringkasan',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text('Jumlah Transaksi: ${filteredDocs.length}'),
                pw.Text(
                  'Total Pendapatan: Rp ${_calculateTotalIncome(filteredDocs)}',
                ),
              ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/Laporan_$month$year.pdf');
      await file.writeAsBytes(await pdf.save());
      Navigator.of(context).pop();

      // Tampilkan popup setelah unduhan selesai
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/download-success.png', height: 120),
                const SizedBox(height: 16),
                const Text(
                  'Laporan berhasil diunduh.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: xprimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop(); // Tutup dialog
                      await OpenFile.open(file.path); // Buka file
                    },
                    child: const Text('Buka', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      );

      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Laporan berhasil dibuat dan dibuka')),
      // );
    } catch (e) {
      print('Error generating report: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuat laporan: $e')));
    }
  }

  // Helper function untuk menghitung total pendapatan
  String _calculateTotalIncome(List<QueryDocumentSnapshot> docs) {
    double total = 0;

    for (var doc in docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final amount = data['totalAmount'];
        if (amount != null) {
          if (amount is num) {
            total += amount.toDouble();
          }
        }
      } catch (e) {
        print('Error calculating total: $e');
      }
    }

    return NumberFormat('#,###', 'id_ID').format(total);
  }

  // Fungsi untuk mengkonversi nama bulan menjadi angka
  int _monthToInt(String month) {
    final months = {
      'Januari': 1,
      'Februari': 2,
      'Maret': 3,
      'April': 4,
      'Mei': 5,
      'Juni': 6,
      'Juli': 7,
      'Agustus': 8,
      'September': 9,
      'Oktober': 10,
      'November': 11,
      'Desember': 12,
    };
    return months[month] ?? 1; // Default ke Januari jika tidak ditemukan
  }

  // Tambahkan fungsi untuk mengecek apakah ini bulan current
  void _generatePeriods() async {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Tambahkan bulan dan tahun saat ini dahulu
    final months = {
      1: 'Januari',
      2: 'Februari',
      3: 'Maret',
      4: 'April',
      5: 'Mei',
      6: 'Juni',
      7: 'Juli',
      8: 'Agustus',
      9: 'September',
      10: 'Oktober',
      11: 'November',
      12: 'Desember',
    };

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('order_history')
              .orderBy('timestamp', descending: true)
              .get();

      final Set<String> addedPeriods = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['timestamp'] is Timestamp) {
          final ts = (data['timestamp'] as Timestamp).toDate();
          final key = '${ts.month}-${ts.year}';
          if (!addedPeriods.contains(key)) {
            _reportPeriods.add({
              'month': months[ts.month] ?? 'N/A',
              'year': ts.year.toString(),
            });
            addedPeriods.add(key);
          }
        }
      }
    } catch (e) {
      print('Error generating periods: $e');
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Pilih Periode Laporan:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _reportPeriods.length,
            itemBuilder: (context, index) {
              final period = _reportPeriods[index];
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                elevation: 0,
                child: InkWell(
                  onTap: () {
                    _generateReport(period['month']!, period['year']!);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 20.0,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.insert_drive_file, color: xprimaryColor),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            '${period['month']} ${period['year']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          HugeIcons.strokeRoundedDownload04,
                          color: xprimaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
