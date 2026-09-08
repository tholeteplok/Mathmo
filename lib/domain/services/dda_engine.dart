import 'dart:math';

/// Dynamic Difficulty Adjustment (DDA) Engine.
///
/// Mengacu pada `math-speed-game-core-gameplay-spec.md` §6:
/// DDA dipisah menjadi dua layer dengan tujuan berbeda:
/// - Layer 1: Timer leniency (jangka pendek, adaptasi tekanan waktu per sesi)
/// - Layer 2: Content mix (jangka panjang, interleaving fakta lemah dari Mastery Bank)
class DdaEngine {
  const DdaEngine();

  // ── Layer 1: Timer Leniency & Confidence Score ──────────────────────────

  /// Memperbarui [currentConfidenceScore] berdasarkan performa pada ronde terakhir.
  ///
  /// Aturan evaluasi:
  /// - Benar cepat (respon < 50% alokasi waktu): +1
  /// - Benar mepet (respon >= 50% alokasi waktu): 0
  /// - Salah atau timeout: -1
  ///
  /// Skor dijaga dalam rentang batas aman [-5, 5].
  int updateConfidenceScore({
    required int currentConfidenceScore,
    required bool isCorrect,
    required int responseTimeMs,
    required int totalTimeMs,
  }) {
    int delta;
    if (!isCorrect) {
      delta = -1;
    } else {
      final isFast = totalTimeMs > 0 && responseTimeMs < (totalTimeMs * 0.5);
      delta = isFast ? 1 : 0;
    }

    return (currentConfidenceScore + delta).clamp(-5, 5);
  }

  /// Menyesuaikan durasi timer level berdasarkan [confidenceScore] saat ini.
  ///
  /// Berdasarkan §6.1:
  /// - `confidence_score <= -2` -> timer +15% (diam-diam memberi nafas pemain yang kesulitan)
  /// - `confidence_score >= 3`  -> timer -5% (sedikit lebih ketat untuk pemain mahir)
  /// - Lainnya: tidak ada penyesuaian.
  double adjustTimerDuration({
    required double baseSec,
    required int confidenceScore,
  }) {
    if (confidenceScore <= -2) {
      return baseSec * 1.15;
    } else if (confidenceScore >= 3) {
      return baseSec * 0.95;
    }
    return baseSec;
  }

  /// Mengecek apakah pemain layak naik level lebih cepat berdasarkan [confidenceScore].
  ///
  /// confidence_score >= 2 -> sinyal pemain sangat mahir pada level ini.
  bool shouldAdvanceLevelFaster(int confidenceScore) {
    return confidenceScore >= 2;
  }

  // ── Layer 2: Content Mix & Spaced Interleaving ─────────────────────────

  /// Menentukan apakah soal berikutnya sebaiknya mengambil fakta lama yang lemah
  /// (interleaving) alih-alih soal baru dari generator level normal.
  ///
  /// Berdasarkan §6.2: rasio 1 dari 6 soal disisipkan fakta lemah jika tersedia.
  /// Nuansa penting: interleaving meningkatkan retensi jangka panjang tanpa
  /// mengganggu alur level yang sedang dimainkan.
  bool shouldInterleaveWeakFact({
    required int questionIndex,
    required bool hasWeakFactsAvailable,
    Random? rng,
  }) {
    if (!hasWeakFactsAvailable) return false;

    // Setiap kelipatan 6 soal atau roll probabilitas 1/6
    if (questionIndex > 0 && questionIndex % 6 == 0) {
      return true;
    }

    final random = rng ?? Random();
    return random.nextInt(6) == 0;
  }
}
