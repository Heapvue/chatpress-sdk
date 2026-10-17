import 'package:flutter_test/flutter_test.dart';
import 'package:chatpress/chatpress.dart';

void main() {
  group('ChatpressConfig Tests', () {
    test('Constructs wsUri correctly', () {
      const config = ChatpressConfig(
        apiKey: 'cp_test_key',
        chatbotId: 'test-bot-123',
        baseUrl: 'https://rag.heapvue.com',
      );

      final uri = config.wsUri(
        browserId: 'browser-456',
        sessionId: 'session-789',
        authToken: 'token-abc',
      );

      expect(uri.scheme, 'wss');
      expect(uri.host, 'rag.heapvue.com');
      expect(uri.path, '/ws/chat');
      expect(uri.queryParameters['chatbot-id'], 'test-bot-123');
      expect(uri.queryParameters['browser-id'], 'browser-456');
      expect(uri.queryParameters['session-id'], 'session-789');
      expect(uri.queryParameters['widget-auth-token'], 'token-abc');
    });

    test('Default headers contain required fields', () {
      const config = ChatpressConfig(
        apiKey: 'cp_test_key',
        chatbotId: 'test-bot-123',
        origin: 'https://myapp.com',
        previewMode: true,
      );

      final headers = config.defaultHeaders;
      expect(headers['x-api-key'], 'cp_test_key');
      expect(headers['Origin'], 'https://myapp.com');
      expect(headers['x-widget-studio-preview'], '1');
    });
  });

  group('Model Serialization Tests', () {
    test('AuthToken parses correctly', () {
      final json = {
        'session_id': 'sess-1',
        'chatbot_id': 'bot-1',
        'expires_in': 36000,
        'auth_token': 'auth-xyz',
        'auth_expires_at': 1700000000.0,
      };

      final token = AuthToken.fromJson(json);
      expect(token.sessionId, 'sess-1');
      expect(token.chatbotId, 'bot-1');
      expect(token.authToken, 'auth-xyz');
      expect(token.authExpiresAt, 1700000000.0);
    });

    test('WsEvent parses all event types', () {
      final streamEv = WsEvent.fromJson({'type': 'stream', 'content': 'Hello', 'done': false});
      expect(streamEv, isA<StreamEvent>());
      expect((streamEv as StreamEvent).content, 'Hello');

      final completeEv = WsEvent.fromJson({
        'type': 'complete',
        'answer': 'Full response',
        'suggested_question': 'What next?',
        'session_id': 'sess-1',
        'done': true,
      });
      expect(completeEv, isA<CompleteEvent>());
      expect((completeEv as CompleteEvent).answer, 'Full response');
      expect(completeEv.suggestedQuestion, 'What next?');

      final sessionEv = WsEvent.fromJson({'type': 'session', 'session_id': 'sess-1'});
      expect(sessionEv, isA<SessionEvent>());

      final rateLimitEv = WsEvent.fromJson({
        'type': 'rate_limit',
        'scope': 'ip',
        'limit': 100,
        'blocked': true,
        'error': 'Too many requests',
      });
      expect(rateLimitEv, isA<RateLimitEvent>());
      expect((rateLimitEv as RateLimitEvent).blocked, isTrue);
    });

    test('ChatMessage copyWith works as expected', () {
      final msg = ChatMessage(
        id: 'msg-1',
        role: 'assistant',
        content: 'Hi',
        createdAt: DateTime.now(),
        isStreaming: true,
      );

      final updated = msg.copyWith(content: 'Hi there', isStreaming: false);
      expect(updated.id, 'msg-1');
      expect(updated.role, 'assistant');
      expect(updated.content, 'Hi there');
      expect(updated.isStreaming, isFalse);
    });
  });
}
