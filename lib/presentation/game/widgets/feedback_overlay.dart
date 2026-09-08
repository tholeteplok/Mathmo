import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Overlay feedback animasi saat jawaban disubmit (benar/salah/timeout).
///
/// Tampil selama [AppTokens.feedbackDuration] (±400ms) untuk memberikan
/// kepuasan sensorik instan tanpa menahan ritme permainan.
class FeedbackOverlay extends StatelessWidget {
  const FeedbackOverlay({
    super.key,
    required this.isCorrect,
    required this.roundScore,
  });

  final bool isCorrect;
  final int roundScore;

  @override
  Widget build(BuildContext context) {
    final iconColor = isCorrect
        ? const Color(0xFF639922)
        : const Color(0xFFD85A30);
    final icon = isCorrect ? AppIcons.answerCorrect : AppIcons.answerWrong;

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: 1.0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTokens.radiusContainer),
            border: Border.all(color: iconColor, width: 3.0),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.4),
                offset: const Offset(0, 8),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: iconColor),
              if (isCorrect && roundScore > 0) ...[
                const SizedBox(width: 12),
                Text(
                  '+$roundScore',
                  style: AppTheme.statNumberStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: iconColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
