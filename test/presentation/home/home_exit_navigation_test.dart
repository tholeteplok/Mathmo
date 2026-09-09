import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mathmo_app/domain/models/player_profile.dart';
import 'package:mathmo_app/domain/repositories/player_repository.dart';
import 'package:mathmo_app/domain/repositories/repo_result.dart';
import 'package:mathmo_app/presentation/game/providers/game_dependencies_provider.dart';
import 'package:mathmo_app/presentation/home/widgets/home_screen.dart';
import 'package:mathmo_app/presentation/splash/widgets/splash_screen.dart';
import 'package:mathmo_app/presentation/shared/widgets/app_shell.dart';
import 'package:mathmo_app/presentation/game/widgets/game_screen.dart';

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
  group('HomeScreen Exit Confirmation & Root Back Navigation', () {
    testWidgets(
      'System back triggers ExitConfirmDialog on HomeScreen fresh from launch',
      (tester) async {
        final mockRepo = _MockPlayerRepo(
          PlayerProfile(
            playerId: 'p_test',
            currentLevel: 1,
            totalXp: 0,
            streak: const StreakState(
              currentStreak: 0,
              freezeTokens: 1,
              lastPlayedDate: null,
            ),
            confidenceScore: 0,
            createdAt: DateTime.now(),
          ),
        );

        final List<MethodCall> platformCalls = [];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            platformCalls.add(methodCall);
            return null;
          },
        );

        final router = GoRouter(
          initialLocation: '/splash',
          routes: [
            GoRoute(
              path: '/splash',
              builder: (context, state) => const SplashScreen(),
            ),
            ShellRoute(
              builder: (context, state, child) => AppShell(
                state: state,
                child: child,
              ),
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const HomeScreen(),
                ),
                GoRoute(
                  path: '/game/:level',
                  builder: (context, state) => const GameScreen(level: 1),
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              playerRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        // Resume lifecycle state
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();

        // 1. Splash screen animation completes (1800ms)
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 1400));
        await tester.pump(const Duration(milliseconds: 200));

        // Player is now on HomeScreen without having visited GameScreen
        expect(find.byType(HomeScreen), findsOneWidget);

        // Verify setFrameworkHandlesBack(true) was sent to Android
        final lastBackState = platformCalls
            .where((c) => c.method == 'SystemNavigator.setFrameworkHandlesBack')
            .map((c) => c.arguments as bool)
            .last;
        expect(
          lastBackState,
          isTrue,
          reason: 'Android frameworkHandlesBack must be TRUE on HomeScreen root',
        );

        // 2. Simulate Android System Back button on HomeScreen
        final handled = await WidgetsBinding.instance.handlePopRoute();
        expect(handled, isTrue);
        await tester.pump(const Duration(milliseconds: 100));

        // Verify "Keluar dari iTHUNG?" dialog is visible
        expect(find.text('Keluar dari iTHUNG?'), findsOneWidget);

        // 3. User cancels exit (taps "Batal")
        await tester.tap(find.text('Batal'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Keluar dari iTHUNG?'), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);

        // 4. Confirm exit dialog when user confirms
        await WidgetsBinding.instance.handlePopRoute();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Keluar dari iTHUNG?'), findsOneWidget);

        // Tap "Keluar"
        await tester.tap(find.text('Keluar'));
        await tester.pump(const Duration(milliseconds: 100));

        // Verify SystemNavigator.pop was called
        final popped = platformCalls.any((c) => c.method == 'SystemNavigator.pop');
        expect(popped, isTrue, reason: 'SystemNavigator.pop must be called on confirmed exit');
      },
    );
  });
}
