import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/models/daily_challenge.dart';
import 'package:mathmo_app/domain/models/level_score_record.dart';
import 'package:mathmo_app/domain/models/mastery_record.dart';
import 'package:mathmo_app/domain/models/player_profile.dart';
import 'package:mathmo_app/domain/models/session_result.dart';
import 'package:mathmo_app/domain/repositories/auth_repository.dart';
import 'package:mathmo_app/domain/repositories/daily_challenge_repository.dart';
import 'package:mathmo_app/domain/repositories/level_score_repository.dart';
import 'package:mathmo_app/domain/repositories/mastery_repository.dart';
import 'package:mathmo_app/domain/repositories/player_repository.dart';
import 'package:mathmo_app/domain/repositories/repo_result.dart';
import 'package:mathmo_app/domain/repositories/session_repository.dart';
import 'package:mathmo_app/presentation/game/providers/game_dependencies_provider.dart';
import 'package:mathmo_app/presentation/home/providers/level_stars_provider.dart';
import 'package:mathmo_app/presentation/home/providers/player_profile_provider.dart';
import 'package:mathmo_app/presentation/profile/providers/account_status_provider.dart';
import 'package:mathmo_app/presentation/shared/widgets/sign_out_confirm_dialog.dart';

class _FakeAuthRepo implements AuthRepository {
  bool _isLoggedIn = true;
  bool _isAnonymous = false;

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  bool get isAnonymous => _isAnonymous;

  @override
  String? get currentUserId => _isLoggedIn ? 'uid_123' : null;

  @override
  String? get currentUsername => _isLoggedIn ? 'BudiPro' : null;

  @override
  Stream<String?> get authStateChanges => Stream.value(currentUserId);

  @override
  Future<RepoResult<String>> signInAnonymously() async {
    _isLoggedIn = true;
    _isAnonymous = true;
    return const RepoSuccess('uid_anon');
  }

  @override
  Future<RepoResult<String>> signInWithGoogle() async {
    _isLoggedIn = true;
    _isAnonymous = false;
    return const RepoSuccess('uid_google');
  }

  @override
  Future<RepoResult<void>> signOut() async {
    _isLoggedIn = false;
    _isAnonymous = false;
    return const RepoSuccess(null);
  }

  @override
  Future<RepoResult<void>> setUsername(String username) async {
    return const RepoSuccess(null);
  }

  @override
  Future<RepoResult<bool>> isUsernameAvailable(String username) async {
    return const RepoSuccess(true);
  }
}

class _FakePlayerRepo implements PlayerRepository {
  _FakePlayerRepo(this.profile);
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
  Future<RepoResult<PlayerProfile>> recordDailyActivity(DateTime date) async =>
      RepoSuccess(profile);

  @override
  Future<RepoResult<PlayerProfile>> resetProfile() async {
    profile = PlayerProfile.initial(playerId: 'p_new_guest');
    return RepoSuccess(profile);
  }
}

class _FakeScoreRepo implements LevelScoreRepository {
  final Map<int, LevelScoreRecord> records = {
    1: const LevelScoreRecord(level: 1, bestScore: 200, stars: 3, attempts: 2),
    2: const LevelScoreRecord(level: 2, bestScore: 180, stars: 2, attempts: 1),
  };

  @override
  Future<RepoResult<LevelScoreRecord?>> getRecord(int level) async =>
      RepoSuccess(records[level]);

  @override
  Future<RepoResult<void>> saveRecord(LevelScoreRecord record) async {
    records[record.level] = record;
    return const RepoSuccess(null);
  }

  @override
  Future<RepoResult<Map<int, LevelScoreRecord>>> getAllRecords() async =>
      RepoSuccess(Map.unmodifiable(records));

  @override
  Future<RepoResult<void>> clearAll() async {
    records.clear();
    return const RepoSuccess(null);
  }
}

class _FakeMasteryRepo implements MasteryRepository {
  final Map<String, MasteryRecord> storage = {
    '7x8': MasteryRecord.initial('7x8'),
  };

  @override
  Future<RepoResult<MasteryRecord?>> get(String factKey) async =>
      RepoSuccess(storage[factKey]);

  @override
  Future<RepoResult<void>> save(MasteryRecord record) async {
    storage[record.factKey] = record;
    return const RepoSuccess(null);
  }

  @override
  Future<RepoResult<Map<String, MasteryRecord>>> getAll() async =>
      RepoSuccess(Map.from(storage));

  @override
  Future<RepoResult<List<MasteryRecord>>> getWeakFacts({
    int maxBox = 2,
    int limit = 10,
  }) async =>
      RepoSuccess(storage.values.toList());

  @override
  Future<RepoResult<void>> saveAll(List<MasteryRecord> records) async {
    for (final r in records) {
      storage[r.factKey] = r;
    }
    return const RepoSuccess(null);
  }

  @override
  Future<RepoResult<void>> clearAll() async {
    storage.clear();
    return const RepoSuccess(null);
  }
}

class _FakeSessionRepo implements SessionRepository {
  final List<SessionResult> sessions = [];

  @override
  Future<RepoResult<void>> saveSession(SessionResult result) async {
    sessions.add(result);
    return const RepoSuccess(null);
  }

  @override
  Future<RepoResult<List<SessionResult>>> getRecentSessions({int limit = 20}) async =>
      RepoSuccess(sessions);

