import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl package

class CategoryDetailScreens extends StatelessWidget {
  final Map<String, dynamic> data;

  const CategoryDetailScreens({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Formatter for formatting numbers
    final formatter = NumberFormat.decimalPattern('id');

    // Format collectedAmount and targetAmount
    final collectedAmount = formatter.format(data['collectedAmount'] ?? 0);
    final targetAmount = formatter.format(data['targetAmount'] ?? 0);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        // title: Text(data['judul'] ?? 'Detail Pendanaan'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.asset(
              data['image'] ?? 'assets/images/default.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200.0,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            data['judul'] ?? 'Tanpa Judul',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pengaju: ${data['pengaju'] ?? 'Anonim'}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                'Kategori: ${data['kategori'] ?? 'Umum'}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Divider(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Terkumpul',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                'Target',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rp $collectedAmount',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              Text(
                'Rp $targetAmount',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
          const Divider(height: 32),

          // Description Text
          Text(
            data['deskripsi'] ?? 'Deskripsi tidak tersedia',
            textAlign: TextAlign.justify,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () {
            // TODO: Implement donation logic
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: Colors.teal,
          ),
          child: const Text('Donasi Sekarang', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
