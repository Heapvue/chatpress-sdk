# Changelog

All notable changes to the `chatpress` package will be documented in this file.

## 1.0.1

- Updated license to MIT.
- Updated repository, issue tracker, and homepage URLs in `pubspec.yaml`.
- Upgraded dependencies (`flutter_lints`, `flutter_markdown`, `http`, etc.).

## 1.0.0

Initial public release.

### Added
- `ChatpressClient` — headless REST + WebSocket client
  - `getWidgetConfig()` — fetch public chatbot config (no auth required)
  - `getAuthToken()` — fetch short-lived WebSocket auth token
  - `getChatHistory()` — paginated linear chat history
  - `getGroupedChatHistory()` — session-grouped chat history
  - `trackProductClick()` — analytics event tracking
  - `connect()` / `sendMessage()` / `disconnect()` — real-time WebSocket
- `ChatpressConfig` — SDK configuration (API key, chatbot ID, base URL, origin, preview mode)
- `SessionService` — auto-generates and persists `browser-id`; resumes last `session-id`
- `WebSocketService` — manages the `wss://` connection with a typed `Stream<WsEvent>`
- Typed WebSocket events: `SessionEvent`, `PingEvent`, `StreamEvent`, `CompleteEvent`, `ErrorEvent`, `RateLimitEvent`
- `ChatpressWidget` — drop-in chat UI (full-screen page or inline)
- `ChatpressController` — `ChangeNotifier` controller powering the widget
- `ChatTheme` — API-driven or manual visual theming; includes dark variant
- `ChatpressLauncher` — static helpers `openPage()` and `openSheet()`
- `ChatpressFab` — floating action button pre-wired to open the chat
- Full Markdown rendering in assistant messages via `flutter_markdown`
- Animated streaming text (tokens appear as they arrive)
- Suggested follow-up questions rendered as tappable chips
- Animated three-dot typing indicator
- Slide-in animation for each message bubble
- Retry / error UI with re-connect support
