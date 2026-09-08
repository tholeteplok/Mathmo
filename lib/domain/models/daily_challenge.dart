/// Model untuk tantangan harian (Daily Challenge) dan hasil pengerjaannya.
///
/// File ini adalah Pure Dart dan tidak bergantung pada Flutter atau Riverpod.
library;

import 'question.dart';

/// Data model untuk soal tantangan harian (Daily Challenge).
///
/// Berdasarkan Core Gameplay Spec §8:
/// - Soal bersifat deterministik dari [seed] per kohor level band.
/// - Soal sama untuk semua pemain dalam [band] yang sama pada tanggal [date].
/// - [aggregateAccuracyPerFact] mencatat rata-rata performa seluruh pemain untuk kalibrasi adaptif.
class DailyChallenge {
  const DailyChallenge({
    required this.date,
    required this.band,
    required this.seed,
    required this.questions,
    this.aggregateAccuracyPerFact = const <String, double>{},
  });

  /// Tanggal tantangan diselenggarakan (format kalender YYYY-MM-DD).
  final DateTime date;

  /// ID band tingkatan tantangan (mis. 'basic', 'intermediate').
  final String band;

  /// Nilai seed acak deterministik (mis. 'a3f9c1').
  final String seed;

  /// Daftar pertanyaan yang dihasilkan dari seed untuk hari ini.
  final List<Question> questions;

  /// Akumulasi data akurasi per fakta dari seluruh pemain kohor (untuk kalibrasi template).
  final Map<String, double> aggregateAccuracyPerFact;

  /// Format tanggal standar YYYY-MM-DD.
  String get formattedDate {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Membuat [DailyChallenge] dari Map JSON.
  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    final questionsRaw = (json['questions'] as List<dynamic>?) ?? [];
    final questionsList = questionsRaw
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();

    final aggRaw =
        (json['aggregate_accuracy_per_fact'] ??
                json['aggregateAccuracyPerFact'])
            as Map<String, dynamic>? ??
        {};
    final aggMap = aggRaw.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return DailyChallenge(
      date: DateTime.parse(json['date'] as String),
      band: json['band'] as String,
      seed: json['seed'] as String,
      questions: questionsList,
      aggregateAccuracyPerFact: aggMap,
    );
  }

  /// Serialisasi ke Map JSON yang kompatibel dengan spesifikasi.
  Map<String, dynamic> toJson() {
    return {
      'date': formattedDate,
      'band': band,
      'seed': seed,
      'questions': questions.map((q) => q.toJson()).toList(),
      'aggregate_accuracy_per_fact': aggregateAccuracyPerFact,
    };
  }

  /// Membuat salinan objek dengan field yang dimodifikasi.
  DailyChallenge copyWith({
    DateTime? date,
    String? band,
    String? seed,
    List<Question>? questions,
    Map<String, double>? aggregateAccuracyPerFact,
  }) {
    return DailyChallenge(
      date: date ?? this.date,
      band: band ?? this.band,
      seed: seed ?? this.seed,
      questions: questions ?? this.questions,
      aggregateAccuracyPerFact:
          aggregateAccuracyPerFact ?? this.aggregateAccuracyPerFact,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DailyChallenge || runtimeType != other.runtimeType) {
      return false;
    }

    if (formattedDate != other.formattedDate ||
        band != other.band ||
        seed != other.seed ||
        questions.length != other.questions.length ||
        aggregateAccuracyPerFact.length !=
            other.aggregateAccuracyPerFact.length) {
      return false;
    }

    for (var i = 0; i < questions.length; i++) {
      if (questions[i] != other.questions[i]) return false;
    }

    for (final entry in aggregateAccuracyPerFact.entries) {
      if (other.aggregateAccuracyPerFact[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    formattedDate,
    band,
    seed,
    Object.hashAll(questions),
    Object.hashAll(aggregateAccuracyPerFact.entries),
  );

  @override
  String toString() =>
      'DailyChallenge(date: $formattedDate, band: $band, seed: $seed, '
      'questions: ${questions.length})';
}

/// Data model hasil pengerjaan tantangan harian oleh pemain (DailyChallengeResult).
///
/// Menyimpan jumlah jawaban benar, total waktu yang dihabiskan,
/// dan peringkat di dalam band pemain hari tersebut.
class DailyChallengeResult {
  const DailyChallengeResult({
    this.id,
    required this.playerId,
    required this.date,
    required this.band,
    required this.correctCount,
    required this.totalTimeMs,
    this.rankInBand,
  });

  /// ID unik submission lokal/remote (opsional, jika kosong dapat diturunkan dari player+date+band).
  final String? id;

  /// ID pemain yang mengerjakan.
  final String playerId;

  /// Tanggal tantangan harian (YYYY-MM-DD).
  final DateTime date;

  /// Level band kohor tempat hasil ini bersaing.
  final String band;

  /// Total jawaban benar (skor utama, §7.3).
  final int correctCount;

  /// Total waktu pengerjaan dalam milidetik (tie-breaker, §7.3).
  final int totalTimeMs;

  /// Peringkat pemain dalam kohor band-nya (null jika offline/belum disinkronkan).
  final int? rankInBand;

  /// Format tanggal standar YYYY-MM-DD.
  String get formattedDate {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Kunci unik submission yang konsisten.
  String get submissionId => id ?? '${playerId}_${formattedDate}_$band';

  /// Membuat [DailyChallengeResult] dari Map JSON.
  factory DailyChallengeResult.fromJson(Map<String, dynamic> json) {
    return DailyChallengeResult(
      id: json['id'] as String?,
      playerId: (json['player_id'] ?? json['playerId']) as String,
      date: DateTime.parse(json['date'] as String),
      band: json['band'] as String,
      correctCount: ((json['correct_count'] ?? json['correctCount']) as num)
          .toInt(),
      totalTimeMs: ((json['total_time_ms'] ?? json['totalTimeMs']) as num)
          .toInt(),
      rankInBand: (json['rank_in_band'] ?? json['rankInBand']) as int?,
    );
  }

  /// Serialisasi ke Map JSON yang kompatibel dengan spesifikasi.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'player_id': playerId,
      'date': formattedDate,
      'band': band,
      'correct_count': correctCount,
      'total_time_ms': totalTimeMs,
      if (rankInBand != null) 'rank_in_band': rankInBand,
    };
  }

  /// Membuat salinan objek dengan field yang dimodifikasi.
  DailyChallengeResult copyWith({
    String? id,
    String? playerId,
    DateTime? date,
    String? band,
    int? correctCount,
    int? totalTimeMs,
    int? rankInBand,
  }) {
    return DailyChallengeResult(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      date: date ?? this.date,
      band: band ?? this.band,
      correctCount: correctCount ?? this.correctCount,
      totalTimeMs: totalTimeMs ?? this.totalTimeMs,
      rankInBand: rankInBand ?? this.rankInBand,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyChallengeResult &&
          runtimeType == other.runtimeType &&
          submissionId == other.submissionId &&
          playerId == other.playerId &&
          formattedDate == other.formattedDate &&
          band == other.band &&
          correctCount == other.correctCount &&
          totalTimeMs == other.totalTimeMs &&
          rankInBand == other.rankInBand;

  @override
  int get hashCode => Object.hash(
    submissionId,
    playerId,
    formattedDate,
    band,
    correctCount,
    totalTimeMs,
    rankInBand,
  );

  @override
  String toString() =>
      'DailyChallengeResult(player: $playerId, band: $band, '
      'correct: $correctCount, time: ${totalTimeMs}ms, rank: $rankInBand)';
}
