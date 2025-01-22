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
    );
  }
}
