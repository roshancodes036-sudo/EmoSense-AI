# 🧠 EmoSense AI — Intelligent Voice Sentiment Assistant

![EmoSense Banner](https://via.placeholder.com/1200x500.png?text=EmoSense+AI+Preview+Here)

> **"Your Voice, Your Emotions, Our Intelligence."**

[![Powered by Gemini](https://img.shields.io/badge/Powered%20by-Gemini%201.5%20Flash-4285F4?style=for-the-badge&logo=google)](https://deepmind.google/technologies/gemini/)
[![Built with Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Language-Dart-0175C2?style=for-the-badge&logo=dart)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](./LICENSE)

---

## 🚀 What is EmoSense AI?

**EmoSense AI** is a next-generation mood detection application that bridges the gap between human speech and artificial emotional intelligence. 

Unlike traditional text-based sentiment tools, EmoSense listens to your **voice**, processes the audio in real-time, and uses **Google's Gemini 1.5 Flash** model to generate a comprehensive diagnostic report of your emotional state (Happy, Sad, Angry, Fear, etc.). All of this is presented in a stunning **Glassmorphism UI** inspired by futuristic interfaces.

---

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| **🎙️ Voice-First Interface** | Seamless speech-to-text conversion for natural interaction. |
| **🧠 Advanced AI Core** | Powered by **Gemini 1.5 Flash** for deep semantic & emotional analysis. |
| **🎨 Glassmorphism UI** | A visually striking, futuristic interface with dynamic animations. |
| **📊 Real-Time Diagnostics** | Visual breakdown of emotions (e.g., *Happy: 80%, Neutral: 20%*). |
| **🔒 Privacy-First Architecture** | API keys and core logic are isolated from the codebase for maximum security. |

---
📂 Professional Project Structure
We follow a clean, scalable architecture separating UI (Views) from Logic (Core).

lib/
├── core/                # 🔒 (Git-Ignored) Business Logic & Services
│   └── services/
│       └── api_service.dart  <-- The Brain (You create this)
├── views/               # 🎨 UI Layer
│   ├── home/            # Main Voice Interface & Glass Panel
│   ├── splash/          # Cinematic Intro
│   └── ...
├── widgets/             # Reusable UI Components
└── main.dart            # Application Entry Point

🛠️ Tech Stack
Framework: Flutter (Dart)

AI Model: Google Gemini 1.5 Flash

Speech Recognition: speech_to_text

Text-to-Speech: flutter_tts

State Management: setState (Optimized for performance)

👨‍💻 Developed By
Roshan Passionate Flutter Developer & AI Innovator

## 🛠️ Installation & Setup Guide (Critical)

> ⚠️ **Security Notice for Recruiters & Developers:** > To adhere to strict security best practices, the `lib/core/` directory (containing the API Key configuration) has been **git-ignored** and is NOT included in this repository. 
>
> **Please follow the steps below to reconstruct the environment and run the app.**

### 1️⃣ Clone the Repository
```bash
git clone [https://github.com/roshancodes036-sudo/EmoSense-AI.git](https://github.com/roshancodes036-sudo/EmoSense-AI.git)
cd EmoSense-AI

2️⃣ Install Dependencies
flutter pub get

3️⃣ 🔐 Restore the Secret API Core
Since the core service is hidden, you must create it manually to connect to the AI.

Step A: Navigate to lib/ and create this folder structure:
lib/core/services/

Step B: Inside that folder, create a file named api_service.dart.

Step C: Paste the following code into that file. (You will need a free API Key from Google AI Studio)

import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class ApiService {
  // 🔑 TODO: REPLACE THIS WITH YOUR GEMINI API KEY
  static const String _apiKey = "PASTE_YOUR_GEMINI_API_KEY_HERE";

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
        resultText = resultText.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(resultText);
      } else {
        throw Exception("Empty response from AI");
      }
    } catch (e) {
      return {
        "overall": {"Happy": 0, "Sad": 0, "Angry": 0, "Neutral": 100},
        "details": "Error analyzing sentiment."
      };
    }
  }
}

4️⃣ Run the Application
flutter run

