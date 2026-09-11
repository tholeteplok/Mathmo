/// Model data murni untuk pengaturan audio dan haptik iTHUNG.
library;

/// Model representasi preferensi audio dan gameplay pengguna.
class AudioSettings {
  const AudioSettings({
    this.bgmMuted = false,
    this.sfxMuted = false,
    this.bgmVolume = 1.0,
    this.sfxVolume = 1.0,
    this.hapticEnabled = true,
  });

  /// Status apakah musik latar (BGM) dibisukan.
  final bool bgmMuted;

  /// Status apakah efek suara (SFX) dibisukan.
  final bool sfxMuted;

  /// Volume musik latar (0.0 sampai 1.0).
  final double bgmVolume;

  /// Volume efek suara (0.0 sampai 1.0).
  final double sfxVolume;

  /// Status getaran haptik saat berinteraksi.
  final bool hapticEnabled;

  /// Nilai awal / default pengaturan audio.
  static const AudioSettings initial = AudioSettings();

  /// Membuat salinan objek dengan modifikasi field tertentu.
  AudioSettings copyWith({
    bool? bgmMuted,
    bool? sfxMuted,
    double? bgmVolume,
    double? sfxVolume,
    bool? hapticEnabled,
  }) {
    return AudioSettings(
      bgmMuted: bgmMuted ?? this.bgmMuted,
      sfxMuted: sfxMuted ?? this.sfxMuted,
      bgmVolume: bgmVolume ?? this.bgmVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    );
  }

  /// Deserialisasi dari Map JSON / Hive Map.
  factory AudioSettings.fromJson(Map<String, dynamic> json) {
    return AudioSettings(
      bgmMuted: (json['bgm_muted'] ?? json['bgmMuted']) as bool? ?? false,
      sfxMuted: (json['sfx_muted'] ?? json['sfxMuted']) as bool? ?? false,
      bgmVolume:
          ((json['bgm_volume'] ?? json['bgmVolume']) as num?)?.toDouble() ??
          1.0,
      sfxVolume:
          ((json['sfx_volume'] ?? json['sfxVolume']) as num?)?.toDouble() ??
          1.0,
      hapticEnabled:
          (json['haptic_enabled'] ?? json['hapticEnabled']) as bool? ?? true,
    );
  }

  /// Serialisasi ke Map JSON yang kompatibel dengan penyimpanan Hive.
  Map<String, dynamic> toJson() {
    return {
      'bgm_muted': bgmMuted,
      'sfx_muted': sfxMuted,
      'bgm_volume': bgmVolume,
      'sfx_volume': sfxVolume,
      'haptic_enabled': hapticEnabled,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioSettings &&
          runtimeType == other.runtimeType &&
          bgmMuted == other.bgmMuted &&
          sfxMuted == other.sfxMuted &&
          bgmVolume == other.bgmVolume &&
          sfxVolume == other.sfxVolume &&
          hapticEnabled == other.hapticEnabled;

  @override
  int get hashCode => Object.hash(
    bgmMuted,
    sfxMuted,
    bgmVolume,
    sfxVolume,
    hapticEnabled,
  );
}
