# Speed Math Game — Error Handling & Edge Cases Spec

Prinsip umum: **gameplay tidak boleh berhenti karena kegagalan infrastruktur** (storage, network, generator). Semua kegagalan di dokumen ini ditangani dengan graceful degradation — game tetap bisa dimainkan, hanya sebagian fitur (persistensi, leaderboard) yang tertunda/hilang sementara.

## 1. MasteryRepository Gagal Save (storage penuh / write error)

### Masalah
`onAnswerSubmit` (§4.3 `math-speed-game-core-gameplay-spec.md`) menulis ke Hive/sqflite tiap jawaban. Kalau write gagal (storage penuh, permission error, korupsi file), gameplay tidak boleh ikut macet menunggu I/O.

### Strategi

```dart
sealed class RepoResult<T> {}
class RepoSuccess<T> extends RepoResult<T> { final T value; RepoSuccess(this.value); }
class RepoFailure<T> extends RepoResult<T> { final String reason; RepoFailure(this.reason); }

class MasteryUpdateService {
  final MasteryRepository _repo;
  final Queue<MasteryRecord> _pendingWrites = Queue();

  Future<void> onAnswerSubmit(/* ... */) async {
    final updated = _computeUpdatedRecord(/* ... */); // pure logic, selalu berhasil

    // TIDAK di-await secara blocking terhadap alur gameplay —
    // fire-and-forget dengan retry queue di belakang layar
    unawaited(_persistWithRetry(updated));
  }

  Future<void> _persistWithRetry(MasteryRecord record, {int attempt = 0}) async {
    final result = await _repo.save(record);
    if (result is RepoFailure && attempt < 3) {
      _pendingWrites.add(record);
      await Future.delayed(Duration(seconds: pow(2, attempt).toInt()));
      return _persistWithRetry(record, attempt: attempt + 1);
    }
    if (result is RepoFailure) {
      // 3x gagal — kemungkinan storage benar-benar penuh.
      // Simpan di memory cache sesi ini supaya minimal state konsisten
      // sampai app ditutup, dan catat event untuk analytics (lihat spec B).
      _inMemoryFallback[record.factKey] = record;
    }
  }
}
```

**Kenapa fire-and-forget, bukan `await` di jalur utama**: kalau `submitAnswer` menunggu write disk selesai sebelum lanjut ke soal berikutnya, disk I/O yang lambat (umum di HP mid-range dengan storage hampir penuh) langsung terasa sebagai lag gameplay — bertentangan dengan feedback ±400ms yang sudah jadi prinsip inti.

**Kalau storage benar-benar penuh** (bukan cuma lambat): tampilkan banner non-blocking sekali per sesi ("Progres belum tersimpan — cek ruang penyimpanan"), bukan dialog yang menghentikan permainan. Data tetap ada di `_inMemoryFallback` selama sesi berjalan, jadi DDA & scoring sesi itu tetap akurat — cuma tidak persisten ke sesi berikutnya kalau app benar-benar ditutup paksa.

## 2. Question Generator Gagal (template conflict / constraint tidak terpenuhi)

### Masalah
Loop `generate(template)` di §2 core-gameplay-spec bisa gagal menemukan operand yang memenuhi semua constraint (mis. kombinasi `require_carry: true` + `avoid_trivial: true` + rentang operand sempit — mungkin tidak ada solusi, atau butuh ribuan percobaan).

### Strategi — constraint relaxation ladder

```dart
Question generate(QuestionTemplate template) {
  const maxAttemptsPerTier = 200;

  for (final relaxedTemplate in _relaxationLadder(template)) {
    for (var i = 0; i < maxAttemptsPerTier; i++) {
      final candidate = _tryGenerate(relaxedTemplate);
      if (candidate != null) {
        if (relaxedTemplate != template) {
          _logGenerationFallback(template, relaxedTemplate); // dev diagnostic, lihat spec B
        }
        return candidate;
      }
    }
  }

  // Tingkat terakhir: tidak pernah gagal total, generate soal paling dasar
  // yang valid secara operasi — lebih baik satu soal terlalu mudah muncul
  // daripada layar game macet tanpa soal sama sekali.
  return _absoluteFallback(template.operation);
}

List<QuestionTemplate> _relaxationLadder(QuestionTemplate t) => [
  t,
  t.copyWith(constraints: t.constraints.copyWith(avoidTrivial: false)),
  t.copyWith(constraints: t.constraints.copyWith(requireCarry: null, requireBorrow: null)),
  t.copyWith(operandRange: t.operandRange.widen()),
];
```

