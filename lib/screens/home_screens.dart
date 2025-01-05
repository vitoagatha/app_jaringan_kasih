import 'package:app_jaringan_kasih/screens/bencana_alam_screens.dart';
import 'package:app_jaringan_kasih/screens/education_detail_screens.dart';
import 'package:app_jaringan_kasih/screens/education_screens.dart';
import 'package:app_jaringan_kasih/screens/health_screens.dart';
import 'package:app_jaringan_kasih/screens/lingkungan_screens.dart';
import 'package:app_jaringan_kasih/screens/rumah_ibadah_screens.dart';
import 'package:app_jaringan_kasih/screens/zakat_screens.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter/material.dart';

class HomeScreens extends StatelessWidget {
  const HomeScreens({super.key});

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
      drawer: const CustomDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const DonationCard(),
          const SizedBox(height: 20),
          const CategoryRow(),
          const SizedBox(height: 20),
          const PopularSection(),
        ],
      ),
    );
  }
}

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

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
                Text('agus.salim@gmail.com', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          _buildDrawerItem(
            title: 'Buat Pendanaan',
            icon: Icons.monetization_on,
            onTap: () {},
          ),
          _buildDrawerItem(
            title: 'Wishlist',
            icon: Icons.bookmarks,
            onTap: () {},
          ),
          _buildDrawerItem(
            title: 'Daftar Transaksi',
            icon: Icons.note_alt,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({required String title, required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.teal)),
      leading: Icon(icon, color: Colors.teal),
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
                    MaterialPageRoute(builder: (context) => const EducationScreens()),
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
  const PopularSection({super.key});

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
        Container(
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EducationDetailScreens()),
                  );
                },
                child: Image.asset(
                  'assets/images/education1.png',
                  fit: BoxFit.fill,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edukasi untuk anak miskin',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(FontAwesome.bookmark),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ditambahkan ke Wishlist'),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Text('By Jaringan Kasih', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat(label: 'Terkumpul', value: 'Rp. 1.200.000,00'),
                  _buildStat(label: 'Target', value: 'Rp. 25.000.000,00'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EducationDetailScreens()),
                  );
                },
                child: Image.asset(
                  'assets/images/education1.png',
                  fit: BoxFit.fill,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edukasi untuk anak miskin',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(FontAwesome.bookmark),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ditambahkan ke Wishlist'),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Text('By Jaringan Kasih', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat(label: 'Terkumpul', value: 'Rp. 1.200.000,00'),
                  _buildStat(label: 'Target', value: 'Rp. 25.000.000,00'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(value),
      ],
    );
  }
}
