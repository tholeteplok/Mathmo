import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/level_score_record.dart';
import '../../../domain/models/session_result.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../../domain/services/scoring_service.dart';
import '../../game/providers/game_dependencies_provider.dart';

/// Provider reaktif yang memetakan level permainan ke jumlah bintang yang diperoleh (1..3)
/// berdasarkan akurasi tertinggi pemain dalam riwayat sesi [SessionResult].
///
/// Menggunakan [AsyncNotifier] agar perolehan bintang dapat di-update seketika (0 ms delay)
/// di memori saat ronde level tuntas.
///
/// Logika konversi akurasi ke bintang:
/// - Akurasi >= 90% (0.9): 3 Bintang (★★★)
/// - Akurasi >= 70% (0.7): 2 Bintang (★★☆)
/// - Akurasi < 70%: 1 Bintang (★☆☆)
final levelStarsProvider =
    AsyncNotifierProvider<LevelStarsNotifier, Map<int, int>>(
  LevelStarsNotifier.new,
);

class LevelStarsNotifier extends AsyncNotifier<Map<int, int>> {
  @override
  Future<Map<int, int>> build() async {
    final sessionRepo = ref.watch(sessionRepositoryProvider);
    final scoreRepo = ref.watch(levelScoreRepositoryProvider);

    final Map<int, int> starsMap = {};

    // 1. Baca dari rekor level terpusat (Hive box: level_scores)
    final recordsResult = await scoreRepo.getAllRecords();
    if (recordsResult is RepoSuccess<Map<int, LevelScoreRecord>>) {
      for (final entry in recordsResult.value.entries) {
        if (entry.value.stars > 0) {
          starsMap[entry.key] = entry.value.stars;
        }
      }
    }

    // 2. Baca dari riwayat sesi lokal (jika ada sesi baru yang lebih tinggi)
    final sessionResult = await sessionRepo.getRecentSessions(limit: 100);
    if (sessionResult is RepoSuccess<List<SessionResult>>) {
      for (final session in sessionResult.value) {
        final level = session.levelReached;
        final accuracy = session.accuracy;
        final stars = calculateStars(accuracy);
        final currentBest = starsMap[level] ?? 0;
        if (stars > currentBest) {
          starsMap[level] = stars;
        }
      }
    }

    return starsMap;
  }

  /// Menghitung jumlah bintang berdasarkan akurasi (0.0 .. 1.0).
  static int calculateStars(double accuracy) =>
      ScoringService.calculateStars(accuracy);

  /// Memperbarui perolehan bintang untuk [level] secara instan di memori (0 ms delay).
  void recordStars({required int level, required double accuracy}) {
    final earnedStars = calculateStars(accuracy);
    final currentMap = state.valueOrNull ?? {};
    final currentBest = currentMap[level] ?? 0;
    if (earnedStars > currentBest) {
      final newMap = Map<int, int>.from(currentMap);
      newMap[level] = earnedStars;
      state = AsyncData(newMap);
    }
  }

  /// Memulihkan perolehan bintang dari Cloud/Cache ke memori secara instan.
  void restoreStars(Map<int, int> restoredMap) {
    if (restoredMap.isEmpty) return;
    final currentMap = Map<int, int>.from(state.valueOrNull ?? {});
    for (final entry in restoredMap.entries) {
      final old = currentMap[entry.key] ?? 0;
      if (entry.value > old) {
        currentMap[entry.key] = entry.value;
      }
    }
    state = AsyncData(currentMap);
  }
}
