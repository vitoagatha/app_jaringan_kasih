import 'package:flutter/material.dart';

class DetailCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String pengaju;
  final String kategori;
  final String deskripsi;
  final String collectedAmount;
  final String targetAmount;

  const DetailCard({
    Key? key,
    required this.imagePath,
    required this.title,
    required this.pengaju,
    required this.kategori,
    required this.deskripsi,
    required this.collectedAmount,
    required this.targetAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200.0,
          ),
        ),
        const SizedBox(height: 16),
        // Title
        Text(
          title,
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
              'Pengaju: $pengaju',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              'Kategori: $kategori',
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
        Text(
          deskripsi.isNotEmpty ? deskripsi : 'Deskripsi tidak tersedia',
          textAlign: TextAlign.justify,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
