import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/bgm_service.dart';
import '../../../core/services/sfx_service.dart';
import '../../home/providers/bgm_provider.dart';

/// Provider instance singleton SfxService.
final sfxServiceProvider = Provider<SfxService>((ref) {
  final service = SfxService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// State pengaturan audio dan preferensi aplikasi iTHUNG.
class AudioSettingsState {
  const AudioSettingsState({
    this.bgmMuted = false,
    this.sfxMuted = false,
    this.bgmVolume = 1.0,
    this.sfxVolume = 1.0,
    this.hapticEnabled = true,
  });

  final bool bgmMuted;
  final bool sfxMuted;
  final double bgmVolume;
  final double sfxVolume;
  final bool hapticEnabled;

  AudioSettingsState copyWith({
    bool? bgmMuted,
    bool? sfxMuted,
    double? bgmVolume,
    double? sfxVolume,
    bool? hapticEnabled,
  }) {
    return AudioSettingsState(
      bgmMuted: bgmMuted ?? this.bgmMuted,
      sfxMuted: sfxMuted ?? this.sfxMuted,
      bgmVolume: bgmVolume ?? this.bgmVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    );
  }
}

/// StateNotifier untuk mengelola preferensi audio dan sinkronisasi ke BGM & SFX service.
class AudioSettingsNotifier extends StateNotifier<AudioSettingsState> {
  AudioSettingsNotifier({
    required BgmService bgmService,
    required SfxService sfxService,
  })  : _bgmService = bgmService,
        _sfxService = sfxService,
        super(AudioSettingsState(
          bgmMuted: bgmService.isMuted,
          sfxMuted: sfxService.isMuted,
          sfxVolume: sfxService.volume,
        ));

  final BgmService _bgmService;
  final SfxService _sfxService;

  Future<void> toggleBgm() async {
    final next = !state.bgmMuted;
    state = state.copyWith(bgmMuted: next);
    await _bgmService.setMuted(next);
  }

  Future<void> setBgmMuted(bool muted) async {
    state = state.copyWith(bgmMuted: muted);
    await _bgmService.setMuted(muted);
  }

  Future<void> toggleSfx() async {
    final next = !state.sfxMuted;
    state = state.copyWith(sfxMuted: next);
    await _sfxService.setMuted(next);
  }

  Future<void> setSfxMuted(bool muted) async {
    state = state.copyWith(sfxMuted: muted);
    await _sfxService.setMuted(muted);
  }

  Future<void> setBgmVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    state = state.copyWith(bgmVolume: clamped);
    if (clamped > 0 && state.bgmMuted) {
      state = state.copyWith(bgmMuted: false);
      await _bgmService.setMuted(false);
    }
  }

  Future<void> setSfxVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    state = state.copyWith(sfxVolume: clamped);
    await _sfxService.setVolume(clamped);
    if (clamped > 0 && state.sfxMuted) {
      state = state.copyWith(sfxMuted: false);
      await _sfxService.setMuted(false);
    }
  }

  void toggleHaptic() {
    state = state.copyWith(hapticEnabled: !state.hapticEnabled);
  }
}

/// Provider terpusat untuk pengaturan audio dan gameplay iTHUNG.
final audioSettingsProvider =
    StateNotifierProvider<AudioSettingsNotifier, AudioSettingsState>((ref) {
  final bgm = ref.watch(bgmServiceProvider);
  final sfx = ref.watch(sfxServiceProvider);
  return AudioSettingsNotifier(bgmService: bgm, sfxService: sfx);
});
