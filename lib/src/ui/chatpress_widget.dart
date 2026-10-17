import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../client/chatpress_config.dart';
import 'chat_bubble.dart';
import 'chat_theme.dart';
import 'chatpress_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public surface
// ─────────────────────────────────────────────────────────────────────────────

/// How [ChatpressWidget] is rendered.
enum ChatpressDisplayMode {
  /// Fills a [Scaffold] body — use inside [MaterialPageRoute] or push it.
  page,

  /// Renders as an inline widget with no [Scaffold] wrapping.
  /// Ideal for embedding inside a bottom sheet or a container.
  inline,
}

/// A ready-to-use AI chat widget powered by the Chatpress platform.
///
/// ### Full-screen page
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => ChatpressWidget(
///     config: ChatpressConfig(
///       apiKey: 'cp_YOUR_KEY',
///       chatbotId: 'YOUR_UUID',
///       previewMode: true, // remove in production
///     ),
///   ),
/// ));
/// ```
///
/// ### Bottom sheet
/// ```dart
/// ChatpressLauncher.openSheet(context, config);
/// ```
///
/// ### Inline inside any widget tree
/// ```dart
/// ChatpressWidget(
///   config: config,
///   mode: ChatpressDisplayMode.inline,
/// )
/// ```
class ChatpressWidget extends StatefulWidget {
  final ChatpressConfig config;

  /// Override the API-driven theme. Leave null to use theme from [WidgetConfig].
  final ChatTheme? themeOverride;

  final ChatpressDisplayMode mode;

  const ChatpressWidget({
    super.key,
    required this.config,
    this.themeOverride,
    this.mode = ChatpressDisplayMode.page,
  });

  @override
  State<ChatpressWidget> createState() => _ChatpressWidgetState();
}

class _ChatpressWidgetState extends State<ChatpressWidget>
    with TickerProviderStateMixin {
  late final ChatpressController _ctrl;
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  // Send button press animation
  late final AnimationController _sendAnim;
  late final Animation<double> _sendScale;

  @override
  void initState() {
    super.initState();

    _sendAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _sendScale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _sendAnim, curve: Curves.easeOut),
    );

    _ctrl = ChatpressController(config: widget.config);
    _ctrl.addListener(_onUpdate);
    _ctrl.initialize();
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onUpdate);
    _ctrl.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    _sendAnim.dispose();
    super.dispose();
  }

  void _onSend() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || !_ctrl.isConnected || _ctrl.isBusy) return;
    HapticFeedback.lightImpact();
    _ctrl.sendMessage(text);
    _textCtrl.clear();
    _sendAnim.forward().then((_) => _sendAnim.reverse());
  }

  ChatTheme get _theme => widget.themeOverride ?? _ctrl.theme;

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    final content = _buildContent(theme);

    if (widget.mode == ChatpressDisplayMode.page) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: theme.backgroundColor,
          resizeToAvoidBottomInset: true,
          body: content,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: content,
    );
  }

  Widget _buildContent(ChatTheme theme) {
    return Column(
      children: [
        _Header(ctrl: _ctrl, theme: theme,
            showBack: widget.mode == ChatpressDisplayMode.page),
        Expanded(child: _buildBody(theme)),
        _SuggestedQuestion(ctrl: _ctrl, theme: theme, onTap: _onSend,
            textCtrl: _textCtrl),
        _InputBar(
          textCtrl: _textCtrl,
          focusNode: _inputFocus,
          ctrl: _ctrl,
          theme: theme,
          sendScale: _sendScale,
          onSend: _onSend,
        ),
      ],
    );
  }

  Widget _buildBody(ChatTheme theme) {
    return switch (_ctrl.state) {
      ChatpressState.idle || ChatpressState.connecting =>
        _LoadingView(theme: theme),
      ChatpressState.error => _ErrorView(
          theme: theme,
          message: _ctrl.errorMessage ?? 'Connection failed.',
          onRetry: _ctrl.retry,
        ),
      ChatpressState.connected || ChatpressState.disconnected =>
        _MessageList(ctrl: _ctrl, scrollCtrl: _scrollCtrl, theme: theme),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final ChatpressController ctrl;
  final ChatTheme theme;
  final bool showBack;

  const _Header({required this.ctrl, required this.theme, required this.showBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            Color.lerp(theme.primaryColor, Colors.indigo.shade900, 0.35)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: showBack ? 4 : 16,
            right: 8,
            top: 10,
            bottom: 14,
          ),
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ctrl.agentName,
                      style: TextStyle(
                        color: theme.headerTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: theme.fontFamily,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _statusColor(ctrl.state),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _statusColor(ctrl.state).withValues(alpha: 0.6),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _statusLabel(ctrl.state),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12.5,
                            fontFamily: theme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // New chat button
              Tooltip(
                message: 'Start new conversation',
                child: Material(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: ctrl.clearSession,
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(ChatpressState s) => switch (s) {
        ChatpressState.connected => const Color(0xFF4ADE80),
        ChatpressState.connecting => Colors.orange,
        ChatpressState.error => Colors.red.shade400,
        _ => Colors.grey,
      };

  String _statusLabel(ChatpressState s) => switch (s) {
        ChatpressState.connected => 'Online',
        ChatpressState.connecting => 'Connecting…',
        ChatpressState.error => 'Error',
        ChatpressState.disconnected => 'Disconnected',
        ChatpressState.idle => 'Starting…',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Message list
// ─────────────────────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final ChatpressController ctrl;
  final ScrollController scrollCtrl;
  final ChatTheme theme;

  const _MessageList(
      {required this.ctrl, required this.scrollCtrl, required this.theme});

  @override
  Widget build(BuildContext context) {
    final msgs = ctrl.messages;

    if (msgs.isEmpty) return _EmptyState(theme: theme);

    return Container(
      color: theme.backgroundColor,
      child: ListView.builder(
        controller: scrollCtrl,
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        itemCount: msgs.length,
        itemBuilder: (_, i) {
          final msg = msgs[i];
          final showAvatar = !msg.isUser &&
              (i == 0 || msgs[i - 1].role != msg.role);
          return TweenAnimationBuilder<double>(
            key: ValueKey(msg.id),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (_, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(msg.isUser ? 20 * (1 - t) : -20 * (1 - t), 0),
                child: child,
              ),
            ),
            child: ChatBubble(
              message: msg,
              theme: theme,
              showAvatar: showAvatar,
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Suggested follow-up question
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestedQuestion extends StatelessWidget {
  final ChatpressController ctrl;
  final ChatTheme theme;
  final VoidCallback onTap;
  final TextEditingController textCtrl;

  const _SuggestedQuestion({
    required this.ctrl,
    required this.theme,
    required this.onTap,
    required this.textCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final sq = ctrl.suggestedQuestion;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: sq != null && sq.isNotEmpty
          ? Container(
              color: theme.backgroundColor,
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: GestureDetector(
                onTap: () {
                  textCtrl.text = sq;
                  onTap();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          size: 15, color: theme.primaryColor),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          sq,
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 13,
                            fontFamily: theme.fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input bar
// ─────────────────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController textCtrl;
  final FocusNode focusNode;
  final ChatpressController ctrl;
  final ChatTheme theme;
  final Animation<double> sendScale;
  final VoidCallback onSend;

  const _InputBar({
    required this.textCtrl,
    required this.focusNode,
    required this.ctrl,
    required this.theme,
    required this.sendScale,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final canSend = ctrl.isConnected && !ctrl.isBusy;
    return Container(
      decoration: BoxDecoration(
        color: theme.inputBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 10,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? 10
            : MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: theme.inputBorderColor, width: 1.2),
              ),
              child: TextField(
                controller: textCtrl,
                focusNode: focusNode,
                style: TextStyle(
                  color: theme.inputTextColor,
                  fontSize: 15,
                  fontFamily: theme.fontFamily,
                ),
                decoration: InputDecoration(
                  hintText: canSend
                      ? 'Ask anything…'
                      : ctrl.state == ChatpressState.connecting
                          ? 'Connecting…'
                          : 'Ask anything…',
                  hintStyle: TextStyle(
                    color: theme.inputHintColor,
                    fontSize: 15,
                    fontFamily: theme.fontFamily,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                enabled: canSend,
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          ScaleTransition(
            scale: sendScale,
            child: GestureDetector(
              onTap: canSend ? onSend : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: canSend
                      ? LinearGradient(
                          colors: [
                            theme.primaryColor,
                            Color.lerp(
                                theme.primaryColor, Colors.purple, 0.3)!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            Colors.grey.shade300,
                            Colors.grey.shade400
                          ],
                        ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (canSend)
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.38),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: ctrl.isBusy && ctrl.state == ChatpressState.connecting
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded,
                        color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State views
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  final ChatTheme theme;
  const _LoadingView({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.backgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(theme.primaryColor),
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Starting chat…',
              style: TextStyle(
                color: theme.botBubbleTextColor.withValues(alpha: 0.45),
                fontSize: 14,
                fontFamily: theme.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final ChatTheme theme;
  final String message;
  final VoidCallback onRetry;
  const _ErrorView(
      {required this.theme, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.backgroundColor,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_off_rounded,
                color: Colors.red.shade400, size: 32),
          ),
          const SizedBox(height: 18),
          Text(
            'Connection Failed',
            style: TextStyle(
              color: theme.botBubbleTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: theme.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.botBubbleTextColor.withValues(alpha: 0.55),
              fontSize: 13.5,
              fontFamily: theme.fontFamily,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 26),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: const EdgeInsets.symmetric(
                  horizontal: 26, vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Try Again',
              style: TextStyle(
                fontFamily: theme.fontFamily,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ChatTheme theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.backgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    theme.primaryColor.withValues(alpha: 0.18),
                    theme.primaryColor.withValues(alpha: 0.04),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: theme.primaryColor,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Start a conversation',
              style: TextStyle(
                color: theme.botBubbleTextColor,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                fontFamily: theme.fontFamily,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ask me anything — I\'m here to help.',
              style: TextStyle(
                color: theme.botBubbleTextColor.withValues(alpha: 0.5),
                fontSize: 13.5,
                fontFamily: theme.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ChatpressLauncher — convenience methods to open the widget
// ─────────────────────────────────────────────────────────────────────────────

/// Utility class with static helpers to open [ChatpressWidget] without writing
/// [Navigator] boilerplate.
class ChatpressLauncher {
  ChatpressLauncher._();

  /// Pushes [ChatpressWidget] as a full-screen route.
  static Future<T?> openPage<T>(
    BuildContext context,
    ChatpressConfig config, {
    ChatTheme? theme,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (_) => ChatpressWidget(
          config: config,
          themeOverride: theme,
        ),
      ),
    );
  }

  /// Opens [ChatpressWidget] in a [DraggableScrollableSheet] bottom sheet.
  static Future<T?> openSheet<T>(
    BuildContext context,
    ChatpressConfig config, {
    ChatTheme? theme,
    double initialSize = 0.85,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: initialSize,
        maxChildSize: 0.95,
        minChildSize: 0.45,
        expand: false,
        builder: (_, __) => ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
          child: ChatpressWidget(
            config: config,
            themeOverride: theme,
            mode: ChatpressDisplayMode.inline,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ChatpressFab — drop-in floating action button
// ─────────────────────────────────────────────────────────────────────────────

/// A [FloatingActionButton] that opens [ChatpressWidget] on tap.
///
/// ```dart
/// Scaffold(
///   floatingActionButton: ChatpressFab(config: myConfig),
///   body: ...,
/// )
/// ```
class ChatpressFab extends StatelessWidget {
  final ChatpressConfig config;
  final ChatTheme? theme;

  /// When `true` opens as a bottom sheet; otherwise as a full-screen page.
  final bool asSheet;

  const ChatpressFab({
    super.key,
    required this.config,
    this.theme,
    this.asSheet = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme ?? const ChatTheme();
    return FloatingActionButton(
      backgroundColor: t.primaryColor,
      elevation: 6,
      onPressed: () => asSheet
          ? ChatpressLauncher.openSheet(context, config, theme: theme)
          : ChatpressLauncher.openPage(context, config, theme: theme),
      child: const Icon(Icons.chat_rounded, color: Colors.white, size: 26),
    );
  }
}
