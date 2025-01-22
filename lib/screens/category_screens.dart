import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/category_card.dart';
import 'category_detail_screens.dart';

class CategoryScreens extends StatefulWidget {
  final String category;

  const CategoryScreens({super.key, required this.category});

  @override
  State<CategoryScreens> createState() => _CategoryScreensState();
}

class _CategoryScreensState extends State<CategoryScreens> {
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
      // Jika ada, hapus dari wishlist
      await FirebaseFirestore.instance.collection('wishlist').doc(id).delete();
      setState(() {
        _wishlistIds.remove(id);
      });
    } else {
      // Jika tidak ada, tambahkan ke wishlist
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
        title: Text(widget.category),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pendanaan')
            .where('kategori', isEqualTo: widget.category)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Belum ada pendanaan di kategori ${widget.category}.'));
          }

          final filteredCategories = snapshot.data!.docs;

          return ListView.builder(
            itemCount: filteredCategories.length,
            itemBuilder: (context, index) {
              final doc = filteredCategories[index];
              final category = doc.data() as Map<String, dynamic>;
              final collectedAmount = category['collectedAmount'] ?? 0;
              final targetAmount = category['targetAmount'] ?? 0;

              return CategoryCard(
                image: category['image'] ?? 'assets/images/education1.png',
                title: category['judul'] ?? 'Tanpa Judul',
                pengajuPendanaan: category['pengaju'] ?? 'Anonim',
                kategori: category['kategori'] ?? 'Umum',
                collectedAmount: collectedAmount,
                targetAmount: targetAmount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryDetailScreens(data: category),
                    ),
                  );
                },
                onBookmark: () {
                  _toggleWishlist(doc.id, category);
                },
                isBookmarked: _isInWishlist(doc.id),
              );
            },
          );
        },
      ),
    );
  }
}
