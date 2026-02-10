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
  late stt.SpeechToText _speech;
  final FlutterTts _tts = FlutterTts();
  final ApiService _apiService = ApiService();

  bool _isListening = false;
  bool _isThinking = false;
  bool _showResultPanel = false;

  String _text = "";
  String _status = "SYSTEM OFFLINE";
  List<String> _consoleLogs = [];

  Map<String, dynamic>? _sentimentData;
  String _advice = "";
  String _heartRate = "--";
  String _stressLevel = "--";
  String _energyLevel = "--";

  late AnimationController _panelController;
  late Animation<Offset> _panelAnimation;
  late AnimationController _textPulseController;
  Timer? _silenceTimer; // ⏱️ NEW: Silence Timer

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

    ApiService.liveLog.stream.listen((log) {
      if (mounted) {
        setState(() {
          _consoleLogs.insert(0, "> $log");
          if (_consoleLogs.length > 20) _consoleLogs.removeLast();
        });
      }
    });

    _initSystem();
  }

  void _initSystem() async {
    await [Permission.microphone, Permission.speech].request();
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);

    if (mounted) setState(() => _status = "SYSTEM ONLINE");
    await Future.delayed(const Duration(milliseconds: 500));
    await _speak("EmoSense AI Online.");
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _tts.speak(text);
      await _tts.awaitSpeakCompletion(true);
    }
  }

  void _handleOrbTap() async {
    if (_isListening || _isThinking) {
      _stopListening(); // Manual Stop
      return;
    }

    if (_showResultPanel) {
      _panelController.reverse();
      setState(() => _showResultPanel = false);
    }

    await _speak("Listening...");
    _startListening();
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onError: (val) => ApiService.liveLog.add("STT Error: $val"),
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          // ⚠️ DO NOT AUTO-STOP HERE immediately
          // Hum manual timer se stop karenge taaki jaldi na kate
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

          // ⏱️ RESET TIMER: Jab tak banda bol raha hai, timer reset karo
          _silenceTimer?.cancel();
          _silenceTimer = Timer(const Duration(seconds: 2), () {
            // Agar 2 second tak kuch nahi bola, tab process karo
            if (_isListening) _stopListening();
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5), // System pause duration
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      );
    }
  }

  void _stopListening() {
    _silenceTimer?.cancel();
    _speech.stop();
    if (mounted && _isListening) {
      setState(() => _isListening = false);
      _processVoice();
    }
  }

  void _processVoice() async {
    if (_text.isEmpty || _text == "Listening..." || _text.length < 3) {
      _speak("I didn't catch that.");
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
      _advice = _getAdvice(mood);

      await _speak("Analysis complete. Mood detected: $mood.");

      if (mounted) {
        setState(() {
          _isThinking = false;
          _status = "COMPLETE";
          _showResultPanel = true;
        });
        _panelController.forward();
      }
    } catch (e) {
      _speak("Connection failed.");
      setState(() {
        _isThinking = false;
        _text = "Error: Check Logs";
      });
    }
  }

  String _getAdvice(String mood) {
    if (mood == "Happy") return "Energy optimal.";
    if (mood == "Sad") return "Rest advised.";
    if (mood == "Angry") return "Deep breathing advised.";
    if (mood == "Fear") return "You are safe.";
    return "Systems normal.";
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
          // 🛠 SYSTEM DEBUG CONSOLE
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      width: double.infinity,
                      color: Colors.cyanAccent.withOpacity(0.1),
                      child: const Text("JARVIS LIVE DEBUG",
                          style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        reverse: false, // Top to bottom
                        padding: const EdgeInsets.all(8),
                        itemCount: _consoleLogs.length,
                        itemBuilder: (context, index) => Text(
                          _consoleLogs[index],
                          style: TextStyle(
                              color: _consoleLogs[index].contains("Error") ||
                                      _consoleLogs[index].contains("Failed")
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                              fontSize: 10,
                              fontFamily: 'Courier'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // MAIN CONTENT
          SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Orb(
                    onTap: _handleOrbTap,
                    isListening: _isListening || _isThinking),
                const SizedBox(height: 30),
                if (!_isListening && !_isThinking)
                  FadeTransition(
                    opacity: _textPulseController,
                    child: const Text("TAP TO START",
                        style: TextStyle(
                            color: Colors.cyanAccent,
                            letterSpacing: 3,
                            fontSize: 16)),
                  ),
                const SizedBox(height: 20),
                if (_text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(_text.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontFamily: 'Courier')),
                  ),
                const Spacer(),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // RESULT PANEL
          SlideTransition(
            position: _panelAnimation,
            child: Align(
                alignment: Alignment.bottomCenter, child: _buildGlassCard()),
          ),
        ],
      ),
    );
  }

  // ... (Baaki glass card code same rahega) ...
  Widget _buildGlassCard() {
    if (_sentimentData == null) return const SizedBox.shrink();
    var overall = _sentimentData!['overall'] as Map<String, dynamic>;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 500,
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              border: const Border(
                  top: BorderSide(color: Colors.cyanAccent, width: 2))),
          child: Column(
            children: [
              const Text("ANALYSIS COMPLETE",
                  style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 16,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _buildDataBox("HEART RATE", _heartRate),
                _buildDataBox("MOOD", _advice),
              ]),
              const SizedBox(height: 20),
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
              ElevatedButton(
                onPressed: () => _panelController.reverse(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.2)),
                child: const Text("CLOSE",
                    style: TextStyle(color: Colors.redAccent)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataBox(String t, String v) => Column(children: [
        Text(t, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        Text(v,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold))
      ]);

  Widget _buildEmotionBar(String label, dynamic value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("$label: $value%",
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
      LinearProgressIndicator(
          value: (value as num) / 100,
          color: Colors.cyanAccent,
          backgroundColor: Colors.white10),
    ]);
  }
}
