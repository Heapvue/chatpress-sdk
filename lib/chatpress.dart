/// Chatpress Flutter SDK
///
/// Integrate the Chatpress AI chatbot into your Flutter mobile app with a
/// single widget or use the headless client for full control.
///
/// ## Quick start
/// ```dart
/// import 'package:chatpress/chatpress.dart';
///
/// // Drop-in widget
/// ChatpressWidget(
///   config: ChatpressConfig(
///     apiKey: 'cp_YOUR_API_KEY',
///     chatbotId: 'YOUR_CHATBOT_UUID',
///   ),
/// )
/// ```
library;

// Config & Client
export 'src/client/chatpress_config.dart';
export 'src/client/chatpress_client.dart';

// Models
export 'src/models/widget_config.dart';
export 'src/models/auth_token.dart';
export 'src/models/chat_message.dart';
export 'src/models/chat_history.dart';
export 'src/models/ws_event.dart';

// Services
export 'src/services/session_service.dart';
export 'src/services/websocket_service.dart';

// UI
export 'src/ui/chat_theme.dart';
export 'src/ui/chatpress_controller.dart';
export 'src/ui/chatpress_widget.dart';
