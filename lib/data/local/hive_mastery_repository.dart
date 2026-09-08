import 'package:hive_ce/hive.dart';

import '../../domain/models/mastery_record.dart';
import '../../domain/repositories/mastery_repository.dart';
import '../../domain/repositories/repo_result.dart';

/// Implementasi persistensi [MasteryRepository] menggunakan Hive CE.
///
/// Menyimpan map serialisasi JSON dari [MasteryRecord] untuk tiap `fact_key`.
class HiveMasteryRepository implements MasteryRepository {
  HiveMasteryRepository([Box<Map>? box]) : _box = box;

  static const String boxName = 'mastery_records';
  Box<Map>? _box;

  Future<Box<Map>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<Map>(boxName);
    return _box!;
  }

  @override
  Future<RepoResult<MasteryRecord?>> get(String factKey) async {
    try {
      final box = await _getBox();
      final raw = box.get(factKey);
      if (raw == null) return const RepoSuccess(null);

      final map = Map<String, dynamic>.from(raw);
      final record = MasteryRecord.fromJson(map);
      return RepoSuccess(record);
    } catch (e) {
      return RepoFailure('Gagal memuat mastery record untuk $factKey', e);
    }
  }

  @override
  Future<RepoResult<void>> save(MasteryRecord record) async {
    try {
      final box = await _getBox();
      await box.put(record.factKey, record.toJson());
      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure(
        'Gagal menyimpan mastery record untuk ${record.factKey}',
        e,
      );
    }
  }

  @override
  Future<RepoResult<Map<String, MasteryRecord>>> getAll() async {
    try {
      final box = await _getBox();
      final result = <String, MasteryRecord>{};
      for (final key in box.keys) {
        final raw = box.get(key);
        if (raw != null) {
          result[key.toString()] = MasteryRecord.fromJson(
            Map<String, dynamic>.from(raw),
          );
        }
      }
      return RepoSuccess(result);
    } catch (e) {
      return RepoFailure('Gagal memuat seluruh mastery bank', e);
    }
  }

  @override
  Future<RepoResult<List<MasteryRecord>>> getWeakFacts({
    int maxBox = 2,
    int limit = 10,
  }) async {
    try {
      final all = await getAll();
      if (all is RepoFailure<Map<String, MasteryRecord>>) {
        return RepoFailure(all.reason, all.exception);
      }
      final records = (all as RepoSuccess<Map<String, MasteryRecord>>).value;
      final weak = records.values
          .where((r) => r.box <= maxBox)
          .take(limit)
          .toList();
      return RepoSuccess(weak);
    } catch (e) {
      return RepoFailure('Gagal memuat fakta lemah', e);
    }
  }

  @override
  Future<RepoResult<void>> saveAll(List<MasteryRecord> records) async {
    try {
      final box = await _getBox();
      final entries = {for (final r in records) r.factKey: r.toJson()};
      await box.putAll(entries);
      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure('Gagal menyimpan kumpulan mastery record', e);
    }
  }
}
