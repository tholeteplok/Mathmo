/// Model untuk catatan penguasaan fakta aritmatika (MasteryRecord) dalam Mastery Bank.
///
/// File ini adalah Pure Dart dan tidak bergantung pada Flutter atau Riverpod.
library;

/// Model penguasaan satu fakta aritmatika berdasarkan sistem Leitner box
/// dan sliding window hasil pengerjaan terbaru.
///
/// Berdasarkan Core Gameplay Spec §4:
/// - Menggunakan sistem 5 kotak (box 1–5).
/// - Jawaban benar menaikkan 1 box (+1), jawaban salah menurunkan 2 box (-2).
/// - [recentResults] menyimpan maksimal 8 percobaan terakhir (sliding window).
/// - [masteryScore] dihitung dengan pembobotan lebih berat pada hasil terbaru.
class MasteryRecord {
  const MasteryRecord({
    required this.factKey,
    required this.attempts,
    required this.correct,
    required this.recentResults,
    required this.avgResponseTimeMs,
    required this.masteryScore,
    required this.box,
    required this.lastSeenAt,
    required this.errorTypeCounts,
  });

  /// Kunci identitas fakta aritmatika (mis. '7x8', '12-5', 'add_crossdecade_2digit').
  final String factKey;

  /// Total berapa kali fakta ini sudah dikerjakan pemain.
  final int attempts;

  /// Jumlah percobaan yang dijawab dengan benar.
  final int correct;

  /// Riwayat benar/salah 8 percobaan terakhir (sliding window).
  final List<bool> recentResults;

  /// Rata-rata waktu respon pemain dalam milidetik.
  final int avgResponseTimeMs;

  /// Skor penguasaan (0.0 sampai 1.0) dengan bobot pada percobaan terbaru.
  final double masteryScore;

  /// Posisi kotak Leitner (1 sampai 5).
  /// Box 1 = sangat sering diulang; Box 5 = sangat dikuasai/jarang diulang.
  final int box;

  /// Waktu terakhir fakta ini ditemui/dikerjakan pemain.
  final DateTime lastSeenAt;

  /// Frekuensi kemunculan tipe kesalahan saat menjawab salah fakta ini.
  /// Kunci berupa nama wire error type (mis. 'adjacent_fact_table').
  final Map<String, int> errorTypeCounts;

  /// Batas maksimal riwayat hasil geser (sliding window).
  static const int maxWindowSize = 8;

  /// Kotak Leitner terendah.
  static const int minBox = 1;

  /// Kotak Leitner tertinggi.
  static const int maxBox = 5;

  /// Apakah fakta ini sedang dalam kondisi lemah (prioritas untuk di-resurface).
  ///
  /// Berdasarkan spec §4.4: box <= 2 adalah fakta lemah.
  bool get isWeak => box <= 2;

  /// Apakah fakta ini sudah dikuasai penuh.
  bool get isMastered => box == maxBox && masteryScore >= 0.85;

  /// Tingkat akurasi keseluruhan sepanjang waktu (0.0 jika attempts = 0).
  double get overallAccuracy => attempts > 0 ? correct / attempts : 0.0;

  /// Inisialisasi record baru untuk fakta yang belum pernah dicoba.
  factory MasteryRecord.initial(String factKey, {DateTime? now}) {
    return MasteryRecord(
      factKey: factKey,
      attempts: 0,
      correct: 0,
      recentResults: const <bool>[],
      avgResponseTimeMs: 0,
      masteryScore: 0.0,
      box: 1,
      lastSeenAt: now ?? DateTime.now().toUtc(),
      errorTypeCounts: const <String, int>{},
    );
  }

  /// Menghasilkan [MasteryRecord] baru setelah pemain menjawab fakta ini.
  ///
  /// Mengimplementasikan alur pembaruan Leitner & sliding window (§4.3):
  /// - [attempts] bertambah 1.
  /// - [recentResults] ditambah dan dibatasi maksimal 8 data terakhir.
  /// - Jika benar: [correct] +1, [box] naik 1 (maks 5).
  /// - Jika salah: [box] turun 2 (min 1), dan mencatat [errorType].
  /// - [masteryScore] dihitung ulang dengan bobot linear ke hasil terbaru.
  /// - [avgResponseTimeMs] dihitung ulang sebagai rata-rata berjalan.
  MasteryRecord withNewResult(
    bool isCorrect,
    int responseTimeMs, [
    String? errorType,
    DateTime? timestamp,
  ]) {
    final newAttempts = attempts + 1;
    final newCorrect = isCorrect ? correct + 1 : correct;

    // Geser sliding window (maksimal 8 data)
    final updatedRecent = <bool>[...recentResults, isCorrect];
    if (updatedRecent.length > maxWindowSize) {
      updatedRecent.removeRange(0, updatedRecent.length - maxWindowSize);
    }

    // Pembaruan kotak Leitner (naik +1 jika benar, turun -2 jika salah)
    final newBox = isCorrect
        ? (box + 1).clamp(minBox, maxBox)
        : (box - 2).clamp(minBox, maxBox);

    // Pembaruan pencatatan taksonomi error
    final updatedErrorCounts = Map<String, int>.from(errorTypeCounts);
    if (!isCorrect && errorType != null && errorType.isNotEmpty) {
      updatedErrorCounts[errorType] = (updatedErrorCounts[errorType] ?? 0) + 1;
    }

    // Skor mastery berbobot
    final newMasteryScore = calculateWeightedMasteryScore(updatedRecent);

    // Rata-rata waktu respon berjalan
    final newAvgResponse = attempts == 0
        ? responseTimeMs
        : ((avgResponseTimeMs * attempts) + responseTimeMs) ~/ newAttempts;

    return MasteryRecord(
      factKey: factKey,
      attempts: newAttempts,
      correct: newCorrect,
      recentResults: List<bool>.unmodifiable(updatedRecent),
      avgResponseTimeMs: newAvgResponse,
      masteryScore: newMasteryScore,
      box: newBox,
      lastSeenAt: timestamp ?? DateTime.now().toUtc(),
      errorTypeCounts: Map<String, int>.unmodifiable(updatedErrorCounts),
    );
  }

