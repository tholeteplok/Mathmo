import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Tombol interaktif bergaya "chunky playful".
///
/// Memiliki efek visual tactile yang memuaskan:
/// Saat ditekan, tombol turun sejauh 4px dan solid shadow menghilang seolah-olah
/// tombol fisik ditekan ke dalam permukaan.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor = Colors.white,
    this.borderColor = AppTheme.darkBorder,
    this.borderRadius = AppTokens.radiusButton,
    this.borderWidth = AppTokens.borderWidthDefault,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.width,
    this.height,
    this.rotation = 0.0,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final double rotation;
  final bool enabled;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (!widget.enabled || widget.onPressed == null) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.enabled || widget.onPressed == null) return;
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (!widget.enabled || widget.onPressed == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    const shadowOffset = 4.0;
    final isPressed = _isPressed;

    Widget button = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: AppTokens.buttonPressDuration,
        curve: Curves.easeInOut,
        width: widget.width,
        height: widget.height,
        constraints: const BoxConstraints(
          minHeight: AppTokens.minTapTarget,
          minWidth: AppTokens.minTapTarget,
        ),
        transform: isPressed
            ? Matrix4.translationValues(0, shadowOffset, 0)
            : Matrix4.identity(),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.enabled
              ? widget.backgroundColor
              : widget.backgroundColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: widget.borderColor,
            width: widget.borderWidth,
          ),
          boxShadow: isPressed
              ? ChunkyShadow.pressed
              : ChunkyShadow.button(widget.borderColor),
        ),
        child: Center(child: widget.child),
      ),
    );

    if (widget.rotation != 0.0) {
      button = Transform.rotate(angle: widget.rotation, child: button);
    }

    return button;
  }
}
