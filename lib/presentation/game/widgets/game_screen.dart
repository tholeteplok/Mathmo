import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../domain/models/session_result.dart';
import '../../home/providers/player_profile_provider.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/exit_confirm_dialog.dart';
import '../providers/game_dependencies_provider.dart';
import '../providers/game_session_provider.dart';
import '../providers/level_band_theme_provider.dart';
import '../state/game_session_state.dart';
import 'answer_grid.dart';
import 'countdown_progress_bar.dart';
import 'feedback_overlay.dart';
import 'question_display.dart';

/// Layar utama sesi permainan cepat (Speed Math Gameplay).
///
/// Menyatukan seluruh alur gameplay loop:
/// - Soal muncul (ShowQuestion) -> Timer & opsi aktif (Active) -> Jawaban (Feedback) -> Hasil (SessionEnded).
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({
    super.key,
    required this.level,
    this.mode = GameMode.normal,
  });

  final int level;
  final GameMode mode;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final GameSessionArgs _args;

  @override
  void initState() {
    super.initState();
    _args = GameSessionArgs(level: widget.level, mode: widget.mode);
  }

  Future<bool> _handleWillPop() async {
    final notifier = ref.read(gameSessionProvider(_args).notifier);
    final state = ref.read(gameSessionProvider(_args));

    if (state is FeedbackState) {
      return false; // Jangan biarkan keluar di tengah animasi umpan balik
    }

    if (state is ActiveState || state is ShowQuestionState) {
      notifier.pause();
      final shouldExit = await showExitConfirmDialog(context);
      if (!shouldExit) {
        notifier.resume();
        return false;
      }
      return true;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(gameSessionProvider(_args));
    final themeAsync = ref.watch(levelBandThemeProvider);
    final profile = ref.watch(playerProfileProvider).valueOrNull;

    final canvasColor =
        themeAsync.valueOrNull?.canvasColor ?? const Color(0xFFEAF3DE);
    final accentColor =
        themeAsync.valueOrNull?.accentColor ?? const Color(0xFF639922);

    // Dengarkan saat sesi selesai untuk navigasi otomatis ke /results
    ref.listen<GameSessionState>(gameSessionProvider(_args), (prev, next) {
      if (next is SessionEndedState) {
        // Tambahkan XP ke profil pemain
        ref.read(playerProfileProvider.notifier).addXp(next.result.xpEarned);

        // Jika performa bagus, naikkan level
        if (next.result.accuracy >= 0.7 &&
            widget.level >= (profile?.currentLevel ?? 1)) {
          ref
              .read(playerProfileProvider.notifier)
              .updateLevel(widget.level + 1);
        }

        context.go('/results', extra: next.result);
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _handleWillPop();
        if (shouldPop && context.mounted) {
          context.go('/');
        }
      },
      child: MediaQuery(
        // Cap text scaling agar layout grid gameplay tidak patah pada text scaling OS ekstrem
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            MediaQuery.of(
              context,
            ).textScaler.scale(1.0).clamp(1.0, AppTokens.maxTextScaleGameplay),
          ),
        ),
        child: Scaffold(
          backgroundColor: canvasColor,
          body: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      // Header: Streak & XP
                      AppHeader(
                        streak: profile?.streak.currentStreak ?? 0,
                        xp: profile?.totalXp ?? 0,
                        onBackTap: () async {
                          final shouldPop = await _handleWillPop();
                          if (shouldPop && context.mounted) {
                            context.go('/');
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Countdown Progress Bar
                      _buildTimerBar(sessionState, accentColor),
                      const SizedBox(height: 24),

                      // Area Tampilan Soal
                      _buildQuestionArea(sessionState),
                      const SizedBox(height: 28),

                      // Grid Tombol Jawaban (2x2)
                      Expanded(child: _buildAnswerArea(sessionState)),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Feedback Overlay saat submit jawaban
              if (sessionState is FeedbackState)
                FeedbackOverlay(
                  isCorrect: sessionState.isCorrect,
                  roundScore: sessionState.roundScore,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerBar(GameSessionState state, Color accentColor) {
    if (state is ActiveState) {
      return CountdownProgressBar(
        key: ValueKey('${state.question.id}_${state.totalTimeMs}'),
        resetToken: state.question.id,
        duration: Duration(milliseconds: state.totalTimeMs),
        primaryColor: accentColor,
        onTimeout: () {
          ref.read(gameSessionProvider(_args).notifier).handleTimeout();
        },
      );
    }

    // Default placeholder bar saat ShowQuestion / Feedback
    return Container(
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
    );
  }

  Widget _buildQuestionArea(GameSessionState state) {
    final question = switch (state) {
      ShowQuestionState(:final question) => question,
      ActiveState(:final question) => question,
      FeedbackState(:final question) => question,
      PausedState(:final pausedFrom) => pausedFrom.question,
      SessionEndedState() => null,
    };

    if (question == null) return const SizedBox.shrink();

    return QuestionDisplay(key: ValueKey(question.id), question: question);
  }

  Widget _buildAnswerArea(GameSessionState state) {
    if (state is ActiveState) {
      return AnswerGrid(
        key: ValueKey(state.question.id),
        question: state.question,
        distractors: state.distractors,
        shuffledIndices: state.shuffledIndices,
        enabled: true,
        onAnswerSelected: (index) {
          ref.read(gameSessionProvider(_args).notifier).submitAnswer(index);
        },
      );
    }

    // Tampilkan grid non-aktif saat state ShowQuestion / Feedback
    return Opacity(
      opacity: 0.6,
      child: IgnorePointer(
        child: AnswerGrid(
          question: switch (state) {
            ShowQuestionState(:final question) => question,
            FeedbackState(:final question) => question,
            PausedState(:final pausedFrom) => pausedFrom.question,
            _ =>
              ref
                  .read(questionGeneratorProvider)
                  .generateForLevel(widget.level),
          },
          distractors: const [],
          shuffledIndices: const [0, 1, 2, 3],
          onAnswerSelected: (_) {},
        ),
      ),
    );
  }
}
