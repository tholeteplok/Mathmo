/// Model untuk baris entri papan peringkat (LeaderboardEntry).
///
/// Menampilkan username (bukan email), skor benar, waktu tie-breaker,
/// dan flag penanda pemain aktif.
/// File ini adalah Pure Dart dan tidak bergantung pada Flutter atau Riverpod.
library;

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.username,
    this.avatarId,
    required this.correctCount,
    required this.totalTimeMs,
    required this.isCurrentPlayer,
  });

  /// Posisi peringkat (1-based index).
  final int rank;

  /// Username pemain (minimal 4 karakter, non-email).
  final String username;

  /// ID preset avatar pemain (mis. 'avatar_0' .. 'avatar_8', atau null jika inisial).
  final String? avatarId;

  /// Jumlah jawaban benar (skor utama).
  final int correctCount;

  /// Total waktu penyelesaian dalam milidetik (tie-breaker).
  final int totalTimeMs;

  /// Menandai apakah entri ini milik pemain yang sedang login.
  final bool isCurrentPlayer;

  /// Format waktu dalam detik (mis. "24.5s").
  String get formattedTime => '${(totalTimeMs / 1000).toStringAsFixed(1)}s';

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: ((json['rank'] ?? 0) as num).toInt(),
      username: (json['username'] ?? 'Pemain') as String,
      avatarId: (json['avatar_id'] ?? json['avatarId']) as String?,
      correctCount:
          ((json['correct_count'] ?? json['correctCount'] ?? 0) as num).toInt(),
      totalTimeMs:
          ((json['total_time_ms'] ?? json['totalTimeMs'] ?? 0) as num).toInt(),
      isCurrentPlayer: (json['is_current_player'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'username': username,
    'avatar_id': avatarId,
    'correct_count': correctCount,
    'total_time_ms': totalTimeMs,
    'is_current_player': isCurrentPlayer,
  };

  LeaderboardEntry copyWith({
    int? rank,
    String? username,
    String? avatarId,
    bool clearAvatar = false,
    int? correctCount,
    int? totalTimeMs,
    bool? isCurrentPlayer,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      username: username ?? this.username,
      avatarId: clearAvatar ? null : (avatarId ?? this.avatarId),
      correctCount: correctCount ?? this.correctCount,
      totalTimeMs: totalTimeMs ?? this.totalTimeMs,
      isCurrentPlayer: isCurrentPlayer ?? this.isCurrentPlayer,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntry &&
          runtimeType == other.runtimeType &&
          rank == other.rank &&
          username == other.username &&
          avatarId == other.avatarId &&
          correctCount == other.correctCount &&
          totalTimeMs == other.totalTimeMs &&
          isCurrentPlayer == other.isCurrentPlayer;

  @override
  int get hashCode => Object.hash(
    rank,
    username,
    avatarId,
    correctCount,
    totalTimeMs,
    isCurrentPlayer,
  );

  @override
  String toString() =>
      'LeaderboardEntry(#$rank, @$username, avatar: $avatarId, score: $correctCount, time: $formattedTime, me: $isCurrentPlayer)';
}
