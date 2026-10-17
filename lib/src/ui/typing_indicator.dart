import 'dart:math';
import 'package:flutter/material.dart';

/// Animated three-dot typing indicator shown while the assistant is responding.
class TypingIndicator extends StatefulWidget {
  final Color color;
  final double dotSize;
  final Duration duration;

  const TypingIndicator({
    super.key,
    required this.color,
    this.dotSize = 7,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.dotSize * 2.2,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final progress = (_controller.value + i / 3) % 1.0;
              final scale = 0.5 + 0.5 * sin(progress * pi);
              final opacity = 0.4 + 0.6 * scale;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.dotSize * 0.3),
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.dotSize,
                      height: widget.dotSize,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
