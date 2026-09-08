import 'dart:async';
import 'dart:collection';
import 'dart:math';

import '../models/distractor.dart';
import '../models/mastery_record.dart';
import '../repositories/mastery_repository.dart';
import '../repositories/repo_result.dart';

/// Service untuk memproses pembaruan Mastery Bank dan Mistake Bank.
///
/// Mengacu pada:
/// - `math-speed-game-core-gameplay-spec.md` §4 (Leitner box, sliding window 8 hasil, weighted average)
/// - `math-speed-game-error-handling-spec.md` §1 (non-blocking fire-and-forget persistence, retry queue, in-memory fallback)
class MasteryUpdateService {
  MasteryUpdateService(this._repo);

  final MasteryRepository _repo;

  /// Cache fallback di memori ketika disk write gagal berulang kali,
  /// menjaga integritas state selama sesi permainan aktif.
  final Map<String, MasteryRecord> _inMemoryFallback = {};

  /// Antrian penulisan yang tertunda.
  final Queue<MasteryRecord> _pendingWrites = Queue();

  /// Mendapatkan record mastery saat ini (dari cache memori atau repository).
  Future<MasteryRecord?> getRecord(String factKey) async {
    if (_inMemoryFallback.containsKey(factKey)) {
      return _inMemoryFallback[factKey];
    }
    final result = await _repo.get(factKey);
    if (result is RepoSuccess<MasteryRecord?>) {
      return result.value;
    }
    return null;
  }

  /// Memproses submit jawaban pemain secara instan tanpa memblokir UI thread.
  ///
  /// Menghitung status penguasaan baru dan menyimpannya secara background
  /// (fire-and-forget dengan retry).
  Future<MasteryRecord> onAnswerSubmit({
    required String factKey,
    required bool isCorrect,
    required int responseTimeMs,
    ErrorType? errorType,
  }) async {
    // Ambil record yang sudah ada atau buat baru jika belum pernah ditemui
    final existing = await getRecord(factKey);
    final updated = computeUpdatedRecord(
      existing: existing,
      factKey: factKey,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
      errorType: errorType,
    );

    // Update in-memory fallback segera agar pembacaan berikutnya di sesi ini langsung sinkron
    _inMemoryFallback[factKey] = updated;

    // Fire-and-forget penyimpanan ke database lokal (tidak menghambat transisi ronde UI)
    unawaited(_persistWithRetry(updated));

    return updated;
  }

  /// Pure computation function: menghitung record penguasaan baru.
  ///
  /// Berdasarkan §4.3:
  /// - Attempts bertambah 1.
  /// - Sliding window 8 percobaan terakhir diperbarui.
  /// - Benar: box + 1 (maksimal 5).
  /// - Salah: box - 2 (minimal 1) dan error_type dicatat di Mistake Bank.
  /// - Weighted average dihitung untuk [masteryScore].
  static MasteryRecord computeUpdatedRecord({
    required MasteryRecord? existing,
    required String factKey,
    required bool isCorrect,
    required int responseTimeMs,
    ErrorType? errorType,
  }) {
    final now = DateTime.now();

    if (existing == null) {
      final initialResults = [isCorrect];
      final errorCounts = <String, int>{};
      if (!isCorrect && errorType != null) {
        errorCounts[errorType.name] = 1;
      }

      return MasteryRecord(
        factKey: factKey,
        attempts: 1,
        correct: isCorrect ? 1 : 0,
        recentResults: initialResults,
        avgResponseTimeMs: responseTimeMs,
        masteryScore: isCorrect ? 1.0 : 0.0,
        box: isCorrect ? 2 : 1,
        lastSeenAt: now,
        errorTypeCounts: errorCounts,
      );
    }

    final newAttempts = existing.attempts + 1;
    final newCorrect = existing.correct + (isCorrect ? 1 : 0);

    // Sliding window: tambahkan hasil terbaru, batas maksimal 8
    final newRecent = List<bool>.from(existing.recentResults)..add(isCorrect);
    if (newRecent.length > 8) {
      newRecent.removeAt(0);
    }

    // Update box (benar: +1 max 5, salah: -2 min 1)
    final newBox = isCorrect
        ? min(existing.box + 1, 5)
        : max(existing.box - 2, 1);

    // Update rata-rata waktu respon (moving average sederhana)
    final newAvgTime =
        ((existing.avgResponseTimeMs * existing.attempts) + responseTimeMs) ~/
        newAttempts;

    // Hitung weighted average: percobaan terbaru diberi bobot eksponensial lebih tinggi
    final newMasteryScore = calculateWeightedMasteryScore(newRecent);

    // Update Mistake Bank error counts
    final newErrorCounts = Map<String, int>.from(existing.errorTypeCounts);
    if (!isCorrect && errorType != null) {
      newErrorCounts[errorType.name] =
          (newErrorCounts[errorType.name] ?? 0) + 1;
    }

    return MasteryRecord(
      factKey: factKey,
      attempts: newAttempts,
      correct: newCorrect,
      recentResults: newRecent,
      avgResponseTimeMs: newAvgTime,
      masteryScore: newMasteryScore,
      box: newBox,
      lastSeenAt: now,
      errorTypeCounts: newErrorCounts,
    );
  }

  /// Menghitung skor penguasaan berbobot (0.0 – 1.0).
  ///
  /// Posisi index lebih tinggi (lebih baru) diberi bobot bertambah secara linier.
  static double calculateWeightedMasteryScore(List<bool> results) {
    if (results.isEmpty) return 0.0;

    var totalWeight = 0.0;
    var weightedSum = 0.0;

    for (var i = 0; i < results.length; i++) {
      final weight = (i + 1).toDouble(); // Bobot 1, 2, 3 ... hingga 8
      totalWeight += weight;
      if (results[i]) {
        weightedSum += weight;
      }
    }

    final score = totalWeight > 0 ? (weightedSum / totalWeight) : 0.0;
    return (score * 100).round() / 100.0;
  }

  /// Menyimpan [record] dengan retry exponential backoff maksimal 3 kali.
  Future<void> _persistWithRetry(
    MasteryRecord record, {
    int attempt = 0,
  }) async {
    try {
      final result = await _repo.save(record);
      if (result is RepoSuccess) {
        // Jika berhasil dan ada antrian lain, proses berikutnya
        if (_pendingWrites.isNotEmpty) {
          final next = _pendingWrites.removeFirst();
          unawaited(_persistWithRetry(next));
        }
        return;
      }
    } catch (_) {
      // Tangkap exception I/O yang tidak tertangani
    }

    if (attempt < 3) {
      _pendingWrites.add(record);
      await Future.delayed(Duration(seconds: pow(2, attempt).toInt()));
      return _persistWithRetry(record, attempt: attempt + 1);
    }

    // 3 kali gagal: data sudah aman di `_inMemoryFallback` untuk sesi ini
  }
}
