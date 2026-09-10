# Speed Math Game — Level Replay Score & Daily Challenge Lock Spec

Spec ini ditulis berdasarkan pengecekan langsung ke `github.com/tholeteplok/Mathmo` (state kode saat ini) — nama file, pola `RepoResult`/`RepoSuccess`/`RepoFailure`, dan gaya model (`fromJson`/`toJson`/`copyWith`/`==`/`hashCode`) mengikuti konvensi yang sudah dipakai di repo, bukan asumsi dari spec kertas sebelumnya.

## 0. Ringkasan Keputusan

- **Model level yang dipakai: discrete node (Model B)** — sudah dikonfirmasi dari `level_node.dart` (`LevelNodeStatus.completed/active/locked`). Tiap level adalah unit tetap yang bisa diulang.
- **Bintang (`levelStarsProvider`) dan skor replay ini adalah dua metrik terpisah** — bintang berbasis akurasi (indikator penguasaan), skor replay di bawah ini berbasis poin (kompetitif/leaderboard). Tidak digabung.
- **Daily Challenge**: infrastruktur penguncian **sudah setengah ada** — `HiveDailyChallengeRepository.getResult(date, band)` sudah bisa dipakai langsung, tinggal di-wire ke provider baru + UI locked state.

## 1. Level Replay Score (Best-Score Delta)

### 1.1 Formula

```
delta = max(0, new_score - level_best_score)
total_score += delta
level_best_score = max(level_best_score, new_score)
```

Replay yang skornya lebih rendah dari rekor sebelumnya: `total_score` tidak berubah. Replay yang lebih tinggi: cuma selisihnya yang ditambahkan — bukan skor penuh dari attempt baru, supaya tidak bisa grinding level yang sama berkali-kali untuk skor tak terbatas.

**Sengaja terpisah dari XP** (`ScoringService.computeSessionXp`, sudah ada di kode) — XP tetap dapat penuh tiap replay berdasarkan fact yang membaik, tidak terkena aturan delta ini. Kalau delta juga diterapkan ke XP, replay untuk melatih fact lemah (yang skornya wajar lebih rendah karena sengaja menghadapi soal sulit) jadi tidak dapat XP — bertentangan dengan tujuan Mastery Bank yang sudah dibangun.

### 1.2 Model Baru: `LevelScoreRecord`

```dart
// lib/domain/models/level_score_record.dart
/// Model untuk rekor skor terbaik pemain per level (discrete node).
///
/// File ini adalah Pure Dart dan tidak bergantung pada Flutter atau Riverpod.
library;

class LevelScoreRecord {
  const LevelScoreRecord({
    required this.level,
    required this.bestScore,
    required this.attempts,
  });

  /// Nomor level (node) yang direkam.
  final int level;

  /// Skor tertinggi yang pernah dicapai di level ini.
  final int bestScore;

  /// Jumlah total percobaan (termasuk yang pertama) di level ini.
  final int attempts;

  factory LevelScoreRecord.initial(int level) =>
      LevelScoreRecord(level: level, bestScore: 0, attempts: 0);

  /// Terapkan hasil attempt baru — mengembalikan record baru + delta yang didapat.
  ({LevelScoreRecord record, int delta}) applyAttempt(int newScore) {
    final delta = (newScore - bestScore) > 0 ? newScore - bestScore : 0;
    return (
      record: LevelScoreRecord(
        level: level,
        bestScore: newScore > bestScore ? newScore : bestScore,
        attempts: attempts + 1,
      ),
      delta: delta,
    );
  }

  factory LevelScoreRecord.fromJson(Map<String, dynamic> json) {
    return LevelScoreRecord(
      level: ((json['level']) as num).toInt(),
      bestScore: ((json['best_score'] ?? json['bestScore']) as num).toInt(),
      attempts: ((json['attempts']) as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'level': level,
    'best_score': bestScore,
    'attempts': attempts,
  };

  LevelScoreRecord copyWith({int? level, int? bestScore, int? attempts}) {
    return LevelScoreRecord(
      level: level ?? this.level,
      bestScore: bestScore ?? this.bestScore,
      attempts: attempts ?? this.attempts,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelScoreRecord &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          bestScore == other.bestScore &&
          attempts == other.attempts;

  @override
  int get hashCode => Object.hash(level, bestScore, attempts);

  @override
  String toString() =>
      'LevelScoreRecord(level: $level, best: $bestScore, attempts: $attempts)';
}
```

