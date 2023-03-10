import 'package:flutter/material.dart';

import 'package:movies/screens/screens.dart';



void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movies',
      debugShowCheckedModeBanner: false,
      initialRoute: 'home',
      routes: {
        'home':( _ ) => HomeScreen(),
        'details':( _ ) => DetailsScreen(),

      },
    );
  }
}