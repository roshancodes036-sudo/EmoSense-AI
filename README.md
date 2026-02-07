# 🧠 EmoSense AI: Real-Time Sentiment Analysis

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0-0175C2?style=for-the-badge&logo=dart)
![Gemini](https://img.shields.io/badge/AI-Gemini%201.5%20Flash-8E75B2?style=for-the-badge&logo=google)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

> **"Transforming Voice into Visual Data instantly."** 🎙️📊

---

## 🚀 Overview

**EmoSense AI** is a cutting-edge mobile application designed to analyze human emotions from voice input in real-time. Built as part of a technical assignment, this app leverages **Google's Gemini 1.5 Flash** model to deconstruct speech patterns and visualize emotional data through dynamic charts.

**Key Differentiator:** This entire project—from architecture to deployment—was coded and built on an **Android Tablet** 📱, demonstrating extreme adaptability and resourcefulness.

---

## ✨ Key Features

* **🎙️ Real-Time Voice Engine:** High-accuracy speech-to-text conversion using `speech_to_text`.
* **🧠 LLM-Powered Analysis:** Integrated **Gemini 1.5 Flash** for ultra-low latency sentiment classification (Happy, Sad, Angry, Neutral).
* **📊 Dynamic Visualization:** Interactive **Pie Charts** & Timeline breakdowns using `fl_chart` to represent emotional shifts.
* **⚡ Optimized Performance:** Clean Architecture ensures the app runs smoothly even on low-end devices.
* **🎨 Glassmorphism UI:** A modern, dark-themed UI inspired by *CodeNetra AI*.

---

## 📱 App Screenshots

| Home Screen (Listening) | Analysis Result (Charts) |
|:---:|:---:|
| <img src="assets/screenshots/home.png" width="250"> | <img src="assets/screenshots/result.png" width="250"> |

*(Note: These screenshots showcase the actual build running on an Android Tablet environment.)*

---

## 🛠️ Tech Stack & Architecture

* **Framework:** Flutter (Dart)
* **AI Model:** Google Gemini 1.5 Flash (via `google_generative_ai`)
* **State Management:** Native `setState` (Optimized for this scope)
* **Visualization:** `fl_chart` library
* **Permissions:** `permission_handler`

### 🔄 The Logic Flow
1.  **Input:** User speaks into the microphone 🎤.
2.  **Processing:** Speech is converted to text locally.
3.  **Analysis:** Text is sent to Gemini API with a custom "JSON-Strict" prompt 🧠.
4.  **Output:** JSON response is parsed to render Pie Charts & Timelines 📊.

---

## 👨‍💻 Developer Note (The "Why")

> *"Why is this submission so fast?"*

I leveraged the core **Voice & AI modules** from my flagship project, **[CodeNetra AI](https://github.com/roshancodes036-sudo/CodeNetra-Flutter-AI)** (built for the visually impaired). By reusing tested, production-grade components, I was able to focus entirely on the new requirements: **Data Visualization and Timeline Logic**.

This project proves my ability to:
1.  Write **Modular Code** that is reusable.
2.  Deliver **High-Quality MVPs** under tight deadlines.
3.  Develop complex apps purely on a **Tablet**.

---

## 🚀 How to Run

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/roshancodes036-sudo/EmoSense-AI.git](https://github.com/roshancodes036-sudo/EmoSense-AI.git)
    ```
2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Setup API Key:**
    * Create a `.env` file or update `api_service.dart` with your Gemini API Key.
4.  **Run the App:**
    ```bash
    flutter run
    ```

---

## 📬 Contact

**Roshan Chaurasiya**
* **Role:** Flutter Developer (Specializing in AI Integrations)
* **Location:** Ghazipur, UP, India
* **Portfolio:** [GitHub Profile](https://github.com/roshancodes036-sudo)

---
*Built with ❤️ and code on an Android Tablet.*