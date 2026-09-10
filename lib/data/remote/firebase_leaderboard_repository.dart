import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/firebase_error_mapper.dart';
import '../../domain/models/daily_challenge.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../../domain/repositories/repo_result.dart';

/// Implementasi [LeaderboardRepository] menggunakan Cloud Firestore.
class FirebaseLeaderboardRepository implements LeaderboardRepository {
  FirebaseLeaderboardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;

  static const String collectionName = 'daily_challenge_results';

  static String _formatDateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<RepoResult<List<LeaderboardEntry>>> fetchTopEntries({
    required String band,
    required DateTime date,
    int limit = 50,
    String? currentPlayerUsername,
  }) async {
    try {
      final dateKey = _formatDateKey(date);

      final snapshot = await firestore
          .collection(collectionName)
          .where('band', isEqualTo: band)
          .where('date', isEqualTo: dateKey)
          .orderBy('correct_count', descending: true)
          .orderBy('total_time_ms', descending: false)
          .limit(limit)
          .get()
          .timeout(const Duration(seconds: 10));

      final entries = <LeaderboardEntry>[];
      var rank = 1;
      bool playerFound = false;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final username = (data['username'] ?? 'Pemain') as String;
        final isCurrent = currentPlayerUsername != null &&
            username.toLowerCase() == currentPlayerUsername.toLowerCase();

        if (isCurrent) {
          playerFound = true;
        }

        entries.add(
          LeaderboardEntry(
            rank: rank++,
            username: username,
            avatarId: data['avatar_id'] as String?,
            correctCount: ((data['correct_count']) as num).toInt(),
            totalTimeMs: ((data['total_time_ms']) as num).toInt(),
            isCurrentPlayer: isCurrent,
          ),
        );
      }

      // Jika pemain saat ini sudah submit tetapi tidak masuk top-N, sisipkan di bawah
      if (!playerFound && currentPlayerUsername != null) {
        final playerEntryResult = await getPlayerEntry(
          band: band,
          date: date,
          username: currentPlayerUsername,
        );
        if (playerEntryResult is RepoSuccess<LeaderboardEntry?> &&
            playerEntryResult.value != null) {
          entries.add(playerEntryResult.value!);
        }
      }

      return RepoSuccess(entries);
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(e, defaultMessage: 'Gagal memuat papan peringkat'),
        e,
      );
    }
  }

  @override
  Future<RepoResult<LeaderboardEntry?>> getPlayerEntry({
    required String band,
    required DateTime date,
    required String username,
  }) async {
    try {
      final dateKey = _formatDateKey(date);

      final query = await firestore
          .collection(collectionName)
          .where('band', isEqualTo: band)
          .where('date', isEqualTo: dateKey)
          .where('username', isEqualTo: username)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      if (query.docs.isEmpty) {
        return const RepoSuccess(null);
      }

      final myDoc = query.docs.first.data();
      final myCorrect = (myDoc['correct_count'] as num).toInt();
      final myTime = (myDoc['total_time_ms'] as num).toInt();

      // Hitung rank pemain: berapa banyak pemain dengan skor lebih baik
      final aheadCountQuery = await firestore
          .collection(collectionName)
          .where('band', isEqualTo: band)
          .where('date', isEqualTo: dateKey)
          .where('correct_count', isGreaterThan: myCorrect)
          .count()
          .get()
          .timeout(const Duration(seconds: 10));

      final higherScoreCount = aheadCountQuery.count ?? 0;

      final sameScoreFasterQuery = await firestore
          .collection(collectionName)
          .where('band', isEqualTo: band)
          .where('date', isEqualTo: dateKey)
          .where('correct_count', isEqualTo: myCorrect)
          .where('total_time_ms', isLessThan: myTime)
          .count()
          .get()
          .timeout(const Duration(seconds: 10));

      final fasterCount = sameScoreFasterQuery.count ?? 0;
      final myRank = higherScoreCount + fasterCount + 1;

      return RepoSuccess(
        LeaderboardEntry(
          rank: myRank,
          username: username,
          avatarId: myDoc['avatar_id'] as String?,
          correctCount: myCorrect,
          totalTimeMs: myTime,
          isCurrentPlayer: true,
        ),
      );
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(e, defaultMessage: 'Gagal menghitung posisi pemain'),
        e,
      );
    }
  }

  @override
  Future<RepoResult<void>> submitDailyResult({
    required DailyChallengeResult result,
    required String username,
    String? avatarId,
  }) async {
    try {
      final dateKey = _formatDateKey(result.date);
      final docId = '${dateKey}_${result.band}_$username';

      await firestore.collection(collectionName).doc(docId).set({
        'player_id': result.playerId,
        'username': username,
        'avatar_id': avatarId,
        'band': result.band,
        'date': dateKey,
        'correct_count': result.correctCount,
        'total_time_ms': result.totalTimeMs,
        'submitted_at': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(e, defaultMessage: 'Gagal mengunggah skor tantangan harian'),
        e,
      );
    }
  }
}
