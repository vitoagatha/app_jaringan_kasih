import 'package:flutter/material.dart';
import 'home_screens.dart';

class EducationDetailScreens extends StatelessWidget{
  const EducationDetailScreens({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(32.0),
        children: [
          GestureDetector(
            onTap: (){
              Navigator.pop(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreens(),
                ),
              );
            },
            child: Text('Back'),
          ),
          SizedBox(height: 16),
          Image.asset(
            'assets/images/chd1.jpeg',
          ),
          SizedBox(height: 16),
          Text(
            'Edukasi untul anak miskin',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,'
                ' quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.'
                ' Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {},
          child: const Text('Donasi sekarang'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ),
    );
  }
}