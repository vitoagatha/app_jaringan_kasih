import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import 'education_detail_screens.dart';

class LingkunganScreens extends StatelessWidget{
  const LingkunganScreens({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
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
                      'Gerakan Lestari Alam',
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
                const Text('By Bumi Lestari', style: TextStyle(fontSize: 12)),
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

          SizedBox(height: 16),
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
                      'Menolong Hewan Terlantar',
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
                const Text('By Sahabat Alam', style: TextStyle(fontSize: 12)),
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

          SizedBox(height: 16),
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
                      'Alirkan Pahal lewat Sedekah\nPohon',
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
                const Text('By Bumi Lestari', style: TextStyle(fontSize: 12)),
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
      ),
    );
  }
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