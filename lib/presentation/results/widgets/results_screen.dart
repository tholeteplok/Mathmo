import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/sfx_service.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/session_result.dart';
import '../../../domain/services/scoring_service.dart';
import '../../game/providers/level_band_theme_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/chunky_card.dart';
import 'animated_star_rating.dart';
import 'score_stat_card.dart';

/// Layar rangkuman hasil sesi permainan (ResultsScreen).
///
/// Menampilkan skor total, statistik akurasi, rincian XP, dan banner streak.
class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key, required this.result});

  final SessionResult result;

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  SessionResult get result => widget.result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(sfxServiceProvider).play(SfxType.levelUp);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeAsync = ref.watch(levelBandThemeProvider);
    final canvasColor =
        themeAsync.valueOrNull?.canvasColor ?? AppTheme.fallbackCanvas;
    final accentColor =
        themeAsync.valueOrNull?.accentColor ?? AppTheme.fallbackAccent;

    final accuracyPercent = (result.accuracy * 100).round();
    final avgTimeSec = (result.avgResponseTimeMs / 1000).toStringAsFixed(1);
    final earnedStars = ScoringService.calculateStars(result.accuracy);

    final isReplay =
        result.previousBestScore != null && result.previousBestScore! > 0;
    final scoreDelta = result.scoreDelta ?? (isReplay ? 0 : result.totalScore);
    final isNewRecord = isReplay && scoreDelta > 0;

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
              const SizedBox(height: 10),

              // Animasi Perolehan Bintang
              AnimatedStarRating(starCount: earnedStars),
              const SizedBox(height: 14),

              // Banner Streak Maintained
              ChunkyCard(
                variant: ChunkyCardVariant.wood,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      AppIcons.streakMaintained,
                      color: AppTheme.colorCoral,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Streak Harian Dipertahankan!',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.colorWoodDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Kartu Skor Total
              ChunkyCard(
                variant: ChunkyCardVariant.wood,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    if (isNewRecord) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.colorHoney.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.colorHoney,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '★ REKOR BARU! ★',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: AppTheme.colorWoodDark,
                              ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      'TOTAL SKOR',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppTheme.colorTaupe,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${result.totalScore}',
                      style: AppTheme.mathNumberStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isNewRecord)
                      Text(
                        '+$scoreDelta ditambahkan ke peringkat',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.colorSage,
                        ),
                      )
                    else if (isReplay)
                      Text(
                        'Rekor terbaik: ${result.previousBestScore}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.colorTaupe,
                        ),
                      )
                    else
                      Text(
                        '+${result.totalScore} ditambahkan ke peringkat',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.colorSage,
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
                      iconColor: AppTheme.colorSage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ScoreStatCard(
                      title: 'Rata-rata',
                      value: '${avgTimeSec}s',
                      icon: AppIcons.timeStat,
                      iconColor: AppTheme.colorHoney,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ScoreStatCard(
                      title: 'Streak',
                      value: '${result.bestStreak}',
                      icon: AppIcons.streak,
                      iconColor: AppTheme.colorCoral,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Kartu Rincian XP
              ChunkyCard(
                variant: ChunkyCardVariant.wood,
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
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.colorEspresso,
                              ),
                        ),
                        Text(
                          '+${result.xpEarned} XP',
                          style: AppTheme.statNumberStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.colorHoney,
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      height: 24,
                      thickness: 1.5,
                      color: AppTheme.colorCardBorder,
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

              // Tiga Tombol Tindakan Bawah (Icon Saja): Beranda, Ulangi, Berikutnya
              Row(
                children: [
                  // 1. Beranda
                  Expanded(
                    child: ChunkyButton(
                      onPressed: () => context.go('/'),
                      backgroundColor: AppTheme.colorVanillaCard,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: const Icon(
                        AppIcons.home,
                        size: 26,
                        color: AppTheme.colorEspresso,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 2. Ulangi Level
                  Expanded(
                    child: ChunkyButton(
                      onPressed: () =>
                          context.go('/game/${result.levelReached}'),
                      backgroundColor: AppTheme.colorVanillaCard,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: const Icon(
                        AppIcons.replay,
                        size: 26,
                        color: AppTheme.colorEspresso,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 3. Level Berikutnya (Aktif jika minimal 1 bintang)
                  Expanded(
                    child: ChunkyButton(
                      enabled: earnedStars >= 1,
                      onPressed: earnedStars >= 1
                          ? () =>
                              context.go('/game/${result.levelReached + 1}')
                          : null,
                      backgroundColor: earnedStars >= 1
                          ? accentColor
                          : const Color(0xFFD5C4A1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Icon(
                        AppIcons.nextLevel,
                        size: 26,
                        color: earnedStars >= 1
                            ? Colors.white
                            : AppTheme.colorTaupe,
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
