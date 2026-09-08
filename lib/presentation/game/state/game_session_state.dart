import '../../../domain/models/distractor.dart';
import '../../../domain/models/question.dart';
import '../../../domain/models/session_result.dart';

/// Sealed class representasi state machine gameplay sesi permainan.
///
/// Mengacu pada `math-speed-game-state-management.md` §3.
sealed class GameSessionState {
  const GameSessionState();
}

/// State saat soal ditampilkan sejenak (~600ms) sebelum tombol jawaban aktif.
class ShowQuestionState extends GameSessionState {
  const ShowQuestionState(this.question);
  final Question question;
}

/// State saat timer berjalan dan tombol jawaban aktif menerima input.
class ActiveState extends GameSessionState {
  const ActiveState({
    required this.question,
    required this.distractors,
    required this.shuffledIndices,
    required this.timeRemainingMs,
    required this.totalTimeMs,
    required this.streakCorrect,
    required this.confidenceScore,
  });

  final Question question;
  final List<Distractor> distractors;

  /// Permutasi indeks dari array virtual [correct_answer, ...distractors].
  final List<int> shuffledIndices;

  /// Snapshot waktu tersisa saat ini (ms).
  final int timeRemainingMs;

  /// Total waktu yang dialokasikan untuk soal ini (ms).
  final int totalTimeMs;

  /// Jumlah jawaban benar beruntun.
  final int streakCorrect;

  /// Skor confidence DDA saat ini.
  final int confidenceScore;

  ActiveState copyWith({
    Question? question,
    List<Distractor>? distractors,
    List<int>? shuffledIndices,
    int? timeRemainingMs,
    int? totalTimeMs,
    int? streakCorrect,
    int? confidenceScore,
  }) {
    return ActiveState(
      question: question ?? this.question,
      distractors: distractors ?? this.distractors,
      shuffledIndices: shuffledIndices ?? this.shuffledIndices,
      timeRemainingMs: timeRemainingMs ?? this.timeRemainingMs,
      totalTimeMs: totalTimeMs ?? this.totalTimeMs,
      streakCorrect: streakCorrect ?? this.streakCorrect,
      confidenceScore: confidenceScore ?? this.confidenceScore,
    );
  }
}

/// State saat animasi umpan balik (benar/salah/timeout) ditampilkan ±400ms.
class FeedbackState extends GameSessionState {
  const FeedbackState({
    required this.isCorrect,
    required this.selectedAnswer,
    required this.question,
    required this.roundScore,
  });

  final bool isCorrect;
  final int? selectedAnswer;
  final Question question;
  final int roundScore;
}

/// State saat game dijeda (mis. app masuk background atau dialog konfirmasi back ditekan).
class PausedState extends GameSessionState {
  const PausedState(this.pausedFrom);

  /// Snapshot [ActiveState] persis sebelum pause, termasuk sisa waktu yang dibekukan.
  final ActiveState pausedFrom;
}

/// State saat sesi berakhir normal dan siap menampilkan layar hasil.
class SessionEndedState extends GameSessionState {
  const SessionEndedState(this.result);
  final SessionResult result;
}