  /// Menghitung skor penguasaan berbobot (0.0–1.0) dari sliding window.
  ///
  /// Hasil paling baru diberi bobot paling besar secara linear (1, 2, ..., N).
  static double calculateWeightedMasteryScore(List<bool> recent) {
    if (recent.isEmpty) return 0.0;

    var totalWeight = 0;
    var weightedSum = 0.0;

    for (var i = 0; i < recent.length; i++) {
      final weight = i + 1;
      totalWeight += weight;
      if (recent[i]) {
        weightedSum += weight;
      }
    }

    if (totalWeight == 0) return 0.0;
    final score = weightedSum / totalWeight;
    // Bulatkan ke 2 desimal
    return double.parse(score.toStringAsFixed(2));
  }

  /// Membuat [MasteryRecord] dari Map JSON.
  factory MasteryRecord.fromJson(Map<String, dynamic> json) {
    final recentRaw =
        (json['recent_results'] ?? json['recentResults']) as List<dynamic>? ??
        [];
    final recentList = recentRaw.map((e) => e as bool).toList();

    final rawErrorCounts =
        json['error_type_counts'] ?? json['errorTypeCounts'];
    final errorCountsMap = rawErrorCounts != null && rawErrorCounts is Map
        ? rawErrorCounts.map(
            (key, value) => MapEntry(key.toString(), (value as num).toInt()),
          )
        : <String, int>{};

    return MasteryRecord(
      factKey: (json['fact_key'] ?? json['factKey']) as String,
      attempts: ((json['attempts'] ?? 0) as num).toInt(),
      correct: ((json['correct'] ?? 0) as num).toInt(),
      recentResults: recentList,
      avgResponseTimeMs:
          ((json['avg_response_time_ms'] ?? json['avgResponseTimeMs'] ?? 0)
                  as num)
              .toInt(),
      masteryScore:
          ((json['mastery_score'] ?? json['masteryScore'] ?? 0.0) as num)
              .toDouble(),
      box: ((json['box'] ?? 1) as num).toInt(),
      lastSeenAt: DateTime.parse(
        (json['last_seen_at'] ?? json['lastSeenAt']) as String,
      ),
      errorTypeCounts: errorCountsMap,
    );
  }

  /// Serialisasi ke Map JSON yang kompatibel dengan spesifikasi.
  Map<String, dynamic> toJson() {
    return {
      'fact_key': factKey,
      'attempts': attempts,
      'correct': correct,
      'recent_results': recentResults,
      'avg_response_time_ms': avgResponseTimeMs,
      'mastery_score': masteryScore,
      'box': box,
      'last_seen_at': lastSeenAt.toIso8601String(),
      'error_type_counts': errorTypeCounts,
    };
  }

  /// Membuat salinan objek dengan field yang dimodifikasi.
  MasteryRecord copyWith({
    String? factKey,
    int? attempts,
    int? correct,
    List<bool>? recentResults,
    int? avgResponseTimeMs,
    double? masteryScore,
    int? box,
    DateTime? lastSeenAt,
    Map<String, int>? errorTypeCounts,
  }) {
    return MasteryRecord(
      factKey: factKey ?? this.factKey,
      attempts: attempts ?? this.attempts,
      correct: correct ?? this.correct,
      recentResults: recentResults ?? this.recentResults,
      avgResponseTimeMs: avgResponseTimeMs ?? this.avgResponseTimeMs,
      masteryScore: masteryScore ?? this.masteryScore,
      box: box ?? this.box,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      errorTypeCounts: errorTypeCounts ?? this.errorTypeCounts,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MasteryRecord || runtimeType != other.runtimeType) {
      return false;
    }

    if (factKey != other.factKey ||
        attempts != other.attempts ||
        correct != other.correct ||
        avgResponseTimeMs != other.avgResponseTimeMs ||
        masteryScore != other.masteryScore ||
        box != other.box ||
        lastSeenAt != other.lastSeenAt ||
        recentResults.length != other.recentResults.length ||
        errorTypeCounts.length != other.errorTypeCounts.length) {
      return false;
    }

    for (var i = 0; i < recentResults.length; i++) {
      if (recentResults[i] != other.recentResults[i]) return false;
    }

    for (final entry in errorTypeCounts.entries) {
      if (other.errorTypeCounts[entry.key] != entry.value) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    factKey,
    attempts,
    correct,
    Object.hashAll(recentResults),
    avgResponseTimeMs,
    masteryScore,
    box,
    lastSeenAt,
    Object.hashAll(errorTypeCounts.entries),
  );

  @override
  String toString() =>
      'MasteryRecord(fact: $factKey, box: $box, score: $masteryScore, '
      'att: $attempts, corr: $correct)';
}
