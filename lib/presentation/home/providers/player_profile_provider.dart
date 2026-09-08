import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/player_profile.dart';
import '../../../domain/repositories/repo_result.dart';
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

  /// Menyelesaikan sesi gameplay secara atomik: menambahkan XP dan menaikkan level
  /// jika performa memenuhi syarat (akurasi >= 70% dan level yang dimainkan >= level saat ini).
  Future<void> completeSession({
    required int playedLevel,
    required int xpEarned,
    required double accuracy,
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

    final shouldAdvance =
        accuracy >= 0.7 && playedLevel >= current.currentLevel;
    final newLevel = shouldAdvance ? playedLevel + 1 : current.currentLevel;

    final updated = current.copyWith(
      totalXp: current.totalXp + xpEarned,
      currentLevel: newLevel,
    );
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
}
