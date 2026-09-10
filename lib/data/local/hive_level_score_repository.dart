import 'package:hive_ce/hive.dart';

import '../../domain/models/level_score_record.dart';
import '../../domain/repositories/level_score_repository.dart';
import '../../domain/repositories/repo_result.dart';

/// Implementasi [LevelScoreRepository] menggunakan Hive CE untuk menyimpan rekor skor tiap level.
class HiveLevelScoreRepository implements LevelScoreRepository {
  HiveLevelScoreRepository([Box<Map>? box]) : _box = box;

  static const String boxName = 'level_scores';
  Box<Map>? _box;

  Future<Box<Map>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<Map>(boxName);
    return _box!;
  }

  @override
  Future<RepoResult<LevelScoreRecord?>> getRecord(int level) async {
    try {
      final box = await _getBox();
      final raw = box.get(level.toString());
      if (raw == null) return const RepoSuccess(null);
      return RepoSuccess(
        LevelScoreRecord.fromJson(Map<String, dynamic>.from(raw)),
      );
    } catch (e) {
      return RepoFailure('Gagal memuat rekor skor level $level', e);
    }
  }

  @override
  Future<RepoResult<void>> saveRecord(LevelScoreRecord record) async {
    try {
      final box = await _getBox();
      await box.put(record.level.toString(), record.toJson());
      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure('Gagal menyimpan rekor skor level ${record.level}', e);
    }
  }

  @override
  Future<RepoResult<Map<int, LevelScoreRecord>>> getAllRecords() async {
    try {
      final box = await _getBox();
      final map = <int, LevelScoreRecord>{};
      for (final entry in box.toMap().entries) {
        final record = LevelScoreRecord.fromJson(
          Map<String, dynamic>.from(entry.value),
        );
        map[record.level] = record;
      }
      return RepoSuccess(map);
    } catch (e) {
      return RepoFailure('Gagal memuat seluruh rekor skor level', e);
    }
  }
}
