import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_token.dart';
import '../models/chat_history.dart';
import '../models/widget_config.dart';
import '../models/ws_event.dart';
import '../services/session_service.dart';
import '../services/websocket_service.dart';
import 'chatpress_config.dart';

/// Thrown when a Chatpress REST API call returns a non-2xx response.
class ChatpressException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const ChatpressException(this.message, {this.code, this.statusCode});

  @override
  String toString() =>
      'ChatpressException(HTTP $statusCode, code: $code): $message';
}

/// The primary entry point of the Chatpress SDK.
///
/// Combines REST API calls and a real-time WebSocket connection into a single,
/// easy-to-use interface.
///
/// ## Lifecycle
/// 1. [initialize] — sets up session management (async, safe to call on app start)
/// 2. [connect] — fetches an auth token and opens the WebSocket
/// 3. [sendMessage] — sends a user turn
/// 4. [events] — listen to the stream of [WsEvent]s
/// 5. [dispose] — call when the chat screen is closed
///
/// ## Example
/// ```dart
/// final client = await ChatpressClient.initialize(
///   ChatpressConfig(apiKey: 'cp_…', chatbotId: 'uuid'),
/// );
/// await client.connect();
/// client.sendMessage('Hello!');
/// client.events.listen((event) { … });
/// ```
class ChatpressClient {
  /// The [ChatpressConfig] this client was created with.
  final ChatpressConfig config;

  final SessionService _session;
  final WebSocketService _ws;

  WidgetConfig? _widgetConfig;
  AuthToken? _authToken;

  ChatpressClient._({
    required this.config,
    required SessionService session,
    required WebSocketService ws,
  })  : _session = session,
        _ws = ws;

  // ── Factory ───────────────────────────────────────────────────────────────

  /// Creates and initialises a [ChatpressClient].
  ///
  /// This sets up persistent session management but does **not** open the
  /// WebSocket. Call [connect] separately (or use [ChatpressWidget] which
  /// handles everything automatically).
  static Future<ChatpressClient> initialize(ChatpressConfig config) async {
    final session = await SessionService.create(config.chatbotId);
    return ChatpressClient._(
      config: config,
      session: session,
      ws: WebSocketService(),
    );
  }

  // ── Accessors ─────────────────────────────────────────────────────────────

  /// The stable device identifier managed by [SessionService].
  String get browserId => _session.browserId;

  /// The current session ID (from the last [getAuthToken] call), or `null`.
  String? get sessionId => _session.sessionId;

  /// The cached [WidgetConfig] from the last [getWidgetConfig] call.
  WidgetConfig? get widgetConfig => _widgetConfig;

  /// The cached [AuthToken] from the last [getAuthToken] call.
  AuthToken? get authToken => _authToken;

  /// Whether the underlying WebSocket is currently open.
  bool get isConnected => _ws.isConnected;

  /// Broadcast stream of [WsEvent]s from the server.
  Stream<WsEvent> get events => _ws.events;

  // ── REST ──────────────────────────────────────────────────────────────────

  /// Fetches the public widget config. **No API key required.**
  ///
  /// Caches the result in [widgetConfig].
  Future<WidgetConfig> getWidgetConfig() async {
    final uri = _buildUri('/widget-config', {
      'chatbot-id': config.chatbotId,
    });
    final res = await http.get(uri, headers: config.publicHeaders);
    _assertOk(res);
    _widgetConfig =
        WidgetConfig.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    return _widgetConfig!;
  }

  /// Fetches a short-lived auth token for WebSocket authentication.
  ///
  /// Automatically uses the stored [sessionId] to resume the last conversation.
  /// Saves the returned [sessionId] to persistent storage.
  Future<AuthToken> getAuthToken({String? sessionId}) async {
    final sid = sessionId ?? _session.sessionId;
    final uri = _buildUri('/widget-auth', {
      'chatbot-id': config.chatbotId,
      'browser-id': _session.browserId,
      if (sid != null) 'session-id': sid,
    });
    final res = await http.get(uri, headers: config.defaultHeaders);
    _assertOk(res);
    _authToken =
        AuthToken.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    await _session.saveSessionId(_authToken!.sessionId);
    return _authToken!;
  }

