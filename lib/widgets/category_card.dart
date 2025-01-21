import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String image;
  final String title;
  final String pengajuPendanaan;  // Update this to reflect the pengaju pendanaan (fundraiser)
  final String kategori;  // Kategori label
  final String description;
  final String collectedAmount;
  final String targetAmount;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  const CategoryCard({
    required this.image,
    required this.title,
    required this.pengajuPendanaan,  // Update to reflect the pengaju pendanaan
    required this.kategori,  // Kategori value (like "Pendidikan")
    required this.description,
    required this.collectedAmount,
    required this.targetAmount,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
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
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 180,  // Adjust the height to fit well in the layout
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.bookmark_border),
                onPressed: onBookmark,
              ),
            ],
          ),
          Text(
            'By $pengajuPendanaan',  // Update to show "Pengaju Pendanaan"
            style: TextStyle(fontSize: 12, color: Colors.grey),
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
                  kategori,  // Show the category (e.g., "Pendidikan")
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(fontSize: 14, color: Colors.black54),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat(label: 'Terkumpul', value: collectedAmount),
              _buildStat(label: 'Target', value: targetAmount),
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
        Text(label, style: TextStyle(fontSize: 12, color: Colors.black45)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
