import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:kopitan_app/colors.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({Key? key}) : super(key: key);

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  // List yang berisi data periode laporan
  final List<Map<String, String>> _reportPeriods = [
    {'month': 'Mei', 'year': '2025'},
    {'month': 'April', 'year': '2025'},
    {'month': 'Maret', 'year': '2025'},
    {'month': 'Februari', 'year': '2025'},
    {'month': 'Januari', 'year': '2025'},
    {'month': 'Desember', 'year': '2024'},
    {'month': 'November', 'year': '2024'},
    {'month': 'Oktober', 'year': '2024'},
    {'month': 'September', 'year': '2024'},
    {'month': 'Agustus', 'year': '2024'},
    {'month': 'Juli', 'year': '2024'},
    {'month': 'Juni', 'year': '2024'},
  ];

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
                  side: BorderSide(
                    color: Colors.grey.shade300, // warna border
                    width: 1, // ketebalan border
                  ),
                ),
                elevation: 0,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur sedang dikembangkan'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 20.0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.insert_drive_file,
                            color: xprimaryColor,
                            size: 28,
                          ),
                        ),
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
