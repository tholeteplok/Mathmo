import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/models/daily_challenge.dart';
import '../../../domain/models/distractor.dart';
import '../../../domain/models/question.dart';
import '../../game/providers/game_dependencies_provider.dart';
import '../../game/providers/level_band_theme_provider.dart';
import '../../game/widgets/answer_grid.dart';
import '../../game/widgets/countdown_progress_bar.dart';
import '../../game/widgets/feedback_overlay.dart';
import '../../game/widgets/question_display.dart';
import '../../home/providers/player_profile_provider.dart';
import '../../profile/providers/account_status_provider.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/chunky_card.dart';
import '../../shared/widgets/exit_confirm_dialog.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../leaderboard/providers/leaderboard_provider.dart';
import '../providers/daily_challenge_provider.dart';

/// Layar tantangan harian (DailyChallengeScreen).
///
/// Menyajikan 12 soal deterministik harian dengan penilaian berbasis total benar.
class DailyChallengeScreen extends ConsumerStatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  ConsumerState<DailyChallengeScreen> createState() =>
      _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends ConsumerState<DailyChallengeScreen> {
  int _currentIndex = 0;
  int _correctCount = 0;
  int _totalTimeMs = 0;
  DateTime? _questionStartTime;
  bool _isFinished = false;
  bool _isFeedback = false;
  bool _lastIsCorrect = false;
  bool _didAttemptSubmit = false;

  late final Stopwatch _sessionStopwatch;

  @override
  void initState() {
    super.initState();
    _sessionStopwatch = Stopwatch()..start();
    _questionStartTime = DateTime.now();
  }

  @override
  void dispose() {
    _sessionStopwatch.stop();
    super.dispose();
  }

  void _handleAnswer(
    Question question,
    DistractorSet distractors,
    int selectedIndex,
  ) {
    if (_isFeedback || _isFinished) return;

    final responseTime = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inMilliseconds
        : 2000;
    _totalTimeMs += responseTime;

    final isCorrect = distractors.shuffledIndices[selectedIndex] == 0;
    if (isCorrect) _correctCount++;

    setState(() {
      _isFeedback = true;
      _lastIsCorrect = isCorrect;
    });

    Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (_currentIndex + 1 >= 12) {
        _finishChallenge();
      } else {
        setState(() {
          _currentIndex++;
          _isFeedback = false;
          _questionStartTime = DateTime.now();
        });
      }
    });
  }

  void _handleTimeout() {
    if (_isFeedback || _isFinished) return;

    _totalTimeMs += 5000;

    setState(() {
      _isFeedback = true;
      _lastIsCorrect = false;
    });

    Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (_currentIndex + 1 >= 12) {
        _finishChallenge();
      } else {
        setState(() {
          _currentIndex++;
          _isFeedback = false;
          _questionStartTime = DateTime.now();
        });
      }
    });
  }

  String? _submitError;

  Future<void> _finishChallenge() async {
    _sessionStopwatch.stop();
    final profile = ref.read(playerProfileProvider).valueOrNull;
    final config = ref.read(levelBandsConfigProvider).valueOrNull;
    final now = DateTime.now();

    final currentLevel = profile?.currentLevel ?? 1;
    final bandId = config?.bandForLevel(currentLevel).id ?? 'basic';

    final result = DailyChallengeResult(
      playerId: profile?.playerId ?? 'player',
      date: now,
      band: bandId,
      correctCount: _correctCount,
      totalTimeMs: _totalTimeMs,
      rankInBand: null,
    );

    String? submitErrMsg;
    try {
      // Rekam aktivitas harian dan update streak
      await ref.read(playerProfileProvider.notifier).recordActivity(now);
      await ref.read(dailyChallengeRepositoryProvider).saveResult(result);
      ref.invalidate(dailyChallengeCompletionProvider);

      // Jika pemain sudah memiliki username akun, submit ke papan peringkat cloud
      final accountState = ref.read(accountStatusProvider).valueOrNull;
      final username = accountState?.username;
      if (username != null && username.isNotEmpty) {
        submitErrMsg = null; // tandai bahwa submit dicoba
        final avatarId = profile?.avatarId;
        final submitResult = await ref
            .read(leaderboardRepositoryProvider)
            .submitDailyResult(
              result: result,
              username: username,
              avatarId: avatarId,
              totalScore: profile?.totalScore,
            );
        if (submitResult case RepoFailure(:final reason)) {
          submitErrMsg = reason;
        } else {
          // Invalidate cache leaderboard agar data baru langsung muncul
          ref.invalidate(leaderboardEntriesProvider(bandId));
          ref.invalidate(allTimeEntriesProvider);
        }
      }
    } catch (_) {
      // Graceful degradation: kegagalan IO tidak menghalangi transisi UI
    } finally {
      if (mounted) {
        setState(() {
          _isFinished = true;
          _isFeedback = false;
          _submitError = submitErrMsg;
          // Jika submitErrMsg == null dan username ada → submit berhasil
          final accountState = ref.read(accountStatusProvider).valueOrNull;
          _didAttemptSubmit = accountState?.hasUsername ?? false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengeAsync = ref.watch(dailyChallengeProvider);
    final themeAsync = ref.watch(levelBandThemeProvider);
    final profile = ref.watch(playerProfileProvider).valueOrNull;

    final canvasColor =
        themeAsync.valueOrNull?.canvasColor ?? const Color(0xFFEAF3DE);
    final accentColor =
        themeAsync.valueOrNull?.accentColor ?? const Color(0xFF639922);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_isFinished) {
          context.go('/');
          return;
        }
        final shouldExit = await showExitConfirmDialog(context);
        if (shouldExit && context.mounted) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: canvasColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: challengeAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Gagal memuat tantangan: $err')),
              data: (challenge) {
                if (_isFinished) {
                  return _buildFinishedView(context, accentColor);
                }

                final currentQuestion = challenge.questions[_currentIndex];
                final service = ref.read(dailyChallengeServiceProvider);
                final distractors = service.generateDistractorsForQuestion(
                  currentQuestion,
                  challenge.seed,
                );

                return Stack(
                  children: [
                    Column(
                      children: [
                        // Header
                        AppHeader(
                          streak: profile?.streak.currentStreak ?? 0,
                          xp: profile?.totalXp ?? 0,
                          onBackTap: () async {
                            final shouldExit = await showExitConfirmDialog(
                              context,
                            );
                            if (shouldExit && context.mounted) {
                              context.go('/');
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Label Progres Soal & Timer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Soal ${_currentIndex + 1} / 12',
                              style: AppTheme.statNumberStyle(fontSize: 16),
                            ),
                            Text(
                              'Benar: $_correctCount',
                              style: AppTheme.statNumberStyle(
                                fontSize: 16,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Countdown bar per soal (5 detik)
                        if (_isFeedback)
                          Container(
                            width: double.infinity,
                            height: 16.0,
                            decoration: BoxDecoration(
                              color: AppTheme.colorVanillaCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFDECFA8),
                                width: AppTokens.borderWidthDefault,
                              ),
                            ),
                          )
                        else
                          CountdownProgressBar(
                            key: ValueKey('dc_${_currentIndex}_${currentQuestion.id}'),
                            resetToken: _currentIndex,
                            duration: const Duration(milliseconds: 5000),
                            primaryColor: accentColor,
                            onTimeout: _handleTimeout,
                          ),
                        const SizedBox(height: 24),

                        // Question Card
                        QuestionDisplay(
                          key: ValueKey(currentQuestion.id),
                          question: currentQuestion,
                        ),
                        const SizedBox(height: 28),

                        // Answer Grid 2x2
                        Expanded(
                          child: AnswerGrid(
                            key: ValueKey(currentQuestion.id),
                            question: currentQuestion,
                            distractors: distractors.distractors,
                            shuffledIndices: distractors.shuffledIndices,
                            enabled: !_isFeedback,
                            onAnswerSelected: (index) {
                              _handleAnswer(
                                currentQuestion,
                                distractors,
                                index,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                    if (_isFeedback)
                      FeedbackOverlay(
                        isCorrect: _lastIsCorrect,
                        roundScore: _lastIsCorrect ? 10 : 0,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedView(BuildContext context, Color accentColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChunkyCard(
              variant: ChunkyCardVariant.wood,
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Icon(
                    AppIcons.streakMaintained,
                    color: AppTheme.colorCoral,
                    size: 54,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Tantangan Selesai!',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.colorEspresso,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Skor Akhir: $_correctCount / 12 Benar',
                    style: AppTheme.statNumberStyle(
                      fontSize: 26,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Total Waktu: ${(_totalTimeMs / 1000).toStringAsFixed(1)} detik',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.colorTaupe,
                    ),
                  ),
                  // Status badge pengiriman skor ke cloud (hanya jika user punya username)
                  if (_didAttemptSubmit) ...[ 
                    const SizedBox(height: 12),
                    if (_submitError != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        border: Border.all(
                          color: const Color(0xFFD4A017),
                          width: AppTokens.borderWidthSubtle,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 14, color: Color(0xFFB45309)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Skor gagal dikirim: $_submitError',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        border: Border.all(
                          color: const Color(0xFF4CAF50),
                          width: AppTokens.borderWidthSubtle,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_done_rounded,
                              size: 14, color: Color(0xFF2E7D32)),
                          SizedBox(width: 6),
                          Text(
                            'Skor terkirim ke papan peringkat!',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ], // end _didAttemptSubmit
                ],
              ),
            ),
            const SizedBox(height: 24),
            ChunkyButton(
              onPressed: () => context.go('/'),
              backgroundColor: accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: const Text(
                'Kembali ke Beranda',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gerbang rute (/daily) yang mengecek apakah Daily Challenge hari ini sudah diselesaikan.
///
/// Jika sudah selesai, menampilkan [DailyChallengeLockedView].
/// Jika belum selesai atau gagal membaca data lokal, menampilkan [DailyChallengeScreen].
class DailyChallengeGate extends ConsumerWidget {
  const DailyChallengeGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completionAsync = ref.watch(dailyChallengeCompletionProvider);

    return completionAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.colorSandyCanvas,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.colorWoodMedium),
        ),
      ),
      error: (err, stack) => const DailyChallengeScreen(),
      data: (result) {
        if (result != null) {
          return DailyChallengeLockedView(result: result);
        }
        return const DailyChallengeScreen();
      },
    );
  }
}

/// Tampilan saat pemain membuka Daily Challenge yang sudah diselesaikan hari ini.
class DailyChallengeLockedView extends ConsumerWidget {
  const DailyChallengeLockedView({super.key, required this.result});

  final DailyChallengeResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileProvider).valueOrNull;
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final hoursLeft = nextMidnight.difference(now).inHours;
    final minutesLeft = nextMidnight.difference(now).inMinutes % 60;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.colorSandyCanvas,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
            children: [
              // Header Profil
              AppHeader(
                streak: profile?.streak.currentStreak ?? 0,
                xp: profile?.totalXp ?? 0,
                onBackTap: () => context.go('/'),
              ),
              const Spacer(),

              // Kartu Papan Kayu Pengumuman
              ChunkyCard(
                variant: ChunkyCardVariant.woodBoard,
                padding: const EdgeInsets.fromLTRB(26, 44, 26, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      AppIcons.levelCompleted,
                      color: AppTheme.colorSage,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tantangan Hari Ini Selesai!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.colorEspresso,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Skor Akhir: ${result.correctCount} / 12 Benar',
                      style: AppTheme.statNumberStyle(
                        fontSize: 24,
                        color: AppTheme.colorSage,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Waktu: ${(result.totalTimeMs / 1000).toStringAsFixed(1)} detik',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.colorTaupe,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.colorVanillaCard,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusPill),
                        border: Border.all(
                          color: const Color(0xFFDECFA8),
                          width: AppTokens.borderWidthSubtle,
                        ),
                      ),
                      child: Text(
                        'Tantangan berikutnya terbuka dalam $hoursLeft jam $minutesLeft menit (00:00).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.colorWoodDark,
                              fontWeight: FontWeight.w700,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Kembali ke Beranda
              ChunkyButton(
                onPressed: () => context.go('/'),
                backgroundColor: AppTheme.colorWoodMedium,
                borderColor: AppTheme.colorWoodDark,
                shadowColor: AppTheme.colorWoodDark,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: const Text(
                  'Kembali ke Beranda',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    ),
  );
}
}
