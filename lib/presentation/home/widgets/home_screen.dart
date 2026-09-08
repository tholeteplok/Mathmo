import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../game/providers/level_band_theme_provider.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/chunky_button.dart';
import '../providers/player_profile_provider.dart';
import 'level_node.dart';

/// Layar beranda (HomeScreen) berisi peta jalur level progres pemain.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(playerProfileProvider);
    final themeAsync = ref.watch(levelBandThemeProvider);

    final currentLevel = profileAsync.valueOrNull?.currentLevel ?? 1;
    final currentStreak = profileAsync.valueOrNull?.streak.currentStreak ?? 0;
    final totalXp = profileAsync.valueOrNull?.totalXp ?? 0;
    final accentColor =
        themeAsync.valueOrNull?.accentColor ?? const Color(0xFF639922);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Avatar, Streak, XP
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AppHeader(
                streak: currentStreak,
                xp: totalXp,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.darkBorder,
                      width: AppTokens.borderWidthDefault,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.darkBorder,
                        offset: const Offset(0, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'M',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.darkBorder,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Peta Jalur Level
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 24),
                reverse: true, // Level 1 di bawah, level tinggi di atas
                itemCount: currentLevel + 6,
                itemBuilder: (context, index) {
                  final level = index + 1;
                  final status = level < currentLevel
                      ? LevelNodeStatus.completed
                      : level == currentLevel
                      ? LevelNodeStatus.active
                      : LevelNodeStatus.locked;

                  // Pola jalan berliku (zigzag offset)
                  final offset = (index % 4 == 1)
                      ? 45.0
                      : (index % 4 == 3)
                      ? -45.0
                      : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Transform.translate(
                      offset: Offset(offset, 0),
                      child: Center(
                        child: LevelNode(
                          level: level,
                          status: status,
                          accentColor: accentColor,
                          onTap: () {
                            if (status != LevelNodeStatus.locked) {
                              context.go('/game/$level');
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Banner Daily Challenge di Bawah
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: ChunkyButton(
                onPressed: () => context.go('/daily'),
                backgroundColor: const Color(0xFFBA7517), // Amber
                borderColor: AppTheme.darkBorder,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      AppIcons.calendar,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Daily Challenge Hari Ini',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
