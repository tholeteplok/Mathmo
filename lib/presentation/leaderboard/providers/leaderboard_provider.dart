import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/leaderboard_entry.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../game/providers/game_dependencies_provider.dart';
import '../../game/providers/level_band_theme_provider.dart';
import '../../home/providers/player_profile_provider.dart';
import '../../profile/providers/account_status_provider.dart';

/// Provider untuk band level yang sedang aktif dipilih pada tab Leaderboard.
final leaderboardSelectedBandProvider = StateProvider<String>((ref) {
  final level = ref.watch(playerProfileProvider).valueOrNull?.currentLevel ?? 1;
  final config = ref.watch(levelBandsConfigProvider).valueOrNull;
  return config?.bandForLevel(level).id ?? 'onboarding';
});

/// Provider untuk memuat daftar entri leaderboard per band level.
final leaderboardEntriesProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>((ref, band) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  final accountState = ref.watch(accountStatusProvider).valueOrNull;
  final username = accountState?.username;
  final now = DateTime.now();

  final result = await repo.fetchTopEntries(
    band: band,
    date: now,
    limit: 50,
    currentPlayerUsername: username,
  );

  return switch (result) {
    RepoSuccess(:final value) => value,
    RepoFailure(:final reason) => throw Exception(reason),
  };
});