**Prinsip**: setiap tingkat relaksasi melonggarkan satu constraint non-esensial (urutan dari yang paling tidak mempengaruhi `strategy_tag` ke yang paling mempengaruhi). Kalau sampai ke `_absoluteFallback`, itu sinyal ada bug di konfigurasi template — event `generation_fallback_triggered` (spec B) mencatatnya supaya developer sadar tanpa pemain pernah melihat error apa pun.

## 3. Daily Challenge — Network Gagal

### Insight penting: konten Daily Challenge tidak butuh network sama sekali

Karena soal Daily Challenge deterministik dari `seed = hash(date + band)` (§8.1 core-gameplay-spec), **client bisa generate soalnya sendiri secara lokal** — tidak ada request network yang wajib berhasil untuk pemain bisa main. Network hanya dibutuhkan untuk dua hal opsional:
1. Submit skor ke leaderboard per-band
2. Tarik `aggregate_accuracy_per_fact` dari server (untuk kalibrasi, bukan untuk pemain main)

### Strategi

```dart
Future<DailyChallenge> loadDailyChallenge(DateTime date, LevelBand band) async {
  // Konten SELALU berhasil — generate lokal, tidak butuh network
  final challenge = generateDailyChallenge(date, band);

  // Submit skor: retry di belakang layar, tidak menghalangi pemain mulai main
  return challenge;
}

Future<void> submitDailyChallengeResult(DailyChallengeResult result) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      await _api.submitResult(result);
      return;
    } catch (_) {
      await Future.delayed(Duration(seconds: pow(2, attempt).toInt()));
    }
  }
  // 3x gagal — simpan di antrian lokal, coba lagi saat app dibuka berikutnya
  await _pendingSubmissionsRepo.enqueue(result);
}
```

Saat app dibuka, proses `_pendingSubmissionsRepo` di background sebelum submission baru — supaya skor lama tidak pernah hilang. UI leaderboard menampilkan status "peringkat belum ter-submit" alih-alih memblokir pemain mengulang Daily Challenge.

## 4. Edge Case Lain

| Kasus | Penanganan | Alasan |
|---|---|---|
| App di-kill paksa (bukan cuma background) di tengah ronde | Saat app dibuka lagi, ronde yang belum selesai **dibuang**, bukan di-resume dari state tersimpan | Mencegah state timer/soal yang stale terasa aneh, dan menutup celah manipulasi (edit save state manual untuk "freeze" timer) |
| Tap ganda cepat di tombol jawaban | Debounce: hanya tap pertama diproses; abaikan tap berikutnya sampai state pindah dari `Active` | Mencegah submit ganda / race condition ke `MasteryRepository` |
| Tanggal device vs tanggal server berbeda (Daily Challenge) | Pakai **tanggal lokal device**, bukan UTC server, untuk menentukan "hari ini" | Konsisten dengan game puzzle harian populer lain — pemain mengharapkan "hari ini" sesuai jam di HP mereka, bukan zona waktu server |
| Semua distraktor berbasis-error kebetulan identik dengan `correct_answer` atau satu sama lain | `DistractorGenerator` sudah filter `distinct` (§3.3 core-gameplay-spec); kalau tetap kurang dari 3 kandidat unik, isi sisa slot dengan random-near-miss | Grid 4 jawaban tidak boleh pernah tampil dengan duplikat nilai |
| Level pemain di luar rentang semua band di `level_bands.json` (mis. konfigurasi JSON tidak update setelah band baru ditambah) | `LevelBandsConfig.bandForLevel` fallback ke band terakhir dalam list | Mencegah crash null — band terakhir seharusnya band tak terbatas (Expert), tapi dijaga untuk kasus konfigurasi tidak lengkap |
| `level_bands.json` gagal dimuat total (asset corrupt/hilang) | `levelBandsConfigProvider` (FutureProvider) masuk state error; UI fallback ke kanvas warna netral default sampai berhasil dimuat ulang | Kegagalan load asset statis seharusnya sangat jarang (bug build, bukan kondisi runtime pemain), tapi tetap tidak boleh membuat app crash total |
