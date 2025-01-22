import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BuatPendanaanScreens extends StatefulWidget {
  const BuatPendanaanScreens({super.key});

  @override
  _BuatPendanaanScreensState createState() => _BuatPendanaanScreensState();
}

class _BuatPendanaanScreensState extends State<BuatPendanaanScreens> {
  final _judulController = TextEditingController();
  final _pengajuController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _targetController = TextEditingController();
  String? _kategori;

  Future<void> _simpanPendanaan() async {
    if (_judulController.text.isNotEmpty &&
        _pengajuController.text.isNotEmpty &&
        _kategori != null &&
        _deskripsiController.text.isNotEmpty &&
        _targetController.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('pendanaan').add({
          'judul': _judulController.text,
          'pengaju': _pengajuController.text,
          'kategori': _kategori,
          'deskripsi': _deskripsiController.text,
          'collectedAmount': 0,
          'targetAmount': int.parse(_targetController.text),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pendanaan berhasil disimpan')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harap isi semua field')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buat Pendanaan'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tambah Pendanaan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _judulController,
              decoration: InputDecoration(
                labelText: 'Judul Pendanaan',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _pengajuController,
              decoration: InputDecoration(
                labelText: 'Pengaju Pendanaan',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _kategori,
              decoration: InputDecoration(labelText: 'Pilih Kategori'),
              items: ['Pendidikan', 'Kesehatan', 'Zakat', 'Lingkungan', 'Rumah Ibadah', 'Bencana Alam']
                  .map((kategori) => DropdownMenuItem(
                value: kategori,
                child: Text(kategori),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _kategori = value;
                });
              },
            ),
            SizedBox(height: 8),
            TextField(
              controller: _deskripsiController,
              decoration: InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 8),
            TextField(
              controller: _targetController,
              decoration: InputDecoration(
                labelText: 'Target Pendanaan',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _simpanPendanaan,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 45),
            backgroundColor: Colors.teal,
          ),
          child: Text('Ajukan', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}