import 'package:flutter/material.dart';

/// Public chatbot configuration returned by `GET /widget-config`.
///
/// No API key is required to fetch this — it is safe for public initialization.
class WidgetConfig {
  final String chatbotId;
  final String agentName;
  final String? welcomeMessage;
  final String? avatarUrl;

  /// Raw theme map from the API. Use the typed color helpers below.
  final Map<String, dynamic>? theme;

  /// Complete raw JSON from the API for any fields not explicitly typed.
  final Map<String, dynamic> raw;

  const WidgetConfig({
    required this.chatbotId,
    required this.agentName,
    this.welcomeMessage,
    this.avatarUrl,
    this.theme,
    this.raw = const {},
  });

  factory WidgetConfig.fromJson(Map<String, dynamic> json) {
    return WidgetConfig(
      chatbotId: json['chatbot_id'] as String? ?? '',
      agentName: json['agent_name'] as String? ?? 'Assistant',
      welcomeMessage: json['welcome_message'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      theme: json['theme'] as Map<String, dynamic>?,
      raw: json,
    );
  }

  /// Parses a hex color string (e.g. `#3a86ff` or `3a86ff`) to a [Color].
  static Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final h = hex.replaceAll('#', '');
    if (h.length == 6) {
      return Color(int.parse('FF$h', radix: 16));
    }
    if (h.length == 8) {
      return Color(int.parse(h, radix: 16));
    }
    return null;
  }

  Color? get primaryColor =>
      _parseHex(theme?['primary_color'] as String? ?? theme?['primaryColor'] as String?);
  Color? get userBubbleColor =>
      _parseHex(theme?['user_bubble_color'] as String? ?? theme?['userBubbleColor'] as String?);
  Color? get botBubbleColor =>
      _parseHex(theme?['bot_bubble_color'] as String? ?? theme?['botBubbleColor'] as String?);
  Color? get backgroundColor =>
      _parseHex(theme?['background_color'] as String? ?? theme?['backgroundColor'] as String?);
  String? get fontFamily =>
      theme?['font_family'] as String? ?? theme?['fontFamily'] as String?;
}
