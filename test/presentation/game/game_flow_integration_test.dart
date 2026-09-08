import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mathmo_app/domain/models/player_profile.dart';

import 'package:mathmo_app/domain/repositories/player_repository.dart';
import 'package:mathmo_app/domain/repositories/repo_result.dart';
import 'package:mathmo_app/presentation/game/providers/game_dependencies_provider.dart';
import 'package:mathmo_app/presentation/game/providers/game_session_provider.dart';
import 'package:mathmo_app/presentation/game/state/game_session_state.dart';
import 'package:mathmo_app/presentation/game/widgets/game_screen.dart';
import 'package:mathmo_app/presentation/home/providers/player_profile_provider.dart';

class _MockPlayerRepo implements PlayerRepository {
  _MockPlayerRepo(this.profile);
  PlayerProfile profile;

  @override
  Future<RepoResult<PlayerProfile>> getProfile() async => RepoSuccess(profile);

  @override
  Future<RepoResult<void>> saveProfile(PlayerProfile p) async {
    profile = p;
    return const RepoSuccess(null);
  }

  @override
  Future<RepoResult<void>> updateLevel(int newLevel) async {
    profile = profile.copyWith(currentLevel: newLevel);
    return const RepoSuccess(null);
  }

  @override
  Future<RepoResult<PlayerProfile>> recordDailyActivity(DateTime date) async {
    return RepoSuccess(profile);
  }
}

void main() {
  testWidgets('Full GameScreen session completion triggers profile updateLevel', (
    tester,
  ) async {
    final mockRepo = _MockPlayerRepo(
      PlayerProfile(
        playerId: 'p_test',
        currentLevel: 1,
        totalXp: 0,
        streak: const StreakState(currentStreak: 0, freezeTokens: 1, lastPlayedDate: null),
        confidenceScore: 0,
        createdAt: DateTime.now(),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        playerRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);

    // Warm up profile provider
    await container.read(playerProfileProvider.future);

    final router = GoRouter(
      initialLocation: '/game/1',
      routes: [
        GoRoute(
          path: '/game/:level',
          builder: (context, state) => const GameScreen(level: 1),
        ),
        GoRoute(
          path: '/results',
          builder: (context, state) => const Scaffold(body: Text('Results')),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    // Initial state should be ShowQuestionState
    await tester.pump(const Duration(milliseconds: 700));

    final args = const GameSessionArgs(level: 1);
    final notifier = container.read(gameSessionProvider(args).notifier);

    // Play all 10 rounds with correct answers
    for (var r = 0; r < 10; r++) {
      // 1. Wait for ShowQuestionState (600ms) -> ActiveState
      await tester.pump(const Duration(milliseconds: 650));

      final state = container.read(gameSessionProvider(args));
      expect(state, isA<ActiveState>());

      // 2. Submit correct answer
      final correctIndex = (state as ActiveState).shuffledIndices.indexOf(0);
      notifier.submitAnswer(correctIndex);

      // 3. Wait for FeedbackState (400ms) -> next round or session ended
      await tester.pump(const Duration(milliseconds: 450));
    }

    // Wait for any remaining microtasks and background retry timers
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 15));

    // Check state
    final profile = container.read(playerProfileProvider).valueOrNull;


    expect(profile?.currentLevel, equals(2));
    expect(mockRepo.profile.currentLevel, equals(2));
  });
}
