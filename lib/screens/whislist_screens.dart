import 'package:flutter/material.dart';

class WhislistScreens extends StatelessWidget{


  final List<Map<String, dynamic>> bookmarkedItems;

  const WhislistScreens({super.key, required this.bookmarkedItems});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('Whislist'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: bookmarkedItems.isEmpty
          ? const Center(child: Text('Belum ada item di Wishlist.'))
          : ListView.builder(
        itemCount: bookmarkedItems.length,
        itemBuilder: (context, index) {
          final item = bookmarkedItems[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: Image.asset(item['image']),
              title: Text(item['title']),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  // Tambahkan logika hapus jika diperlukan
                },
              ),
            ),
          );
        },
      ),
    );
  }
}