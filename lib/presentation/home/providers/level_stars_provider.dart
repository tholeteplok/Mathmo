import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/session_result.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../game/providers/game_dependencies_provider.dart';

/// Provider yang memetakan level permainan ke jumlah bintang yang diperoleh (1..3)
/// berdasarkan akurasi tertinggi pemain dalam riwayat sesi [SessionResult].
///
/// Logika konversi akurasi ke bintang:
/// - Akurasi >= 90% (0.9): 3 Bintang (★★★)
/// - Akurasi >= 70% (0.7): 2 Bintang (★★☆)
/// - Akurasi < 70%: 1 Bintang (★☆☆)
final levelStarsProvider = FutureProvider<Map<int, int>>((ref) async {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final result = await sessionRepo.getRecentSessions(limit: 100);

  if (result is! RepoSuccess<List<SessionResult>>) {
    return const {};
  }

  final Map<int, int> starsMap = {};

  for (final session in result.value) {
    final level = session.levelReached;
    final accuracy = session.accuracy;

    final int stars;
    if (accuracy >= 0.9) {
      stars = 3;
    } else if (accuracy >= 0.7) {
      stars = 2;
    } else {
      stars = 1;
    }

    final currentBest = starsMap[level] ?? 0;
    if (stars > currentBest) {
      starsMap[level] = stars;
    }
  }

  return starsMap;
});
