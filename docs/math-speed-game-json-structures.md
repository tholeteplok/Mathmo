# Speed Math Game — JSON Data Structures

Semua struktur di bawah adalah bentuk serialisasi (persisted atau dikirim antar layer) dari model yang sudah dibahas di spec sebelumnya. Field bertanda `// derived` dihitung ulang saat runtime, tidak perlu disimpan kalau storage terbatas — tapi tetap didokumentasikan karena model Dart-nya perlu punya properti ini.

## 1. Question

```json
{
  "id": "q_8f3a1c",
  "fact_key": "7x8",
  "operation": "multiply",
  "operands": [7, 8],
  "correct_answer": 56,
  "difficulty": {
    "operand_magnitude": "1-digit",
    "structural_property": "none",
    "strategy_tag": "retrieval",
    "step_count": 1
  },
  "level_band": "basic",
  "level": 12
}
```

## 2. Distractor (melekat pada satu Question)

```json
{
  "question_id": "q_8f3a1c",
  "distractors": [
    { "value": 63, "error_type": "adjacent_fact_table" },
    { "value": 15, "error_type": "operation_swap_add" },
    { "value": 48, "error_type": "adjacent_fact_table" }
  ],
  "shuffled_indices": [2, 0, 3, 1]
}
```

**Kenapa bukan `answer_order` berisi nilai literal**: menyimpan array nilai (`[56, 63, 15, 48]`) terpisah dari `correct_answer` + `distractors` menciptakan dua sumber kebenaran — kalau suatu saat nilai di `answer_order` tidak sinkron dengan `correct_answer`/`distractors` (bug generator, migrasi data, dsb.), tidak ada cara mendeteksinya, jadi bug tersembunyi sampai pemain melihat jawaban aneh.

`shuffled_indices` sebagai gantinya: indeks permutasi dari array virtual `values = [correct_answer, ...distractors]` (indeks 0 selalu `correct_answer`, 1–3 urutan `distractors`). Contoh di atas: `[2, 0, 3, 1]` berarti tombol pertama menampilkan `values[2]` (distractor kedua, nilai 15), tombol kedua `values[0]` (jawaban benar, 56), dst.

```
values = [correct_answer, ...distractors.map(d => d.value)]
display_values = shuffled_indices.map(i => values[i])
isCorrect(selected_index) = shuffled_indices[selected_index] == 0
```

Karena `shuffled_indices` cuma permutasi angka 0–3, tidak mungkin merepresentasikan nilai yang tidak ada di `values` — kelas bug "jawaban benar hilang dari opsi" jadi mustahil terjadi secara struktural, bukan cuma dicegah lewat disiplin penulisan kode.

## 3. RoundResult (satu jawaban pemain)

```json
{
  "question_id": "q_8f3a1c",
  "fact_key": "7x8",
  "selected_answer": 56,
  "is_correct": true,
  "error_type": null,
  "response_time_ms": 1840,
  "time_total_ms": 4000,
  "round_score": 34,
  "score_breakdown": {
    "base_points": 20,
    "speed_bonus": 6,
    "mastery_bonus": 8,
    "streak_bonus": 0
  },
  "timestamp": "2026-09-08T14:22:10Z"
}
```

## 4. MasteryRecord

```json
{
  "fact_key": "7x8",
  "attempts": 14,
  "correct": 11,
  "recent_results": [true, true, false, true, true, true, false, true],
  "avg_response_time_ms": 2150,
  "mastery_score": 0.78,
  "box": 4,
  "last_seen_at": "2026-09-08T14:22:10Z",
  "error_type_counts": {
    "adjacent_fact_table": 2,
    "operation_swap_add": 1
  }
}
```

Disimpan sebagai map `fact_key -> MasteryRecord`, bukan array, supaya lookup O(1) saat Question Generator query fact yang perlu di-resurface.

```json
{
  "mastery_bank": {
    "7x8": { "...": "MasteryRecord di atas" },
    "add_crossdecade_2digit": { "...": "MasteryRecord lain" }
  }
}
```

## 5. LevelBandConfig (data statis, bukan per-pemain — SATU-SATUNYA sumber kebenaran untuk warna & rentang band)

File ini (`assets/level_bands.json`) dimuat oleh kode saat runtime, bukan di-duplikasi sebagai nilai hardcoded di Dart — lihat `level_band_theme.dart` yang sudah direvisi untuk parse dari JSON ini. Kalau designer ingin ubah warna kanvas suatu band, cukup ubah file ini; tidak ada kode Dart yang perlu disentuh.

