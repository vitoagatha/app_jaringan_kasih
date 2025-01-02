import 'package:app_jaringan_kasih/screens/home_screens.dart';
import 'package:flutter/material.dart';

class EducationScreens extends StatelessWidget {
  const EducationScreens({super.key});

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
          Container(
            padding: const EdgeInsets.all(20.0),
            margin: const EdgeInsets.all(10.0),
            height: 280,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12)
            ),
            child:
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/chd1.jpeg',
                  // width: 100,
                  // height: 200,
                  fit: BoxFit.fill,
                ),
                Text(
                  'Edukasi untuk anak miskin',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'By Jaringan Kasih',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Terkumpul',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rp. 1.200.000,00',
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Target',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                            'Rp. 25.000.000,00'
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20.0),
            margin: const EdgeInsets.all(10.0),
            height: 280,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12)
            ),
            child:
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/chd1.jpeg',
                  // width: 100,
                  // height: 200,
                  fit: BoxFit.fill,
                ),
                Text(
                  'Edukasi untuk anak miskin',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'By Jaringan Kasih',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Terkumpul',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rp. 1.200.000,00',
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Target',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                            'Rp. 25.000.000,00'
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20.0),
            margin: const EdgeInsets.all(10.0),
            height: 280,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12)
            ),
            child:
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/chd1.jpeg',
                  // width: 100,
                  // height: 200,
                  fit: BoxFit.fill,
                ),
                Text(
                  'Edukasi untuk anak miskin',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'By Jaringan Kasih',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Terkumpul',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rp. 1.200.000,00',
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Target',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                            'Rp. 25.000.000,00'
                        ),
                      ],
                    )
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