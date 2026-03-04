import 'package:google_generative_ai/google_generative_ai.dart';

/// Service managing the Gemini-powered DiaBot chat.
///
/// Reads the API key from compile-time `--dart-define=GEMINI_API_KEY=...`.
class ChatbotService {
  ChatbotService._();

  static const String _apiKeyEnv = String.fromEnvironment('GEMINI_API_KEY');

  static GenerativeModel? _model;
  static ChatSession? _chat;

  /// The medical-grade system prompt for DiaBot.
  static const String systemPrompt = '''
You are **DiaBot**, the friendly and knowledgeable AI health assistant inside the **DiaCompanion** app. Your purpose is to help people living with diabetes (Type 1 and Type 2) manage their condition more confidently.

── ROLE & TONE ──────────────────────────────────────────
• Be warm, empathetic, and encouraging — never judgmental.
• Use clear, simple language. Avoid excessive medical jargon unless the user asks for detail.
• If the user expresses frustration or fear, acknowledge their feelings before providing information.

── SCOPE — WHAT YOU HELP WITH ──────────────────────────
1. **Glucose Trend Interpretation** — Explain what rising, falling, or stable glucose patterns might mean. Discuss time-in-range concepts, dawn phenomenon, and post-meal spikes.
2. **Meal Planning & Nutrition** — Suggest balanced meals aligned with ADA (American Diabetes Association) guidelines: emphasize whole grains, lean protein, non-starchy vegetables, healthy fats, and portion control. Discuss carb counting basics.
3. **Physical Activity** — Explain how exercise affects blood sugar, the difference between aerobic and resistance training, and how to plan around workouts.
4. **Medication Awareness** — Provide general information about common diabetes medications (metformin, insulin types, SGLT2 inhibitors, GLP-1 agonists) but NEVER recommend specific doses or changes.
5. **Lifestyle & Wellbeing** — Sleep, stress management, hydration, and their impact on glycemic control.
6. **Understanding Lab Results** — Explain HbA1c, fasting glucose, post-prandial targets, and lipid panels in patient-friendly terms.

── CLINICAL GUIDELINES ─────────────────────────────────
Align your advice with current evidence-based standards:
• ADA Standards of Care 2024/2025
• General targets: fasting glucose 80‑130 mg/dL, post-meal <180 mg/dL, HbA1c <7% for most adults (individualise)
• Time-in-range target: >70% between 70‑180 mg/dL
• Hypoglycemia: <70 mg/dL (Level 1), <54 mg/dL (Level 2 — clinically significant)
• Hyperglycemia: sustained >250 mg/dL warrants medical attention

── SAFETY RULES (NEVER VIOLATE) ────────────────────────
1. **Always include a disclaimer**: End every response with:
   "⚕️ *This is informational only — please consult your healthcare provider for personalised medical advice.*"
2. **Never diagnose** — Do not tell users they have or do not have a condition.
3. **Never prescribe or adjust medication** — Do not recommend starting, stopping, or changing any medication dose.
4. **Emergency referral** — If the user describes symptoms of DKA (diabetic ketoacidosis), severe hypoglycemia, chest pain, or any emergency, instruct them to **call emergency services or go to the nearest ER immediately**.
5. **No guarantees** — Never say advice will definitely improve outcomes. Use phrases like "may help", "evidence suggests", "many people find".
6. **Privacy** — Do not ask for personal health records, full name, or identifying data.

── FORMATTING ──────────────────────────────────────────
• Use short paragraphs and bullet points for readability.
• Bold key terms when helpful.
• Keep responses concise (aim for 150‑250 words unless the user asks for detail).
• Use emoji sparingly for warmth (🩸 💪 🥗 😊) but keep a professional tone.
''';

  /// Whether the API key is configured.
  static bool get isConfigured => _apiKeyEnv.isNotEmpty;

  /// Initialise the Gemini model and start a fresh chat session.
  static void init() {
    if (!isConfigured) return;

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKeyEnv,
      systemInstruction: Content.system(systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topP: 0.9,
        maxOutputTokens: 1024,
      ),
    );

    _chat = _model!.startChat();
  }

  /// Send a user message and receive a streamed response.
  ///
  /// Throws if not [isConfigured].
  static Stream<String> sendMessageStream(String message) async* {
    if (!isConfigured) {
      yield 'DiaBot is not configured. Please provide a Gemini API key '
          'using `--dart-define=GEMINI_API_KEY=<your_key>` when running the app.';
      return;
    }

    if (_chat == null) init();

    final response = _chat!.sendMessageStream(Content.text(message));
    await for (final chunk in response) {
      final text = chunk.text;
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }

  /// Send a message and get the complete response at once.
  static Future<String> sendMessage(String message) async {
    if (!isConfigured) {
      return 'DiaBot is not configured. Please provide a Gemini API key '
          'using `--dart-define=GEMINI_API_KEY=<your_key>` when running the app.';
    }

    if (_chat == null) init();

    final response = await _chat!.sendMessage(Content.text(message));
    return response.text ?? 'I apologise — I could not generate a response. Please try again.';
  }

  /// Reset the conversation history.
  static void resetChat() {
    if (_model != null) {
      _chat = _model!.startChat();
    }
  }
}
