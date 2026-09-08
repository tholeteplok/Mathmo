import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/session_result.dart';
import '../../game/providers/level_band_theme_provider.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/chunky_card.dart';
import 'score_stat_card.dart';

/// Layar rangkuman hasil sesi permainan (ResultsScreen).
///
/// Menampilkan skor total, statistik akurasi, rincian XP, dan banner streak.
class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key, required this.result});

  final SessionResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(levelBandThemeProvider);
    final canvasColor =
        themeAsync.valueOrNull?.canvasColor ?? const Color(0xFFEAF3DE);
    final accentColor =
        themeAsync.valueOrNull?.accentColor ?? const Color(0xFF639922);

    final accuracyPercent = (result.accuracy * 100).round();
    final avgTimeSec = (result.avgResponseTimeMs / 1000).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: canvasColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Judul Halaman
              Text(
                'Sesi Selesai!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.darkBorder,
                ),
              ),
              const SizedBox(height: 18),

              // Banner Streak Maintained
              ChunkyCard(
                backgroundColor: const Color(
                  0xFFFAEEDA,
                ), // Warm amber background
                borderColor: const Color(0xFFBA7517),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      AppIcons.streakMaintained,
                      color: Color(0xFFE65100),
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Streak Harian Dipertahankan!',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFBA7517),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Kartu Skor Total
              ChunkyCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    Text(
                      'TOTAL SKOR',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: const Color(0xFF7A8670),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${result.totalScore}',
                      style: AppTheme.mathNumberStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Baris 3 Kartu Statistik
              Row(
                children: [
                  Expanded(
                    child: ScoreStatCard(
                      title: 'Akurasi',
                      value: '$accuracyPercent%',
                      icon: AppIcons.accuracyStat,
                      iconColor: const Color(0xFF639922),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ScoreStatCard(
                      title: 'Rata-rata',
                      value: '${avgTimeSec}s',
                      icon: AppIcons.timeStat,
                      iconColor: const Color(0xFFBA7517),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ScoreStatCard(
                      title: 'Streak',
                      value: '${result.bestStreak}',
                      icon: AppIcons.streak,
                      iconColor: const Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Kartu Rincian XP
              ChunkyCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'XP Diperoleh',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '+${result.xpEarned} XP',
                          style: AppTheme.statNumberStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFF57F17),
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      height: 24,
                      thickness: 1.5,
                      color: Color(0xFFEAEAEA),
                    ),
                    _buildXpRow(
                      context,
                      label:
                          '${result.xpBreakdown.distinctFactsPracticed} Fakta Dilatih',
                      xp: '+${result.xpBreakdown.distinctFactsPracticed * 2} XP',
                    ),
                    const SizedBox(height: 8),
                    _buildXpRow(
                      context,
                      label:
                          '${result.xpBreakdown.factsMovedUpABox} Fakta Naik Tingkat Box',
                      xp: '+${result.xpBreakdown.factsMovedUpABox * 5} XP',
                    ),
                    if (result.xpBreakdown.sessionCompletedBonus > 0) ...[
                      const SizedBox(height: 8),
                      _buildXpRow(
                        context,
                        label: 'Bonus Sesi Tuntas',
                        xp: '+${result.xpBreakdown.sessionCompletedBonus} XP',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Tombol Tindakan Bawah
              Row(
                children: [
                  Expanded(
                    child: ChunkyButton(
                      onPressed: () => context.go('/'),
                      backgroundColor: Colors.white,
                      borderColor: AppTheme.darkBorder,
                      child: const Text(
                        'Ke Beranda',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkBorder,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ChunkyButton(
                      onPressed: () =>
                          context.go('/game/${result.levelReached}'),
                      backgroundColor: accentColor,
                      borderColor: AppTheme.darkBorder,
                      child: const Text(
                        'Main Lagi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildXpRow(
    BuildContext context, {
    required String label,
    required String xp,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF556050),
          ),
        ),
        Text(
          xp,
          style: AppTheme.statNumberStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFBA7517),
          ),
        ),
      ],
    );
  }
}
