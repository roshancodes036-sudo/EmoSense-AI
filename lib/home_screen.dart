import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
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

  // Animation (Zoom In/Out Effect)
  late AnimationController _orbController;
  late Animation<double> _orbAnimation;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    // Zoom In - Zoom Out Animation (Breathing)
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _orbAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
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

  // 2. LISTENING LOGIC
  void _startListening() async {
    if (_isThinking) return;

    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          if (mounted && _isListening) {
            setState(() => _isListening = false);
            _processVoice();
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

  // 3. AI LOGIC
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
      backgroundColor: Colors.black, // Pura Black Background
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
          // --- STATUS TEXT ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                  color: _isListening
                      ? Colors.redAccent
                      : Colors.cyanAccent.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(5),
              color: Colors.transparent,
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

          // --- THE ORB (Clean Black Background) ---
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
                    // Jab sun raha ho tab Zoom In/Out karega
                    scale: _isListening ? _orbAnimation.value : 1.0,
                    child: Container(
                      height: 400,
                      width: 400,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        // Maine yahan se boxShadow (Glow) hata diya hai
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          "assets/orb.gif",
                          fit: BoxFit.cover, // Pura circle cover karega
                          height: 400,
                          width: 400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 50),

          // --- LIVE TEXT ---
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
