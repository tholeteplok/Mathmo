# Speed Math Game — Core Gameplay Spec (Difficulty, Distractor, Mastery)

## 0. Filosofi Inti

> Speed Math bukan game untuk membuktikan siapa yang paling cepat menghitung.
> Speed adalah alat untuk mengukur dan melatih **fluency**.

Fluency didefinisikan bukan sekadar kecepatan, tapi kombinasi empat hal: **akurasi, efisiensi, fleksibilitas strategi, dan ketepatan memilih strategi** (Kilpatrick et al., *Adding It Up*, National Research Council). Prinsip ini jadi filter untuk semua keputusan desain di bawah — Question Generator, Distractor Generator, Mastery Bank, DDA, scoring, sampai visual — semuanya harus mengukur dan melatih fluency, bukan cuma memaksimalkan kecepatan mentah.

Dokumen ini melengkapi dua spec sebelumnya:
- `math-speed-game-spec.md` — state machine, level/timer formula, scoring dasar, arsitektur Flutter umum
- `math-speed-game-visual-design-spec.md` — sistem warna, tipografi, gaya komponen

---

## 1. Question Difficulty Model

### 1.1 Masalah dengan model kesulitan linear

Menyamakan "sulit" dengan "digit lebih banyak" itu keliru. Riset strategi aritmatika (Siegler) mengidentifikasi kesulitan sebenarnya datang dari **strategi kognitif apa yang dipaksa dipakai otak**:

1. **Direct retrieval** — fakta dihafal langsung (6×7, doubles, ×0/×1/×10)
2. **Counting** — masih menghitung manual (level sangat awal)
3. **Derived facts** — turunan dari fakta lain (7+8 = 7+7+1, kompensasi 19+6 = 20+6−1)

`27 + 8` dan `27 + 3` sama-sama "2-digit + 1-digit" tapi yang pertama butuh *crossing decade* — secara kognitif jauh lebih berat meski terlihat setara dari ukuran digit.

### 1.2 Model multi-dimensi

```
QuestionDifficulty {
  operand_magnitude: 1-digit | 2-digit | 3-digit
  operation: add | sub | mul | div | mixed
  structural_property: requires_carry | requires_borrow | crosses_decade | none
  strategy_tag: retrieval | derived | procedural
  step_count: 1 | 2 | 3
}
```

`strategy_tag` adalah prediktor kesulitan kognitif riil — bukan proxy visual (jumlah digit) yang bisa menyesatkan (soal "kelihatan level 20" tapi trivial, atau sebaliknya).

---

## 2. Question Generator

Template + constraint, bukan random murni — menjamin `strategy_tag` selalu konsisten dengan isi soal yang dihasilkan.

```
QuestionTemplate {
  operation: Operation
  operand_range: Range
  constraints: {
    require_carry: bool?
    require_borrow: bool?
    avoid_trivial: bool        // hindari ×1, ×0, ×10, a−a kecuali sengaja disertakan
    strategy_tag: StrategyTag
    step_count: int
  }
}

generate(template) -> Question {
  loop: sample operands dalam operand_range
  until: semua constraint terpenuhi
  return Question(operands, strategy_tag, difficulty_tier, fact_key)
}
```

Setiap `Question` membawa `fact_key` unik (mis. `"7x8"`, `"add_crossdecade_2digit"`) — fondasi wajib untuk Mastery + Mistake Bank (§4).

---

## 3. Distractor / Answer Generator

### 3.1 Prinsip

Distraktor berkualitas bukan angka acak di sekitar jawaban benar, tapi hasil dari **kesalahan prosedural nyata**. Distraktor acak gampang ditebak (terasa "terlalu jauh"); distraktor berbasis miskonsepsi terasa meyakinkan — dan justru itu yang membuat tantangan terasa jujur, bukan menipu.

### 3.2 Taksonomi error per operasi

| Operasi | Error pattern | Cara hasilkan |
|---|---|---|
| Penjumlahan | lupa carry | jumlah per kolom tanpa carry-over |
| | off-by-10 | hasil benar ±10 |
| Pengurangan | lupa borrow | kurangi per kolom, ambil nilai absolut |
| | tertukar arah | hasil dari operand terbalik |
| Perkalian | ganti operasi jadi tambah | `a + b` alih-alih `a × b` |
| | fakta tabel tetangga | hasil dari `a × (b±1)` |
| | cuma kalikan satu digit | digit puluhan diabaikan |
| Pembagian | tertukar arah | `b ÷ a` alih-alih `a ÷ b` |
| | sisa bagi salah dibulatkan | pembulatan ke arah salah |

### 3.3 Arsitektur

```
DistractorGenerator {
  strategies: List<DistractorStrategy>  // satu strategy = satu error pattern

  generate(question, count=3) -> List<Distractor> {
    candidates = strategies
      .filter(applicable to question.operation)
      .map(strategy => strategy.apply(question))
      .filter(distinct from correct_answer, distinct from each other, plausible/positive)

    if candidates.length < count:
      fill sisa slot dengan random-near-miss (correct ± small offset)

    return shuffle(take(candidates, count))
  }
}

Distractor {
  value: number
  error_type: string   // wajib disimpan — input Mistake Bank
}
```

