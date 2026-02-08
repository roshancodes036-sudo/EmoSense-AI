import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class ApiService {
  // Yahan apani API Key Dalein
  static const String _apiKey = "AIzaSy..."; // Apni Real Key yahan daalein

  late final GenerativeModel _model;

  ApiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<Map<String, dynamic>> analyzeSentiment(String text) async {
    final prompt = '''
      Analyze the sentiment of the following text: "$text".
      Return the result strictly as a JSON object with this format:
      {
        "overall": {"Happy": 0, "Sad": 0, "Angry": 0, "Neutral": 0, "Fear": 0, "Surprise": 0},
        "details": "A one-line summary of why."
      }
      Do not include ```json or any markdown formatting. Just the raw JSON.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      String? resultText = response.text;

      if (resultText != null) {
        // Cleaning the response just in case
        resultText =
            resultText.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(resultText);
      } else {
        throw Exception("Empty response from AI");
      }
    } catch (e) {
      print("Error: $e");
      // Fallback agar error aaye
      return {
        "overall": {
          "Happy": 0,
          "Sad": 0,
          "Angry": 0,
          "Neutral": 100,
          "Fear": 0,
          "Surprise": 0
        },
        "details": "Error analyzing sentiment."
      };
    }
  }
}
