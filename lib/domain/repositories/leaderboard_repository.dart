import '../models/daily_challenge.dart';
import '../models/leaderboard_entry.dart';
import 'repo_result.dart';

/// Kontrak repositori untuk papan peringkat (Leaderboard).
abstract class LeaderboardRepository {
  /// Mengambil daftar top-N entri papan peringkat untuk band dan tanggal tertentu.
  /// Menandai [currentPlayerUsername] dengan `isCurrentPlayer = true`.
  Future<RepoResult<List<LeaderboardEntry>>> fetchTopEntries({
    required String band,
    required DateTime date,
    int limit = 50,
    String? currentPlayerUsername,
  });

  /// Mengambil entri posisi pemain tertentu jika tidak masuk di top-N.
  Future<RepoResult<LeaderboardEntry?>> getPlayerEntry({
    required String band,
    required DateTime date,
    required String username,
  });

  /// Mengambil daftar top-N entri papan peringkat all-time (total skor akumulatif).
  Future<RepoResult<List<LeaderboardEntry>>> fetchAllTimeEntries({
    int limit = 50,
    String? currentPlayerUsername,
  });

  /// Mengunggah hasil tantangan harian pemain ke cloud papan peringkat.
  Future<RepoResult<void>> submitDailyResult({
    required DailyChallengeResult result,
    required String username,
    String? avatarId,
    int? totalScore,
  });
}
