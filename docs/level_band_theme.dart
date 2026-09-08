import 'dart:convert';
import 'dart:ui' show Color;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Satu level band, di-parse dari `assets/level_bands.json` — TIDAK pernah
/// di-hardcode di kode. JSON adalah satu-satunya sumber kebenaran (lihat
/// `math-speed-game-json-structures.md` §5); designer mengubah warna/rentang
/// level cukup lewat file JSON, tanpa menyentuh kode Dart sama sekali.
class LevelBand {
  const LevelBand({
    required this.id,
    required this.levelStart,
    required this.levelEnd, // null = tak terbatas (band Expert)
    required this.canvasColor,
    required this.canvasColorEnd,
    required this.accentColor,
  });

  final String id;
  final int levelStart;
  final int? levelEnd;
  final Color canvasColor;
  final Color canvasColorEnd;
  final Color accentColor;

  factory LevelBand.fromJson(Map<String, dynamic> json) {
    final range = json['level_range'] as List<dynamic>;
    return LevelBand(
      id: json['id'] as String,
      levelStart: range[0] as int,
      levelEnd: range[1] as int?, // null lolos apa adanya dari JSON `null`
      canvasColor: _colorFromHex(json['canvas_color'] as String),
      canvasColorEnd: _colorFromHex(json['canvas_color_end'] as String),
      accentColor: _colorFromHex(json['accent_color'] as String),
    );
  }

  static Color _colorFromHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  bool containsLevel(int level) {
    if (level < levelStart) return false;
    if (levelEnd == null) return true;
    return level <= levelEnd!;
  }
}

/// Wadah seluruh band hasil parse `assets/level_bands.json`. Instance ini
/// yang di-cache di [levelBandsConfigProvider] (lihat
/// `math-speed-game-state-management.md` §5) — dimuat SEKALI saat app start,
/// bukan setiap kali warna dibutuhkan.
class LevelBandsConfig {
  const LevelBandsConfig(this.bands);

  final List<LevelBand> bands;

  factory LevelBandsConfig.fromJson(Map<String, dynamic> json) {
    final list = (json['bands'] as List<dynamic>)
        .map((e) => LevelBand.fromJson(e as Map<String, dynamic>))
        .toList();
    return LevelBandsConfig(list);
  }

  /// Dipanggil sekali di awal app (mis. di `main()` sebelum `runApp`, atau
  /// lewat `FutureProvider` — lihat state management doc §5).
  static Future<LevelBandsConfig> load({
    String assetPath = 'assets/level_bands.json',
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return LevelBandsConfig.fromJson(decoded);
  }

  LevelBand bandForLevel(int level) {
    for (final band in bands) {
      if (band.containsLevel(level)) return band;
    }
    // Fallback: band terakhir (seharusnya band tak terbatas / expert-like)
    // hanya tercapai kalau JSON dikonfigurasi tidak lengkap.
    return bands.last;
  }
}

/// Hasil resolusi tema untuk satu level spesifik.
class LevelBandTheme {
  const LevelBandTheme({
    required this.band,
    required this.canvasColor,
    required this.accentColor,
  });

  final LevelBand band;
  final Color canvasColor; // sudah diinterpolasi sesuai posisi level di band
  final Color accentColor;
}

/// Interpolasi linear warna kanvas berdasarkan posisi level di dalam band-nya.
///
/// t = 0 di level pertama band, t = 1 di level terakhir band. Band tanpa
/// `levelEnd` (mis. Expert) tidak diinterpolasi — selalu pakai `canvasColor`
/// dasar, karena tidak ada batas atas untuk menghitung posisi relatif.
///
/// [config] WAJIB diteruskan dari hasil [LevelBandsConfig.load] yang sudah
/// dimuat sebelumnya — fungsi ini murni (pure), tidak melakukan I/O sendiri,
/// supaya gampang di-unit-test tanpa mock asset bundle.
LevelBandTheme resolveLevelBandTheme(LevelBandsConfig config, int level) {
  final band = config.bandForLevel(level);

  if (band.levelEnd == null) {
    return LevelBandTheme(
      band: band,
      canvasColor: band.canvasColor,
      accentColor: band.accentColor,
    );
  }

  final span = band.levelEnd! - band.levelStart;
  final t = span == 0 ? 0.0 : (level - band.levelStart) / span;
  final clampedT = t.clamp(0.0, 1.0);

  return LevelBandTheme(
    band: band,
    canvasColor: Color.lerp(band.canvasColor, band.canvasColorEnd, clampedT)!,
    accentColor: band.accentColor,
  );
}

/// Opsional: bungkus [resolveLevelBandTheme] sebagai [ThemeExtension] kalau
/// tim ingin akses lewat `Theme.of(context).extension<LevelBandThemeExtension>()`
/// alih-alih lewat provider secara langsung.
@immutable
class LevelBandThemeExtension extends ThemeExtension<LevelBandThemeExtension> {
  const LevelBandThemeExtension({
    required this.canvasColor,
    required this.accentColor,
  });

  final Color canvasColor;
  final Color accentColor;

  factory LevelBandThemeExtension.from(LevelBandTheme theme) {
    return LevelBandThemeExtension(
      canvasColor: theme.canvasColor,
      accentColor: theme.accentColor,
    );
  }

  @override
  LevelBandThemeExtension copyWith({Color? canvasColor, Color? accentColor}) {
    return LevelBandThemeExtension(
      canvasColor: canvasColor ?? this.canvasColor,
      accentColor: accentColor ?? this.accentColor,
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
    );
  }
}
