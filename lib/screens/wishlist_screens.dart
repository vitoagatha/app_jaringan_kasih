import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/category_card.dart';
import 'category_detail_screens.dart';

class WishlistScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('wishlist').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Wishlist kosong.'));
          }

          final wishlistItems = snapshot.data!.docs;

          return ListView.builder(
            itemCount: wishlistItems.length,
            itemBuilder: (context, index) {
              final item = wishlistItems[index].data() as Map<String, dynamic>;

              return CategoryCard(
                image: item['image'] ?? 'assets/images/default.png',
                title: item['judul'] ?? 'Tanpa Judul',
                pengajuPendanaan: item['pengaju'] ?? 'Anonim',
                kategori: item['kategori'] ?? 'Umum',
                collectedAmount: item['collectedAmount'] ?? 0,
                targetAmount: item['targetAmount'] ?? 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryDetailScreens(data: item),
                    ),
                  );
                },
                onBookmark: () async {
                  await FirebaseFirestore.instance
                      .collection('wishlist')
                      .doc(wishlistItems[index].id)
                      .delete();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dihapus dari Wishlist')),
                  );
                },
                isBookmarked: true,
              );
            },
          );
        },
      ),
    );
  }
}