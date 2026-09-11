import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/bgm_service.dart';
import '../../../core/services/sfx_service.dart';
import '../../../domain/models/audio_settings.dart';
import '../../../domain/repositories/audio_settings_repository.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../game/providers/game_dependencies_provider.dart';

/// Provider instance singleton BgmService.
final bgmServiceProvider = Provider<BgmService>((ref) {
  final service = BgmService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Provider instance singleton SfxService.
final sfxServiceProvider = Provider<SfxService>((ref) {
  final service = SfxService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Typedef untuk kompatibilitas ke belakang antarmuka UI.
typedef AudioSettingsState = AudioSettings;

/// StateNotifier untuk mengelola preferensi audio dan sinkronisasi ke BGM & SFX service serta Hive.
class AudioSettingsNotifier extends StateNotifier<AudioSettingsState> {
  AudioSettingsNotifier({
    required BgmService bgmService,
    required SfxService sfxService,
    AudioSettingsRepository? repository,
  })  : _bgmService = bgmService,
        _sfxService = sfxService,
        _repository = repository,
        super(AudioSettingsState(
          bgmMuted: bgmService.isMuted,
          sfxMuted: sfxService.isMuted,
          sfxVolume: sfxService.volume,
        )) {
    initializationFuture = _loadInitialSettings();
  }

  final BgmService _bgmService;
  final SfxService _sfxService;
  final AudioSettingsRepository? _repository;

  /// Future yang selesai ketika preferensi audio dari Hive selesai dimuat.
  late final Future<void> initializationFuture;

  Future<void> _loadInitialSettings() async {
    if (_repository == null) return;
    final result = await _repository.getSettings();
    if (result is RepoSuccess<AudioSettings>) {
      final saved = result.value;
      state = saved;
      await _bgmService.setMuted(saved.bgmMuted);
      await _sfxService.setMuted(saved.sfxMuted);
      await _sfxService.setVolume(saved.sfxVolume);
    }
  }

  Future<void> toggleBgm() async {
    final next = !state.bgmMuted;
    state = state.copyWith(bgmMuted: next);
    await _bgmService.setMuted(next);
    await _repository?.saveSettings(state);
  }

  Future<void> setBgmMuted(bool muted) async {
    state = state.copyWith(bgmMuted: muted);
    await _bgmService.setMuted(muted);
    await _repository?.saveSettings(state);
  }

  Future<void> toggleSfx() async {
    final next = !state.sfxMuted;
    state = state.copyWith(sfxMuted: next);
    await _sfxService.setMuted(next);
    await _repository?.saveSettings(state);
  }

  Future<void> setSfxMuted(bool muted) async {
    state = state.copyWith(sfxMuted: muted);
    await _sfxService.setMuted(muted);
    await _repository?.saveSettings(state);
  }

  Future<void> setBgmVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    state = state.copyWith(bgmVolume: clamped);
    if (clamped > 0 && state.bgmMuted) {
      state = state.copyWith(bgmMuted: false);
      await _bgmService.setMuted(false);
    }
    await _repository?.saveSettings(state);
  }

  Future<void> setSfxVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    state = state.copyWith(sfxVolume: clamped);
    await _sfxService.setVolume(clamped);
    if (clamped > 0 && state.sfxMuted) {
      state = state.copyWith(sfxMuted: false);
      await _sfxService.setMuted(false);
    }
    await _repository?.saveSettings(state);
  }

  void toggleHaptic() {
    state = state.copyWith(hapticEnabled: !state.hapticEnabled);
    _repository?.saveSettings(state);
  }
}

/// Provider terpusat untuk pengaturan audio dan gameplay iTHUNG.
final audioSettingsProvider =
    StateNotifierProvider<AudioSettingsNotifier, AudioSettingsState>((ref) {
  final bgm = ref.watch(bgmServiceProvider);
  final sfx = ref.watch(sfxServiceProvider);
  final repo = ref.watch(audioSettingsRepositoryProvider);
  return AudioSettingsNotifier(
    bgmService: bgm,
    sfxService: sfx,
    repository: repo,
  );
});

/// StateNotifier pembantu untuk memantau dan mengubah status Mute audio
/// yang didelegasikan langsung ke [audioSettingsProvider] sebagai Single Source of Truth.
class BgmMuteNotifier extends StateNotifier<bool> {
  BgmMuteNotifier(this._ref, bool isMuted) : super(isMuted);

  final Ref _ref;

  Future<void> toggle() async {
    await _ref.read(audioSettingsProvider.notifier).toggleBgm();
  }

  Future<void> setMuted(bool muted) async {
    await _ref.read(audioSettingsProvider.notifier).setBgmMuted(muted);
  }
}

/// Provider pembantu untuk status mute BGM (kompatibel dengan HomeScreen lama).
final bgmMuteProvider = StateNotifierProvider<BgmMuteNotifier, bool>((ref) {
  final isMuted = ref.watch(audioSettingsProvider.select((s) => s.bgmMuted));
  return BgmMuteNotifier(ref, isMuted);
});
