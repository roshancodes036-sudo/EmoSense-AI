import 'dart:async';
import 'dart:ui'; // Glass effect के लिए
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

// ✅ फिक्स: पाथ में 'services' (s के साथ) कर दिया गया है
import '../../core/services/api_service.dart';

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
  bool _showResultPanel = false;
  String _text = "";
  String _status = "STANDBY";

  // Data Holders
  Map<String, dynamic>? _sentimentData;
  String _advice = "";

  // Animations
  late AnimationController _orbController;
  late Animation<double> _orbAnimation;
  late AnimationController _panelController;
  late Animation<Offset> _panelAnimation;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    // Orb Animation
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _orbAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _orbController, curve: Curves.easeInOut),
    );

    // Slide Up Animation
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _panelAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _panelController, curve: Curves.fastLinearToSlowEaseIn));

    // Pulse Animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _initSystem();
  }

  void _initSystem() async {
    await Permission.microphone.request();
    await _tts.setLanguage("en-US");
    await _tts.setPitch(0.6);
    await _tts.setSpeechRate(0.5);

    if (mounted) setState(() => _status = "SYSTEM ONLINE");

    await Future.delayed(const Duration(milliseconds: 1000));
    await _speak("EmoSense AI is Online, Sir.");
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _tts.speak(text);
      await _tts.awaitSpeakCompletion(true);
    }
  }

  void _handleOrbTap() async {
    if (_isListening || _isThinking) {
      _stopListening();
      return;
    }

    if (_showResultPanel) {
      _panelController.reverse();
      setState(() => _showResultPanel = false);
    }

    await _speak("I am here, Sir.");
    _startListening();
  }

  void _startListening() async {
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
          onResult: (val) => setState(() => _text = val.recognizedWords));
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _processVoice() async {
    if (_text.isEmpty || _text == "Listening..." || _text.length < 2) {
      _speak("Input unclear. Please tap again.");
      setState(() => _status = "STANDBY");
      return;
    }

    setState(() {
      _isThinking = true;
      _status = "PROCESSING...";
    });

    try {
      final data = await _apiService.analyzeSentiment(_text);
      _sentimentData = data;

      Map<String, dynamic> overall = data['overall'];
      String mood = "Neutral";
      int maxVal = 0;
      overall.forEach((key, value) {
        if (value > maxVal) {
          maxVal = value;
          mood = key;
        }
      });

      String action = "";
      if (mood == "Happy") {
        action = "Keep maintaining this energy level.";
      } else if (mood == "Sad") {
        action = "I recommend taking a short break. Playing calming music now.";
      } else if (mood == "Angry") {
        action =
            "Pulse elevated. Deep breathing protocols advised immediately.";
      } else if (mood == "Fear") {
        action = "Analyze the threat logically. You are safe, Sir.";
      } else {
        action = "Systems functioning within normal parameters.";
      }

      setState(() {
        _advice = action;
      });

      await _speak("Processing complete. User is $mood. $action");

      setState(() {
        _isThinking = false;
        _status = "ANALYSIS COMPLETE";
        _showResultPanel = true;
      });
      _panelController.forward();
    } catch (e) {
      _speak("System failure. Unable to analyze.");
      setState(() {
        _isThinking = false;
        _text = "Error: Check Connection";
      });
    }
  }

  @override
  void dispose() {
    _orbController.dispose();
    _panelController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SafeArea(
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: _isListening
                              ? Colors.redAccent
                              : Colors.cyanAccent.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(_status,
                        style: TextStyle(
                            color: _isListening
                                ? Colors.redAccent
                                : Colors.cyanAccent,
                            fontFamily: 'Courier',
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const Spacer(),
                if (!_isListening && !_isThinking) ...[
                  FadeTransition(
                    opacity: _pulseController,
                    child: Column(
                      children: [
                        const Icon(Icons.fingerprint,
                            color: Colors.cyanAccent, size: 50),
                        const SizedBox(height: 10),
                        Text(
                          "TAP ORB TO START",
                          style: TextStyle(
                              color: Colors.cyanAccent.withOpacity(0.8),
                              fontFamily: 'Courier',
                              letterSpacing: 3.0,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
                GestureDetector(
                  onTap: _handleOrbTap,
                  child: AnimatedBuilder(
                    animation: _orbAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isListening ? _orbAnimation.value : 1.0,
                        child: Container(
                          height: 350,
                          width: 350,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent),
                          child: ClipOval(
                            child: Image.asset("assets/orb.gif",
                                fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    _text.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                        fontFamily: 'Courier',
                        letterSpacing: 1.0),
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 120),
              ],
            ),
          ),
          SlideTransition(
            position: _panelAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _buildGlassCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard() {
    if (_sentimentData == null) return const SizedBox.shrink();
    var overall = _sentimentData!['overall'] as Map<String, dynamic>;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 520,
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            border: const Border(
                top: BorderSide(color: Colors.cyanAccent, width: 2)),
            gradient: LinearGradient(
              colors: [Colors.cyanAccent.withOpacity(0.15), Colors.black],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 50,
                      height: 4,
                      color: Colors.white24,
                      margin: const EdgeInsets.only(bottom: 20))),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("DIAGNOSTIC REPORT",
                      style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 14,
                          letterSpacing: 3,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold)),
                  const Icon(Icons.data_usage,
                      color: Colors.cyanAccent, size: 20),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.cyanAccent.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user, color: Colors.cyanAccent),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("AI PROTOCOL:",
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontFamily: 'Courier',
                                  letterSpacing: 1.5)),
                          const SizedBox(height: 5),
                          Text(_advice.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const Text("EMOTION MATRIX:",
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 2,
                      fontFamily: 'Courier')),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: overall.entries.map((e) {
                    return _buildEmotionBar(e.key, e.value);
                  }).toList(),
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () => _panelController.reverse(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.redAccent),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("CLOSE INTERFACE",
                        style: TextStyle(
                            color: Colors.redAccent,
                            letterSpacing: 2,
                            fontFamily: 'Courier',
                            fontSize: 12)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionBar(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontFamily: 'Courier')),
            Text("$value%",
                style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 10,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: (value as int) / 100,
          backgroundColor: Colors.white10,
          color: value > 50 ? Colors.cyanAccent : Colors.purpleAccent,
          minHeight: 2,
        ),
      ],
    );
  }
}
