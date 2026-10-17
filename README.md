# chatpress

[![license: Proprietary](https://img.shields.io/badge/license-Proprietary-red.svg)](#)
[![access: Private SDK](https://img.shields.io/badge/access-Commercial-purple.svg)](#)
[![platform: iOS & Android](https://img.shields.io/badge/platform-iOS%20%7C%20Android-blue.svg)](#)

Official private Flutter SDK for integrating **Chatpress AI chatbots** into mobile apps.

- 🤖 Drop-in `ChatpressWidget` — zero boilerplate, full-featured chat UI
- 🔌 Headless `ChatpressClient` — build your own UI with the same power
- 🎨 API-driven theming — colors & fonts flow from your Chatpress dashboard
- ⚡️ Real-time streaming — tokens stream as the LLM generates them
- 💾 Session persistence — conversations resume across app restarts automatically

---

## Installation

Because this is a private commercial SDK, clients can integrate it using any of the following methods after obtaining access:

### Option 1: Via Private Git Repository (Recommended)

Add the Git repository to your app's `pubspec.yaml` (using SSH or HTTPS access token):

```yaml
dependencies:
  chatpress:
    git:
      url: git@github.com:chatpress/chatpress-flutter-sdk.git
      ref: v1.0.0 # or main / specific tag
```

### Option 2: Via Local Path / Vendored Package

If you distribute the SDK folder directly to authorized clients:

```yaml
dependencies:
  chatpress:
    path: ./packages/chatpress-sdk
```

### Option 3: Via Private / Hosted Pub Server

If you run a private package repository (e.g. Unpub, Cloudsmith, AWS CodeArtifact):

```yaml
dependencies:
  chatpress:
    hosted:
      name: chatpress
      url: https://pub.yourcompany.com
    version: ^1.0.0
```

Then run:

```sh
flutter pub get
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
