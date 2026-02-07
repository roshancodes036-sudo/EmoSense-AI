import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Chart banane ke liye

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> sentimentData; // Gemini se aya hua JSON
  final String userText; // User ne jo bola tha

  const ResultScreen({
    super.key,
    required this.sentimentData,
    required this.userText,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Data Safely Nikalein (Taki app crash na ho)
    final overall = sentimentData['overall'] ?? {};
    final timeline = sentimentData['timeline'] as List? ?? [];

    // Helper function percentages lene ke liye
    double getVal(String key) => (overall[key] ?? 0).toDouble();

    return Scaffold(
      backgroundColor: Colors.black, // Dark Theme Professional Look
      appBar: AppBar(
        title: const Text("Emotional Analysis 📊", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            const Text(
              "Overall Vibe Check",
              style: TextStyle(
                color: Colors.cyanAccent, 
                fontSize: 22, 
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 10),
            
            // --- SECTION 1: PIE CHART (The Visual) ---
            SizedBox(
              height: 250,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 4, // Sections ke beech gap
                      centerSpaceRadius: 50, // Beech mein khali jagah (Donut Chart)
                      sections: [
                        _buildSection("Happy", getVal("Happy"), Colors.greenAccent),
                        _buildSection("Sad", getVal("Sad"), Colors.blueAccent),
                        _buildSection("Angry", getVal("Angry"), Colors.redAccent),
                        _buildSection("Neutral", getVal("Neutral"), Colors.grey),
                      ],
                    ),
                  ),
                  // Beech mein Text dikhane ke liye
                  const Center(
                     child: Text("Mood", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            
            // Legend (Rang ka matlab)
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LegendItem(color: Colors.greenAccent, text: "Happy 😊"),
                _LegendItem(color: Colors.blueAccent, text: "Sad 😢"),
                _LegendItem(color: Colors.redAccent, text: "Angry 😡"),
              ],
            ),
            
            const Divider(color: Colors.grey, height: 40),

            // --- SECTION 2: TIMELINE BREAKDOWN (HR Requirement) ---
            const Text(
              "Timeline Breakdown 📝",
              style: TextStyle(
                color: Colors.cyanAccent, 
                fontSize: 22, 
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 10),
            
            // List of Sentences
            if (timeline.isEmpty)
              const Text("No detailed timeline available.", style: TextStyle(color: Colors.grey))
            else
              ...timeline.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      // Emotion Emoji
                      Text(
                        _getEmoji(item['emotion']),
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 15),
                      // Sentence Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['text'] ?? "",
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Detected: ${item['emotion']}",
                              style: TextStyle(color: _getColor(item['emotion']), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- HELPER FUNCTIONS ---

  // Chart ka ek tukda banane ke liye
  PieChartSectionData _buildSection(String title, double value, Color color) {
    return PieChartSectionData(
      color: color,
      value: value,
      title: value > 0 ? '${value.toInt()}%' : '', // 0% hai to mat dikhao
      radius: 60,
      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      badgeWidget: value > 0 ? _getIcon(title) : null,
      badgePositionPercentageOffset: 1.3,
    );
  }

  // Emotion ke hisab se Icon
  Widget _getIcon(String title) {
    IconData icon;
    switch (title) {
      case 'Happy': icon = Icons.sentiment_very_satisfied; break;
      case 'Sad': icon = Icons.sentiment_very_dissatisfied; break;
      case 'Angry': icon = Icons.warning_amber_rounded; break;
      default: icon = Icons.sentiment_neutral;
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Icon(icon, size: 16, color: Colors.black),
    );
  }

  // Emoji helper
  String _getEmoji(String? emotion) {
    switch (emotion?.toLowerCase()) {
      case 'happy': return '😊';
      case 'sad': return '😢';
      case 'angry': return '😡';
      case 'neutral': return '😐';
      default: return '🤖';
    }
  }

  // Color helper
  Color _getColor(String? emotion) {
    switch (emotion?.toLowerCase()) {
      case 'happy': return Colors.greenAccent;
      case 'sad': return Colors.blueAccent;
      case 'angry': return Colors.redAccent;
      default: return Colors.grey;
    }
  }
}

// Legend Widget (Chhota sa box aur text)
class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}