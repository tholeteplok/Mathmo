import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../shared/widgets/chunky_card.dart';

class LevelProgressCard extends StatelessWidget {
  const LevelProgressCard({
    super.key,
    required this.currentLevel,
    required this.totalXp,
  });

  final int currentLevel;
  final int totalXp;

  @override
  Widget build(BuildContext context) {
    // Tiap level butuh (currentLevel * 100) XP untuk naik ke level berikutnya
    final xpRequiredForCurrent = (currentLevel - 1) * 100;
    final progressXp = (totalXp - xpRequiredForCurrent).clamp(0, 100);
    final progressFraction = (progressXp / 100.0).clamp(0.0, 1.0);

    return ChunkyCard(
      variant: ChunkyCardVariant.woodBoard,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      AppIcons.levelCompleted,
                      size: 20,
                      color: AppTheme.colorSage,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Level $currentLevel',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.colorEspresso,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Total $totalXp XP',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppTheme.colorTaupe,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: AppTheme.colorSandyCanvas,
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              border: Border.all(
                color: AppTheme.darkBorder,
                width: AppTokens.borderWidthSubtle,
              ),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: progressFraction,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.colorSage,
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$progressXp / 100 XP ke Level ${currentLevel + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.colorTaupe,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progressFraction * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.colorWoodDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
