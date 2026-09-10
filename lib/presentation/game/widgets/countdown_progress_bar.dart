import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Progress bar countdown 60fps yang di-drive langsung oleh Flutter Ticker
/// lokal di widget State, BUKAN melalui Riverpod StateNotifier.
///
/// Mengacu pada `math-speed-game-performance-budget.md` §2.1:
/// Menggunakan [RepaintBoundary] dan [CustomPainter] terisolasi agar repaint ~60x/detik
/// tidak memicu re-layout atau widget rebuild pada parent tree.
class CountdownProgressBar extends StatefulWidget {
  const CountdownProgressBar({
    super.key,
    required this.duration,
    required this.onTimeout,
    this.height = 16.0,
    this.primaryColor = AppTheme.colorSage,
    this.warningColor = AppTheme.colorCoral,
    this.borderColor = const Color(0xFFDECFA8),
    this.resetToken,
  });

  final Duration duration;
  final VoidCallback onTimeout;
  final double height;
  final Color primaryColor;
  final Color warningColor;
  final Color borderColor;
  final Object? resetToken;

  @override
  State<CountdownProgressBar> createState() => CountdownProgressBarState();
}

class CountdownProgressBarState extends State<CountdownProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener(_onAnimationStatus);
    _controller.forward(from: 0.0);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onTimeout();
    }
  }

  @override
  void didUpdateWidget(covariant CountdownProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetToken != widget.resetToken ||
        oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      _controller.stop();
      _controller.reset();
      _controller.forward(from: 0.0);
    }
  }

  /// Pause countdown saat game dijeda.
  void pause() {
    _controller.stop();
  }

  /// Lanjut countdown.
  void resume() {
    _controller.forward();
  }

  /// Reset countdown.
  void reset() {
    _controller.reset();
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppTheme.colorVanillaCard,
          borderRadius: BorderRadius.circular(widget.height / 2),
          border: Border.all(
            color: widget.borderColor,
            width: AppTokens.borderWidthDefault,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.colorWoodDark.withValues(alpha: 0.10),
              offset: const Offset(0, 2),
              blurRadius: 3,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            (widget.height / 2) - AppTokens.borderWidthDefault,
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = (1.0 - _controller.value).clamp(0.0, 1.0);
              return CustomPaint(
                size: Size(double.infinity, widget.height),
                painter: _ProgressBarPainter(
                  progress: progress,
                  primaryColor: widget.primaryColor,
                  warningColor: widget.warningColor,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  const _ProgressBarPainter({
    required this.progress,
    required this.primaryColor,
    required this.warningColor,
  });

  final double progress;
  final Color primaryColor;
  final Color warningColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    // Gradasi transisi warna hijau ke oranye/merah saat waktu menipis (<30%)
    final color = progress < 0.3
        ? Color.lerp(warningColor, primaryColor, progress / 0.3)!
        : primaryColor;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final fillWidth = size.width * progress;
    canvas.drawRect(Rect.fromLTWH(0, 0, fillWidth, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ProgressBarPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
