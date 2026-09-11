import 'package:hive_ce/hive.dart';

import '../../domain/models/audio_settings.dart';
import '../../domain/repositories/audio_settings_repository.dart';
import '../../domain/repositories/repo_result.dart';

/// Implementasi persistensi [AudioSettingsRepository] menggunakan Box Hive CE.
class HiveAudioSettingsRepository implements AudioSettingsRepository {
  HiveAudioSettingsRepository([Box<Map>? box]) : _box = box;

  static const String boxName = 'audio_settings';
  static const String settingsKey = 'preferences';
  Box<Map>? _box;

  Future<Box<Map>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<Map>(boxName);
    return _box!;
  }

  @override
  Future<RepoResult<AudioSettings>> getSettings() async {
    try {
      final box = await _getBox();
      final raw = box.get(settingsKey);
      if (raw == null) {
        return const RepoSuccess(AudioSettings.initial);
      }
      final map = Map<String, dynamic>.from(raw);
      final settings = AudioSettings.fromJson(map);
      return RepoSuccess(settings);
    } catch (e) {
      return RepoFailure('Gagal memuat pengaturan audio dari Hive', e);
    }
  }

  @override
  Future<RepoResult<void>> saveSettings(AudioSettings settings) async {
    try {
      final box = await _getBox();
      await box.put(settingsKey, settings.toJson());
      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure('Gagal menyimpan pengaturan audio ke Hive', e);
    }
  }
}
