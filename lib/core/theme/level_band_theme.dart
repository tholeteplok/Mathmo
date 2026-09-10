import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../domain/models/level_band_config.dart';
import 'app_theme.dart';

/// Hasil resolusi tema visual dinamis untuk satu level spesifik.
class LevelBandTheme {
  const LevelBandTheme({
    required this.band,
    required this.canvasColor,
    required this.accentColor,
    required this.borderColor,
  });

  /// Konfigurasi band terkait.
  final LevelBand band;

  /// Warna latar kanvas yang sudah diinterpolasi berdasarkan posisi level di dalam band.
  final Color canvasColor;

  /// Warna aksen utama (tombol, progress bar, badge aktif).
  final Color accentColor;

  /// Warna border (biasanya varian lebih gelap atau turunan aksen).
  final Color borderColor;
}

/// Helper untuk mengonversi string hex ('#EAF3DE') ke Flutter [Color].
Color colorFromHex(String hex) {
  final cleaned = hex.replaceFirst('#', '').trim();
  if (cleaned.length == 6) {
    return Color(int.parse('FF$cleaned', radix: 16));
  } else if (cleaned.length == 8) {
    return Color(int.parse(cleaned, radix: 16));
  }
  return AppTheme.colorSandyCanvas; // fallback
}

/// Fungsi murni untuk menyelesaikan [LevelBandTheme] dari [LevelBandsConfig] dan [level].
LevelBandTheme resolveLevelBandTheme(LevelBandsConfig config, int level) {
  final band = config.bandForLevel(level);
  final startColor = colorFromHex(band.canvasColorHex);
  final endColor = colorFromHex(band.canvasColorEndHex);
  final accent = colorFromHex(band.accentColorHex);

  final t = band.progressInBand(level);
  final interpolatedCanvas = Color.lerp(startColor, endColor, t) ?? startColor;

  // Border kayu hangat / saddle wood
  const borderColor = AppTheme.colorWoodMedium;

  return LevelBandTheme(
    band: band,
    canvasColor: interpolatedCanvas,
    accentColor: accent,
    borderColor: borderColor,
  );
}

/// [ThemeExtension] untuk akses tema level band lewat `Theme.of(context).extension<LevelBandThemeExtension>()`.
@immutable
class LevelBandThemeExtension extends ThemeExtension<LevelBandThemeExtension> {
  const LevelBandThemeExtension({
    required this.canvasColor,
    required this.accentColor,
    required this.borderColor,
  });

  final Color canvasColor;
  final Color accentColor;
  final Color borderColor;

  factory LevelBandThemeExtension.fromTheme(LevelBandTheme theme) {
    return LevelBandThemeExtension(
      canvasColor: theme.canvasColor,
      accentColor: theme.accentColor,
      borderColor: theme.borderColor,
    );
  }

  @override
  LevelBandThemeExtension copyWith({
    Color? canvasColor,
    Color? accentColor,
    Color? borderColor,
  }) {
    return LevelBandThemeExtension(
      canvasColor: canvasColor ?? this.canvasColor,
      accentColor: accentColor ?? this.accentColor,
      borderColor: borderColor ?? this.borderColor,
    );
  }

  @override
  LevelBandThemeExtension lerp(
    ThemeExtension<LevelBandThemeExtension>? other,
    double t,
  ) {
    if (other is! LevelBandThemeExtension) return this;
    return LevelBandThemeExtension(
      canvasColor: Color.lerp(canvasColor, other.canvasColor, t)!,
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
    );
  }
}

/// Helper loader konfigurasi dari `assets/level_bands.json`.
Future<LevelBandsConfig> loadLevelBandsConfig({
  String assetPath = 'assets/level_bands.json',
}) async {
  final raw = await rootBundle.loadString(assetPath);
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return LevelBandsConfig.fromJson(decoded);
}
