/// Model untuk hasil pengerjaan satu ronde/pertanyaan oleh pemain.
///
/// File ini adalah Pure Dart dan tidak bergantung pada Flutter atau Riverpod.
library;

import 'distractor.dart';

/// Rincian komponen poin yang diperoleh pemain dalam satu ronde.
///
/// Berdasarkan Core Gameplay Spec §7.1:
/// - [basePoints]: 10 × level_multiplier
/// - [speedBonus]: round(base_points × 0.3 × (time_left / time_total))
/// - [masteryBonus]: 8 poin jika menjawab benar fakta yang lemah (box <= 2)
/// - [streakBonus]: min(streak_correct × 2, 20)
class ScoreBreakdown {
  const ScoreBreakdown({
    required this.basePoints,
    required this.speedBonus,
    required this.masteryBonus,
    required this.streakBonus,
  });

  /// Poin dasar berdasarkan level dan tingkat kesulitan.
  final int basePoints;

  /// Bonus kecepatan respons (proporsional terhadap sisa waktu).
  final int speedBonus;

  /// Bonus penguasaan (diberikan saat menjawab benar fakta yang sedang lemah).
  final int masteryBonus;

  /// Bonus streak jawaban benar beruntun (maksimal 20 poin).
  final int streakBonus;

  /// Total seluruh komponen skor ronde.
  int get total => basePoints + speedBonus + masteryBonus + streakBonus;

  /// Nilai awal / nol.
  static const ScoreBreakdown zero = ScoreBreakdown(
    basePoints: 0,
    speedBonus: 0,
    masteryBonus: 0,
    streakBonus: 0,
  );

