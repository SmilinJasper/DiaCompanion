import 'package:flutter/foundation.dart';

import '../../../core/services/chatbot_service.dart';

/// Manages DiaBot chat state.
class DiaBotProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  /// Whether the Gemini API is available.
  bool get isConfigured => ChatbotService.isConfigured;

  DiaBotProvider() {
    // Add a welcome message from DiaBot
    _messages.add(ChatMessage(
      text: 'Hi there! 👋 I\'m **DiaBot**, your diabetes management assistant. '
          'I can help with:\n\n'
          '• 📊 Interpreting glucose trends\n'
          '• 🥗 Meal planning & carb counting\n'
          '• 💊 Understanding medications\n'
          '• 💪 Exercise & lifestyle tips\n\n'
          'How can I help you today?\n\n'
          '⚕️ *This is informational only — please consult your healthcare '
          'provider for personalised medical advice.*',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  /// Send a user message and stream DiaBot's response.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    _messages.add(ChatMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    // Start streaming bot response
    _isTyping = true;
    notifyListeners();

    final botMessage = ChatMessage(
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(botMessage);

    try {
      final stream = ChatbotService.sendMessageStream(text.trim());
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        buffer.write(chunk);
        botMessage.text = buffer.toString();
        notifyListeners();
      }
    } catch (e) {
      botMessage.text = 'I\'m sorry, I encountered an error: $e\n\n'
          'Please try again in a moment.';
      notifyListeners();
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  /// Clear conversation history and reset the Gemini chat session.
  void resetConversation() {
    _messages.clear();
    ChatbotService.resetChat();

    // Re-add the welcome message
    _messages.add(ChatMessage(
      text: 'Conversation cleared! 🔄 How can I help you today?\n\n'
          '⚕️ *This is informational only — please consult your healthcare '
          'provider for personalised medical advice.*',
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
}

/// A single chat message.
class ChatMessage {
  String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
