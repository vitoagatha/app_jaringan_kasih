import 'package:app_jaringan_kasih/screens/education_detail_screens.dart';
import 'package:app_jaringan_kasih/screens/education_screens.dart';
import 'package:flutter/material.dart';

class HomeScreens extends StatelessWidget {
  const HomeScreens({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
              fontSize: 22,
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Donasi sekarang'),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCategory(icon: Icons.apps, label: 'All', onTap: () {}),
        _buildCategory(icon: Icons.health_and_safety_outlined, label: 'Kesehatan', onTap: () {}),
        _buildCategory(
          icon: Icons.school,
          label: 'Edukasi',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EducationScreens()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategory({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 45),
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
                  'assets/images/chd1.jpeg',
                  fit: BoxFit.fill,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Edukasi untuk anak miskin',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