  /// Membuat [ScoreBreakdown] dari Map JSON.
  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      basePoints: ((json['base_points'] ?? json['basePoints'] ?? 0) as num)
          .toInt(),
      speedBonus: ((json['speed_bonus'] ?? json['speedBonus'] ?? 0) as num)
          .toInt(),
      masteryBonus:
          ((json['mastery_bonus'] ?? json['masteryBonus'] ?? 0) as num).toInt(),
      streakBonus: ((json['streak_bonus'] ?? json['streakBonus'] ?? 0) as num)
          .toInt(),
    );
  }

  /// Serialisasi ke Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'base_points': basePoints,
      'speed_bonus': speedBonus,
      'mastery_bonus': masteryBonus,
      'streak_bonus': streakBonus,
    };
  }

  /// Membuat salinan objek dengan field yang dimodifikasi.
  ScoreBreakdown copyWith({
    int? basePoints,
    int? speedBonus,
    int? masteryBonus,
    int? streakBonus,
  }) {
    return ScoreBreakdown(
      basePoints: basePoints ?? this.basePoints,
      speedBonus: speedBonus ?? this.speedBonus,
      masteryBonus: masteryBonus ?? this.masteryBonus,
      streakBonus: streakBonus ?? this.streakBonus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreBreakdown &&
          runtimeType == other.runtimeType &&
          basePoints == other.basePoints &&
          speedBonus == other.speedBonus &&
          masteryBonus == other.masteryBonus &&
          streakBonus == other.streakBonus;

  @override
  int get hashCode =>
      Object.hash(basePoints, speedBonus, masteryBonus, streakBonus);

  @override
  String toString() =>
      'ScoreBreakdown(base: $basePoints, speed: $speedBonus, '
      'mastery: $masteryBonus, streak: $streakBonus, total: $total)';
}

/// Data model hasil pengerjaan satu soal (RoundResult).
///
/// Disimpan per ronde dan diagregasi ke dalam [SessionResult] di akhir sesi.
class RoundResult {
  const RoundResult({
    required this.questionId,
    required this.factKey,
    required this.selectedAnswer,
    required this.isCorrect,
    this.errorType,
    required this.responseTimeMs,
    required this.timeTotalMs,
    required this.roundScore,
    required this.scoreBreakdown,
    required this.timestamp,
  });

  /// ID pertanyaan yang dijawab.
  final String questionId;

  /// Kunci fakta aritmatika (mis. '7x8').
  final String factKey;

  /// Angka yang dipilih oleh pemain.
  final int selectedAnswer;

  /// Status apakah jawaban pemain benar.
  final bool isCorrect;

  /// Tipe kesalahan jika pemain salah menjawab (null jika benar).
  final ErrorType? errorType;

  /// Waktu respon pemain dalam milidetik.
  final int responseTimeMs;

  /// Total waktu batas ronde dalam milidetik.
  final int timeTotalMs;

  /// Total skor yang didapat untuk ronde ini.
  final int roundScore;

  /// Rincian perhitungan skor per komponen.
  final ScoreBreakdown scoreBreakdown;

  /// Waktu saat jawaban diserahkan (UTC / ISO-8601).
  final DateTime timestamp;

  /// Sisa waktu pemain dalam milidetik.
  int get timeLeftMs => (timeTotalMs - responseTimeMs).clamp(0, timeTotalMs);

  /// String nama wire error_type jika ada kesalahan.
  String? get errorTypeWireName => errorType?.wireName;

  /// Membuat [RoundResult] dari Map JSON.
  factory RoundResult.fromJson(Map<String, dynamic> json) {
    final rawError = json['error_type'] ?? json['errorType'];
    final ErrorType? parsedError = rawError != null
        ? ErrorType.fromJson(rawError as String)
        : null;

    final rawScoreBreakdown = json['score_breakdown'] ?? json['scoreBreakdown'];
    final breakdown = rawScoreBreakdown != null && rawScoreBreakdown is Map
        ? ScoreBreakdown.fromJson(
            Map<String, dynamic>.from(rawScoreBreakdown),
          )
        : ScoreBreakdown.zero;

    return RoundResult(
      questionId: (json['question_id'] ?? json['questionId']) as String,
      factKey: (json['fact_key'] ?? json['factKey']) as String,
      selectedAnswer:
          ((json['selected_answer'] ?? json['selectedAnswer']) as num).toInt(),
      isCorrect: (json['is_correct'] ?? json['isCorrect']) as bool,
      errorType: parsedError,
      responseTimeMs:
          ((json['response_time_ms'] ?? json['responseTimeMs']) as num).toInt(),
      timeTotalMs: ((json['time_total_ms'] ?? json['timeTotalMs']) as num)
          .toInt(),
      roundScore: ((json['round_score'] ?? json['roundScore']) as num).toInt(),
      scoreBreakdown: breakdown,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Serialisasi ke Map JSON yang kompatibel dengan spesifikasi.
  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'fact_key': factKey,
      'selected_answer': selectedAnswer,
      'is_correct': isCorrect,
      'error_type': errorType?.toJson(),
      'response_time_ms': responseTimeMs,
      'time_total_ms': timeTotalMs,
      'round_score': roundScore,
      'score_breakdown': scoreBreakdown.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Membuat salinan objek dengan field yang dimodifikasi.
  RoundResult copyWith({
    String? questionId,
    String? factKey,
    int? selectedAnswer,
    bool? isCorrect,
    ErrorType? errorType,
    int? responseTimeMs,
    int? timeTotalMs,
    int? roundScore,
    ScoreBreakdown? scoreBreakdown,
    DateTime? timestamp,
  }) {
    return RoundResult(
      questionId: questionId ?? this.questionId,
      factKey: factKey ?? this.factKey,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      errorType: errorType ?? this.errorType,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      timeTotalMs: timeTotalMs ?? this.timeTotalMs,
      roundScore: roundScore ?? this.roundScore,
      scoreBreakdown: scoreBreakdown ?? this.scoreBreakdown,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoundResult &&
          runtimeType == other.runtimeType &&
          questionId == other.questionId &&
          factKey == other.factKey &&
          selectedAnswer == other.selectedAnswer &&
          isCorrect == other.isCorrect &&
          errorType == other.errorType &&
          responseTimeMs == other.responseTimeMs &&
          timeTotalMs == other.timeTotalMs &&
          roundScore == other.roundScore &&
          scoreBreakdown == other.scoreBreakdown &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
    questionId,
    factKey,
    selectedAnswer,
    isCorrect,
    errorType,
    responseTimeMs,
    timeTotalMs,
    roundScore,
    scoreBreakdown,
    timestamp,
  );

  @override
  String toString() =>
      'RoundResult(qid: $questionId, fact: $factKey, correct: $isCorrect, '
      'score: $roundScore, time: ${responseTimeMs}ms)';
}
