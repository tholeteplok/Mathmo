import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/models/level_score_record.dart';
import 'package:mathmo_app/domain/models/player_profile.dart';
import 'package:mathmo_app/domain/repositories/level_score_repository.dart';
import 'package:mathmo_app/domain/repositories/player_repository.dart';
import 'package:mathmo_app/domain/repositories/repo_result.dart';
import 'package:mathmo_app/presentation/game/providers/game_dependencies_provider.dart';
import 'package:mathmo_app/presentation/home/providers/player_profile_provider.dart';

class _FakePlayerRepository implements PlayerRepository {
  _FakePlayerRepository(this._profile);
  PlayerProfile _profile;

  @override
  Future<RepoResult<PlayerProfile>> getProfile() async => RepoSuccess(_profile);

  @override
  Future<RepoResult<void>> saveProfile(PlayerProfile profile) async {
    _profile = profile;
    return const RepoSuccess(null);
  }

  @override
  Future<RepoResult<void>> updateLevel(int newLevel) async {
    _profile = _profile.copyWith(currentLevel: newLevel);
    return const RepoSuccess(null);
  }

  @override
  Future<RepoResult<PlayerProfile>> recordDailyActivity(DateTime date) async {
    return RepoSuccess(_profile);
  }

  @override
  Future<RepoResult<PlayerProfile>> resetProfile() async {
    _profile = PlayerProfile.initial(playerId: 'test_p');
    return RepoSuccess(_profile);
  }
}

class _FakeLevelScoreRepository implements LevelScoreRepository {
  final Map<int, LevelScoreRecord> records = {};

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

void main() {
  test('Atomic completeSession updates both level and totalXp safely', () async {
    final fakeRepo = _FakePlayerRepository(
      PlayerProfile(
        playerId: 'test_p',
        currentLevel: 1,
        totalXp: 0,
        streak: const StreakState(currentStreak: 0, freezeTokens: 1, lastPlayedDate: null),
        confidenceScore: 0,
        createdAt: DateTime.now(),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        playerRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    // Initial load
    final initialProfile = await container.read(playerProfileProvider.future);
    expect(initialProfile.currentLevel, equals(1));

    // Call atomic completeSession
    await container.read(playerProfileProvider.notifier).completeSession(
      playedLevel: 1,
      xpEarned: 150,
      accuracy: 0.8,
    );

    final updatedProfile = container.read(playerProfileProvider).valueOrNull;
    expect(updatedProfile?.currentLevel, equals(2));
    expect(updatedProfile?.totalXp, equals(150));
    expect(fakeRepo._profile.currentLevel, equals(2));
    expect(fakeRepo._profile.totalXp, equals(150));
  });

  test('PlayerProfile.fromJson safely deserializes Hive _Map<dynamic, dynamic>', () {
    final hiveMap = <dynamic, dynamic>{
      'player_id': 'p_123',
      'current_level': 2,
      'total_xp': 250,
      'streak': <dynamic, dynamic>{
        'current_streak': 3,
        'freeze_tokens': 1,
        'last_played_date': '2026-09-08',
      },
      'confidence_score': 1,
      'created_at': DateTime.now().toIso8601String(),
    };

    final profile = PlayerProfile.fromJson(Map<String, dynamic>.from(hiveMap));
    expect(profile.playerId, equals('p_123'));
    expect(profile.currentLevel, equals(2));
    expect(profile.totalXp, equals(250));
    expect(profile.totalScore, equals(0)); // default when omitted
    expect(profile.streak.currentStreak, equals(3));
  });

  test('PlayerProfile deserializes total_score when present', () {
    final hiveMap = <dynamic, dynamic>{
      'player_id': 'p_123',
      'current_level': 1,
      'total_xp': 100,
      'total_score': 350,
      'streak': <dynamic, dynamic>{
        'current_streak': 1,
        'freeze_tokens': 1,
        'last_played_date': null,
      },
      'confidence_score': 0,
      'created_at': DateTime.now().toIso8601String(),
    };

    final profile = PlayerProfile.fromJson(Map<String, dynamic>.from(hiveMap));
    expect(profile.totalScore, equals(350));
  });

  test('completeSession adds scoreDelta to totalScore atomically', () async {
    final fakeRepo = _FakePlayerRepository(
      PlayerProfile(
        playerId: 'test_p',
        currentLevel: 1,
        totalXp: 50,
        totalScore: 100,
        streak: const StreakState(
          currentStreak: 0,
          freezeTokens: 1,
          lastPlayedDate: null,
        ),
        confidenceScore: 0,
        createdAt: DateTime.now(),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        playerRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(playerProfileProvider.notifier).completeSession(
      playedLevel: 1,
      xpEarned: 20,
      accuracy: 0.9,
      scoreDelta: 50,
    );

    final profile = container.read(playerProfileProvider).valueOrNull;
    expect(profile?.totalScore, equals(150));
    expect(profile?.totalXp, equals(70));
    expect(profile?.currentLevel, equals(2));
  });

  test('recordLevelScore calculates delta and updates totalScore and repository', () async {
    final fakePlayerRepo = _FakePlayerRepository(
      PlayerProfile(
        playerId: 'test_p',
        currentLevel: 2,
        totalXp: 100,
        totalScore: 200,
        streak: const StreakState(
          currentStreak: 0,
          freezeTokens: 1,
          lastPlayedDate: null,
        ),
        confidenceScore: 0,
        createdAt: DateTime.now(),
      ),
    );
    final fakeScoreRepo = _FakeLevelScoreRepository();

    final container = ProviderContainer(
      overrides: [
        playerRepositoryProvider.overrideWithValue(fakePlayerRepo),
        levelScoreRepositoryProvider.overrideWithValue(fakeScoreRepo),
      ],
    );
    addTearDown(container.dispose);

    // Initial load
    await container.read(playerProfileProvider.future);

    // First attempt on level 1: 150 points
    final res1 =
        await container.read(playerProfileProvider.notifier).recordLevelScore(
          level: 1,
          sessionScore: 150,
        );

    expect(res1.scoreDelta, equals(150));
    expect(res1.previousBestScore, isNull);
    expect(res1.isFirstPlay, isTrue);
    expect(fakeScoreRepo.records[1]?.bestScore, equals(150));
    expect(fakeScoreRepo.records[1]?.attempts, equals(1));
    expect(
      container.read(playerProfileProvider).valueOrNull?.totalScore,
      equals(350),
    );

    // Second attempt on level 1 with lower score: 120 points
    final res2 =
        await container.read(playerProfileProvider.notifier).recordLevelScore(
          level: 1,
          sessionScore: 120,
        );

    expect(res2.scoreDelta, equals(0));
    expect(res2.previousBestScore, equals(150));
    expect(res2.isFirstPlay, isFalse);
    expect(fakeScoreRepo.records[1]?.bestScore, equals(150));
    expect(fakeScoreRepo.records[1]?.attempts, equals(2));
    expect(
      container.read(playerProfileProvider).valueOrNull?.totalScore,
      equals(350),
    );

    // Third attempt on level 1 with higher score: 180 points (+30 delta)
    final res3 =
        await container.read(playerProfileProvider.notifier).recordLevelScore(
          level: 1,
          sessionScore: 180,
        );

    expect(res3.scoreDelta, equals(30));
    expect(res3.previousBestScore, equals(150));
    expect(res3.isFirstPlay, isFalse);
    expect(fakeScoreRepo.records[1]?.bestScore, equals(180));
    expect(fakeScoreRepo.records[1]?.attempts, equals(3));
    expect(
      container.read(playerProfileProvider).valueOrNull?.totalScore,
      equals(380),
    );
  });
}
