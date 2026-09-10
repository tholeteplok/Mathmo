import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/firebase_error_mapper.dart';
import '../../domain/models/daily_challenge.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../../domain/repositories/repo_result.dart';

/// Implementasi [LeaderboardRepository] menggunakan Cloud Firestore.
class FirebaseLeaderboardRepository implements LeaderboardRepository {
  FirebaseLeaderboardRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore,
        _auth = auth;

  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;
  FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;

  static const String collectionName = 'daily_challenge_results';
  static const String profilesCollection = 'profiles';

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

      // Query server-side dengan orderBy + limit (butuh composite index
      // band ASC + date ASC + correct_count DESC, lihat firestore.indexes.json).
      // Tie-break total_time_ms tetap di memori untuk halaman teratas.
      final snapshot = await firestore
          .collection(collectionName)
          .where('band', isEqualTo: band)
          .where('date', isEqualTo: dateKey)
          .orderBy('correct_count', descending: true)
          .limit(limit)
          .get()
          .timeout(const Duration(seconds: 10));

      // Parsing dan sorting di memori (correct_count desc, total_time_ms asc)
      final sortedDocs = snapshot.docs.map((doc) => doc.data()).toList()
        ..sort((a, b) {
          final cA = ((a['correct_count'] ?? 0) as num).toInt();
          final cB = ((b['correct_count'] ?? 0) as num).toInt();
          final comp = cB.compareTo(cA);
          if (comp != 0) return comp;
          final tA = ((a['total_time_ms'] ?? 0) as num).toInt();
          final tB = ((b['total_time_ms'] ?? 0) as num).toInt();
          return tA.compareTo(tB);
        });

      final entries = <LeaderboardEntry>[];
      var rank = 1;
      bool playerFound = false;

      for (var i = 0; i < sortedDocs.length; i++) {
        final data = sortedDocs[i];
        final username = (data['username'] ?? 'Pemain') as String;
        final isCurrent = currentPlayerUsername != null &&
            username.toLowerCase() == currentPlayerUsername.toLowerCase();

        if (isCurrent) {
          playerFound = true;
        }

        if (i < limit) {
          entries.add(
            LeaderboardEntry(
              rank: rank++,
              username: username,
              avatarId: data['avatar_id'] as String?,
              correctCount: ((data['correct_count'] ?? 0) as num).toInt(),
              totalTimeMs: ((data['total_time_ms'] ?? 0) as num).toInt(),
              isCurrentPlayer: isCurrent,
            ),
          );
        } else if (playerFound && isCurrent) {
          // Pemain berada di luar top-limit, sisipkan posisinya di paling bawah
          entries.add(
            LeaderboardEntry(
              rank: i + 1,
              username: username,
              avatarId: data['avatar_id'] as String?,
              correctCount: ((data['correct_count'] ?? 0) as num).toInt(),
              totalTimeMs: ((data['total_time_ms'] ?? 0) as num).toInt(),
              isCurrentPlayer: true,
            ),
          );
          break;
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
      final cleanUsername = username.trim().toLowerCase();
      final docId = '${dateKey}_${band}_$cleanUsername';
      final col = firestore.collection(collectionName);

      // 1. Ambil dokumen pemain langsung (tanpa scan koleksi).
      final doc = await col.doc(docId).get().timeout(
        const Duration(seconds: 10),
      );
      if (!doc.exists) {
        // Fallback: dokumen lama memakai username case-asli.
        final legacy = await col
            .where('band', isEqualTo: band)
            .where('date', isEqualTo: dateKey)
            .where('username', isEqualTo: username)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10));
        if (legacy.docs.isEmpty) return const RepoSuccess(null);
        final data = legacy.docs.first.data();
        return RepoSuccess(
          LeaderboardEntry(
            rank: -1, // rank tidak diketahui tanpa scan; UI pakai fetchTopEntries
            username: (data['username'] ?? username) as String,
            avatarId: data['avatar_id'] as String?,
            correctCount: ((data['correct_count'] ?? 0) as num).toInt(),
            totalTimeMs: ((data['total_time_ms'] ?? 0) as num).toInt(),
            isCurrentPlayer: true,
          ),
        );
      }

