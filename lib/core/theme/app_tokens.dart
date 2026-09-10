import 'package:flutter/material.dart';

/// Sumber kebenaran tunggal untuk token visual non-warna (warna ditangani
/// `level_band_theme.dart` + `level_bands.json`).
///
/// Komponen UI TIDAK BOLEH menulis angka border/radius/shadow secara hardcode,
/// selalu lewat `AppTokens`.
class AppTokens {
  AppTokens._();

  // ── Border ───────────────────────────────────────────────────────
  static const double borderWidthDefault = 1.5;
  static const double borderWidthSubtle = 1.2; // untuk badge/pill kecil
  static const double borderWidthWood = 2.5; // untuk kontainer/plang kayu

  // ── Radius ───────────────────────────────────────────────────────
  static const double radiusAvatar = 32.0; // container avatar profil (match curvature gambar)
  static const double radiusContainer = 28.0; // bingkai layar/kartu besar
  static const double radiusCard = 26.0; // kartu soal, kartu skor
  static const double radiusButton = 22.0; // tombol jawaban / aksi
  static const double radiusPill = 16.0; // badge streak/XP

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

/// Builder shadow "Cozy Tactile" (bottom depth 3D fisik & soft warm ambient).
class ChunkyShadow {
  ChunkyShadow._();

  /// Shadow default untuk kartu/kontainer besar (soft warm depth).
  static List<BoxShadow> container(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.12),
      offset: const Offset(0, 6),
      blurRadius: 10,
    ),
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.06),
      offset: const Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  /// Shadow untuk kartu kertas putih (hanging paper sheet drop shadow).
  static List<BoxShadow> paper(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.12),
      offset: const Offset(0, 8),
      blurRadius: 14,
    ),
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.06),
      offset: const Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  /// Shadow untuk plang/kontainer kayu (3D wood bottom lip).
  static List<BoxShadow> wood(Color shadowColor) => [
    BoxShadow(
      color: shadowColor,
      offset: const Offset(0, 5),
      blurRadius: 0,
    ),
  ];

  /// Shadow untuk tombol taktil 3D (bottom lip 4px).
  static List<BoxShadow> button(Color shadowColor) => [
    BoxShadow(
      color: shadowColor,
      offset: const Offset(0, 4),
      blurRadius: 0,
    ),
  ];

  /// State tombol saat ditekan (shadow menghilang rata permukaan).
  static const List<BoxShadow> pressed = [];
}

/// Helper konversi derajat ke radian.
double degreesToRadians(double degrees) => degrees * (3.14159265359 / 180);

/// Sumber kebenaran tunggal untuk path aset visual aplikasi iTHUNG.
class AppAssets {
  AppAssets._();

  // Custom Navigation Icons
  static const String icProfile = 'assets/icon/ic_profile.png';
  static const String icLead = 'assets/icon/ic_lead.png';
  static const String icDaily = 'assets/icon/ic_daily.png';
  static const String icSettings = 'assets/icon/ic_settings.png';
  static const String appLauncher = 'assets/icon/app_launcher.png';

  // Preset Avatars (assets/images/avatar/avatar_0.png .. avatar_8.png)
  static const List<String> avatarPresets = [
    'assets/images/avatar/avatar_0.png',
    'assets/images/avatar/avatar_1.png',
    'assets/images/avatar/avatar_2.png',
    'assets/images/avatar/avatar_3.png',
    'assets/images/avatar/avatar_4.png',
    'assets/images/avatar/avatar_5.png',
    'assets/images/avatar/avatar_6.png',
    'assets/images/avatar/avatar_7.png',
    'assets/images/avatar/avatar_8.png',
  ];

  /// Mengembalikan path aset avatar berdasarkan ID (misal: 'avatar_0' -> 'assets/images/avatar/avatar_0.png').
  /// Mengembalikan null jika [avatarId] kosong atau null.
  static String? avatarPath(String? avatarId) {
    if (avatarId == null || avatarId.isEmpty) return null;
    final match = avatarPresets.where((p) => p.contains(avatarId)).firstOrNull;
    return match ?? avatarId;
  }

  // Legacy (dijaga agar backward-compatible bila ada referensi lama)
  static const String woodTokenLocked = 'assets/images/wood_token_locked.png';
  static const String woodTokenChecked = 'assets/images/wood_token_checked.png';
  static const String woodBoardSquare = 'assets/images/wood_board_square.png';
  static const String woodSignHanging = 'assets/images/wood_sign_hanging.png';
}

