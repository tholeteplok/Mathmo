/// Model untuk ringkasan satu sesi permainan (SessionResult).
///
/// File ini adalah Pure Dart dan tidak bergantung pada Flutter atau Riverpod.
library;

import 'round_result.dart';

/// Mode permainan yang tersedia di aplikasi Mathmo.
enum GameMode {
  /// Mode normal berbasis level naik dengan Dynamic Difficulty Adjustment.
  normal('normal'),

  /// Mode latihan khusus untuk memperkuat fakta-fakta yang lemah di Mastery Bank.
  practice('practice'),

  /// Mode sprint cepat berbasis waktu terbatas.
  sprint('sprint'),

  /// Mode tantangan harian ber-seed kohor sama per level band.
  dailyChallenge('daily_challenge');

  const GameMode(this.wireName);

  /// Nama representasi saat diserialisasi ke JSON.
  final String wireName;

  /// Mengonversi nilai String dari JSON ke enum [GameMode].
  static GameMode fromJson(String value) {
    return switch (value.toLowerCase().trim()) {
      'normal' => GameMode.normal,
      'practice' => GameMode.practice,
      'sprint' => GameMode.sprint,
      'daily_challenge' || 'dailychallenge' => GameMode.dailyChallenge,
      _ => throw ArgumentError('Nilai GameMode tidak valid: $value'),
    };
  }

  /// Serialisasi ke string JSON.
  String toJson() => wireName;
}

/// Rincian perolehan Experience Point (XP) dalam satu sesi bermain.
///
/// Berdasarkan Core Gameplay Spec §7.2:
/// `session_xp = (distinct_facts * 2) + (facts_moved_up_a_box * 5) + (completed ? 10 : 0)`
///
/// XP sama sekali tidak memberi insentif pada kecepatan mentah, melainkan
/// pada keberagaman fakta dan perbaikan penguasaan riil.
class XpBreakdown {
  const XpBreakdown({
    required this.distinctFactsPracticed,
    required this.factsMovedUpABox,
    required this.sessionCompletedBonus,
  });

  /// Jumlah fakta matematika unik yang dilatih selama sesi.
  final int distinctFactsPracticed;

  /// Jumlah fakta yang berhasil naik box Leitner (menunjukkan perbaikan).
  final int factsMovedUpABox;

  /// Bonus penyelesaian sesi secara penuh (mis. 10 XP jika selesai).
  final int sessionCompletedBonus;

  /// Total XP terhitung berdasarkan formula spesifikasi.
  int get totalCalculatedXp =>
      (distinctFactsPracticed * 2) +
      (factsMovedUpABox * 5) +
      sessionCompletedBonus;

  /// Nilai awal / nol.
  static const XpBreakdown zero = XpBreakdown(
    distinctFactsPracticed: 0,
    factsMovedUpABox: 0,
    sessionCompletedBonus: 0,
  );

  /// Membuat [XpBreakdown] dari Map JSON.
  factory XpBreakdown.fromJson(Map<String, dynamic> json) {
    return XpBreakdown(
      distinctFactsPracticed:
          ((json['distinct_facts_practiced'] ??
                      json['distinctFactsPracticed'] ??
                      0)
                  as num)
              .toInt(),
      factsMovedUpABox:
          ((json['facts_moved_up_a_box'] ?? json['factsMovedUpABox'] ?? 0)
                  as num)
              .toInt(),
      sessionCompletedBonus:
          ((json['session_completed_bonus'] ??
                      json['sessionCompletedBonus'] ??
                      0)
                  as num)
              .toInt(),
    );
  }

