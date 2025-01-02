import 'package:app_jaringan_kasih/screens/welcome_screens.dart';
import 'package:flutter/material.dart';
import 'package:app_jaringan_kasih/screens/home_screens.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const String appTitle = 'Jaringan Kasih';
    return const MaterialApp(
      title: appTitle,
      home: WelcomeScreens(),
    );
  }
}