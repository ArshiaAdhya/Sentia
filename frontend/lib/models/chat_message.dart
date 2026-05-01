class ChatMessage {
  final String id;
  String text;
  final bool isUser;
  bool isStreaming;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.isStreaming = false,
  });
}