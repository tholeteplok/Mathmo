import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/level_score_record.dart';
import '../../../domain/models/player_profile.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../../domain/services/scoring_service.dart';
import '../../game/providers/game_dependencies_provider.dart';

/// Provider state untuk profil pemain yang sedang aktif.
final playerProfileProvider =
    AsyncNotifierProvider<PlayerProfileNotifier, PlayerProfile>(
      PlayerProfileNotifier.new,
    );

class PlayerProfileNotifier extends AsyncNotifier<PlayerProfile> {
  @override
  FutureOr<PlayerProfile> build() async {
    final repo = ref.watch(playerRepositoryProvider);
    final result = await repo.getProfile();
    if (result is RepoSuccess<PlayerProfile>) {
      return result.value;
    } else {
      throw Exception((result as RepoFailure<PlayerProfile>).reason);
    }
  }

  /// Memperbarui profil pemain di state dan menyimpannya ke penyimpanan lokal (Hive).
  Future<void> updateProfile(PlayerProfile profile) async {
    state = AsyncData(profile);
    final repo = ref.read(playerRepositoryProvider);
    await repo.saveProfile(profile);
  }

  /// Mereset state profil ke profil baru (mis. saat sign out / reset data).
  void resetProfile(PlayerProfile profile) {
    state = AsyncData(profile);
  }

  /// Menyelesaikan sesi gameplay secara atomik: menambahkan XP, skor delta, dan menaikkan level
  /// jika performa memenuhi syarat (akurasi >= 70% dan level yang dimainkan >= level saat ini).
  Future<void> completeSession({
    required int playedLevel,
    required int xpEarned,
    required double accuracy,
    int scoreDelta = 0,
  }) async {
    PlayerProfile? current = state.valueOrNull;
    if (current == null) {
      final repo = ref.read(playerRepositoryProvider);
      final res = await repo.getProfile();
      if (res is RepoSuccess<PlayerProfile>) {
        current = res.value;
      }
    }
    if (current == null) return;

    final earnedStars = ScoringService.calculateStars(accuracy);
    final shouldAdvance =
        earnedStars >= 1 && playedLevel >= current.currentLevel;
    final newLevel = shouldAdvance ? playedLevel + 1 : current.currentLevel;

    final updated = current.copyWith(
      totalXp: current.totalXp + xpEarned,
      totalScore: current.totalScore + scoreDelta,
      currentLevel: newLevel,
    );
    state = AsyncData(updated);

    final repo = ref.read(playerRepositoryProvider);
    await repo.saveProfile(updated);
  }

  /// Mencatat hasil attempt skor level dan menerapkan delta skor terbaik ke profil pemain.
  Future<({int scoreDelta, int? previousBestScore, bool isFirstPlay})>
  recordLevelScore({
    required int level,
    required int sessionScore,
    double? accuracy,
  }) async {
    final scoreRepo = ref.read(levelScoreRepositoryProvider);
    final scoringService = ref.read(scoringServiceProvider);

    final existingRecordResult = await scoreRepo.getRecord(level);
    final currentRecord = switch (existingRecordResult) {
      RepoSuccess(:final value) => value ?? LevelScoreRecord.initial(level),
      RepoFailure() => LevelScoreRecord.initial(level),
    };

    final isFirstPlay =
        currentRecord.attempts == 0 || currentRecord.bestScore == 0;
    final previousBestScore = isFirstPlay ? null : currentRecord.bestScore;

    final (:scoreDelta, :updatedRecord) = scoringService
        .computeLevelReplayDelta(
          currentRecord: currentRecord,
          newSessionScore: sessionScore,
          accuracy: accuracy,
        );

    await scoreRepo.saveRecord(updatedRecord);

    if (scoreDelta > 0) {
      await addScore(scoreDelta);
    }

    return (
      scoreDelta: scoreDelta,
      previousBestScore: previousBestScore,
      isFirstPlay: isFirstPlay,
    );
  }

  /// Menambahkan skor total pemain.
  Future<void> addScore(int scoreDelta) async {
    if (scoreDelta <= 0) return;
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.copyWith(totalScore: current.totalScore + scoreDelta);
    state = AsyncData(updated);

    final repo = ref.read(playerRepositoryProvider);
    await repo.saveProfile(updated);
  }

  /// Memperbarui level pemain dan menyimpan ke Hive.
  Future<void> updateLevel(int newLevel) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.copyWith(currentLevel: newLevel);
    state = AsyncData(updated);

    final repo = ref.read(playerRepositoryProvider);
    await repo.saveProfile(updated);
  }

  /// Menambahkan XP pemain.
  Future<void> addXp(int xpEarned) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.copyWith(totalXp: current.totalXp + xpEarned);
    state = AsyncData(updated);

    final repo = ref.read(playerRepositoryProvider);
    await repo.saveProfile(updated);
  }

  /// Mencatat aktivitas hari ini dan memperbarui status streak harian.
  Future<void> recordActivity(DateTime date) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final repo = ref.read(playerRepositoryProvider);
    final result = await repo.recordDailyActivity(date);
    if (result is RepoSuccess<PlayerProfile>) {
      state = AsyncData(result.value);
    }
  }

  /// Memperbarui avatar pemain (preset avatarId atau null untuk inisial huruf).
  Future<void> updateAvatar(String? avatarId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.copyWith(
      avatarId: avatarId,
      clearAvatar: avatarId == null,
    );
    state = AsyncData(updated);

    final repo = ref.read(playerRepositoryProvider);
    await repo.saveProfile(updated);
  }
}
