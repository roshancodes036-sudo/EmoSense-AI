import 'package:flutter/material.dart';
import 'views/splash/splash_screen.dart'; // ✅ सही प्रोफेशनल पाथ

void main() {
  // 1. इंजन को शुरू करने के लिए यह लाइन सबसे ज़रूरी है (Fixes NotInitializedError)
  WidgetsFlutterBinding.ensureInitialized();
  
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
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
        fontFamily: 'Courier', // प्रोफेशनल जार्विस फॉन्ट
      ),
      // ऐप हमेशा स्पलैश स्क्रीन से शुरू होगा
      home: const SplashScreen(),
    );
  }
}