import 'package:flutter/material.dart';

class BuatPendanaanScreens extends StatelessWidget{
  const BuatPendanaanScreens ({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('Buat Pendanaan'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tambah Pendanaan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Judul pendanaan',
              style: TextStyle(fontSize: 16),
            ),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Masukkan judul',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Pengaju pendanaan',
              style: TextStyle(fontSize: 16),
            ),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Masukkan nama pengaju',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Deskripsi',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan Deskripsi',
                ),
                maxLines: 5,
              ),
            ),

            SizedBox(height: 8),
            Text(
              'Target pendanaan',
              style: TextStyle(fontSize: 16),
            ),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Masukkan target',
              ),
            ),

          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // TODO: Implement donation logic
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: Colors.teal,
          ),
          child: const Text('Ajukan', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}