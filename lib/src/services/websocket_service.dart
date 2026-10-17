import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/ws_event.dart';

/// Manages the WebSocket connection to the Chatpress `/ws/chat` endpoint.
///
/// Exposes a broadcast [events] stream of typed [WsEvent]s.
class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  final StreamController<WsEvent> _controller =
      StreamController<WsEvent>.broadcast();

  bool _isConnected = false;

  /// Broadcast stream of typed [WsEvent]s from the server.
  Stream<WsEvent> get events => _controller.stream;

  /// Whether the WebSocket channel is currently open.
  bool get isConnected => _isConnected;

  // ── Connection ────────────────────────────────────────────────────────────

  /// Opens a WebSocket connection to [uri].
  ///
  /// Any previously open connection is cleanly closed first.
  /// [headers] are sent during the HTTP upgrade handshake (e.g. `Origin`).
  Future<void> connect(Uri uri, {Map<String, dynamic>? headers}) async {
    await disconnect();

    _channel = IOWebSocketChannel.connect(
      uri,
      headers: headers ?? {},
    );

    _isConnected = true;

    _subscription = _channel!.stream.listen(
      (raw) {
        if (!_controller.isClosed) {
          _controller.add(WsEvent.fromRaw(raw));
        }
      },
      onError: (Object error, StackTrace stack) {
        _isConnected = false;
        if (!_controller.isClosed) {
          _controller.addError(error, stack);
        }
      },
      onDone: () {
        _isConnected = false;
      },
    );
  }

  // ── Messaging ─────────────────────────────────────────────────────────────

  /// Sends a user message over the open WebSocket.
  ///
  /// [input] must be ≤ 4 000 characters.
  /// [fingerprintHash] is an optional device fingerprint string.
  ///
  /// Throws [StateError] if the socket is not connected.
  void sendMessage(String input, {String? fingerprintHash}) {
    if (!_isConnected || _channel == null) {
      throw StateError(
        'WebSocket is not connected. Call connect() before sendMessage().',
      );
    }

    final trimmed = input.length > 4000 ? input.substring(0, 4000) : input;
    final payload = jsonEncode({
      'input': trimmed,
      'fingerprint': {
        'hash': fingerprintHash,
        'fingerprintChanged': false,
        'previousHash': null,
      },
    });
    _channel!.sink.add(payload);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Closes the WebSocket connection gracefully.
  Future<void> disconnect() async {
    _isConnected = false;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  /// Disposes this service entirely. Do not call any other methods after this.
  Future<void> dispose() async {
    await disconnect();
    await _controller.close();
  }
}
