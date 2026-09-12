import '../models/mastery_record.dart';
import 'repo_result.dart';

/// Abstraksi penyimpanan data Mastery + Mistake Bank per pemain.
///
/// Menyimpan riwayat penguasaan fakta aritmatika (`fact_key` -> `MasteryRecord`).
/// Implementasi konkret ada di `lib/data/local/hive_mastery_repository.dart`.
abstract interface class MasteryRepository {
  /// Mengambil record mastery untuk satu [factKey] spesifik.
  Future<RepoResult<MasteryRecord?>> get(String factKey);

  /// Menyimpan atau memperbarui [record] mastery.
  Future<RepoResult<void>> save(MasteryRecord record);

  /// Mengambil semua record mastery yang tersimpan.
  Future<RepoResult<Map<String, MasteryRecord>>> getAll();

  /// Mengambil daftar fakta lemah (mis. [maxBox] <= 2) untuk interleaving / practice mode.
  Future<RepoResult<List<MasteryRecord>>> getWeakFacts({
    int maxBox = 2,
    int limit = 10,
  });

  /// Menyimpan batch record sekaligus.
  Future<RepoResult<void>> saveAll(List<MasteryRecord> records);

  /// Menghapus seluruh data mastery (mis. saat sign out).
  Future<RepoResult<void>> clearAll();
}