  @override
  Future<RepoResult<void>> clearAll() async {
    sessions.clear();
    return const RepoSuccess(null);
  }
}

class _FakeDailyRepo implements DailyChallengeRepository {
  final Map<String, DailyChallengeResult> results = {};

  @override
  Future<RepoResult<DailyChallenge?>> getCachedChallenge(DateTime date, String band) async =>
      const RepoSuccess(null);

  @override
  Future<RepoResult<void>> cacheChallenge(DailyChallenge challenge) async =>
      const RepoSuccess(null);

  @override
  Future<RepoResult<void>> saveResult(DailyChallengeResult result) async {
    results[result.id ?? 'd_test'] = result;
    return const RepoSuccess(null);
  }

  @override
  Future<RepoResult<DailyChallengeResult?>> getResult(DateTime date, String band) async =>
      const RepoSuccess(null);

  @override
  Future<RepoResult<List<DailyChallengeResult>>> getPendingSubmissions() async =>
      const RepoSuccess([]);

  @override
  Future<RepoResult<void>> markSubmissionSynced(String id) async =>
      const RepoSuccess(null);

  @override
  Future<RepoResult<void>> clearUserData() async {
    results.clear();
    return const RepoSuccess(null);
  }
}

void main() {
  group('SignOutConfirmDialog Tests', () {
    testWidgets('Renders linked Google account dialog and handles cancel', (tester) async {
      SignOutAction? selectedAction;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedAction = await showSignOutConfirmDialog(
                  context,
                  accountStatus: AccountStatus.linked,
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Keluar dari Akun?'), findsOneWidget);
      expect(find.textContaining('Progres bermainmu aman tersimpan di akun Google'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_sign_out_cancel')));
      await tester.pumpAndSettle();

      expect(selectedAction, equals(SignOutAction.cancel));
    });

    testWidgets('Renders anonymous account dialog with link Google button', (tester) async {
      SignOutAction? selectedAction;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedAction = await showSignOutConfirmDialog(
                  context,
                  accountStatus: AccountStatus.anonymous,
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Perhatian: Akun Anonim'), findsOneWidget);
      expect(find.textContaining('tanpa menautkan akun Google'), findsOneWidget);
      expect(find.byKey(const Key('btn_sign_out_link_google')), findsOneWidget);
      expect(find.byKey(const Key('btn_sign_out_confirm')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_sign_out_link_google')));
      await tester.pumpAndSettle();

      expect(selectedAction, equals(SignOutAction.linkGoogle));
    });
  });

  group('AccountStatusNotifier.signOut clean reset tests', () {
    test('signOut resets local player profile, level scores, and stars', () async {
      final fakeAuth = _FakeAuthRepo();
      final fakePlayer = _FakePlayerRepo(
        PlayerProfile(
          playerId: 'p_google_user',
          username: 'BudiPro',
          avatarId: 'avatar_1',
          currentLevel: 17,
          totalXp: 1970,
          totalScore: 5340,
          streak: const StreakState(currentStreak: 5, freezeTokens: 2, lastPlayedDate: null),
          confidenceScore: 1,
          createdAt: DateTime.now(),
        ),
      );
      final fakeScore = _FakeScoreRepo();
      final fakeMastery = _FakeMasteryRepo();
      final fakeSession = _FakeSessionRepo();
      final fakeDaily = _FakeDailyRepo();

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuth),
          playerRepositoryProvider.overrideWithValue(fakePlayer),
          levelScoreRepositoryProvider.overrideWithValue(fakeScore),
          masteryRepositoryProvider.overrideWithValue(fakeMastery),
          sessionRepositoryProvider.overrideWithValue(fakeSession),
          dailyChallengeRepositoryProvider.overrideWithValue(fakeDaily),
        ],
      );
      addTearDown(container.dispose);

      // Preload profile and account state
      final initialProfile = await container.read(playerProfileProvider.future);
      expect(initialProfile.currentLevel, equals(17));
      expect(initialProfile.totalScore, equals(5340));
      expect(fakeScore.records.isNotEmpty, isTrue);
      expect(fakeMastery.storage.isNotEmpty, isTrue);

      // Execute signOut
      final result = await container.read(accountStatusProvider.notifier).signOut();
      expect(result is RepoSuccess, isTrue);

      // Verify AccountState is now Guest
      final accountState = container.read(accountStatusProvider).valueOrNull;
      expect(accountState?.status, equals(AccountStatus.guest));
      expect(accountState?.username, isNull);
      expect(accountState?.hasVerifiedSession, isFalse);

      // Verify local player profile was reset to Level 1, 0 XP, 0 score
      final resetProfile = container.read(playerProfileProvider).valueOrNull;
      expect(resetProfile?.currentLevel, equals(1));
      expect(resetProfile?.totalXp, equals(0));
      expect(resetProfile?.totalScore, equals(0));
      expect(resetProfile?.username, isNull);

      // Verify local repositories were completely cleared
      expect(fakeScore.records.isEmpty, isTrue);
      expect(fakeMastery.storage.isEmpty, isTrue);

      // Verify level stars were reset in memory
      final stars = container.read(levelStarsProvider).valueOrNull;
      expect(stars?.isEmpty ?? true, isTrue);
    });
  });
}
