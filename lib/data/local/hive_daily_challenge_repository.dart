import 'package:hive_ce/hive.dart';

import '../../domain/models/daily_challenge.dart';
import '../../domain/repositories/daily_challenge_repository.dart';
import '../../domain/repositories/repo_result.dart';

/// Implementasi persistensi [DailyChallengeRepository] menggunakan Hive CE.
class HiveDailyChallengeRepository implements DailyChallengeRepository {
  HiveDailyChallengeRepository([
    Box<Map>? challengeBox,
    Box<Map>? resultBox,
    Box<Map>? pendingBox,
  ]) : _challengeBox = challengeBox,
       _resultBox = resultBox,
       _pendingBox = pendingBox;

  static const String challengeBoxName = 'daily_challenges';
  static const String resultBoxName = 'daily_challenge_results';
  static const String pendingBoxName = 'daily_challenge_pending';

  Box<Map>? _challengeBox;
  Box<Map>? _resultBox;
  Box<Map>? _pendingBox;

  Future<Box<Map>> _getChallengeBox() async {
    if (_challengeBox != null && _challengeBox!.isOpen) return _challengeBox!;
    _challengeBox = await Hive.openBox<Map>(challengeBoxName);
    return _challengeBox!;
  }

  Future<Box<Map>> _getResultBox() async {
    if (_resultBox != null && _resultBox!.isOpen) return _resultBox!;
    _resultBox = await Hive.openBox<Map>(resultBoxName);
    return _resultBox!;
  }

  Future<Box<Map>> _getPendingBox() async {
    if (_pendingBox != null && _pendingBox!.isOpen) return _pendingBox!;
    _pendingBox = await Hive.openBox<Map>(pendingBoxName);
    return _pendingBox!;
  }

  static String _formatDateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<RepoResult<DailyChallenge?>> getCachedChallenge(
    DateTime date,
    String band,
  ) async {
    try {
      final box = await _getChallengeBox();
      final key = '${_formatDateKey(date)}_$band';
      final raw = box.get(key);
      if (raw == null) return const RepoSuccess(null);
      return RepoSuccess(
        DailyChallenge.fromJson(Map<String, dynamic>.from(raw)),
      );
    } catch (e) {
      return RepoFailure('Gagal memuat cache tantangan harian', e);
    }
  }

  @override
  Future<RepoResult<void>> cacheChallenge(DailyChallenge challenge) async {
    try {
      final box = await _getChallengeBox();
      final key = '${_formatDateKey(challenge.date)}_${challenge.band}';
      await box.put(key, challenge.toJson());
      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure('Gagal menyimpan cache tantangan harian', e);
    }
  }

  @override
  Future<RepoResult<void>> saveResult(DailyChallengeResult result) async {
    try {
      final box = await _getResultBox();
      final dateKey = _formatDateKey(result.date);
      final key = '${dateKey}_${result.band}';
      await box.put(key, result.toJson());

      // Juga masukkan ke antrian pending submissions
      final pending = await _getPendingBox();
      await pending.put(key, result.toJson());

      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure('Gagal menyimpan hasil tantangan harian', e);
    }
  }

  @override
  Future<RepoResult<DailyChallengeResult?>> getResult(
    DateTime date,
    String band,
  ) async {
    try {
      final box = await _getResultBox();
      final dateKey = _formatDateKey(date);
      final key = '${dateKey}_$band';
      var raw = box.get(key);

      // Fallback untuk key versi legacy yang memuat timestamp lengkap
      if (raw == null) {
        for (final k in box.keys) {
          final kStr = k.toString();
          if (kStr.startsWith(dateKey) && kStr.endsWith('_$band')) {
            raw = box.get(k);
            break;
          }
        }
      }

      if (raw == null) return const RepoSuccess(null);
      return RepoSuccess(
        DailyChallengeResult.fromJson(Map<String, dynamic>.from(raw)),
      );
    } catch (e) {
      return RepoFailure('Gagal memuat hasil tantangan harian', e);
    }
  }

  @override
  Future<RepoResult<List<DailyChallengeResult>>> getPendingSubmissions() async {
    try {
      final box = await _getPendingBox();
      final results = <DailyChallengeResult>[];
      for (final raw in box.values) {
        results.add(
          DailyChallengeResult.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
      return RepoSuccess(results);
    } catch (e) {
      return RepoFailure('Gagal memuat antrian submission', e);
    }
  }

  @override
  Future<RepoResult<void>> markSubmissionSynced(String id) async {
    try {
      final box = await _getPendingBox();
      await box.delete(id);
      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure('Gagal menghapus antrian submission terkirim', e);
    }
  }
}
