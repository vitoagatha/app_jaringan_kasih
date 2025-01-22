import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CategoryCard extends StatelessWidget {
  final String image;
  final String title;
  final String pengajuPendanaan;
  final String kategori;
  final int collectedAmount;
  final int targetAmount;
  final VoidCallback onTap;
  final VoidCallback onBookmark;
  final bool isBookmarked;

  const CategoryCard({
    super.key,
    required this.image,
    required this.title,
    required this.pengajuPendanaan,
    required this.kategori,
    required this.collectedAmount,
    required this.targetAmount,
    required this.onTap,
    required this.onBookmark,
    required this.isBookmarked,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern('id'); // Formatter untuk angka

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: image.isNotEmpty
                  ? Image.network(
                image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 180,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
                  );
                },
              )
                  : const Center(
                child: Icon(Icons.image, size: 80, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? Colors.black : null,
                ),
                onPressed: onBookmark,
              ),
            ],
          ),
          Text(
            'By $pengajuPendanaan',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  kategori,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat(
                label: 'Terkumpul',
                value: 'Rp ${formatter.format(collectedAmount)}',
              ),
              _buildStat(
                label: 'Target',
                value: 'Rp ${formatter.format(targetAmount)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
