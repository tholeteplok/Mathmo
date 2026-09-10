/// Model untuk rekor skor terbaik pemain per level (discrete node).
///
/// File ini adalah Pure Dart dan tidak bergantung pada Flutter atau Riverpod.
library;

class LevelScoreRecord {
  const LevelScoreRecord({
    required this.level,
    required this.bestScore,
    required this.attempts,
  });

  /// Nomor level (node) yang direkam.
  final int level;

  /// Skor tertinggi yang pernah dicapai di level ini.
  final int bestScore;

  /// Jumlah total percobaan (termasuk yang pertama) di level ini.
  final int attempts;

  factory LevelScoreRecord.initial(int level) =>
      LevelScoreRecord(level: level, bestScore: 0, attempts: 0);

  /// Terapkan hasil attempt baru — mengembalikan record baru + delta yang didapat.
  ({LevelScoreRecord record, int delta}) applyAttempt(int newScore) {
    final delta = (newScore - bestScore) > 0 ? newScore - bestScore : 0;
    return (
      record: LevelScoreRecord(
        level: level,
        bestScore: newScore > bestScore ? newScore : bestScore,
        attempts: attempts + 1,
      ),
      delta: delta,
    );
  }

  factory LevelScoreRecord.fromJson(Map<String, dynamic> json) {
    return LevelScoreRecord(
      level: ((json['level']) as num).toInt(),
      bestScore: ((json['best_score'] ?? json['bestScore']) as num).toInt(),
      attempts: ((json['attempts']) as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'level': level,
    'best_score': bestScore,
    'attempts': attempts,
  };

  LevelScoreRecord copyWith({int? level, int? bestScore, int? attempts}) {
    return LevelScoreRecord(
      level: level ?? this.level,
      bestScore: bestScore ?? this.bestScore,
      attempts: attempts ?? this.attempts,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelScoreRecord &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          bestScore == other.bestScore &&
          attempts == other.attempts;

  @override
  int get hashCode => Object.hash(level, bestScore, attempts);

  @override
  String toString() =>
      'LevelScoreRecord(level: $level, best: $bestScore, attempts: $attempts)';
}
