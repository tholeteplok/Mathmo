import 'package:flutter/material.dart';

/// Sumber kebenaran tunggal untuk token visual non-warna (warna sudah
/// ditangani `level_band_theme.dart` + `level_bands.json`). Nilai di sini
/// bersumber langsung dari `math-speed-game-visual-design-spec.md` §4 —
/// widget TIDAK BOLEH menulis angka border/radius/shadow secara manual,
/// selalu lewat `AppTokens`.
class AppTokens {
  AppTokens._();

  // ── Border ───────────────────────────────────────────────────────
  static const double borderWidthDefault = 2.0;
  static const double borderWidthSubtle = 1.5; // untuk badge/pill kecil

  // ── Radius ───────────────────────────────────────────────────────
  static const double radiusContainer = 28.0; // bingkai layar/kartu besar
  static const double radiusCard = 24.0; // kartu soal, kartu skor
  static const double radiusButton = 20.0; // tombol jawaban
  static const double radiusPill = 14.0; // badge streak/XP

  // ── Rotasi elemen non-kritis (kesan hand-drawn, §1 visual design spec) ──
  static const double rotationSubtleNegative = -0.035; // radian, ≈ -2°
  static const double rotationSubtlePositive = 0.035; // radian, ≈ +2°

  // ── Durasi mikro-interaksi (§6 visual design spec) ──────────────
  static const Duration feedbackDuration = Duration(milliseconds: 400);
  static const Duration questionShowDelay = Duration(milliseconds: 600);
  static const Duration canvasColorTransition = Duration(milliseconds: 300);

  // ── Aksesibilitas ────────────────────────────────────────────────

  /// Batas atas `MediaQuery.textScaler` KHUSUS untuk layar gameplay
  /// (soal + grid jawaban). Tipografi tabular numerals di layar ini
  /// (40-42px soal, 22px jawaban) dirancang pas untuk grid 2x2 yang rapat —
  /// text scaling OS yang sangat besar bisa memecah layout tombol.
  ///
  /// Keputusan: CAP di layar gameplay saja (bukan seluruh app) — layar lain
  /// (Home, Results, menu) tetap ikut text scaling OS penuh secara normal,
  /// karena tidak punya batasan grid serapat layar gameplay.
  static const double maxTextScaleGameplay = 1.3;

  /// Jarak minimum tap target, mengikuti pedoman aksesibilitas mobile umum
  /// (≥44px). Tombol jawaban di mockup sudah 64-68px — nilai ini jadi
  /// batas bawah eksplisit untuk komponen baru yang belum dimockup.
  static const double minTapTarget = 44.0;
}

/// Builder shadow "chunky" (offset solid, BUKAN blur) — lihat catatan
/// performa di `math-speed-game-performance-budget.md` §3: shadow jenis ini
/// sengaja dipilih karena lebih murah dirender daripada `BoxShadow` dengan
/// `blurRadius` atau efek Material elevation bawaan.
class ChunkyShadow {
  ChunkyShadow._();

  /// Shadow default untuk kartu/kontainer besar (bingkai layar, kartu soal).
  static List<BoxShadow> container(Color borderColor) => [
    BoxShadow(color: borderColor, offset: const Offset(0, 6), blurRadius: 0),
  ];

  /// Shadow untuk tombol jawaban — offset lebih kecil dari container.
  static List<BoxShadow> button(Color borderColor) => [
    BoxShadow(color: borderColor, offset: const Offset(0, 4), blurRadius: 0),
  ];

  /// State "ditekan" — shadow hilang, dikombinasikan dengan
  /// `Transform.translate(Offset(0, 4))` di widget pemanggil supaya tombol
  /// terlihat turun persis sejauh shadow yang hilang (§6 visual design spec).
  static const List<BoxShadow> pressed = [];
}

/// Helper radian dari derajat, dipakai kalau butuh rotasi selain dua nilai
/// standar di [AppTokens] (mis. variasi rotasi acak ±1-2° per elemen berbeda
/// dalam satu layar, supaya tidak semua elemen berotasi persis sama).
double degreesToRadians(double degrees) => degrees * (3.14159265359 / 180);
