import 'dart:convert';

/// Base sealed class for all WebSocket events sent by the Chatpress server.
///
/// Use a `switch` expression to handle each event type exhaustively:
/// ```dart
/// client.events.listen((event) {
///   switch (event) {
///     case StreamEvent(:final content):
///       print('chunk: $content');
///     case CompleteEvent(:final answer):
///       print('done: $answer');
///     default:
///       break;
///   }
/// });
/// ```
sealed class WsEvent {
  const WsEvent();

  /// Parses a raw WebSocket frame (JSON string) into the correct [WsEvent] subtype.
  factory WsEvent.fromRaw(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      return WsEvent.fromJson(json);
    } catch (e) {
      return UnknownEvent(type: 'parse_error', raw: {'raw': raw, 'error': e.toString()});
    }
  }

  factory WsEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'session' => SessionEvent(
          sessionId: json['session_id'] as String? ?? '',
        ),
      'ping' => PingEvent(
          timestamp: (json['timestamp'] as num?)?.toDouble() ?? 0,
        ),
      'stream' => StreamEvent(
          content: json['content'] as String? ?? '',
          done: json['done'] as bool? ?? false,
        ),
      'complete' => CompleteEvent(
          answer: json['answer'] as String? ?? '',
          suggestedQuestion: json['suggested_question'] as String?,
          sessionId: json['session_id'] as String? ?? '',
          done: json['done'] as bool? ?? true,
        ),
      'error' => ErrorEvent(
          error: json['error'] as String? ?? 'Unknown error',
          details: json['details'] as String?,
        ),
      'rate_limit' => RateLimitEvent(
          scope: json['scope'] as String? ?? 'unknown',
          limit: (json['limit'] as num?)?.toInt() ?? 0,
          blocked: json['blocked'] as bool? ?? false,
          error: json['error'] as String? ?? 'Rate limit exceeded',
        ),
      _ => UnknownEvent(type: type ?? 'unknown', raw: json),
    };
  }
}

/// Fired immediately after the WebSocket connection is established.
/// Contains the active [sessionId].
final class SessionEvent extends WsEvent {
  final String sessionId;
  const SessionEvent({required this.sessionId});
}

/// Keep-alive ping from the server (fired ~every 10 seconds).
final class PingEvent extends WsEvent {
  final double timestamp;
  const PingEvent({required this.timestamp});
}

/// A partial LLM response token streamed from the server.
/// Accumulate [content] chunks until [done] is true or [CompleteEvent] arrives.
final class StreamEvent extends WsEvent {
  final String content;
  final bool done;
  const StreamEvent({required this.content, required this.done});
}

/// Fired when the LLM has finished generating the full response.
/// [answer] contains the complete response. [suggestedQuestion] is an optional
/// follow-up prompt you can surface in the UI.
final class CompleteEvent extends WsEvent {
  final String answer;
  final String? suggestedQuestion;
  final String sessionId;
  final bool done;
  const CompleteEvent({
    required this.answer,
    this.suggestedQuestion,
    required this.sessionId,
    required this.done,
  });
}

/// Server-side error event.
final class ErrorEvent extends WsEvent {
  final String error;
  final String? details;
  const ErrorEvent({required this.error, this.details});
}

/// Rate limit enforcement event.
/// If [blocked] is `true`, the user has been temporarily suspended.
final class RateLimitEvent extends WsEvent {
  /// `'ip'` or `'session'`.
  final String scope;
  final int limit;
  final bool blocked;
  final String error;
  const RateLimitEvent({
    required this.scope,
    required this.limit,
    required this.blocked,
    required this.error,
  });
}

/// Fallback for any unrecognized event type.
final class UnknownEvent extends WsEvent {
  final String type;
  final Map<String, dynamic> raw;
  const UnknownEvent({required this.type, required this.raw});
}
