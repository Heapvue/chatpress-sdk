# chatpress

[![pub.dev](https://img.shields.io/pub/v/chatpress.svg)](https://pub.dev/packages/chatpress)
[![license: Commercial](https://img.shields.io/badge/license-Commercial-blue.svg)](#license)
[![platform: iOS & Android](https://img.shields.io/badge/platform-iOS%20%7C%20Android-blue.svg)](#)

Official Flutter SDK for integrating **Chatpress AI chatbots** into mobile apps.

> ℹ️ **Commercial Service SDK**: This package is published for easy integration by Chatpress customers. Access to the backend requires a valid API key and an active subscription from [chatpress.io](https://chatpress.io).

- 🤖 Drop-in `ChatpressWidget` — zero boilerplate, full-featured chat UI
- 🔌 Headless `ChatpressClient` — build your own UI with the same power
- 🎨 API-driven theming — colors & fonts flow from your Chatpress dashboard
- ⚡️ Real-time streaming — tokens stream as the LLM generates them
- 💾 Session persistence — conversations resume across app restarts automatically

---

## Installation

Add `chatpress` to your app's `pubspec.yaml`:

```yaml
dependencies:
  chatpress: ^1.0.0
```

Or install via terminal:

```sh
flutter pub add chatpress
```

---

## Quick Start

### 1. Open as a full-screen chat page

```dart
import 'package:chatpress/chatpress.dart';

final config = ChatpressConfig(
  apiKey: 'cp_YOUR_API_KEY',       // from Chatpress dashboard
  chatbotId: 'YOUR_CHATBOT_UUID',  // from Chatpress dashboard
  // previewMode: true,            // ← enable only during local development
);

// Anywhere in your widget tree:
ChatpressLauncher.openPage(context, config);
```

### 2. Open as a bottom sheet

```dart
ChatpressLauncher.openSheet(context, config);
```

### 3. Add a floating action button

```dart
Scaffold(
  floatingActionButton: ChatpressFab(config: config),
  body: ...,
)
```

### 4. Embed inline

```dart
ChatpressWidget(
  config: config,
  mode: ChatpressDisplayMode.inline,
)
```

---

## Configuration

| Parameter | Type | Default | Description |
|---|---|---|---|
| `apiKey` | `String` | required | Your `cp_...` API key |
| `chatbotId` | `String` | required | UUID of your chatbot |
| `baseUrl` | `String` | `https://rag.heapvue.com` | API base URL |
| `origin` | `String` | `https://chatpress.app` | Origin header value — must be whitelisted in your dashboard |
| `previewMode` | `bool` | `false` | Bypasses origin checks. **Development only.** |

### Production: whitelist your app's origin

The Chatpress backend validates the `Origin` header on every request. For production builds:

1. Go to your **Chatpress Dashboard → Chatbot Settings → Allowed Origins**.
2. Add a custom origin that represents your app (e.g. `https://myapp.com`).
3. Pass it as `origin` in `ChatpressConfig`.

```dart
ChatpressConfig(
  apiKey: 'cp_...',
  chatbotId: '...',
  origin: 'https://myapp.com', // whitelisted in dashboard
)
```

---

## Theming

By default, the widget reads colors from your Chatpress dashboard theme. You can also override it:

```dart
ChatpressWidget(
  config: config,
  themeOverride: ChatTheme(
    primaryColor: Color(0xFF6C63FF),
    backgroundColor: Color(0xFFF4F5FB),
    userBubbleColor: Color(0xFF6C63FF),
    botBubbleColor: Colors.white,
    fontFamily: 'Inter',
  ),
)
```

Use the built-in dark theme:

```dart
themeOverride: ChatTheme.dark,
```

---

## Headless Client

Use `ChatpressClient` directly when you want full control over the UI:

```dart
// 1. Initialise
final client = await ChatpressClient.initialize(config);

// 2. Fetch public widget config
final widgetConfig = await client.getWidgetConfig();

// 3. Connect WebSocket (fetches auth token automatically)
await client.connect();

// 4. Listen to events
client.events.listen((event) {
  switch (event) {
    case StreamEvent(:final content):
      print('chunk: $content');
    case CompleteEvent(:final answer, :final suggestedQuestion):
      print('answer: $answer');
    case ErrorEvent(:final error):
      print('error: $error');
    default:
      break;
  }
});

// 5. Send a message
client.sendMessage('What is your return policy?');

// 6. Load history
final history = await client.getChatHistory(page: 1, limit: 20);

// 7. Dispose when done
await client.dispose();
```

---

## WebSocket Events

| Event | Fields | Description |
|---|---|---|
| `SessionEvent` | `sessionId` | Fired on connect; provides the active session ID |
| `PingEvent` | `timestamp` | Keep-alive (~every 10 s) |
| `StreamEvent` | `content`, `done` | Partial LLM token |
| `CompleteEvent` | `answer`, `suggestedQuestion`, `sessionId` | Full response ready |
| `ErrorEvent` | `error`, `details` | Server-side error |
| `RateLimitEvent` | `scope`, `limit`, `blocked`, `error` | Rate limit hit |

---

## Analytics

Track product / link clicks inside the chat:

```dart
await client.trackProductClick(
  actionType: 'click',
  productId: 'prod_123',
  queryText: 'blue sneakers',
  position: 1,
);
```

---

## Session Management

Sessions are automatically persisted and resumed across app restarts. To start a fresh conversation:

```dart
await client.clearSession();
await client.connect(); // will start a new session
```

---

## Requirements

- **Flutter** ≥ 3.10.0
- **Dart** ≥ 3.0.0
- **Platforms**: iOS, Android

---

## License

Commercial / Proprietary © Chatpress. All rights reserved. Access and use require a valid API key and commercial agreement.
