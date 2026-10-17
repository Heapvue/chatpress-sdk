import 'package:flutter/material.dart';
import '../models/widget_config.dart';

/// Visual theme for [ChatpressWidget].
///
/// Create from the API response with [ChatTheme.fromWidgetConfig], or
/// build manually and pass as [ChatpressWidget.themeOverride].
@immutable
class ChatTheme {
  final Color primaryColor;
  final Color backgroundColor;
  final Color userBubbleColor;
  final Color userBubbleTextColor;
  final Color botBubbleColor;
  final Color botBubbleTextColor;
  final Color inputBackgroundColor;
  final Color inputBorderColor;
  final Color inputTextColor;
  final Color inputHintColor;
  final Color headerTextColor;
  final String? fontFamily;
  final double bubbleBorderRadius;
  final EdgeInsets bubblePadding;

  const ChatTheme({
    this.primaryColor = const Color(0xFF6C63FF),
    this.backgroundColor = const Color(0xFFF4F5FB),
    this.userBubbleColor = const Color(0xFF6C63FF),
    this.userBubbleTextColor = Colors.white,
    this.botBubbleColor = Colors.white,
    this.botBubbleTextColor = const Color(0xFF1A1A2E),
    this.inputBackgroundColor = Colors.white,
    this.inputBorderColor = const Color(0xFFE0E0F0),
    this.inputTextColor = const Color(0xFF1A1A2E),
    this.inputHintColor = const Color(0xFFAAAAAA),
    this.headerTextColor = Colors.white,
    this.fontFamily,
    this.bubbleBorderRadius = 18.0,
    this.bubblePadding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  });

  /// Dark variant.
  static const dark = ChatTheme(
    primaryColor: Color(0xFF7C6BFF),
    backgroundColor: Color(0xFF0F0F1A),
    userBubbleColor: Color(0xFF7C6BFF),
    userBubbleTextColor: Colors.white,
    botBubbleColor: Color(0xFF1E1E2E),
    botBubbleTextColor: Color(0xFFE0E0F0),
    inputBackgroundColor: Color(0xFF1E1E2E),
    inputBorderColor: Color(0xFF2E2E4E),
    inputTextColor: Color(0xFFE0E0F0),
    inputHintColor: Color(0xFF666688),
    headerTextColor: Colors.white,
  );

  /// Creates a [ChatTheme] driven by the API [WidgetConfig.theme] map.
  factory ChatTheme.fromWidgetConfig(WidgetConfig config) {
    const defaultPrimary = Color(0xFF6C63FF);
    final primary = config.primaryColor ?? defaultPrimary;
    return ChatTheme(
      primaryColor: primary,
      userBubbleColor: config.userBubbleColor ?? primary,
      botBubbleColor: config.botBubbleColor ?? Colors.white,
      backgroundColor: config.backgroundColor ?? const Color(0xFFF4F5FB),
      fontFamily: config.fontFamily,
    );
  }

  ChatTheme copyWith({
    Color? primaryColor,
    Color? backgroundColor,
    Color? userBubbleColor,
    Color? userBubbleTextColor,
    Color? botBubbleColor,
    Color? botBubbleTextColor,
    Color? inputBackgroundColor,
    Color? inputBorderColor,
    Color? inputTextColor,
    Color? inputHintColor,
    Color? headerTextColor,
    String? fontFamily,
    double? bubbleBorderRadius,
    EdgeInsets? bubblePadding,
  }) {
    return ChatTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      userBubbleColor: userBubbleColor ?? this.userBubbleColor,
      userBubbleTextColor: userBubbleTextColor ?? this.userBubbleTextColor,
      botBubbleColor: botBubbleColor ?? this.botBubbleColor,
      botBubbleTextColor: botBubbleTextColor ?? this.botBubbleTextColor,
      inputBackgroundColor: inputBackgroundColor ?? this.inputBackgroundColor,
      inputBorderColor: inputBorderColor ?? this.inputBorderColor,
      inputTextColor: inputTextColor ?? this.inputTextColor,
      inputHintColor: inputHintColor ?? this.inputHintColor,
      headerTextColor: headerTextColor ?? this.headerTextColor,
      fontFamily: fontFamily ?? this.fontFamily,
      bubbleBorderRadius: bubbleBorderRadius ?? this.bubbleBorderRadius,
      bubblePadding: bubblePadding ?? this.bubblePadding,
    );
  }
}
