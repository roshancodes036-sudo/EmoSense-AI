import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Bolne ke liye
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Services
  late stt.SpeechToText _speech;
  final FlutterTts _tts = FlutterTts();
  final ApiService _apiService = ApiService();

  // Variables
  bool _isListening = false;
  bool _isThinking = false;
  String _text = "System Initializing...";
  String _status = "OFFLINE";

  // Animation (CodeNetra Orb)
  late AnimationController _orbController;
  late Animation<double> _orbAnimation;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    // Orb Pulse Animation
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _orbAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _orbController, curve: Curves.easeInOut),
    );

    _initSystem();
  }

  // 1. SETUP SYSTEM
  void _initSystem() async {
    await Permission.microphone.request();

    // TTS Settings
    await _tts.setLanguage("en-US");
    await _tts.setPitch(0.8);
    await _tts.setSpeechRate(0.5);

    if (mounted) {
      setState(() => _status = "ONLINE");
    }

    // App start hote hi bolega
    await Future.delayed(const Duration(milliseconds: 500));
    _speak("EmoSense is online. Tap the orb to analyze your emotions.");

    if (mounted) {
      setState(() => _text = "Tap the Orb to Speak...");
    }
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _tts.speak(text);
    }
  }

  // 2. SUNNA (Listening)
  void _startListening() async {
    if (_isThinking) return;

    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          if (mounted && _isListening) {
            setState(() => _isListening = false);
            _processVoice(); // Auto-Process
          }
        }
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _status = "LISTENING...";
        _text = "Listening...";
      });

      _speech.listen(
        onResult: (val) {
          setState(() {
            _text = val.recognizedWords;
          });
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  // 3. DIMAG (Analyzing)
  void _processVoice() async {
    if (_text.isEmpty || _text == "Listening..." || _text.length < 2) {
      _speak("I didn't catch that. Please try again.");
      setState(() => _status = "IDLE");
      return;
    }

    setState(() {
      _isThinking = true;
      _status = "ANALYZING...";
    });

    try {
      final data = await _apiService.analyzeSentiment(_text);

      // Dominant Emotion nikalo
      Map<String, dynamic> overall = data['overall'];
      String mood = "Neutral";
      int maxVal = 0;
      overall.forEach((key, value) {
        if (value > maxVal) {
          maxVal = value;
          mood = key;
        }
      });

      await _speak("Analysis complete. You sound $mood.");

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ResultScreen(sentimentData: data, userText: _text),
          ),
        ).then((_) {
          setState(() {
            _isThinking = false;
            _text = "Tap the Orb to Speak...";
            _status = "ONLINE";
          });
        });
      }
    } catch (e) {
      _speak("Sorry, I encountered an error.");
      setState(() {
        _isThinking = false;
        _text = "Error: Try Again";
      });
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("CODE NETRA AI",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                  color: _isListening
                      ? Colors.redAccent
                      : Colors.cyanAccent.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(5),
              color: Colors.white.withOpacity(0.05),
            ),
            child: Text(
              _status,
              style: TextStyle(
                color: _isListening ? Colors.redAccent : Colors.cyanAccent,
                fontSize: 16,
                fontFamily: 'Courier',
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 50),

          // --- THE ORB (Fixed: No Filter Error) ---
          Center(
            child: GestureDetector(
              onTap: () {
                if (_isListening) {
                  _stopListening();
                } else {
                  _startListening();
                }
              },
              child: AnimatedBuilder(
                animation: _orbAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _orbAnimation.value : 1.0,
                    child: Container(
                      height: 220,
                      width: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Gradient wahi CodeNetra wala
                        gradient: const RadialGradient(
                          colors: [
                            Color(0xFFB388FF), // Light Purple
                            Color(0xFF651FFF), // Deep Purple
                            Color(0xFF2962FF), // Blue
                          ],
                          stops: [0.1, 0.5, 1.0],
                        ),
                        // ERROR FIX: 'filter' hata diya, 'boxShadow' use kiya
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF651FFF).withOpacity(0.6),
                            blurRadius: _isListening ? 50 : 20,
                            spreadRadius: _isListening ? 10 : 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isThinking
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Icon(
                                _isListening
                                    ? Icons.graphic_eq
                                    : Icons.mic_none,
                                color: Colors.white,
                                size: 80,
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 60),

          // Live Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              _text.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
                fontWeight: FontWeight.w300,
                fontFamily: 'Courier',
                letterSpacing: 1.1,
              ),
            ),
          ),

          const Spacer(),
          const Text("POWERED BY GEMINI 1.5",
              style: TextStyle(
                  color: Colors.white24, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
