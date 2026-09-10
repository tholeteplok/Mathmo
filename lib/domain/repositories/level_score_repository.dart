import '../models/level_score_record.dart';
import 'repo_result.dart';

/// Antarmuka repositori untuk persistensi rekor skor level (discrete node).
///
/// Pure Dart interface tanpa dependensi UI.
abstract interface class LevelScoreRepository {
  /// Mengambil rekor skor untuk [level] tertentu, mengembalikan null jika belum pernah dimainkan.
  Future<RepoResult<LevelScoreRecord?>> getRecord(int level);

  /// Menyimpan atau memperbarui [record] skor level.
  Future<RepoResult<void>> saveRecord(LevelScoreRecord record);

  /// Mengambil seluruh rekor skor level yang tersimpan (dimetakan berdasarkan nomor level).
  Future<RepoResult<Map<int, LevelScoreRecord>>> getAllRecords();
}
