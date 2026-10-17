/// Represents a single message in a Chatpress conversation.
class ChatMessage {
  /// Unique identifier. Auto-generated if the API response omits it.
  final String id;

  /// `'user'` or `'assistant'`.
  final String role;

  /// Message content (may be partial/empty while [isStreaming] is true).
  final String content;

  final DateTime createdAt;

  /// `true` while the assistant is still streaming this message token-by-token.
  final bool isStreaming;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isStreaming = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  String toString() =>
      'ChatMessage(role: $role, content: ${content.length > 50 ? '${content.substring(0, 50)}…' : content})';
}
