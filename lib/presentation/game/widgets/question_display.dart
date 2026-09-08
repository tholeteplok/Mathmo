import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/models/question.dart';
import '../../shared/widgets/chunky_card.dart';

/// Kartu tampilan soal aritmatika di layar permainan.
class QuestionDisplay extends StatelessWidget {
  const QuestionDisplay({
    super.key,
    required this.question,
    this.rotation = AppTokens.rotationSubtleNegative,
  });

  final Question question;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return ChunkyCard(
      rotation: rotation,
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${question.displayExpression} = ?',
            style: AppTheme.mathNumberStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