```json
{
  "bands": [
    {
      "id": "onboarding",
      "level_range": [1, 5],
      "operations": ["add", "subtract"],
      "digit_range": "1-digit",
      "timer_base_sec": 8,
      "canvas_color": "#EAF3DE",
      "accent_color": "#639922"
    },
    {
      "id": "basic",
      "level_range": [6, 15],
      "operations": ["add", "subtract", "multiply"],
      "digit_range": "1-2-digit",
      "timer_base_sec": 6,
      "canvas_color": "#FAEEDA",
      "accent_color": "#BA7517"
    },
    {
      "id": "intermediate",
      "level_range": [16, 30],
      "operations": ["add", "subtract", "multiply", "divide"],
      "digit_range": "2-digit",
      "timer_base_sec": 4.5,
      "canvas_color": "#FAECE7",
      "accent_color": "#D85A30"
    },
    {
      "id": "advanced",
      "level_range": [31, 50],
      "operations": ["mixed"],
      "digit_range": "2-3-digit",
      "timer_base_sec": 3.5,
      "canvas_color": "#FBEAF0",
      "accent_color": "#D4537E"
    },
    {
      "id": "expert",
      "level_range": [51, null],
      "operations": ["mixed_multistep"],
      "digit_range": "3-digit",
      "timer_base_sec": 3.0,
      "canvas_color": "#EEEDFE",
      "accent_color": "#7F77DD"
    }
  ]
}
```

## 6. SessionResult (ringkasan satu sesi bermain)

```json
{
  "session_id": "s_20260908_1",
  "mode": "normal",
  "started_at": "2026-09-08T14:20:00Z",
  "ended_at": "2026-09-08T14:24:30Z",
  "level_reached": 13,
  "rounds": [ "... array RoundResult" ],
  "total_score": 340,
  "accuracy": 0.86,
  "avg_response_time_ms": 2100,
  "best_streak": 9,
  "xp_earned": 45,
  "xp_breakdown": {
    "distinct_facts_practiced": 8,
    "facts_moved_up_a_box": 3,
    "session_completed_bonus": 10
  }
}
```

`mode` bisa `"normal" | "practice" | "sprint" | "daily_challenge"`.

## 7. PlayerProfile (data akun, persisted)

```json
{
  "player_id": "p_mika01",
  "current_level": 13,
  "total_xp": 1240,
  "streak": {
    "current_streak": 7,
    "freeze_tokens": 1,
    "last_played_date": "2026-09-08"
  },
  "confidence_score": 1,
  "created_at": "2026-08-01T00:00:00Z"
}
```

`confidence_score` (Layer 1 DDA) sengaja ikut disimpan di profile meski sifatnya jangka pendek per level — supaya kalau sesi ditutup di tengah level, nilainya tidak hilang saat dibuka lagi.

## 8. DailyChallenge

```json
{
  "date": "2026-09-08",
  "band": "basic",
  "seed": "a3f9c1",
  "questions": [ "... array Question" ],
  "aggregate_accuracy_per_fact": {
    "7x8": 0.62,
    "9x6": 0.41
  }
}
```

```json
{
  "player_id": "p_mika01",
  "date": "2026-09-08",
  "band": "basic",
  "correct_count": 10,
  "total_time_ms": 38000,
  "rank_in_band": 142
}
```

## 9. GameSessionState (in-memory saja — TIDAK persisted, dokumentasi untuk bentuk state runtime)

```json
{
  "phase": "ACTIVE",
  "current_question": { "...": "Question" },
  "current_distractors": { "...": "Distractor" },
  "shuffled_indices": [2, 0, 3, 1],
  "time_remaining_ms": 2400,
  "streak_correct": 3,
  "streak_wrong": 0,
  "confidence_score": 1
}
```

Saat app masuk background di tengah `ACTIVE`, phase berubah jadi `PAUSED` (lihat `math-speed-game-state-management.md` §3.1 untuk penanganan lifecycle):

```json
{
  "phase": "PAUSED",
  "resumed_phase": "ACTIVE",
  "current_question": { "...": "Question" },
  "current_distractors": { "...": "Distractor" },
  "shuffled_indices": [2, 0, 3, 1],
  "time_remaining_ms": 2400,
  "paused_at": "2026-09-08T14:22:12Z"
}
```

`time_remaining_ms` dibekukan persis di nilai saat pause — bukan dihitung ulang dari `paused_at`, supaya durasi background tidak ikut mengurangi waktu pemain.

Ini bentuk logis state machine (§1 di `math-speed-game-spec.md`, direvisi §3.1 di dokumen state management) — di Flutter direpresentasikan sebagai sealed class/union type, bukan JSON literal, tapi field-nya identik dengan struktur ini.

## 10. Ringkasan Relasi Penyimpanan

| Data | Lokasi | Siklus hidup |
|---|---|---|
| `LevelBandConfig` | asset JSON bundel, read-only | statis, ikut app release |
| `MasteryRecord` (map per fact_key) | local DB (Hive/sqflite) | permanen per pemain |
| `PlayerProfile` | local DB | permanen per pemain |
| `SessionResult` | local DB, append-only log | permanen, untuk riwayat/statistik |
| `DailyChallenge` | fetch/generate sekali per hari, cache lokal | 24 jam |
| `GameSessionState` | in-memory (state notifier) | hilang setelah sesi/app close |
