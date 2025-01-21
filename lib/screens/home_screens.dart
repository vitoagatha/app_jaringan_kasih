import 'package:app_jaringan_kasih/screens/bencana_alam_screens.dart';
import 'package:app_jaringan_kasih/screens/category_screens.dart';
import 'package:app_jaringan_kasih/screens/education_detail_screens.dart';
import 'package:app_jaringan_kasih/screens/education_screens.dart';
import 'package:app_jaringan_kasih/screens/health_screens.dart';
import 'package:app_jaringan_kasih/screens/lingkungan_screens.dart';
import 'package:app_jaringan_kasih/screens/login_screens.dart';
import 'package:app_jaringan_kasih/screens/profile_screens.dart';
import 'package:app_jaringan_kasih/screens/rumah_ibadah_screens.dart';
import 'package:app_jaringan_kasih/screens/zakat_screens.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter/material.dart';

import 'whislist_screens.dart';
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
            onBookmarkToggle: (item) {
              setState(() {
                if (bookmarkedItems.contains(item)) {
                  bookmarkedItems.remove(item);
                } else {
                  bookmarkedItems.add(item);
                }
              });
            },
            bookmarkedItems: bookmarkedItems,
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
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30.0,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.teal, size: 40.0),
                ),
                SizedBox(height: 10.0),
                Text('Agus Salim', style: TextStyle(color: Colors.white)),
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
                  builder: (context) => WhislistScreens(
                  bookmarkedItems: bookmarkedItems,
                  ),
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
        color: icon == Icons.logout ? Colors.red : Colors.teal, // Merah untuk ikon logout
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
      height: 155,
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
                  MaterialPageRoute(builder: (context) => HomeScreens()),
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
                    MaterialPageRoute(builder: (context) => CategoryScreens()),
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
                    MaterialPageRoute(builder: (context) => const HealthScreens()),
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
                    MaterialPageRoute(builder: (context) => const ZakatScreens()),
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
                    MaterialPageRoute(builder: (context) => const LingkunganScreens()),
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
                    MaterialPageRoute(builder: (context) => const RumahIbadahScreens()),
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
                    MaterialPageRoute(builder: (context) => const BencanaAlamScreens()),
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

class PopularSection extends StatelessWidget {
  final Function(Map<String, dynamic>) onBookmarkToggle;
  final List<Map<String, dynamic>> bookmarkedItems;

  const PopularSection({
    super.key,
    required this.onBookmarkToggle,
    required this.bookmarkedItems,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'id': 1, 'title': 'Edukasi untuk anak miskin', 'image': 'assets/images/education1.png'},
      {'id': 2, 'title': 'Bantuan pendidikan anak', 'image': 'assets/images/education1.png'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        const SizedBox(height: 16),
        for (var item in items)
          _buildCard(item, bookmarkedItems.contains(item)),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> item, bool isBookmarked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item['title'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? Colors.teal : Colors.black,
            ),
            onPressed: () => onBookmarkToggle(item),
          ),
        ],
      ),
    );
  }
}


