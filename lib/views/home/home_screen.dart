import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

// ✅ Services Import
import '../../core/services/api_service.dart';
// ✅ Widget Import
import '../../widgets/orb_widget.dart';

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

  // ⏱️ SMART SILENCE TIMER
  Timer? _silenceTimer;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _panelAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _panelController, curve: Curves.fastLinearToSlowEaseIn));

    _textPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initSystem();
  }

  void _initSystem() async {
    await [Permission.microphone, Permission.speech].request();

    // ⚡ FASTER SPEECH SETTINGS
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.6); // Thoda tez bolega

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

    await _speak("I am listening...");
    _startListening();
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onError: (val) => print('Error: $val'),
      onStatus: (val) {},
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

          // ⚡ SUPER FAST LOGIC:
          if (_silenceTimer?.isActive ?? false) _silenceTimer!.cancel();

          // 🔴 CHANGE: 1500ms se ghatakar 800ms kar दिया (Fast Response)
          _silenceTimer = Timer(const Duration(milliseconds: 800), () {
            if (_isListening && _text.length > 2) {
              _stopListening();
            }
          });
        },
        pauseFor: const Duration(seconds: 5),
        listenFor: const Duration(seconds: 60),
        cancelOnError: false,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      );
    }
  }

  void _stopListening() {
    _silenceTimer?.cancel();
    _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
      _processVoice();
    }
  }

  void _processVoice() async {
    if (_text.isEmpty || _text == "Listening..." || _text.length < 2) {
      _speak("Audio not captured.");
      setState(() => _status = "STANDBY");
      return;
    }

    setState(() {
      _isThinking = true;
      _status = "ANALYZING...";
    });

    try {
      final data = await _apiService.analyzeSentiment(_text);
      _sentimentData = data;
      Map<String, dynamic> overall = data['overall'];
      String mood = "Neutral";
      num maxVal = 0;

      overall.forEach((key, value) {
        if (value > maxVal) {
          maxVal = value;
          mood = key;
        }
      });

      _generateJarvisData(mood);

      String action = "";
      if (mood == "Happy")
        action = "Energy levels optimal.";
      else if (mood == "Sad")
        action = "Rest advised.";
      else if (mood == "Angry")
        action = "Deep breathing advised.";
      else if (mood == "Fear")
        action = "You are safe.";
      else
        action = "Systems normal.";

      setState(() => _advice = action);

      // ⚡ SHORT RESPONSE (Taaki jaldi bole)
      await _speak("You are $mood. $action");

      if (mounted) {
        setState(() {
          _isThinking = false;
          _status = "COMPLETE";
          _showResultPanel = true;
        });
        _panelController.forward();
      }
    } catch (e) {
      _speak("Connection error.");
      if (mounted) setState(() => _isThinking = false);
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
    _silenceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ✅ LAYER 1: SCROLLABLE CONTENT (Orb + Text)
          Positioned.fill(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100),

                    // ORB WIDGET
                    SizedBox(
                      height: 250,
                      width: 250,
                      child: Orb(
                        onTap: _handleOrbTap,
                        isListening: _isListening || _isThinking,
                      ),
                    ),

                    const SizedBox(height: 40),

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

                    if (_text.isNotEmpty && _text != "Tap to Orb")
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

                    const SizedBox(height: 150),
                  ],
                ),
              ),
            ),
          ),

          // ✅ LAYER 2: PINNED STATUS BAR
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
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
                  color: Colors.black.withOpacity(0.5),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                      color:
                          _isListening ? Colors.redAccent : Colors.cyanAccent,
                      fontFamily: 'Courier',
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // ✅ LAYER 3: RESULT PANEL
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
            color: Colors.black.withOpacity(0.85),
            border: const Border(
                top: BorderSide(color: Colors.cyanAccent, width: 2)),
            gradient: LinearGradient(
                colors: [Colors.cyanAccent.withOpacity(0.1), Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
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
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("BIOMETRIC ANALYSIS",
                    style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 14,
                        letterSpacing: 3,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold)),
                const Icon(Icons.monitor_heart_outlined,
                    color: Colors.cyanAccent, size: 20),
              ]),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _buildDataBox("HEART RATE", _heartRate),
                _buildDataBox("STRESS", _stressLevel),
                _buildDataBox("ENERGY", _energyLevel),
              ]),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.cyanAccent.withOpacity(0.05)),
                child: Row(children: [
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
                      ])),
                ]),
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
                  children: overall.entries
                      .map((e) => _buildEmotionBar(e.key, e.value))
                      .toList(),
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
                        borderRadius: BorderRadius.circular(20)),
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

  Widget _buildDataBox(String t, String v) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t,
            style: const TextStyle(
                color: Colors.white54, fontSize: 9, fontFamily: 'Courier')),
        const SizedBox(height: 4),
        Text(v,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold))
      ]);

  Widget _buildEmotionBar(String l, dynamic v) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white70, fontSize: 10, fontFamily: 'Courier')),
          Text("$v%",
              style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 10,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold))
        ]),
        const SizedBox(height: 5),
        LinearProgressIndicator(
            value: (v as num) / 100,
            backgroundColor: Colors.white10,
            color: v > 50 ? Colors.cyanAccent : Colors.purpleAccent,
            minHeight: 2)
      ]);
}
