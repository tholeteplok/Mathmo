import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/models/player_profile.dart';
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
    expect(profile.streak.currentStreak, equals(3));
  });
}
