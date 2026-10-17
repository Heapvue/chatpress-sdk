import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/chat_message.dart';
import 'chat_theme.dart';
import 'typing_indicator.dart';

/// A single chat message bubble — renders user messages as plain text and
/// assistant messages as Markdown.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final ChatTheme theme;

  /// When true a bot avatar icon is shown to the left of the bubble.
  final bool showAvatar;

  const ChatBubble({
    super.key,
    required this.message,
    required this.theme,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser && showAvatar) ...[
            _BotAvatar(theme: theme),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _BubbleBody(message: message, theme: theme),
                const SizedBox(height: 3),
                _Timestamp(message: message),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BubbleBody extends StatelessWidget {
  final ChatMessage message;
  final ChatTheme theme;

  const _BubbleBody({required this.message, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bgColor = isUser ? theme.userBubbleColor : theme.botBubbleColor;
    final textColor =
        isUser ? theme.userBubbleTextColor : theme.botBubbleTextColor;

    final radius = theme.bubbleBorderRadius;
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
      bottomLeft: Radius.circular(isUser ? radius : 4),
      bottomRight: Radius.circular(isUser ? 4 : radius),
    );

    Widget child;
    if (message.isStreaming && message.content.isEmpty) {
      // Show animated dots while waiting for first token
      child = TypingIndicator(color: textColor.withValues(alpha: 0.7));
    } else if (isUser) {
      child = Text(
        message.content,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontFamily: theme.fontFamily,
          height: 1.45,
        ),
      );
    } else {
      child = MarkdownBody(
        data: message.content,
        shrinkWrap: true,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            color: textColor,
            fontSize: 15,
            fontFamily: theme.fontFamily,
            height: 1.45,
          ),
          h1: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: theme.fontFamily,
          ),
          h2: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: theme.fontFamily,
          ),
          h3: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: theme.fontFamily,
          ),
          strong: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontFamily: theme.fontFamily,
          ),
          em: TextStyle(
            color: textColor,
            fontStyle: FontStyle.italic,
            fontFamily: theme.fontFamily,
          ),
          code: TextStyle(
            color: theme.primaryColor,
            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
            fontFamily: 'monospace',
            fontSize: 13,
          ),
          codeblockDecoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: theme.primaryColor, width: 3),
            ),
          ),
          listBullet: TextStyle(color: textColor, fontFamily: theme.fontFamily),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.76,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isUser ? 0.12 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: theme.bubblePadding,
      child: child,
    );
  }
}

class _BotAvatar extends StatelessWidget {
  final ChatTheme theme;
  const _BotAvatar({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.smart_toy_outlined, size: 17, color: Colors.white),
    );
  }
}

class _Timestamp extends StatelessWidget {
  final ChatMessage message;
  const _Timestamp({required this.message});

  @override
  Widget build(BuildContext context) {
    final h = message.createdAt.hour.toString().padLeft(2, '0');
    final m = message.createdAt.minute.toString().padLeft(2, '0');
    return Text(
      '$h:$m',
      style: const TextStyle(fontSize: 10.5, color: Color(0xFFAAAAAA)),
    );
  }
}
