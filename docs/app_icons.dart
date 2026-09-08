import 'package:flutter/widgets.dart' show IconData;
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

/// Sumber kebenaran tunggal untuk semua ikon di app.
///
/// Widget TIDAK BOLEH memanggil `TablerIcons.xxx` langsung — selalu lewat
/// `AppIcons.xxx`. Tujuannya: kalau suatu saat icon pack perlu diganti
/// (mis. ada masalah lisensi/maintenance di `tabler_icons_plus`), hanya
/// file ini yang disentuh, tidak perlu grep-replace di seluruh widget tree.
///
/// Pemetaan di bawah bersumber dari mockup Visualizer yang sudah disetujui:
/// `math_speed_game_screen_playful`, `math_speed_game_home_path_v2`,
/// `math_speed_game_session_results_v2`.
class AppIcons {
  AppIcons._();

  // ── Game Play Screen ────────────────────────────────────────────
  // (header: badge streak kiri, badge XP kanan — lihat CountdownProgressBar
  // di math-speed-game-performance-budget.md §2.1 untuk widget di sekitarnya)

  /// Badge streak harian di header gameplay.
  static const IconData streak = TablerIcons.flame;

  /// Badge XP/poin akun di header gameplay.
  static const IconData xp = TablerIcons.star;

  // ── Home / Peta Level Screen ────────────────────────────────────

  /// Badge streak di header home — SAMA dengan [streak], dipisah sebagai
  /// referensi eksplisit supaya jelas dipakai di dua layar berbeda.
  static const IconData homeStreak = TablerIcons.flame;

  /// Badge XP di header home — SAMA dengan [xp].
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
  // Belum divisualisasikan eksplisit di mockup Visualizer — ditambahkan
  // di sini karena state FEEDBACK sudah didefinisikan di state machine
  // (math-speed-game-spec.md §1) dan butuh representasi visual saat
  // implementasi. Sesuaikan/ganti kalau developer punya preferensi lain.

  /// Overlay saat jawaban benar.
  static const IconData answerCorrect = TablerIcons.circleCheck;

  /// Overlay saat jawaban salah atau timeout.
  static const IconData answerWrong = TablerIcons.circleX;

  // ── Belum Dipakai di Mockup Manapun (disiapkan untuk kelengkapan) ──
  // Ikon berikut relevan dari spec lain tapi belum pernah tampil visual
  // di mockup — tinjau ulang saat layar terkait benar-benar didesain.

  /// Ikon avatar generik, kalau nanti dibutuhkan selain inisial huruf
  /// (avatar di Home Path saat ini pakai huruf "M", bukan ikon).
  static const IconData profile = TablerIcons.user;

  /// Kandidat ikon untuk kartu statistik "akurasi" di Session Results,
  /// kalau nanti kartu stat ditambah ikon (mockup saat ini teks-only).
  static const IconData accuracyStat = TablerIcons.target;

  /// Kandidat ikon untuk kartu statistik "rata-rata waktu".
  static const IconData timeStat = TablerIcons.clock;
}
