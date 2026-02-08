import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(const EmoSenseApp());
}

class EmoSenseApp extends StatelessWidget {
  const EmoSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EmoSense AI',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
        fontFamily: 'Courier',
      ),
      // ERROR FIX: Yahan se 'const' hata diya hai
      home: SplashScreen(),
    );
  }
}
