import 'package:flutter/material.dart';

class AboutScreens extends StatelessWidget {
  const AboutScreens({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tentang Kami'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Text(
            'Jaringan Kasih: Semua dapat membantu',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
              'Jaringan Kasih adalah aplikasi yang memfasilitasi setiap individu untuk menyalurkan donasi dalam berbagai kategori seperti pangan,'
                  ' pendidikan, kesehatan, dan kebutuhan sosial lainnya. Kami hadir untuk memberikan solusi yang mempermudah Anda dalam berbagi kebaikan dan membantu mereka yang membutuhkan.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.justify,
          ),
          SizedBox(height: 16),
          Text('Kami percaya bahwa setiap orang memiliki potensi untuk berkontribusi, tidak peduli seberapa besar atau kecil bantuannya. Dengan Jaringan Kasih,'
              ' kami ingin menciptakan platform yang memudahkan proses donasi dan memastikan bantuan sampai tepat kepada yang membutuhkan.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.justify,
          ),
          SizedBox(height: 16),
          Text('Tagline: "Semua dapat membantu."',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.justify,
          ),
          SizedBox(height: 16),
          Text('Mari bergabung bersama kami dalam menyebarkan kebaikan dan menciptakan dampak positif bagi masyarakat.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
