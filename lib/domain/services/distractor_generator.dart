import 'dart:math';

import '../models/distractor.dart';
import '../models/question.dart';

/// Generator pilihan pengecoh (distractor) berbasis kesalahan prosedural nyata.
///
/// Mengacu pada `math-speed-game-core-gameplay-spec.md` §3:
/// Distraktor yang baik bukan angka acak, melainkan berasal dari taksonomi
/// miskonsepsi perhitungan nyata agar tantangan terasa adil, logis, dan mendidik.
class DistractorGenerator {
  const DistractorGenerator();

  /// Menghasilkan [DistractorSet] lengkap dengan 3 distraktor dan [shuffledIndices].
  ///
  /// [question]: soal yang sedang aktif.
  /// [count]: jumlah distraktor yang dibutuhkan (default 3 untuk total 4 pilihan).
  /// [isEarlyLevel]: jika true, campur dengan 1 opsi yang jelas salah untuk pemula (§3.4).
  DistractorSet generate(
    Question question, {
    int count = 3,
    bool isEarlyLevel = false,
    Random? rng,
  }) {
    final random = rng ?? Random();
    final correct = question.correctAnswer;
    final candidates = <Distractor>[];
    final usedValues = <int>{correct};

    // 1. Kumpulkan kandidat dari taksonomi error spesifik per operasi
    final errorCandidates = _generateErrorCandidates(question, random);
    for (final candidate in errorCandidates) {
      if (candidate.value > 0 && !usedValues.contains(candidate.value)) {
        candidates.add(candidate);
        usedValues.add(candidate.value);
        if (candidates.length >= count) break;
      }
    }

    // 2. Untuk level pemula, jika ada slot, tambahkan 1 distractor yang jelas salah
    if (isEarlyLevel && candidates.length < count) {
      final farMiss = _generateFarDistractor(correct, random);
      if (farMiss > 0 && !usedValues.contains(farMiss)) {
        candidates.add(Distractor(value: farMiss, errorType: ErrorType.other));
        usedValues.add(farMiss);
      }
    }

    // 3. Fallback: jika kandidat masih kurang dari count, isi dengan random near-miss (correct ± offset)
    var offset = 1;
    while (candidates.length < count) {
      final sign = random.nextBool() ? 1 : -1;
      final val = correct + (sign * offset);
      if (val > 0 && !usedValues.contains(val)) {
        candidates.add(Distractor(value: val, errorType: ErrorType.other));
        usedValues.add(val);
      }
      offset++;
      if (offset > 50) break; // batas proteksi loop
    }

    final selectedDistractors = candidates.take(count).toList();

    // 4. Buat shuffledIndices (permutasi acak dari 0..3)
    // Virtual array: [correct_answer (index 0), ...distractors (index 1..3)]
    final totalChoices = 1 + selectedDistractors.length;
    final indices = List<int>.generate(totalChoices, (i) => i)..shuffle(random);

    return DistractorSet(
      questionId: question.id,
      distractors: selectedDistractors,
      shuffledIndices: indices,
    );
  }