`applyAttempt` sengaja jadi method di model (bukan logic tersebar di provider) — pola ini konsisten dengan `StreakState.recordActivity`/`onDayMissed` yang sudah dipakai di `player_profile.dart` untuk logic serupa (transformasi state + aturan bisnis menyatu di satu tempat yang gampang di-unit-test tanpa mock apa pun).

### 1.3 Repository

```dart
// lib/domain/repositories/level_score_repository.dart
abstract interface class LevelScoreRepository {
  Future<RepoResult<LevelScoreRecord?>> getRecord(int level);
  Future<RepoResult<void>> saveRecord(LevelScoreRecord record);
  Future<RepoResult<Map<int, LevelScoreRecord>>> getAllRecords();
}
```

```dart
// lib/data/local/hive_level_score_repository.dart
class HiveLevelScoreRepository implements LevelScoreRepository {
  HiveLevelScoreRepository([Box<Map>? box]) : _box = box;

  static const String boxName = 'level_scores';
  Box<Map>? _box;

  Future<Box<Map>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<Map>(boxName);
    return _box!;
  }

  @override
  Future<RepoResult<LevelScoreRecord?>> getRecord(int level) async {
    try {
      final box = await _getBox();
      final raw = box.get(level.toString());
      if (raw == null) return const RepoSuccess(null);
      return RepoSuccess(
        LevelScoreRecord.fromJson(Map<String, dynamic>.from(raw)),
      );
    } catch (e) {
      return RepoFailure('Gagal memuat rekor skor level', e);
    }
  }

  @override
  Future<RepoResult<void>> saveRecord(LevelScoreRecord record) async {
    try {
      final box = await _getBox();
      await box.put(record.level.toString(), record.toJson());
      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure('Gagal menyimpan rekor skor level', e);
    }
  }

  @override
  Future<RepoResult<Map<int, LevelScoreRecord>>> getAllRecords() async {
    try {
      final box = await _getBox();
      final map = <int, LevelScoreRecord>{};
      for (final entry in box.toMap().entries) {
        final record = LevelScoreRecord.fromJson(
          Map<String, dynamic>.from(entry.value),
        );
        map[record.level] = record;
      }
      return RepoSuccess(map);
    } catch (e) {
      return RepoFailure('Gagal memuat seluruh rekor skor level', e);
    }
  }
}
```

Box terpisah (`level_scores`) dari `daily_challenges`/`daily_challenge_results` — mengikuti pola satu Hive box per concern yang sudah konsisten dipakai di seluruh `data/local/`.

### 1.4 Field Baru di `PlayerProfile`

Tambahkan `totalScore` ke `lib/domain/models/player_profile.dart`, sejajar dengan `totalXp` yang sudah ada — termasuk di constructor, `fromJson`/`toJson` (key `total_score`), `copyWith`, `==`, dan `hashCode`. Nilai awal `0` di `PlayerProfile.initial`.

### 1.5 Wiring ke `ScoringService`

```dart
// tambahan method di lib/domain/services/scoring_service.dart
/// Menghitung delta skor untuk penyelesaian/pengulangan sebuah level (node).
///
/// Berbeda dari [computeRoundScore] (per-soal) — ini beroperasi di level
/// SessionResult.totalScore vs rekor terbaik level tersebut.
({int scoreDelta, LevelScoreRecord updatedRecord}) computeLevelReplayDelta({
  required LevelScoreRecord currentRecord,
  required int newSessionScore,
}) {
  final result = currentRecord.applyAttempt(newSessionScore);
  return (scoreDelta: result.delta, updatedRecord: result.record);
}
```

Dipanggil dari titik yang sama dengan `computeSessionXp` sekarang dipanggil — kemungkinan besar di `game_session_provider.dart` saat transisi ke `SessionEnded`, atau di layer yang mengonsumsi `SessionResult` sebelum masuk `ResultsScreen`. `PlayerProfile.totalScore` di-update lewat `playerProfileProvider` di titik yang sama dengan update `totalXp` sekarang.

