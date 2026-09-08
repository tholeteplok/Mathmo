import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../shared/widgets/chunky_button.dart';

/// Status visual sebuah node level pada peta progres.
enum LevelNodeStatus { completed, active, locked }

/// Node individual pada peta jalur level di HomeScreen.
///
/// Berdasarkan `app_icons.dart`:
/// - Selesai: Checkmark hijau ([AppIcons.levelCompleted])
/// - Aktif: Tombol play beranimasi ([AppIcons.levelActive])
/// - Terkunci: Gembok abu-abu ([AppIcons.levelLocked])
class LevelNode extends StatelessWidget {
  const LevelNode({
    super.key,
    required this.level,
    required this.status,
    required this.onTap,
    this.accentColor = const Color(0xFF639922),
  });

  final int level;
  final LevelNodeStatus status;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      LevelNodeStatus.completed => _buildCompletedNode(),
      LevelNodeStatus.active => _buildActiveNode(context),
      LevelNodeStatus.locked => _buildLockedNode(),
    };
  }

  Widget _buildCompletedNode() {
    return ChunkyButton(
      onPressed: onTap,
      width: 58,
      height: 58,
      borderRadius: 29,
      backgroundColor: const Color(0xFFDCEACB),
      borderColor: const Color(0xFF639922),
      padding: EdgeInsets.zero,
      child: const Icon(
        AppIcons.levelCompleted,
        color: Color(0xFF639922),
        size: 26,
      ),
    );
  }

  Widget _buildActiveNode(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChunkyButton(
          onPressed: onTap,
          width: 76,
          height: 76,
          borderRadius: 38,
          backgroundColor: accentColor,
          borderColor: AppTheme.darkBorder,
          padding: EdgeInsets.zero,
          child: const Icon(
            AppIcons.levelActive,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            border: Border.all(
              color: AppTheme.darkBorder,
              width: AppTokens.borderWidthSubtle,
            ),
          ),
          child: Text(
            'Level $level',
            style: AppTheme.statNumberStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkBorder,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedNode() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFB0B0B0),
          width: AppTokens.borderWidthDefault,
        ),
      ),
      child: const Center(
        child: Icon(AppIcons.levelLocked, color: Color(0xFF888888), size: 22),
      ),
    );
  }
}
