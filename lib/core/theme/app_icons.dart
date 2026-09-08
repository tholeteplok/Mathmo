import 'package:flutter/widgets.dart' show IconData;
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

/// Sumber kebenaran tunggal untuk semua ikon di aplikasi.
///
/// Widget TIDAK BOLEH memanggil `TablerIcons.xxx` secara langsung — selalu melalui
/// `AppIcons.xxx` agar konsisten dan mudah di-maintain.
class AppIcons {
  AppIcons._();

  // ── Game Play Screen ────────────────────────────────────────────

  /// Badge streak harian di header gameplay.
  static const IconData streak = TablerIcons.flame;

  /// Badge XP/poin akun di header gameplay.
  static const IconData xp = TablerIcons.star;

  // ── Home / Peta Level Screen ────────────────────────────────────

  /// Badge streak di header home.
  static const IconData homeStreak = TablerIcons.flame;

  /// Badge XP di header home.
  static const IconData homeXp = TablerIcons.star;

  /// Node level yang sedang aktif — tombol "lanjut main".
  static const IconData levelActive = TablerIcons.playerPlay;

  /// Node level yang sudah diselesaikan (checkmark hijau).
  static const IconData levelCompleted = TablerIcons.check;

  /// Node level yang masih terkunci.
  static const IconData levelLocked = TablerIcons.lock;

  // ── Session Results Screen ──────────────────────────────────────

  /// Banner "streak harian dipertahankan" di layar hasil sesi.
  static const IconData streakMaintained = TablerIcons.flame;

  // ── Feedback Overlay ────────────────────────────────────────────

  /// Overlay saat jawaban benar.
  static const IconData answerCorrect = TablerIcons.circleCheck;

  /// Overlay saat jawaban salah atau timeout.
  static const IconData answerWrong = TablerIcons.circleX;

  // ── Tambahan Menu & Profil ──────────────────────────────────────

  /// Ikon avatar profil.
  static const IconData profile = TablerIcons.user;

  /// Ikon akurasi di kartu statistik.
  static const IconData accuracyStat = TablerIcons.target;

  /// Ikon waktu respon di kartu statistik.
  static const IconData timeStat = TablerIcons.clock;

  /// Ikon kalender / daily challenge.
  static const IconData calendar = TablerIcons.calendarEvent;
}