## 2. Daily Challenge Lock

### 2.1 Yang Sudah Tersedia

`HiveDailyChallengeRepository.getResult(DateTime date, String band)` **sudah ada** dan mengembalikan `RepoResult<DailyChallengeResult?>` — `null` berarti belum dikerjakan hari itu. Tidak perlu method repository baru.

### 2.2 Provider Baru

```dart
// tambahan di lib/presentation/daily_challenge/providers/daily_challenge_provider.dart
final dailyChallengeCompletionProvider = FutureProvider<DailyChallengeResult?>((
  ref,
) async {
  final now = DateTime.now();
  final profile = await ref.watch(playerProfileProvider.future);
  final config = await ref.watch(levelBandsConfigProvider.future);
  final band = config.bandForLevel(profile.currentLevel);

  final repo = ref.watch(dailyChallengeRepositoryProvider);
  final result = await repo.getResult(now, band.id);

  return switch (result) {
    RepoSuccess(:final value) => value,
    RepoFailure() => null, // gagal baca dianggap belum selesai — tidak boleh mengunci pemain karena error I/O
  };
});
```

**Kenapa `RepoFailure` dianggap "belum selesai"**: kalau baca dari Hive gagal (kasus langka, disk error), pilihan paling aman adalah tetap izinkan main — mengunci pemain dari fitur karena kegagalan infrastruktur yang tidak terkait dirinya sendiri bertentangan dengan prinsip graceful degradation di `math-speed-game-error-handling-spec.md`. Worst case, mereka main ulang; tidak ada kerugian dibanding dikunci keliru dari fitur yang sah.

### 2.3 UI Locked State

```dart
// di DailyChallengeScreen atau wrapper sebelum masuk ke gameplay soal
class DailyChallengeGate extends ConsumerWidget {
  const DailyChallengeGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completion = ref.watch(dailyChallengeCompletionProvider);

    return completion.when(
      loading: () => const _DailyChallengeLoadingView(),
      error: (_, __) => const DailyChallengeScreen(), // gagal cek = izinkan main, sesuai §2.2
      data: (result) {
        if (result != null) {
          return _DailyChallengeLockedView(
            correctCount: result.correctCount,
            nextAvailableAt: _nextMidnight(),
          );
        }
        return const DailyChallengeScreen();
      },
    );
  }

  DateTime _nextMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }
}
```

`_DailyChallengeLockedView` mengikuti gaya visual chunky yang sudah ada (`ChunkyCard`, `AppHeader`) — tampilkan hasil hari ini (`correctCount`/12) + countdown ke jam 00:00 berikutnya, bukan pesan error generik.

### 2.4 Edge Case yang Sudah Tercatat (Belum Diubah)

Celah manipulasi tanggal device (mundurkan tanggal sistem untuk main ulang) masih berlaku seperti dicatat di `math-speed-game-error-handling-spec.md` §4 — risiko rendah untuk mode lokal murni, baru jadi isu integritas nyata begitu submission ke leaderboard Supabase aktif (validasi tanggal harus di server, bukan percaya `date` dari client).

## 3. File yang Terdampak (Ringkasan)

| File | Perubahan |
|---|---|
| `lib/domain/models/level_score_record.dart` | **Baru** |
| `lib/domain/repositories/level_score_repository.dart` | **Baru** |
| `lib/data/local/hive_level_score_repository.dart` | **Baru** |
| `lib/domain/models/player_profile.dart` | Tambah field `totalScore` |
| `lib/domain/services/scoring_service.dart` | Tambah method `computeLevelReplayDelta` |
| `lib/presentation/daily_challenge/providers/daily_challenge_provider.dart` | Tambah `dailyChallengeCompletionProvider` |
| `lib/presentation/daily_challenge/widgets/daily_challenge_screen.dart` | Tambah `DailyChallengeGate` + `_DailyChallengeLockedView` |
| `lib/presentation/home/providers/player_profile_provider.dart` | Wiring update `totalScore` sejajar `totalXp` |
