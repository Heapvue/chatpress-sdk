/// Auth token response from `GET /widget-auth`.
///
/// Use [authToken] in the WebSocket query params to authenticate the chat
/// connection without exposing your raw API key on the wire.
class AuthToken {
  final String sessionId;
  final String chatbotId;

  /// Lifetime of this token in seconds (typically 36 000 = 10 hours).
  final int expiresIn;

  /// The short-lived token to pass as `widget-auth-token` on the WebSocket.
  final String authToken;

  /// Unix timestamp (seconds) when this token expires.
  final double authExpiresAt;

  const AuthToken({
    required this.sessionId,
    required this.chatbotId,
    required this.expiresIn,
    required this.authToken,
    required this.authExpiresAt,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      sessionId: json['session_id'] as String,
      chatbotId: json['chatbot_id'] as String,
      expiresIn: json['expires_in'] as int? ?? 36000,
      authToken: json['auth_token'] as String,
      authExpiresAt: (json['auth_expires_at'] as num).toDouble(),
    );
  }

  /// `true` if the auth token has already expired.
  bool get isExpired {
    final expiryMs = (authExpiresAt * 1000).toInt();
    return DateTime.now().millisecondsSinceEpoch >= expiryMs;
  }

  /// Expiry [DateTime] of this token.
  DateTime get expiresAt =>
      DateTime.fromMillisecondsSinceEpoch((authExpiresAt * 1000).toInt());
}
