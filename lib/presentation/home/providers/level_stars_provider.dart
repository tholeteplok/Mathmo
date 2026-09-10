import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/session_result.dart';
import '../../../domain/repositories/repo_result.dart';
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
    final result = await sessionRepo.getRecentSessions(limit: 100);

    if (result is! RepoSuccess<List<SessionResult>>) {
      return const {};
    }

    final Map<int, int> starsMap = {};

    for (final session in result.value) {
      final level = session.levelReached;
      final accuracy = session.accuracy;

      final stars = calculateStars(accuracy);
      final currentBest = starsMap[level] ?? 0;
      if (stars > currentBest) {
        starsMap[level] = stars;
      }
    }

    return starsMap;
  }

  /// Menghitung jumlah bintang berdasarkan akurasi (0.0 .. 1.0).
  static int calculateStars(double accuracy) {
    if (accuracy >= 0.9) {
      return 3;
    } else if (accuracy >= 0.7) {
      return 2;
    } else {
      return 1;
    }
  }

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
}
