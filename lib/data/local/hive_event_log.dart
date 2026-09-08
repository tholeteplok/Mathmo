import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

/// Logging event analitik lokal (local-first, tanpa PII, capped ~2000 event).
///
/// Mengacu pada `math-speed-game-analytics-logging-spec.md` §1 & §2:
/// - Menyimpan data lokal terlebih dahulu di Hive box.
/// - Tidak mengumpulkan data pribadi (PII). `playerId` adalah UUID lokal.
/// - Membatasi jumlah event tersimpan maksimal 2000 untuk efisiensi penyimpanan perangkat.
class HiveEventLog {
  HiveEventLog([Box<Map>? box]) : _box = box;

  static const String boxName = 'analytics_events';
  static const int maxEvents = 2000;
  Box<Map>? _box;

  Future<Box<Map>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<Map>(boxName);
    return _box!;
  }

  /// Mencatat event baru ke dalam antrian append-only lokal.
  Future<void> logEvent({
    required String eventName,
    required String playerId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final box = await _getBox();
      final eventId =
          '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 4)}';

      final entry = {
        'event': eventName,
        'timestamp': DateTime.now().toIso8601String(),
        'player_id': playerId,
        'payload': payload,
      };

      await box.put(eventId, entry);

      // Jaga batas kapasitas ~2000 event (hapus yang tertua jika melebihi batas)
      if (box.length > maxEvents) {
        final excess = box.length - maxEvents;
        final keysToDelete = box.keys.take(excess).toList();
        await box.deleteAll(keysToDelete);
      }
    } catch (_) {
      // Analytics log tidak boleh melempar exception ke alur utama
    }
  }

  /// Mengambil semua event yang tersimpan untuk diagnosis/debug.
  Future<List<Map<String, dynamic>>> getEvents() async {
    try {
      final box = await _getBox();
      return box.values.map((raw) => Map<String, dynamic>.from(raw)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Mengosongkan event log setelah di-flush atau diekspor.
  Future<void> clear() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (_) {}
  }
}
