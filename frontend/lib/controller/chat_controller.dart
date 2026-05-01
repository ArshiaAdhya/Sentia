import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatController extends ChangeNotifier {
  // The master list of all messages in the current session
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  // A flag to prevent the user from spamming the send button
  bool _isWaitingForReply = false;
  bool get isWaitingForReply => _isWaitingForReply;

  void sendMessage(String rawText) {
    if (rawText.trim().isEmpty || _isWaitingForReply) return;

    // 1. Add the User's message to the state
    _messages.add(
      ChatMessage(
        id: DateTime.now().toString(),
        text: rawText,
        isUser: true,
      ),
    );
    
    // 2. Add an empty message that we will fill up chunk-by-chunk
    final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    _messages.add(
      ChatMessage(
        id: aiMessageId,
        text: "",
        isUser: false,
        isStreaming: true,
      ),
    );

    _isWaitingForReply = true;
    notifyListeners(); // Tell the UI to draw the new bubbles

    // 3. Open the WebSocket pipeline and listen to the stream
    final aiStream = ChatService.streamMessageToSentia(rawText);

    aiStream.listen(
      (translatedChunk) {
        // Find the AI message we just created and update its text
        final targetMessage = _messages.firstWhere((msg) => msg.id == aiMessageId);
        
        // Because ChatService yields the FULL translated string (not just the chunk),
        // we completely overwrite the text rather than appending it.
        targetMessage.text = translatedChunk;
        
        notifyListeners(); // Tell the UI to re-draw with the new text
      },
      onDone: () {
        // The stream has hit the STOP flag from Gemini
        final targetMessage = _messages.firstWhere((msg) => msg.id == aiMessageId);
        targetMessage.isStreaming = false;
        _isWaitingForReply = false;
        notifyListeners();
      },
      onError: (error) {
        final targetMessage = _messages.firstWhere((msg) => msg.id == aiMessageId);
        targetMessage.text = "I'm having trouble connecting to my network right now.";
        targetMessage.isStreaming = false;
        _isWaitingForReply = false;
        notifyListeners();
      },
    );
  }
}