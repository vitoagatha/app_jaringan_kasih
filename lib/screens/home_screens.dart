import 'package:app_jaringan_kasih/screens/about_screens.dart';
import 'package:app_jaringan_kasih/screens/category_screens.dart';
import 'package:app_jaringan_kasih/screens/login_screens.dart';
import 'package:app_jaringan_kasih/screens/popular_section_screens.dart';
import 'package:app_jaringan_kasih/screens/profile_screens.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/category_card.dart';
import 'category_detail_screens.dart';
import 'wishlist_screens.dart';
import 'buat_pendanaan_screens.dart';

class HomeScreens extends StatefulWidget {
  const HomeScreens({super.key});

  @override
  _HomeScreensState createState() => _HomeScreensState();
}

class _HomeScreensState extends State<HomeScreens>{
  final List<Map<String, dynamic>> bookmarkedItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      drawer: CustomDrawer(
        bookmarkedItems: bookmarkedItems,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const DonationCard(),
          const SizedBox(height: 20),
          const CategoryRow(),
          const SizedBox(height: 20),
          PopularSection(

          ),
        ],
      ),
    );
  }
}

class CustomDrawer extends StatelessWidget {
  final List<Map<String, dynamic>> bookmarkedItems;

  const CustomDrawer({super.key, required this.bookmarkedItems});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.teal),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 50.0),
                CircleAvatar(
                  radius: 35.0,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.teal, size: 50.0),
                ),
                const SizedBox(height: 10),
                Text(
                  FirebaseAuth.instance.currentUser?.displayName ?? 'Nama Tidak Tersedia', // Menampilkan nama pengguna
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            title: 'Akun',
            icon: Icons.account_circle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreens()),
              );
            },
          ),
          _buildDrawerItem(
            title: 'Buat Pendanaan',
            icon: Icons.note_alt,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BuatPendanaanScreens()),
              );
            },
          ),
          _buildDrawerItem(
            title: 'Wishlist',
            icon: Icons.bookmarks,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WishlistScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            title: 'Daftar Transaksi',
            icon: Icons.my_library_books,
            onTap: () {
              _showAlertDialog(context);
            },
          ),
          _buildDrawerItem(
            title: 'Tentang Kami',
            icon: Icons.info,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutScreens()),
              );
            },
          ),
          _buildDrawerItem(
            title: 'Keluar',
            icon: Icons.logout,
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreens()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Container(
              alignment: Alignment.center,
              child: Text('Oopss...')
          ),
          content: Text("Maaf fitur masih dalam pengembangan."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawerItem({required String title, required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.black)),
      leading: Icon(
        icon,
        color: icon == Icons.logout ? Colors.red : Colors.teal,
      ),
      onTap: onTap,
    );
  }
}

class DonationCard extends StatelessWidget {
  const DonationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      height: 170,
      decoration: BoxDecoration(
        color: Colors.teal,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Mulai melakukan pendanaan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const Text(
            'Ciptakan kebaikanmu',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            child: ElevatedButton(
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PopularSectionScreens()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Donasi Sekarang",
                style: TextStyle(fontSize: 14, color: Colors.teal),
              )
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryRow extends StatelessWidget {
  const CategoryRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCategory(
                icon: FontAwesome.graduation_cap_solid,
                label: 'Pendidikan',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CategoryScreens(category: 'Pendidikan')),
                  );
                },
              ),
            ),
            Expanded(
              child: _buildCategory(
                icon: FontAwesome.house_medical_solid,
                color: Colors.teal,
                label: 'Kesehatan',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CategoryScreens(category: 'Kesehatan')),
                  );
                },
              ),
            ),
            Expanded(
              child: _buildCategory(
                icon: FontAwesome.hand_holding_dollar_solid,
                label: 'Zakat',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CategoryScreens(category: 'Zakat')),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildCategory(
                icon: FontAwesome.tree_solid,
                label: 'Lingkungan',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CategoryScreens(category: 'Lingkungan')),
                  );
                },
              ),
            ),
            Expanded(
              child: _buildCategory(
                icon: FontAwesome.mosque_solid,
                color: Colors.teal,
                label: 'Rumah Ibadah',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CategoryScreens(category: 'Rumah Ibadah')),
                  );
                },
              ),
            ),
            Expanded(
              child: _buildCategory(
                icon: FontAwesome.earth_europe_solid,
                label: 'Bencana Alam',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CategoryScreens(category: 'Bencana Alam')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategory({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 30, color: color),
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class PopularSection extends StatefulWidget {
  const PopularSection({super.key});

  @override
  State<PopularSection> createState() => _PopularSectionState();
}

class _PopularSectionState extends State<PopularSection> {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
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
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
      ],
    );
  }
}