      final data = doc.data()!;
      final mineCorrect = ((data['correct_count'] ?? 0) as num).toInt();
      final mineTime = ((data['total_time_ms'] ?? 0) as num).toInt();

      // 2. Hitung rank via agregasi count (tanpa unduh dokumen lain).
      final baseQuery = col
          .where('band', isEqualTo: band)
          .where('date', isEqualTo: dateKey);
      final better = await baseQuery
          .where('correct_count', isGreaterThan: mineCorrect)
          .count()
          .get()
          .timeout(const Duration(seconds: 10));
      final tiedFaster = await baseQuery
          .where('correct_count', isEqualTo: mineCorrect)
          .where('total_time_ms', isLessThan: mineTime)
          .count()
          .get()
          .timeout(const Duration(seconds: 10));
      final rank =
          ((better.count ?? 0) + (tiedFaster.count ?? 0)) + 1;

      return RepoSuccess(
        LeaderboardEntry(
          rank: rank,
          username: (data['username'] ?? username) as String,
          avatarId: data['avatar_id'] as String?,
          correctCount: mineCorrect,
          totalTimeMs: mineTime,
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
  Future<RepoResult<List<LeaderboardEntry>>> fetchAllTimeEntries({
    int limit = 50,
    String? currentPlayerUsername,
  }) async {
    try {
      // Query /profiles diurutkan by total_score desc (single-field, tidak butuh Composite Index)
      final snapshot = await firestore
          .collection(profilesCollection)
          .orderBy('total_score', descending: true)
          .limit(limit)
          .get()
          .timeout(const Duration(seconds: 10));

      final entries = <LeaderboardEntry>[];
      var rank = 1;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final username = (data['username'] ?? '') as String;
        if (username.isEmpty) continue; // skip profil tanpa username

        final isCurrent = currentPlayerUsername != null &&
            username.toLowerCase() == currentPlayerUsername.toLowerCase();

        entries.add(
          LeaderboardEntry(
            rank: rank++,
            username: username,
            avatarId: data['avatar_id'] as String?,
            correctCount: 0,
            totalTimeMs: 0,
            isCurrentPlayer: isCurrent,
            totalScore: data['total_score'] != null
                ? ((data['total_score']) as num).toInt()
                : 0,
          ),
        );
      }

      return RepoSuccess(entries);
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(e, defaultMessage: 'Gagal memuat papan all-time'),
        e,
      );
    }
  }

  @override
  Future<RepoResult<void>> submitDailyResult({
    required DailyChallengeResult result,
    required String username,
    String? avatarId,
    int? totalScore,
  }) async {
    try {
      final dateKey = _formatDateKey(result.date);
      final cleanUsername = username.trim().toLowerCase();
      final docId = '${dateKey}_${result.band}_$cleanUsername';

      final currentUid = auth.currentUser?.uid ?? result.playerId;

      // 1. Simpan hasil daily challenge
      await firestore.collection(collectionName).doc(docId).set({
        'player_id': currentUid,
        'username': username,
        'avatar_id': avatarId,
        'band': result.band,
        'date': dateKey,
        'correct_count': result.correctCount,
        'total_time_ms': result.totalTimeMs,
        'submitted_at': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      // 2. Sinkronisasi total_score + avatar_id ke /profiles/{currentUid}
      //    agar all-time leaderboard selalu up-to-date
      if (totalScore != null) {
        await firestore
            .collection(profilesCollection)
            .doc(currentUid)
            .set({
              'username': username,
              'avatar_id': avatarId,
              'total_score': totalScore,
              'updated_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 10));
      }

      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(e, defaultMessage: 'Gagal mengunggah skor tantangan harian'),
        e,
      );
    }
  }
}
