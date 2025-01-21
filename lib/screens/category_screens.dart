import 'package:flutter/material.dart';
import '../widgets/category_card.dart';
import 'education_detail_screens.dart';

class CategoryScreens extends StatelessWidget {
  final List<Map<String, String>> categories = [
    {
      'image': 'assets/images/education1.png',
      'title': 'Edukasi untuk anak miskin',
      'pengajuPendanaan': 'Pondok Yatim',
      'kategori': 'Pendidikan',  // Category label (e.g., "Pendidikan")
      'description': 'A detailed description of the project',
      'collectedAmount': 'Rp. 1.200.000,00',
      'targetAmount': 'Rp. 25.000.000,00',
    },
    {
      'image': 'assets/images/education1.png',
      'title': 'Bantuan Sekolah Anak Terlantar',
      'pengajuPendanaan': 'Panti Asuhan Yadika, Surabaya',
      'kategori': 'Pendidikan',  // Category label
      'description': 'A detailed description of the project',
      'collectedAmount': 'Rp. 1.200.000,00',
      'targetAmount': 'Rp. 25.000.000,00',
    },
    // Add more categories here...
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kategori Pendanaan'),
        centerTitle: true,

      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return CategoryCard(
            image: categories[index]['image']!,
            title: categories[index]['title']!,
            pengajuPendanaan: categories[index]['pengajuPendanaan']!,  // Pass pengajuPendanaan
            kategori: categories[index]['kategori']!,  // Pass kategori
            description: categories[index]['description']!,
            collectedAmount: categories[index]['collectedAmount']!,
            targetAmount: categories[index]['targetAmount']!,
            onTap: () {
              // Navigate to detail screen when tapped
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EducationDetailScreens()),
              );
            },
            onBookmark: () {
              // Handle bookmark action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ditambahkan ke Wishlist')),
              );
            },
          );
        },
      ),
    );
  }
}
