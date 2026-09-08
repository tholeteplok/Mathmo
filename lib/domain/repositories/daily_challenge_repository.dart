import '../models/daily_challenge.dart';
import 'repo_result.dart';

/// Abstraksi penyimpanan tantangan harian (Daily Challenge).
///
/// Mengatur cache tantangan per hari/band dan antrian submission yang tertunda.
abstract interface class DailyChallengeRepository {
  /// Mengambil cache soal tantangan untuk [date] dan [band].
  Future<RepoResult<DailyChallenge?>> getCachedChallenge(
    DateTime date,
    String band,
  );

  /// Menyimpan cache soal tantangan harian.
  Future<RepoResult<void>> cacheChallenge(DailyChallenge challenge);

  /// Menyimpan hasil pengerjaan tantangan harian.
  Future<RepoResult<void>> saveResult(DailyChallengeResult result);

  /// Mengambil hasil pengerjaan tantangan harian pemain untuk hari ini jika sudah pernah main.
  Future<RepoResult<DailyChallengeResult?>> getResult(
    DateTime date,
    String band,
  );

  /// Mengambil daftar submission hasil yang belum berhasil dikirim ke server.
  Future<RepoResult<List<DailyChallengeResult>>> getPendingSubmissions();

  /// Menghapus submission dari antrian setelah berhasil terkirim.
  Future<RepoResult<void>> markSubmissionSynced(String id);
}
