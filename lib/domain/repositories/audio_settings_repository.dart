import '../models/audio_settings.dart';
import 'repo_result.dart';

/// Kontrak abstraksi untuk penyimpanan dan pengambilan preferensi audio pengguna.
abstract interface class AudioSettingsRepository {
  /// Memuat preferensi audio yang tersimpan di database lokal.
  Future<RepoResult<AudioSettings>> getSettings();

  /// Menyimpan preferensi audio pengguna ke database lokal.
  Future<RepoResult<void>> saveSettings(AudioSettings settings);
}
