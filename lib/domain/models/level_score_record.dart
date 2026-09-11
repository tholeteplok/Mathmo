/// Model untuk rekor skor terbaik pemain per level (discrete node).
///
/// File ini adalah Pure Dart dan tidak bergantung pada Flutter atau Riverpod.
library;

class LevelScoreRecord {
  const LevelScoreRecord({
    required this.level,
    required this.bestScore,
    required this.attempts,
    this.stars = 0,
  });

  /// Nomor level (node) yang direkam.
  final int level;

  /// Skor tertinggi yang pernah dicapai di level ini.
  final int bestScore;

  /// Jumlah total percobaan (termasuk yang pertama) di level ini.
  final int attempts;

  /// Jumlah bintang tertinggi (1..3) yang diperoleh pada level ini.
  final int stars;

  factory LevelScoreRecord.initial(int level) =>
      LevelScoreRecord(level: level, bestScore: 0, attempts: 0, stars: 0);

  /// Terapkan hasil attempt baru — mengembalikan record baru + delta yang didapat.
  ({LevelScoreRecord record, int delta}) applyAttempt(
    int newScore, {
    int? earnedStars,
  }) {
    final delta = (newScore - bestScore) > 0 ? newScore - bestScore : 0;
    final resolvedStars = (earnedStars != null && earnedStars > stars)
        ? earnedStars
        : stars;
    return (
      record: LevelScoreRecord(
        level: level,
        bestScore: newScore > bestScore ? newScore : bestScore,
        attempts: attempts + 1,
        stars: resolvedStars,
      ),
      delta: delta,
    );
  }

  factory LevelScoreRecord.fromJson(Map<String, dynamic> json) {
    return LevelScoreRecord(
      level: ((json['level']) as num).toInt(),
      bestScore: ((json['best_score'] ?? json['bestScore']) as num).toInt(),
      attempts: ((json['attempts']) as num).toInt(),
      stars: ((json['stars']) as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'level': level,
    'best_score': bestScore,
    'attempts': attempts,
    'stars': stars,
  };

  LevelScoreRecord copyWith({
    int? level,
    int? bestScore,
    int? attempts,
    int? stars,
  }) {
    return LevelScoreRecord(
      level: level ?? this.level,
      bestScore: bestScore ?? this.bestScore,
      attempts: attempts ?? this.attempts,
      stars: stars ?? this.stars,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelScoreRecord &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          bestScore == other.bestScore &&
          attempts == other.attempts &&
          stars == other.stars;

  @override
  int get hashCode => Object.hash(level, bestScore, attempts, stars);

  @override
  String toString() =>
      'LevelScoreRecord(level: $level, best: $bestScore, attempts: $attempts, stars: $stars)';
}