### 3.4 Kalibrasi per level

- **Level rendah**: campur distractor berbasis-error dengan 1 distractor jauh jelas salah — pemula tidak langsung dihadapkan 4 pilihan mirip semua
- **Level tinggi**: semua 4 pilihan dari error pattern nyata, berdekatan nilainya — kesulitan datang dari pilihan yang menggoda, bukan angka besar

### 3.5 Posisi jawaban

Posisi jawaban benar di grid 2×2 **diacak tiap soal**. Posisi berpola membuat pemain pattern-match posisi, bukan menghitung — merusak tujuan mengukur fluency.

---

## 4. Mastery + Mistake Bank

### 4.1 Pendekatan

Gold standard di intelligent tutoring system adalah Bayesian Knowledge Tracing (BKT) — model probabilistik dengan mastery sebagai variabel laten biner, diperbarui dari observasi benar/salah per skill. BKT penuh (fitting parameter, HMM inference) adalah **over-engineering untuk v1** — cocok jadi upgrade fase lanjut. Untuk sekarang: sliding window + sistem box ala Leitner, cukup akurat untuk skill space kecil (fakta aritmatika) dan jauh lebih murah dihitung.

### 4.2 Data Model

```
MasteryRecord {
  fact_key: string
  attempts: int
  correct: int
  recent_results: List<bool>            // sliding window, 8 percobaan terakhir
  avg_response_time: float
  mastery_score: float                  // 0.0–1.0, bobot ke hasil terbaru
  box: int                              // 1–5, box tinggi = interval kemunculan makin jarang
  last_seen_at: timestamp
  error_type_counts: Map<string, int>   // dari Distractor Generator
}
```

Sliding window + box dipilih ketimbang persentase-benar-total karena persentase total lambat bereaksi — pemain yang dulu lemah tapi sudah membaik tetap terlihat "lemah" lama.

### 4.3 Alur Update

```
onAnswerSubmit(fact_key, isCorrect, responseTime, errorType?) {
  record = masteryBank.get(fact_key) ?? new MasteryRecord(fact_key)
  record.attempts += 1
  record.recent_results.push(isCorrect); trim to last 8

  if isCorrect:
    record.correct += 1
    record.box = min(record.box + 1, 5)
  else:
    record.box = max(record.box - 2, 1)   // turun lebih cepat drpd naik
    record.error_type_counts[errorType] += 1

  record.mastery_score = weighted_average(record.recent_results)
  record.last_seen_at = now
}
```

### 4.4 Hubungan ke Practice Mode

- Fact dengan `box <= 2` masuk antrian prioritas resurface — **tidak langsung diulang**, diselipkan setelah 3–5 soal lain (spaced retrieval, prinsip sama dengan Leitner/spaced repetition)
- `error_type_counts` dominan bisa memicu micro-hint kontekstual **khusus di Practice Mode** (bukan Sprint Mode yang harus tetap cepat) — selaras dengan filosofi fluency: game membantu memperbaiki cara berpikir, bukan cuma mengukur kecepatan
- Fact dengan `mastery_score` tinggi & `box = 5` boleh jarang muncul, tapi tidak pernah 0% — forgetting curve tetap berlaku meski sudah "dikuasai"

### 4.5 Arsitektur Flutter

```
domain/
  mastery/
    mastery_record.dart
    mastery_repository.dart      // abstraksi; implementasi lokal Hive/sqflite
    mastery_update_service.dart  // pure logic, testable tanpa DB nyata
```

`MasteryRepository` di-inject ke `GameController` (state machine gameplay) dan `QuestionGenerator` (query fact mana yang perlu resurface untuk Practice Mode) — dua konsumen, satu sumber data.

---

## 5. Keterhubungan Antar Komponen

```
QuestionGenerator ──fact_key──> Question ──> DistractorGenerator ──error_type──> Distractor[]
       ▲                                              │
       │                                              ▼
       └──────────────── MasteryRepository <── onAnswerSubmit (fact_key, isCorrect, error_type)
```

`fact_key` dan `error_type` adalah dua identitas yang mengalir lintas komponen — keduanya fondasi setiap fitur adaptif berikutnya (DDA, Practice Mode, hint kontekstual).

---

## 6. DDA Formula (Revisi)

DDA versi awal (`math-speed-game-spec.md` §3) hanya bereaksi ke performa sesi berjalan. Ini dipecah jadi dua layer dengan tujuan berbeda — jangan digabung jadi satu angka.

### 6.1 Layer 1 — Timer leniency (jangka pendek, per sesi)

Formula awal tetap dipakai, khusus untuk tekanan waktu:

```
confidence_score: benar cepat (+1) / benar mepet (0) / salah-timeout (−1)
confidence_score <= -2 → timer level ini +15% (diam-diam)
confidence_score >= 2  → level naik lebih cepat
```

### 6.2 Layer 2 — Content mix (jangka panjang, dari Mastery Bank)

Sisipkan interleaving bahkan di mode normal, bukan cuma di Practice Mode:

