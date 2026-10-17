/// Configuration for the Chatpress SDK.
///
/// Pass an instance of this to [ChatpressClient.initialize] or [ChatpressWidget].
class ChatpressConfig {
  /// Your Chatpress API key (format: `cp_...`).
  final String apiKey;

  /// The UUID of the chatbot to connect to.
  final String chatbotId;

  /// Base URL of the Chatpress backend.
  ///
  /// Defaults to `https://rag.heapvue.com`.
  final String baseUrl;

  /// The `Origin` header value sent with every request.
  ///
  /// For production, this must match a domain/origin you have whitelisted in
  /// your Chatpress dashboard. For development, set [previewMode] to `true`
  /// to bypass this check entirely.
  ///
  /// Defaults to `'https://chatpress.app'`.
  final String origin;

  /// When `true`, sends the `x-widget-studio-preview: 1` header which bypasses
  /// all domain/origin restriction checks on the server.
  ///
  /// **Use only during development/testing — never ship with this enabled.**
  final bool previewMode;

  const ChatpressConfig({
    required this.apiKey,
    required this.chatbotId,
    this.baseUrl = 'https://rag.heapvue.com',
    this.origin = 'https://chatpress.app',
    this.previewMode = false,
  });

  /// HTTP headers common to all authenticated REST requests.
  Map<String, String> get defaultHeaders => {
        'x-api-key': apiKey,
        'Origin': origin,
        'Content-Type': 'application/json',
        if (previewMode) 'x-widget-studio-preview': '1',
      };

  /// HTTP headers for unauthenticated requests (no API key).
  Map<String, String> get publicHeaders => {
        'Origin': origin,
        if (previewMode) 'x-widget-studio-preview': '1',
      };

  /// Constructs the WebSocket [Uri] for the `/ws/chat` endpoint.
  Uri wsUri({
    required String browserId,
    String? sessionId,
    String? authToken,
  }) {
    final parsed = Uri.parse(baseUrl);
    final wsScheme = parsed.scheme == 'https' ? 'wss' : 'ws';
    return Uri(
      scheme: wsScheme,
      host: parsed.host,
      port: parsed.hasPort ? parsed.port : null,
      path: '/ws/chat',
      queryParameters: {
        'chatbot-id': chatbotId,
        'browser-id': browserId,
        if (sessionId != null) 'session-id': sessionId,
        if (authToken != null) 'widget-auth-token': authToken,
      },
    );
  }
}
