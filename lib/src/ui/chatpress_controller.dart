import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../client/chatpress_client.dart';
import '../client/chatpress_config.dart';
import '../models/chat_message.dart';
import '../models/widget_config.dart';
import '../models/ws_event.dart';
import 'chat_theme.dart';

const _uuid = Uuid();

/// Connection / lifecycle state of [ChatpressController].
enum ChatpressState {
  /// Not yet initialised.
  idle,

  /// Fetching config and establishing the WebSocket.
  connecting,

  /// WebSocket is open and ready.
  connected,

  /// A fatal error occurred (check [errorMessage]).
  error,

  /// The WebSocket was closed after a successful connection.
  disconnected,
}

/// ChangeNotifier-based controller that drives [ChatpressWidget].
///
/// You rarely need to use this directly — [ChatpressWidget] creates and manages
/// it internally. However you can instantiate it yourself if you want to build
/// a fully custom UI:
///
/// ```dart
/// final controller = ChatpressController(config: myConfig);
/// await controller.initialize();
/// // controller.messages, controller.theme, etc. are now populated.
/// ```
class ChatpressController extends ChangeNotifier {
  final ChatpressConfig config;

  ChatpressClient? _client;
  StreamSubscription<WsEvent>? _eventsSub;

  ChatpressState _state = ChatpressState.idle;
  String? _errorMessage;
  WidgetConfig? _widgetConfig;
  ChatTheme _theme = const ChatTheme();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String? _suggestedQuestion;
  String? _streamingId; // ID of the current streaming assistant message

  // ── Getters ───────────────────────────────────────────────────────────────

  ChatpressState get state => _state;
  String? get errorMessage => _errorMessage;
  WidgetConfig? get widgetConfig => _widgetConfig;
  ChatTheme get theme => _theme;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  String? get suggestedQuestion => _suggestedQuestion;
  bool get isConnected => _state == ChatpressState.connected;

  /// True while connecting or waiting for an assistant reply.
  bool get isBusy =>
      _isTyping || _state == ChatpressState.connecting;

  String get agentName => _widgetConfig?.agentName ?? 'Assistant';

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  ChatpressController({required this.config});

  /// Initialises the client, fetches config, loads history, and connects WS.
  Future<void> initialize() async {
    if (_state == ChatpressState.connecting ||
        _state == ChatpressState.connected) {
      return;
    }

    _setState(ChatpressState.connecting);
    _errorMessage = null;

    try {
      _client = await ChatpressClient.initialize(config);

      // 1. Fetch public widget config (themes, agent name, welcome message)
      _widgetConfig = await _client!.getWidgetConfig();
      _theme = ChatTheme.fromWidgetConfig(_widgetConfig!);
      notifyListeners();

      // 2. Load chat history (best-effort)
      try {
        final history = await _client!.getChatHistory(limit: 50);
        if (history.messages.isNotEmpty) {
          _messages.insertAll(0, history.messages);
          notifyListeners();
        }
      } catch (_) {
        // History is optional; silently ignore errors
      }

      // 3. Connect WebSocket
      await _client!.connect();
      _eventsSub = _client!.events.listen(
        _handleEvent,
        onError: (Object e) => _setError('WebSocket error: $e'),
      );

      _setState(ChatpressState.connected);

      // 4. Insert welcome message if history is empty
      if (_messages.isEmpty) {
        final welcome = _widgetConfig?.welcomeMessage;
        if (welcome != null && welcome.isNotEmpty) {
          _addMessage(ChatMessage(
            id: _uuid.v4(),
            role: 'assistant',
            content: welcome,
            createdAt: DateTime.now(),
          ));
        }
      }
    } on ChatpressException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Sends a user message and adds it optimistically to [messages].
  void sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !isConnected || _isTyping) return;

    // Add user message immediately
    _addMessage(ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      content: trimmed,
      createdAt: DateTime.now(),
    ));

    _suggestedQuestion = null;

    // Placeholder for the streaming assistant reply
    _streamingId = _uuid.v4();
    _isTyping = true;
    _addMessage(ChatMessage(
      id: _streamingId!,
      role: 'assistant',
      content: '',
      createdAt: DateTime.now(),
      isStreaming: true,
    ));

    _client!.sendMessage(trimmed);
  }

  /// Clears the session and starts a fresh conversation.
  Future<void> clearSession() async {
    _removeStreamingMessage();
    _messages.clear();
    _isTyping = false;
    _suggestedQuestion = null;
    notifyListeners();

    await _client?.clearSession();
    await _client?.disconnect();

    _setState(ChatpressState.connecting);
    try {
      await _client!.connect();
      _eventsSub?.cancel();
      _eventsSub = _client!.events.listen(
        _handleEvent,
        onError: (Object e) => _setError('WebSocket error: $e'),
      );
      _setState(ChatpressState.connected);

      final welcome = _widgetConfig?.welcomeMessage;
      if (welcome != null && welcome.isNotEmpty) {
        _addMessage(ChatMessage(
          id: _uuid.v4(),
          role: 'assistant',
          content: welcome,
          createdAt: DateTime.now(),
        ));
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Clears [errorMessage] and retries [initialize].
  Future<void> retry() async {
    _errorMessage = null;
    _state = ChatpressState.idle;
    await initialize();
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _client?.dispose();
    super.dispose();
  }

  // ── Event handling ────────────────────────────────────────────────────────

  void _handleEvent(WsEvent event) {
    switch (event) {
      case SessionEvent():
        // Session ID is persisted by the client automatically
        break;

      case PingEvent():
        // Keep-alive — no UI update required
        break;

      case StreamEvent(:final content, :final done):
        if (_streamingId == null) break;
        _appendToStreaming(content);
        if (done) _finalizeStreaming(null);

      case CompleteEvent(:final answer, :final suggestedQuestion):
        _finalizeStreaming(answer);
        _suggestedQuestion = suggestedQuestion?.isNotEmpty == true
            ? suggestedQuestion
            : null;
        notifyListeners();

      case ErrorEvent(:final error):
        _removeStreamingMessage();
        _isTyping = false;
        _errorMessage = error;
        notifyListeners();

      case RateLimitEvent(:final blocked, :final error):
        _removeStreamingMessage();
        _isTyping = false;
        if (blocked) {
          _setError(error);
        } else {
          _errorMessage = error;
          notifyListeners();
        }

      case UnknownEvent():
        break;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _appendToStreaming(String chunk) {
    final idx = _indexOfStreaming();
    if (idx == -1) return;
    _messages[idx] = _messages[idx].copyWith(
      content: _messages[idx].content + chunk,
      isStreaming: true,
    );
    notifyListeners();
  }

  void _finalizeStreaming(String? fullAnswer) {
    final idx = _indexOfStreaming();
    if (idx != -1) {
      final content = (fullAnswer != null && fullAnswer.isNotEmpty)
          ? fullAnswer
          : _messages[idx].content;
      _messages[idx] =
          _messages[idx].copyWith(content: content, isStreaming: false);
    }
    _isTyping = false;
    _streamingId = null;
    notifyListeners();
  }

  void _removeStreamingMessage() {
    _messages.removeWhere((m) => m.id == _streamingId);
    _streamingId = null;
  }

  int _indexOfStreaming() =>
      _messages.indexWhere((m) => m.id == _streamingId);

  void _addMessage(ChatMessage msg) {
    _messages.add(msg);
    notifyListeners();
  }

  void _setState(ChatpressState s) {
    _state = s;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _setState(ChatpressState.error);
  }
}
