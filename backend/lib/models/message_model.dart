/// Represents a single chat message between the user and Pip.
class MessageModel {

  const MessageModel({
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        sessionId: json['session_id'] as String? ?? '',
        role: json['role'] as String? ?? 'user',
        content: json['content'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now().toUtc(),
      );
  final String sessionId;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'role': role,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  String toString() => 'MessageModel(role: $role, content: $content)';
}