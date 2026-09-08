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
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/chunky_card.dart';
import '../../shared/widgets/exit_confirm_dialog.dart';
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

  Future<void> _finishChallenge() async {
    _sessionStopwatch.stop();
    final profile = ref.read(playerProfileProvider).valueOrNull;
    final now = DateTime.now();

    final result = DailyChallengeResult(
      playerId: profile?.playerId ?? 'player',
      date: now,
      band: 'basic',
      correctCount: _correctCount,
      totalTimeMs: _totalTimeMs,
      rankInBand: null,
    );

    // Rekam aktivitas harian dan update streak
    await ref.read(playerProfileProvider.notifier).recordActivity(now);
    await ref.read(dailyChallengeRepositoryProvider).saveResult(result);

    setState(() {
      _isFinished = true;
      _isFeedback = false;
    });
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF232B1E),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChunkyCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Icon(
                  AppIcons.streakMaintained,
                  color: Color(0xFFE65100),
                  size: 54,
                ),
                const SizedBox(height: 14),
                Text(
                  'Tantangan Selesai!',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
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
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ChunkyButton(
            onPressed: () => context.go('/'),
            backgroundColor: accentColor,
            borderColor: AppTheme.darkBorder,
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
    );
  }
}