  /// Serialisasi ke Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'distinct_facts_practiced': distinctFactsPracticed,
      'facts_moved_up_a_box': factsMovedUpABox,
      'session_completed_bonus': sessionCompletedBonus,
    };
  }

  /// Membuat salinan objek dengan field yang dimodifikasi.
  XpBreakdown copyWith({
    int? distinctFactsPracticed,
    int? factsMovedUpABox,
    int? sessionCompletedBonus,
  }) {
    return XpBreakdown(
      distinctFactsPracticed:
          distinctFactsPracticed ?? this.distinctFactsPracticed,
      factsMovedUpABox: factsMovedUpABox ?? this.factsMovedUpABox,
      sessionCompletedBonus:
          sessionCompletedBonus ?? this.sessionCompletedBonus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XpBreakdown &&
          runtimeType == other.runtimeType &&
          distinctFactsPracticed == other.distinctFactsPracticed &&
          factsMovedUpABox == other.factsMovedUpABox &&
          sessionCompletedBonus == other.sessionCompletedBonus;

  @override
  int get hashCode => Object.hash(
    distinctFactsPracticed,
    factsMovedUpABox,
    sessionCompletedBonus,
  );

  @override
  String toString() =>
      'XpBreakdown(distinct: $distinctFactsPracticed, movedUp: $factsMovedUpABox, '
      'bonus: $sessionCompletedBonus, total: $totalCalculatedXp)';
}

/// Data model ringkasan satu sesi permainan (SessionResult).
///
/// Disimpan di database lokal sebagai log riwayat pengerjaan permanen
/// untuk analisis performa dan tampilan statistik.
class SessionResult {
  const SessionResult({
    required this.sessionId,
    required this.mode,
    required this.startedAt,
    required this.endedAt,
    required this.levelReached,
    required this.rounds,
    required this.totalScore,
    required this.accuracy,
    required this.avgResponseTimeMs,
    required this.bestStreak,
    required this.xpEarned,
    required this.xpBreakdown,
  });

  /// ID unik sesi permainan (mis. 's_20260908_1').
  final String sessionId;

  /// Mode permainan sesi ini.
  final GameMode mode;

  /// Waktu sesi dimulai.
  final DateTime startedAt;

  /// Waktu sesi berakhir.
  final DateTime endedAt;

  /// Level tertinggi yang dicapai dalam sesi ini.
  final int levelReached;

  /// Daftar hasil per ronde dalam sesi ini.
  final List<RoundResult> rounds;

  /// Total akumulasi skor dari seluruh ronde.
  final int totalScore;

  /// Rasio akurasi jawaban (0.0 sampai 1.0).
  final double accuracy;

  /// Rata-rata waktu respon dalam milidetik.
  final int avgResponseTimeMs;

  /// Streak jawaban benar berturut-turut terbaik dalam sesi.
  final int bestStreak;

  /// Total XP yang didapatkan pemain dari sesi ini.
  final int xpEarned;

  /// Rincian asal perolehan XP.
  final XpBreakdown xpBreakdown;

  /// Durasi total bermain dalam sesi ini.
  Duration get duration => endedAt.difference(startedAt);

  /// Jumlah soal yang dijawab benar.
  int get correctCount => rounds.where((r) => r.isCorrect).length;

  /// Total soal yang dikerjakan dalam sesi.
  int get totalRounds => rounds.length;

  /// Membuat [SessionResult] dari Map JSON.
  factory SessionResult.fromJson(Map<String, dynamic> json) {
    final roundsRaw = (json['rounds'] as List<dynamic>?) ?? [];
    final roundsList = roundsRaw
        .map((e) => RoundResult.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final xpBreakdownRaw = json['xp_breakdown'] ?? json['xpBreakdown'];
    final xpBreakdown = xpBreakdownRaw != null && xpBreakdownRaw is Map
        ? XpBreakdown.fromJson(Map<String, dynamic>.from(xpBreakdownRaw))
        : XpBreakdown.zero;

    return SessionResult(
      sessionId: (json['session_id'] ?? json['sessionId']) as String,
      mode: GameMode.fromJson(json['mode'] as String),
      startedAt: DateTime.parse(
        (json['started_at'] ?? json['startedAt']) as String,
      ),
      endedAt: DateTime.parse((json['ended_at'] ?? json['endedAt']) as String),
      levelReached: ((json['level_reached'] ?? json['levelReached']) as num)
          .toInt(),
      rounds: roundsList,
      totalScore: ((json['total_score'] ?? json['totalScore']) as num).toInt(),
      accuracy: ((json['accuracy']) as num).toDouble(),
      avgResponseTimeMs:
          ((json['avg_response_time_ms'] ?? json['avgResponseTimeMs']) as num)
              .toInt(),
      bestStreak: ((json['best_streak'] ?? json['bestStreak']) as num).toInt(),
      xpEarned: ((json['xp_earned'] ?? json['xpEarned']) as num).toInt(),
      xpBreakdown: xpBreakdown,
    );
  }

  /// Serialisasi ke Map JSON yang kompatibel dengan spesifikasi.
  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'mode': mode.toJson(),
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
      'level_reached': levelReached,
      'rounds': rounds.map((r) => r.toJson()).toList(),
      'total_score': totalScore,
      'accuracy': accuracy,
      'avg_response_time_ms': avgResponseTimeMs,
      'best_streak': bestStreak,
      'xp_earned': xpEarned,
      'xp_breakdown': xpBreakdown.toJson(),
    };
  }

  /// Membuat salinan objek dengan field yang dimodifikasi.
  SessionResult copyWith({
    String? sessionId,
    GameMode? mode,
    DateTime? startedAt,
    DateTime? endedAt,
    int? levelReached,
    List<RoundResult>? rounds,
    int? totalScore,
    double? accuracy,
    int? avgResponseTimeMs,
    int? bestStreak,
    int? xpEarned,
    XpBreakdown? xpBreakdown,
  }) {
    return SessionResult(
      sessionId: sessionId ?? this.sessionId,
      mode: mode ?? this.mode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      levelReached: levelReached ?? this.levelReached,
      rounds: rounds ?? this.rounds,
      totalScore: totalScore ?? this.totalScore,
      accuracy: accuracy ?? this.accuracy,
      avgResponseTimeMs: avgResponseTimeMs ?? this.avgResponseTimeMs,
      bestStreak: bestStreak ?? this.bestStreak,
      xpEarned: xpEarned ?? this.xpEarned,
      xpBreakdown: xpBreakdown ?? this.xpBreakdown,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SessionResult || runtimeType != other.runtimeType) {
      return false;
    }

    if (sessionId != other.sessionId ||
        mode != other.mode ||
        startedAt != other.startedAt ||
        endedAt != other.endedAt ||
        levelReached != other.levelReached ||
        totalScore != other.totalScore ||
        accuracy != other.accuracy ||
        avgResponseTimeMs != other.avgResponseTimeMs ||
        bestStreak != other.bestStreak ||
        xpEarned != other.xpEarned ||
        xpBreakdown != other.xpBreakdown ||
        rounds.length != other.rounds.length) {
      return false;
    }

    for (var i = 0; i < rounds.length; i++) {
      if (rounds[i] != other.rounds[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    mode,
    startedAt,
    endedAt,
    levelReached,
    Object.hashAll(rounds),
    totalScore,
    accuracy,
    avgResponseTimeMs,
    bestStreak,
    xpEarned,
    xpBreakdown,
  );

  @override
  String toString() =>
      'SessionResult(id: $sessionId, mode: $mode, score: $totalScore, '
      'acc: ${(accuracy * 100).toStringAsFixed(1)}%, xp: $xpEarned)';
}
