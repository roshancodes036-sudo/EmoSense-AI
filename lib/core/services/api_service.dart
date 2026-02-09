import 'dart:convert';
import 'dart:developer'; // For debugging logs
import 'package:google_generative_ai/google_generative_ai.dart';

class ApiService {
  // ⚠️ REPLACE THIS WITH YOUR REAL API KEY
  static const String _apiKey = "AIzaSyAuzRQ6eHmrI2lsefcl2nMeKlAAGNFcGwM";

  final GenerativeModel _model;

  ApiService()
      : _model = GenerativeModel(
          // ✅ Using 'gemini-1.5-pro' as it is the most capable model currently available.
          // It handles complex prompts better than 'gemini-pro'.
          model: 'gemini-1.5-pro',
          apiKey: _apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.5, // Balanced creativity and accuracy
          ),
        );

  Future<Map<String, dynamic>> analyzeSentiment(String text) async {
    try {
      log("Sending to Gemini 1.5 Pro: $text");

      // 🔥 STRONG PROMPT: Forces Gemini to detect specific emotions
      final prompt = '''
      You are an Emotion Analysis AI. Analyze this user statement: "$text"

      Your Rules:
      1. Classify the user's emotion into ONE of these: Happy, Sad, Angry, Fear, Neutral.
      2. Be highly sensitive to keywords:
         - "happy", "good", "great", "excited" -> HAPPY
         - "stressed", "scared", "worried", "anxious", "panic" -> FEAR
         - "sad", "depressed", "tired", "burnout", "exhausted" -> SAD
         - "angry", "mad", "frustrated", "annoyed", "hate" -> ANGRY
      3. Return ONLY a valid JSON object. Do not use Markdown or code blocks.

      Required JSON Format:
      {
        "overall": {
          "Happy": 0,
          "Sad": 0,
          "Angry": 0,
          "Fear": 0,
          "Neutral": 0
        }
      }
      (Ensure the dominant emotion is set to 100 or a high percentage).
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      String? responseText = response.text;

      if (responseText == null) {
        throw Exception("Gemini returned empty response.");
      }

      // 🧹 CLEANUP: Remove markdown formatting if Gemini adds it
      responseText =
          responseText.replaceAll('```json', '').replaceAll('```', '').trim();

      log("Gemini Response: $responseText");

      return jsonDecode(responseText);
    } catch (e) {
      log("API Error: $e");

      // ⚠️ Fallback: If API fails (e.g., no internet), return Neutral to prevent app crash.
      return {
        'overall': {'Happy': 0, 'Neutral': 100, 'Sad': 0, 'Angry': 0, 'Fear': 0}
      };
    }
  }
}
