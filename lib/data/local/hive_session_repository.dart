import 'package:hive_ce/hive.dart';

import '../../domain/models/session_result.dart';
import '../../domain/repositories/repo_result.dart';
import '../../domain/repositories/session_repository.dart';

/// Implementasi persistensi [SessionRepository] menggunakan Hive CE (append-only log).
class HiveSessionRepository implements SessionRepository {
  HiveSessionRepository([Box<Map>? box]) : _box = box;

  static const String boxName = 'session_history';
  Box<Map>? _box;

  Future<Box<Map>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<Map>(boxName);
    return _box!;
  }

  @override
  Future<RepoResult<void>> saveSession(SessionResult result) async {
    try {
      final box = await _getBox();
      await box.put(result.sessionId, result.toJson());
      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure('Gagal menyimpan sesi ${result.sessionId}', e);
    }
  }

  @override
  Future<RepoResult<List<SessionResult>>> getRecentSessions({
    int limit = 20,
  }) async {
    try {
      final box = await _getBox();
      final sessions = <SessionResult>[];
      for (final raw in box.values) {
        sessions.add(SessionResult.fromJson(Map<String, dynamic>.from(raw)));
      }

      // Urutkan dari yang paling baru
      sessions.sort((a, b) => b.endedAt.compareTo(a.endedAt));

      final limited = sessions.take(limit).toList();
      return RepoSuccess(limited);
    } catch (e) {
      return RepoFailure('Gagal memuat riwayat sesi', e);
    }
  }

  @override
  Future<RepoResult<void>> clearAll() async {
    try {
      final box = await _getBox();
      await box.clear();
      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure('Gagal mengosongkan riwayat sesi', e);
    }
  }
}
