import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../services/chat_service.dart';
import '../services/api_service.dart';

// The text is no longer final, allowing us to safely mutate it during the animation
class ChatMessage {
  String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatController extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isThinking = false;
  bool get isThinking => _isThinking;

  // The UI will attach to this so we can auto-scroll
  final ScrollController scrollController = ScrollController();

  final String _sessionId = const Uuid().v4();

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add user message and show thinking state
    _messages.add(ChatMessage(text: text.trim(), isUser: true));
    _isThinking = true;
    notifyListeners();
    _scrollToBottom();

    try {
      // 2. Authenticate
      final userId = await ApiService.getUserId();

      // 3. Hit the REST API
      final fullReply = await ChatService.sendMessageToSentia(
        rawUserMessage: text,
        userId: userId,
        sessionId: _sessionId,
      );

      // 4. Hide thinking state BEFORE the animation starts
      _isThinking = false;
      notifyListeners();

      // 5. Trigger the animation
      await _animateTypewriterEffect(fullReply);

    } catch (e) {
      _isThinking = false;
      _messages.add(
        ChatMessage(text: "I got my flippers tangled for a second 🐧 Can we try that again?", isUser: false)
      );
      notifyListeners();
      _scrollToBottom();
    }
  }

  Future<void> _animateTypewriterEffect(String fullText) async {
    // Hold a direct reference to the object so index shifting doesn't break it
    final aiMessage = ChatMessage(text: "", isUser: false);
    _messages.add(aiMessage);

    for (int i = 0; i < fullText.length; i++) {
      aiMessage.text = fullText.substring(0, i + 1);
      notifyListeners();
      
      // Auto-scroll slightly as the paragraph expands
      _scrollToBottom();
      
      // 25ms feels like natural, fast typing
      await Future.delayed(const Duration(milliseconds: 25)); 
    }
  }

  void _scrollToBottom() {
    // Only scroll if the UI is actively attached to the controller
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}