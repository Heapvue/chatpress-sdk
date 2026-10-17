import 'chat_message.dart';

/// Pagination metadata returned by the chat history endpoints.
class Pagination {
  final int page;
  final int limit;
  final int totalCount;
  final int totalPages;
  final bool hasMore;

  const Pagination({
    required this.page,
    required this.limit,
    required this.totalCount,
    required this.totalPages,
    required this.hasMore,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      totalCount: json['total_count'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'Pagination(page: $page/$totalPages, total: $totalCount, hasMore: $hasMore)';
}

/// Linear chat history from `GET /widget-chat-history`.
class ChatHistory {
  final List<ChatMessage> messages;
  final String? scope;
  final Pagination pagination;

  const ChatHistory({
    required this.messages,
    this.scope,
    required this.pagination,
  });

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    final msgs = (json['messages'] as List<dynamic>?)
            ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];
    return ChatHistory(
      messages: msgs,
      scope: json['scope'] as String?,
      pagination: Pagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

/// A single historic conversation group from the grouped history endpoint.
class ChatSession {
  final List<ChatMessage> messages;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const ChatSession({
    required this.messages,
    this.startedAt,
    this.endedAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.tryParse(json['ended_at'] as String)
          : null,
    );
  }
}

/// Grouped history from `GET /widget-chat-history-grouped`.
class GroupedChatHistory {
  final List<ChatSession> sessions;

  const GroupedChatHistory({required this.sessions});

  factory GroupedChatHistory.fromJson(Map<String, dynamic> json) {
    return GroupedChatHistory(
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((s) => ChatSession.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
