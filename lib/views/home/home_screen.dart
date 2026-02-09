import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

// ✅ Services Import
import '../../core/services/api_service.dart';

// -----------------------------------------------------------
// 1️⃣ MAIN HOME SCREEN
// -----------------------------------------------------------

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

  // ✅ FIX: इसे खाली कर दिया ताकि नीचे डुप्लीकेट टेक्स्ट न आए
  String _text = "";
  String _status = "SYSTEM OFFLINE";

  // Data Holders
  Map<String, dynamic>? _sentimentData;
  String _advice = "";

  // Jarvis Dummy Data Holders
  String _heartRate = "--";
  String _stressLevel = "--";
  String _energyLevel = "--";

  // Animations
  late AnimationController _panelController;
  late Animation<Offset> _panelAnimation;
  late AnimationController _textPulseController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    // Panel Animation
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _panelAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _panelController, curve: Curves.fastLinearToSlowEaseIn));

    // Text Pulse Animation
    _textPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initSystem();
  }

  void _initSystem() async {
    await Permission.microphone.request();

    // JARVIS SETTINGS
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.6);

    if (mounted) setState(() => _status = "SYSTEM ONLINE");

    await Future.delayed(const Duration(milliseconds: 500));
    await _speak("EmoSense AI Online, Sir.");
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

    await _speak("I am listening, Sir.");
    _startListening();
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onError: (val) => print('Error: $val'),
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
        onResult: (val) => setState(() => _text = val.recognizedWords),
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(seconds: 30),
        cancelOnError: false,
        partialResults: true,
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _processVoice() async {
    if (_text.isEmpty || _text == "Listening..." || _text.length < 2) {
      _speak("Audio not captured. Please try again.");
      setState(() => _status = "STANDBY");
      return;
    }

    setState(() {
      _isThinking = true;
      _status = "ANALYZING MOOD...";
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

      _generateJarvisData(mood);

      String action = "";
      if (mood == "Happy") {
        action = "Energy levels are optimal.";
      } else if (mood == "Sad") {
        action = "Dopamine levels low. Recommending rest.";
      } else if (mood == "Angry") {
        action = "Adrenaline spike detected. Calm down, Sir.";
      } else if (mood == "Fear") {
        action = "Stress markers elevated. You are safe.";
      } else {
        action = "All systems normal.";
      }

      setState(() {
        _advice = action;
      });

      await _speak("Analysis complete. You are $mood. $action");

      setState(() {
        _isThinking = false;
        _status = "ANALYSIS COMPLETE";
        _showResultPanel = true;
      });
      _panelController.forward();
    } catch (e) {
      _speak("Unable to connect to Gemini server.");
      setState(() {
        _isThinking = false;
        _text = "Error: Check Internet";
      });
    }
  }

  void _generateJarvisData(String mood) {
    if (mood == "Angry") {
      _heartRate = "120 BPM";
      _stressLevel = "HIGH";
      _energyLevel = "SPIKING";
    } else if (mood == "Fear") {
      _heartRate = "110 BPM";
      _stressLevel = "CRITICAL";
      _energyLevel = "UNSTABLE";
    } else if (mood == "Sad") {
      _heartRate = "65 BPM";
      _stressLevel = "MODERATE";
      _energyLevel = "LOW";
    } else if (mood == "Happy") {
      _heartRate = "85 BPM";
      _stressLevel = "NORMAL";
      _energyLevel = "OPTIMAL";
    } else {
      _heartRate = "72 BPM";
      _stressLevel = "LOW";
      _energyLevel = "STABLE";
    }
  }

  @override
  void dispose() {
    _panelController.dispose();
    _textPulseController.dispose();
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
                    child: Text(
                      _status,
                      style: TextStyle(
                          color: _isListening
                              ? Colors.redAccent
                              : Colors.cyanAccent,
                          fontFamily: 'Courier',
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const Spacer(),

                // ✅ ORB WIDGET
                Orb(
                  onTap: _handleOrbTap,
                  isListening: _isListening || _isThinking,
                ),

                const SizedBox(height: 30),

                // ✅ BIG ANIMATED TEXT (Sirf yahi dikhega)
                if (!_isListening && !_isThinking)
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.6, end: 1.0)
                        .animate(_textPulseController),
                    child: const Text(
                      "TAP TO ORB",
                      style: TextStyle(
                          color: Colors.cyanAccent,
                          fontFamily: 'Courier',
                          letterSpacing: 3.0,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),

                const SizedBox(height: 20),

                // ✅ RESULT TEXT (Sirf tab dikhega jab aap bolenge)
                if (_text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      _text.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontFamily: 'Courier',
                          letterSpacing: 1.0),
                    ),
                  ),

                const Spacer(),
                const SizedBox(height: 100),
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

  // ✅ JARVIS STYLE GLASS CARD
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
            color: Colors.black.withOpacity(0.85),
            border: const Border(
                top: BorderSide(color: Colors.cyanAccent, width: 2)),
            gradient: LinearGradient(
              colors: [Colors.cyanAccent.withOpacity(0.1), Colors.black],
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
                  const Text("BIOMETRIC ANALYSIS",
                      style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 14,
                          letterSpacing: 3,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold)),
                  const Icon(Icons.monitor_heart_outlined,
                      color: Colors.cyanAccent, size: 20),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDataBox("HEART RATE", _heartRate),
                  _buildDataBox("STRESS", _stressLevel),
                  _buildDataBox("ENERGY", _energyLevel),
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
                          const Text("JARVIS PROTOCOL:",
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontFamily: 'Courier',
                                  letterSpacing: 1.5)),
                          const SizedBox(height: 5),
                          Text(_advice.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
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

  Widget _buildDataBox(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white54, fontSize: 9, fontFamily: 'Courier')),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold)),
      ],
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

// -----------------------------------------------------------
// 3️⃣ ORB WIDGET (No Changes here)
// -----------------------------------------------------------

class Orb extends StatefulWidget {
  final VoidCallback onTap;
  final bool isListening;

  const Orb({
    super.key,
    required this.onTap,
    required this.isListening,
  });

  @override
  State<Orb> createState() => _OrbState();
}

class _OrbState extends State<Orb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double scaleValue =
              1.0 + (_controller.value * (widget.isListening ? 0.15 : 0.08));
          return Transform.scale(
            scale: scaleValue,
            child: Container(
              height: 600,
              width: 600,
              child: Image.asset(
                "assets/orb.gif",
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
