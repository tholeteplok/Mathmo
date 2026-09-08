import 'dart:math';

import '../models/daily_challenge.dart';
import '../models/distractor.dart';
import '../models/level_band_config.dart';
import '../models/question.dart';
import 'distractor_generator.dart';
import 'question_generator.dart';

/// Service logika Daily Challenge (Tantangan Harian).
///
/// Mengacu pada `math-speed-game-core-gameplay-spec.md` §8:
/// - Soal bersifat deterministik per kohor band level (seed = hash(date + band)).
/// - Client dapat menghasilkan konten soal lokal tanpa ketergantungan koneksi jaringan.
/// - Penilaian utama berfokus pada jumlah jawaban benar; total waktu hanya sebagai tie-breaker.
class DailyChallengeService {
  const DailyChallengeService({
    this.questionGenerator = const QuestionGenerator(),
    this.distractorGenerator = const DistractorGenerator(),
  });

  final QuestionGenerator questionGenerator;
  final DistractorGenerator distractorGenerator;

  /// Algoritma hashing deterministik FNV-1a pure Dart (tanpa dependensi eksternal).
  static int deterministicHash(String input) {
    var hash = 0x811c9dc5;
    for (var i = 0; i < input.length; i++) {
      hash ^= input.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return hash;
  }

  /// Menghasilkan [DailyChallenge] deterministik untuk [date] dan [band].
  DailyChallenge generateDailyChallenge({
    required DateTime date,
    required LevelBand band,
  }) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final seedString = '${dateStr}_${band.id}';

    final intSeed = deterministicHash(seedString);
    final rng = Random(intSeed);
    const totalQuestions = 12;

    final questions = <Question>[];
    for (var i = 0; i < totalQuestions; i++) {
      // Sample level representatif di dalam band
      final level = band.levelEnd != null
          ? band.levelStart + (i % (band.levelEnd! - band.levelStart + 1))
          : band.levelStart + (i % 10);

      final q = questionGenerator.generateForLevel(level, rng: rng);
      questions.add(q);
    }

    return DailyChallenge(
      date: date,
      band: band.id,
      seed: intSeed.toRadixString(16),
      questions: questions,
      aggregateAccuracyPerFact: const {},
    );
  }

  /// Menghasilkan pilihan distraktor deterministik untuk pertanyaan tantangan harian.
  DistractorSet generateDistractorsForQuestion(Question question, String seed) {
    final combined = '${question.id}_$seed';
    final intSeed = deterministicHash(combined);

    final rng = Random(intSeed);
    return distractorGenerator.generate(question, rng: rng);
  }
}