```
question_selection(current_level) {
  roll = random(1, 6)
  if roll == 1 and masteryBank.has_facts(box <= 3):
    return pick_weak_fact_from(masteryBank)   // fact lama, box rendah
  else:
    return questionGenerator.next(current_level)  // fact baru sesuai level normal
}
```

Berbasis riset *desirable difficulties* (Bjork): interleaving terasa lebih sulit di sesi berjalan (performa terlihat lebih buruk), tapi retensi jangka panjang jauh lebih baik dibanding blocked practice — studi kelas nyata mencatat interleaving meningkatkan hasil tes tunda ~43 poin persentase dibanding blocked practice. Nuansa penting: blocking tetap optimal di **awal** perkenalan fact type (fokus eksekusi strategi dulu); begitu box terisi (sudah pernah dicoba), fact itu masuk pool interleaving. Rasio 1 dari 6 soal sengaja kecil — cukup untuk efek interleaving tanpa mengganggu flow level yang sedang dimainkan.

## 7. Scoring & XP Economy (Revisi)

Dipisah jadi dua sistem dengan tujuan berbeda — round score untuk feedback instan, XP untuk progres akun jangka panjang.

### 7.1 Round score

```
base_points   = 10 * level_multiplier
speed_bonus   = round(base_points * 0.3 * (time_left / time_total))   // dibatasi, bukan dominan
mastery_bonus = fact.box <= 2 ? 8 : 0     // bonus khusus menjawab benar fact yang sedang lemah
streak_bonus  = min(streak_correct * 2, 20)

round_score = base_points + speed_bonus + mastery_bonus + streak_bonus
```

`mastery_bonus` menegaskan pesan filosofis §0: melatih kelemahan bernilai setara/lebih dari sekadar cepat.

### 7.2 XP (progres akun — terpisah total dari kecepatan)

```
session_xp = (distinct_facts_practiced * 2) + (facts_moved_up_a_box * 5) + (session_completed ? 10 : 0)
```

XP sengaja tidak menghitung kecepatan sama sekali — kalau XP ikut reward kecepatan, pemain punya insentif menghindari fact sulit demi grinding fact mudah secepat mungkin, bertentangan dengan tujuan fluency. XP naik dari keberagaman fact yang dilatih dan fact yang benar-benar membaik (box naik).

### 7.3 Daily Challenge scoring (beda tujuan)

Total benar sebagai skor utama, waktu total cuma tie-breaker — tanpa `speed_bonus` per soal, supaya pemain dengan device/koneksi lebih responsif tidak diuntungkan secara tidak adil.

## 8. Daily Challenge / Retention Loop

### 8.1 Fairness: seed per band, bukan per semua pemain

Soal identik untuk semua pemain tanpa mempertimbangkan level bikin timpang (expert menganggap terlalu mudah, pemula menganggap terlalu sulit). Solusi: seed sama **di dalam kohor level band yang sama** (band yang sama dengan sistem warna kanvas §2 di spec visual).

```
DailyChallenge {
  date: date
  band: LevelBand
  seed: hash(date_string + band)
  questions: List<Question>   // deterministik dari seed, digenerate sekali per hari
}

generateDailyChallenge(date, band) {
  rng = SeededRandom(hash(date + band))
  template = difficultyTemplateFor(band)
  questions = (1..12).map(_ => questionGenerator.generate(template, rng: rng))
  distractors = questions.map(q => distractorGenerator.generate(q, rng: rng))
  return DailyChallenge(date, band, questions, distractors)
}
```

Leaderboard per-band, bukan global — pemain level 8 tidak dibandingkan dengan pemain level 60.

### 8.2 Kalibrasi dari data agregat

Karena soal deterministik & sama untuk satu kohor, simpan `aggregate_accuracy_per_fact` dari semua pemain yang mengerjakan tantangan hari itu. Kalau akurasi kohor <40% atau >95% pada suatu fact, kalibrasi template hari berikutnya — kesulitan dijaga dari data pemain sungguhan, bukan asumsi desainer.

### 8.3 Streak dengan jaring pengaman

```
StreakState {
  current_streak: int
  freeze_tokens: int   // "asuransi" — otomatis dipakai kalau 1 hari absen
}

onDayMissed() {
  if freeze_tokens > 0:
    freeze_tokens -= 1   // streak tetap lanjut
  else:
    current_streak = 0
}
```

`freeze_tokens` didapat dari konsistensi (mis. +1 tiap 7 hari beruntun), bukan dibeli — selaras prinsip "tidak menghukum" yang dipegang sejak awal, dan menghindari tekanan monetisasi yang bertentangan dengan filosofi game ini.

### 8.4 Tidak ada sistem paralel

Daily Challenge memakai `questionGenerator` dan `distractorGenerator` yang sama — otomatis mewarisi `fact_key`, `strategy_tag`, dan distraktor berbasis miskonsepsi. Bedanya hanya determinisme (seeded) dan pengelompokan per band.

## 9. Setelah Core Stabil

Leaderboard, achievements, cosmetics, fitur sosial — sengaja ditunda sampai fondasi fact_key/error_type/mastery di atas teruji lewat playtesting nyata.
