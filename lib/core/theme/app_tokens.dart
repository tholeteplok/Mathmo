import 'package:flutter/material.dart';

/// Sumber kebenaran tunggal untuk token visual non-warna (warna ditangani
/// `level_band_theme.dart` + `level_bands.json`).
///
/// Komponen UI TIDAK BOLEH menulis angka border/radius/shadow secara hardcode,
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

  // ── Rotasi elemen non-kritis (kesan playful hand-drawn) ───────────
  static const double rotationSubtleNegative = -0.035; // radian, ≈ -2°
  static const double rotationSubtlePositive = 0.035; // radian, ≈ +2°

  // ── Durasi mikro-interaksi ───────────────────────────────────────
  static const Duration feedbackDuration = Duration(milliseconds: 400);
  static const Duration questionShowDelay = Duration(milliseconds: 600);
  static const Duration canvasColorTransition = Duration(milliseconds: 300);
  static const Duration buttonPressDuration = Duration(milliseconds: 80);

  // ── Aksesibilitas ────────────────────────────────────────────────

  /// Batas atas `MediaQuery.textScaler` khusus untuk layar gameplay (soal + grid jawaban).
  static const double maxTextScaleGameplay = 1.3;

  /// Jarak minimum tap target (≥44px).
  static const double minTapTarget = 44.0;
}

/// Builder shadow "chunky" (offset solid, BUKAN blur).
///
/// Offset solid dirender sangat cepat di GPU HP mid-range dibanding blur radius.
class ChunkyShadow {
  ChunkyShadow._();

  /// Shadow default untuk kartu/kontainer besar.
  static List<BoxShadow> container(Color borderColor) => [
    BoxShadow(color: borderColor, offset: const Offset(0, 6), blurRadius: 0),
  ];

  /// Shadow untuk tombol jawaban.
  static List<BoxShadow> button(Color borderColor) => [
    BoxShadow(color: borderColor, offset: const Offset(0, 4), blurRadius: 0),
  ];

  /// State tombol saat ditekan (shadow hilang).
  static const List<BoxShadow> pressed = [];
}

/// Helper konversi derajat ke radian.
double degreesToRadians(double degrees) => degrees * (3.14159265359 / 180);
