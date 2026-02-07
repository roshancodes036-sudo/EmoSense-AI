import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class ApiService {
  // अपनी API Key यहाँ डालें
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';

  final model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _apiKey,
  );

  Future<Map<String, dynamic>> analyzeSentiment(String text) async {
    final prompt = '''
      Analyze the sentiment of the following text: "$text".
      
      You must return the response in STRICT JSON format (do not use markdown code blocks).
      The JSON structure must be:
      {
        "overall": {
          "Happy": <percentage>,
          "Sad": <percentage>,
          "Angry": <percentage>,
          "Neutral": <percentage>
        },
        "timeline": [
          {"text": "<sentence 1>", "emotion": "<emotion>", "time": "Start"},
          {"text": "<sentence 2>", "emotion": "<emotion>", "time": "End"}
        ]
      }
      Ensure the percentages in "overall" sum up to 100.
    ''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      print("Gemini Response: ${response.text}"); // Debugging ke liye

      // Markdown hatana agar Gemini galti se ```json laga de
      String cleanJson = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(cleanJson);
    } catch (e) {
      print("Error analyzing sentiment: $e");
      return {}; // Error aane par khali map bhejein
    }
  }
}