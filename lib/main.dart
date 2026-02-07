import 'package:flutter/material.dart';
import 'home_screen.dart'; // Humne Home Screen yahan connect ki hai

void main() {
  runApp(const EmoSenseApp());
}

class EmoSenseApp extends StatelessWidget {
  const EmoSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Debug ka ribbon hatane ke liye
      title: 'EmoSense AI',
      theme: ThemeData(
        brightness: Brightness.dark, // Professional Dark Mode
        primarySwatch: Colors.cyan,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const HomeScreen(), // App yahan se shuru hoga
    );
  }
}
