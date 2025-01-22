import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/category_card.dart';
import 'category_detail_screens.dart';

class PopularSectionScreens extends StatefulWidget {
  const PopularSectionScreens({super.key});

  @override
  State<PopularSectionScreens> createState() => _PopularSectionScreensState();
}

class _PopularSectionScreensState extends State<PopularSectionScreens> {
  final Set<String> _wishlistIds = {};

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
  }

  Future<void> _fetchWishlist() async {
    final wishlistSnapshot = await FirebaseFirestore.instance.collection('wishlist').get();
    setState(() {
      _wishlistIds.addAll(wishlistSnapshot.docs.map((doc) => doc.id));
    });
  }

  bool _isInWishlist(String id) {
    return _wishlistIds.contains(id);
  }

  Future<void> _toggleWishlist(String id, Map<String, dynamic> data) async {
    if (_isInWishlist(id)) {
      await FirebaseFirestore.instance.collection('wishlist').doc(id).delete();
      setState(() {
        _wishlistIds.remove(id);
      });
    } else {
      await FirebaseFirestore.instance.collection('wishlist').doc(id).set(data);
      setState(() {
        _wishlistIds.add(id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Popular Section'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('pendanaan').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Terjadi kesalahan saat memuat data.'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Belum ada pendanaan yang tersedia.'));
            }

            final popularItems = snapshot.data!.docs;

            return ListView.builder(
              itemCount: popularItems.length,
              itemBuilder: (context, index) {
                final doc = popularItems[index];
                final item = doc.data() as Map<String, dynamic>;
                final collectedAmount = item['collectedAmount'] ?? 0;
                final targetAmount = item['targetAmount'] ?? 0;

                return CategoryCard(
                  image: item['image'] ?? 'assets/images/default.png',
                  title: item['judul'] ?? 'Tanpa Judul',
                  pengajuPendanaan: item['pengaju'] ?? 'Anonim',
                  kategori: item['kategori'] ?? 'Umum',
                  collectedAmount: collectedAmount,
                  targetAmount: targetAmount,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryDetailScreens(data: item),
                      ),
                    );
                  },
                  onBookmark: () {
                    _toggleWishlist(doc.id, item);
                  },
                  isBookmarked: _isInWishlist(doc.id),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