  /// Menghasilkan daftar kandidat error berbasis taksonomi aritmatika (§3.2).
  List<Distractor> _generateErrorCandidates(Question question, Random random) {
    final candidates = <Distractor>[];
    final ops = question.operands;
    if (ops.length < 2) return candidates;

    final a = ops[0];
    final b = ops[1];

    switch (question.operation) {
      case Operation.add:
        // Lupa carry (tambah kolom tanpa simpanan)
        final noCarry = _addWithoutCarry(a, b);
        if (noCarry != null) {
          candidates.add(
            Distractor(value: noCarry, errorType: ErrorType.lupaCarry),
          );
        }
        // Off-by-10
        candidates.add(
          Distractor(
            value: question.correctAnswer + 10,
            errorType: ErrorType.offBy10,
          ),
        );
        if (question.correctAnswer - 10 > 0) {
          candidates.add(
            Distractor(
              value: question.correctAnswer - 10,
              errorType: ErrorType.offBy10,
            ),
          );
        }
        // Off-by-1
        candidates.add(
          Distractor(
            value: question.correctAnswer + 1,
            errorType: ErrorType.other,
          ),
        );
        if (question.correctAnswer - 1 > 0) {
          candidates.add(
            Distractor(
              value: question.correctAnswer - 1,
              errorType: ErrorType.other,
            ),
          );
        }

      case Operation.subtract:
        // Lupa borrow (kurangi kolom dengan selisih mutlak)
        final noBorrow = _subtractWithoutBorrow(a, b);
        if (noBorrow != null) {
          candidates.add(
            Distractor(value: noBorrow, errorType: ErrorType.lupaBorrow),
          );
        }
        // Tertukar arah (b - a jika positif)
        if (b - a > 0) {
          candidates.add(
            Distractor(value: b - a, errorType: ErrorType.tertukarArah),
          );
        }
        // Off-by-10
        candidates.add(
          Distractor(
            value: question.correctAnswer + 10,
            errorType: ErrorType.offBy10,
          ),
        );
        if (question.correctAnswer - 10 > 0) {
          candidates.add(
            Distractor(
              value: question.correctAnswer - 10,
              errorType: ErrorType.offBy10,
            ),
          );
        }

      case Operation.multiply:
        // Salah ganti jadi tambah (a + b)
        candidates.add(
          Distractor(value: a + b, errorType: ErrorType.swapToMultiplyOrAdd),
        );
        // Fakta tabel tetangga: a * (b ± 1)
        if (b + 1 > 0) {
          candidates.add(
            Distractor(
              value: a * (b + 1),
              errorType: ErrorType.adjacentFactTable,
            ),
          );
        }
        if (b - 1 > 0) {
          candidates.add(
            Distractor(
              value: a * (b - 1),
              errorType: ErrorType.adjacentFactTable,
            ),
          );
        }
        // Fakta tabel tetangga: (a ± 1) * b
        if (a + 1 > 0) {
          candidates.add(
            Distractor(
              value: (a + 1) * b,
              errorType: ErrorType.adjacentFactTable,
            ),
          );
        }
        if (a - 1 > 0) {
          candidates.add(
            Distractor(
              value: (a - 1) * b,
              errorType: ErrorType.adjacentFactTable,
            ),
          );
        }

      case Operation.divide:
        // Tertukar arah (b ÷ a) jika habis dibagi
        if (a > 0 && b % a == 0 && b ~/ a > 0) {
          candidates.add(
            Distractor(value: b ~/ a, errorType: ErrorType.tertukarArah),
          );
        }
        // Salah bulatkan sisa (correct ± 1, ± 2)
        candidates.add(
          Distractor(
            value: question.correctAnswer + 1,
            errorType: ErrorType.remainderWrongRounding,
          ),
        );
        if (question.correctAnswer - 1 > 0) {
          candidates.add(
            Distractor(
              value: question.correctAnswer - 1,
              errorType: ErrorType.remainderWrongRounding,
            ),
          );
        }
        if (question.correctAnswer + 2 > 0) {
          candidates.add(
            Distractor(
              value: question.correctAnswer + 2,
              errorType: ErrorType.remainderWrongRounding,
            ),
          );
        }

      case Operation.mixed || Operation.mixedMultistep:
        candidates.add(
          Distractor(
            value: question.correctAnswer + 10,
            errorType: ErrorType.offBy10,
          ),
        );
        if (question.correctAnswer - 10 > 0) {
          candidates.add(
            Distractor(
              value: question.correctAnswer - 10,
              errorType: ErrorType.offBy10,
            ),
          );
        }
        candidates.add(
          Distractor(
            value: question.correctAnswer + 2,
            errorType: ErrorType.other,
          ),
        );
        if (question.correctAnswer - 2 > 0) {
          candidates.add(
            Distractor(
              value: question.correctAnswer - 2,
              errorType: ErrorType.other,
            ),
          );
        }
    }

    candidates.shuffle(random);
    return candidates;
  }

  /// Penjumlahan per digit tanpa carry (mis. 27 + 18 -> (2+1)(7+8%10) = 35 alih-alih 45).
  int? _addWithoutCarry(int a, int b) {
    if (a < 10 && b < 10) return null;
    final digitsA = a.toString().split('').map(int.parse).toList();
    final digitsB = b.toString().split('').map(int.parse).toList();

    final maxLen = max(digitsA.length, digitsB.length);
    while (digitsA.length < maxLen) {
      digitsA.insert(0, 0);
    }
    while (digitsB.length < maxLen) {
      digitsB.insert(0, 0);
    }

    final resultDigits = <int>[];
    var hadCarry = false;
    for (var i = 0; i < maxLen; i++) {
      final sum = digitsA[i] + digitsB[i];
      if (sum >= 10) hadCarry = true;
      resultDigits.add(sum % 10);
    }

    if (!hadCarry) return null;
    final result = int.tryParse(resultDigits.join());
    return (result != null && result > 0) ? result : null;
  }

  /// Pengurangan per digit tanpa borrow (mis. 42 - 17 -> |4-1||2-7| = 35).
  int? _subtractWithoutBorrow(int a, int b) {
    if (a < 10 && b < 10) return null;
    final digitsA = a.toString().split('').map(int.parse).toList();
    final digitsB = b.toString().split('').map(int.parse).toList();

    final maxLen = max(digitsA.length, digitsB.length);
    while (digitsA.length < maxLen) {
      digitsA.insert(0, 0);
    }
    while (digitsB.length < maxLen) {
      digitsB.insert(0, 0);
    }

    final resultDigits = <int>[];
    var hadBorrow = false;
    for (var i = 0; i < maxLen; i++) {
      if (digitsA[i] < digitsB[i]) hadBorrow = true;
      resultDigits.add((digitsA[i] - digitsB[i]).abs());
    }

    if (!hadBorrow) return null;
    final result = int.tryParse(resultDigits.join());
    return (result != null && result > 0) ? result : null;
  }

  /// Distraktor jauh yang jelas salah untuk pemula (±20 hingga ±50).
  int _generateFarDistractor(int correct, Random random) {
    final delta = (random.nextInt(3) + 2) * 10; // 20, 30, atau 40
    final val = random.nextBool() ? correct + delta : correct - delta;
    return val > 0 ? val : correct + delta;
  }
}
