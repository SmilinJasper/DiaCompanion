import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/diabot_provider.dart';
import '../widgets/chat_bubble.dart';

/// DiaBot — AI-powered diabetes management chatbot.
class DiaBotPage extends StatefulWidget {
  const DiaBotPage({super.key});

  @override
  State<DiaBotPage> createState() => _DiaBotPageState();
}

class _DiaBotPageState extends State<DiaBotPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    _controller.clear();
    context.read<DiaBotProvider>().sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<DiaBotProvider>();

    // Auto-scroll when new messages arrive
    _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text('DiaBot'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'New conversation',
            onPressed: () => _showResetDialog(context, provider),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Message List ──────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount:
                  provider.messages.length + (provider.isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                // Typing indicator at the bottom
                if (index == provider.messages.length) {
                  return const TypingIndicator();
                }

                final msg = provider.messages[index];
                return ChatBubble(
                  text: msg.text,
                  isUser: msg.isUser,
                  timestamp: msg.timestamp,
                );
              },
            ),
          ),

          // ── API Key Warning ──────────────────────────────────
          if (!provider.isConfigured)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              color: colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: colorScheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No API key — run with --dart-define=GEMINI_API_KEY=<key>',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Powered by Gemini ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Text(
              'Powered by Gemini  ·  Not medical advice',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ),

          // ── Input Bar ────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    maxLines: 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Ask DiaBot anything...',
                      hintStyle: TextStyle(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: provider.isTyping ? null : _send,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: provider.isTyping
                              ? [
                                  colorScheme.outline.withValues(alpha: 0.3),
                                  colorScheme.outline.withValues(alpha: 0.3),
                                ]
                              : [colorScheme.primary, colorScheme.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, DiaBotProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Conversation'),
        content: const Text(
            'This will clear the current chat history. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.resetConversation();
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
