import 'dart:math';

import '../models/level_score_record.dart';
import '../models/round_result.dart';
import '../models/session_result.dart';

/// Service untuk perhitungan skor ronde dan XP akun.
///
/// Mengacu pada `math-speed-game-core-gameplay-spec.md` §7:
/// - Round score: mengukur efisiensi dan fluency instan (base + speed + mastery + streak)
/// - Session XP: mengukur progres akun jangka panjang, terpisah dari kecepatan
class ScoringService {
  const ScoringService();

  /// Menghitung skor dan rincian poin untuk satu ronde yang baru selesai.
  ///
  /// [level]: level pemain saat ronde dimainkan.
  /// [timeLeftMs]: sisa waktu saat tombol ditekan (0 jika timeout/salah).
  /// [timeTotalMs]: total alokasi waktu untuk ronde tersebut.
  /// [streakCorrect]: jumlah jawaban benar beruntun sebelum/termasuk ronde ini.
  /// [factBox]: kotak Leitner fakta saat ini (1-5). Jika <= 2, mendapat bonus mastery.
  /// [isCorrect]: apakah jawaban benar. Jika salah, total score = 0.
  ({int roundScore, ScoreBreakdown breakdown}) computeRoundScore({
    required int level,
    required int timeLeftMs,
    required int timeTotalMs,
    required int streakCorrect,
    required bool isCorrect,
    int? factBox,
  }) {
    if (!isCorrect) {
      return (
        roundScore: 0,
        breakdown: const ScoreBreakdown(
          basePoints: 0,
          speedBonus: 0,
          masteryBonus: 0,
          streakBonus: 0,
        ),
      );
    }

    // base_points = 10 * level_multiplier (skala bertahap setiap 5 level)
    final levelMultiplier = 1.0 + (level ~/ 5) * 0.2;
    final basePoints = (10 * levelMultiplier).round();

    // speed_bonus = round(base_points * 0.3 * (time_left / time_total))
    final timeRatio = timeTotalMs > 0
        ? (timeLeftMs / timeTotalMs).clamp(0.0, 1.0)
        : 0.0;
    final speedBonus = (basePoints * 0.3 * timeRatio).round();

    // mastery_bonus = fact.box <= 2 ? 8 : 0 (insentif melatih fakta yang masih lemah)
    final masteryBonus = (factBox != null && factBox <= 2) ? 8 : 0;

    // streak_bonus = min(streak_correct * 2, 20)
    final streakBonus = min(streakCorrect * 2, 20);

    final total = basePoints + speedBonus + masteryBonus + streakBonus;

    final breakdown = ScoreBreakdown(
      basePoints: basePoints,
      speedBonus: speedBonus,
      masteryBonus: masteryBonus,
      streakBonus: streakBonus,
    );

    return (roundScore: total, breakdown: breakdown);
  }

  /// Menghitung XP akun yang didapat dari satu sesi permainan.
  ///
  /// Mengacu pada §7.2: XP TIDAK menghitung kecepatan agar pemain tidak terdorong
  /// grinding fakta mudah secara terburu-buru.
  ///
  /// Formula: (distinct_facts * 2) + (facts_moved_up * 5) + (session_completed ? 10 : 0)
  ({int totalXp, XpBreakdown breakdown}) computeSessionXp({
    required int distinctFactsPracticed,
    required int factsMovedUpABox,
    required bool sessionCompleted,
  }) {
    final breakdown = XpBreakdown(
      distinctFactsPracticed: distinctFactsPracticed,
      factsMovedUpABox: factsMovedUpABox,
      sessionCompletedBonus: sessionCompleted ? 10 : 0,
    );

    final total =
        (distinctFactsPracticed * 2) +
        (factsMovedUpABox * 5) +
        (sessionCompleted ? 10 : 0);

    return (totalXp: total, breakdown: breakdown);
  }

  /// Menghitung delta skor untuk penyelesaian/pengulangan sebuah level (node).
  ///
  /// Berbeda dari [computeRoundScore] (per-soal) — ini beroperasi di level
  /// SessionResult.totalScore vs rekor terbaik level tersebut.
  ({int scoreDelta, LevelScoreRecord updatedRecord}) computeLevelReplayDelta({
    required LevelScoreRecord currentRecord,
    required int newSessionScore,
  }) {
    final result = currentRecord.applyAttempt(newSessionScore);
    return (scoreDelta: result.delta, updatedRecord: result.record);
  }
}