  /// Retrieves paginated linear chat history.
  ///
  /// [page] starts at 1. [limit] is capped at 100 by the server.
  Future<ChatHistory> getChatHistory({
    int page = 1,
    int limit = 20,
    String? sessionId,
  }) async {
    final sid = sessionId ?? _session.sessionId;
    final uri = _buildUri('/widget-chat-history', {
      'chatbot-id': config.chatbotId,
      'browser-id': _session.browserId,
      if (sid != null) 'session-id': sid,
      'page': page.toString(),
      'limit': limit.toString(),
      if (_authToken != null) 'widget-auth-token': _authToken!.authToken,
    });
    final res = await http.get(uri, headers: config.defaultHeaders);
    _assertOk(res);
    return ChatHistory.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Retrieves grouped (per-session) chat history.
  Future<GroupedChatHistory> getGroupedChatHistory({String? sessionId}) async {
    final sid = sessionId ?? _session.sessionId;
    final uri = _buildUri('/widget-chat-history-grouped', {
      'chatbot-id': config.chatbotId,
      'browser-id': _session.browserId,
      if (sid != null) 'session-id': sid,
      if (_authToken != null) 'widget-auth-token': _authToken!.authToken,
    });
    final res = await http.get(uri, headers: config.defaultHeaders);
    _assertOk(res);
    return GroupedChatHistory.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Tracks a product/link click event for analytics.
  ///
  /// Call this when a user taps on a product recommendation inside the chat.
  Future<void> trackProductClick({
    required String actionType,
    String? productId,
    String? queryText,
    int? position,
    bool converted = false,
  }) async {
    final sid = _session.sessionId;
    final uri = _buildUri('/widget-product-click', {
      'chatbot-id': config.chatbotId,
      if (_authToken != null) 'widget-auth-token': _authToken!.authToken,
    });
    final res = await http.post(
      uri,
      headers: config.defaultHeaders,
      body: jsonEncode({
        'browser_id': _session.browserId,
        if (sid != null) 'session_id': sid,
        if (productId != null) 'product_id': productId,
        'action_type': actionType,
        'converted': converted,
        if (queryText != null) 'query_text': queryText,
        if (position != null) 'position': position,
      }),
    );
    _assertOk(res);
  }

  // ── WebSocket ─────────────────────────────────────────────────────────────

  /// Authenticates and opens the WebSocket chat connection.
  ///
  /// Fetches a fresh auth token, then connects to `/ws/chat`.
  /// If the token is still valid and [forceRefresh] is false, the cached
  /// token is reused.
  Future<void> connect({bool forceRefresh = false}) async {
    if (_authToken == null || _authToken!.isExpired || forceRefresh) {
      await getAuthToken();
    }
    final wsUri = config.wsUri(
      browserId: _session.browserId,
      sessionId: _authToken!.sessionId,
      authToken: _authToken!.authToken,
    );
    await _ws.connect(wsUri, headers: {
      'Origin': config.origin,
      if (config.previewMode) 'x-widget-studio-preview': '1',
    });
  }

  /// Sends a user message. The WebSocket must be open (call [connect] first).
  ///
  /// [input] is truncated to 4 000 characters automatically.
  void sendMessage(String input, {String? fingerprintHash}) {
    _ws.sendMessage(input, fingerprintHash: fingerprintHash);
  }

  /// Closes the WebSocket connection.
  Future<void> disconnect() => _ws.disconnect();

  /// Clears the stored session. The next [connect] call will start a new conversation.
  Future<void> clearSession() => _session.clearSession();

  /// Disposes all resources. **Must** be called when the client is no longer needed.
  Future<void> dispose() => _ws.dispose();

  // ── Internal ──────────────────────────────────────────────────────────────

  Uri _buildUri(String path, Map<String, String?> queryParameters) {
    final base = Uri.parse(config.baseUrl);
    final filtered = Map<String, String>.fromEntries(
      queryParameters.entries
          .where((e) => e.value != null)
          .map((e) => MapEntry(e.key, e.value!)),
    );
    return base.replace(path: path, queryParameters: filtered);
  }

  void _assertOk(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}
    throw ChatpressException(
      body['error'] as String? ?? 'Request failed (HTTP ${response.statusCode})',
      code: body['code'] as String?,
      statusCode: response.statusCode,
    );
  }
}
