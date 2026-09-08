# Speed Math Game — Analytics & Logging Spec

## 0. Catatan Penting: Kemungkinan Audiens Anak

Kalau game ini juga menyasar audiens usia sekolah (sama seperti FLARE Node), analytics punya implikasi kepatuhan nyata — bukan cuma keputusan teknis. Regulasi seperti COPPA (AS) dan UU PDP (Indonesia) membatasi pengumpulan data dari anak di bawah umur, termasuk identifier yang bisa dipakai untuk tracking iklan/lintas-app. Ini bukan sesuatu untuk diputuskan sepihak di level implementasi — **perlu keputusan produk eksplisit** sebelum memilih provider analytics pihak ketiga. Rekomendasi default paling aman: mulai dari local-first (§2), tunda provider pihak ketiga sampai kebutuhan dan audiens targetnya jelas.

## 1. Prinsip

- **Local-first**: semua event dicatat lokal dulu. Kirim ke server bersifat opsional/tertunda, bukan syarat game bisa jalan (selaras §3 error handling spec — Daily Challenge juga tidak bergantung network).
- **Tanpa PII**: tidak ada nama, email, atau identifier lintas-app. `player_id` adalah UUID lokal yang digenerate saat instalasi pertama, bukan terhubung ke identitas nyata.
- **Event minimal tapi cukup untuk kalibrasi**: fokus ke apa yang benar-benar dipakai — kalibrasi kesulitan Daily Challenge (§8.2 core-gameplay-spec) dan tuning DDA — bukan mengumpulkan semua yang bisa dilog "siapa tahu berguna nanti".

## 2. Strategi Penyimpanan & Pengiriman

```
EventLog (Hive box lokal, append-only, capped)
  ├─ event_name: string
  ├─ timestamp: ISO8601
  ├─ player_id: uuid lokal
  ├─ payload: Map<String, dynamic>

Cap: simpan maksimum ~2000 event terbaru mentah.
Setiap 24 jam (atau saat app dibuka setelah gap panjang):
  - agregasi event lama jadi ringkasan harian (mis. total soal dijawab,
    akurasi rata-rata, waktu main) — pola yang sama dengan rolling log
    di sistem lain: jangan simpan mentah selamanya, ringkas lalu buang.
  - event mentah yang sudah diagregasi dibuang dari box.
```

**Pengiriman ke server** (opsional untuk v1, lihat §0): kalau nanti diaktifkan, kirim dalam batch saat perangkat terhubung WiFi, bukan tiap event individual — penting untuk pasar Indonesia di mana kuota data seluler jadi pertimbangan nyata bagi banyak pemain, terutama audiens pelajar.

```dart
Future<void> flushEventsIfOnWifi() async {
  final connectivity = await Connectivity().checkConnectivity();
  if (connectivity != ConnectivityResult.wifi) return;
  final batch = await _eventLog.pendingBatch();
  if (batch.isEmpty) return;
  await _analyticsApi.sendBatch(batch); // gagal? biarkan, coba lagi nanti — tidak ada retry agresif untuk analytics
}
```

Analytics **tidak butuh retry seagresif** Daily Challenge submission (§3 error handling spec) — kehilangan sebagian data telemetri jauh lebih dapat diterima daripada kehilangan skor pemain.

## 3. Daftar Event

| Event | Trigger | Payload |
|---|---|---|
| `session_started` | Sesi gameplay dimulai (semua mode) | `session_id, mode, level, band` |
| `question_answered` | Tiap jawaban disubmit | `session_id, fact_key, is_correct, error_type, response_time_ms, level, band` |
| `level_up` | Level pemain naik | `from_level, to_level, band_changed (bool)` |
| `mastery_box_changed` | `box` di `MasteryRecord` naik/turun | `fact_key, old_box, new_box` |
| `session_completed` | Sesi berakhir normal | `session_id, total_score, accuracy, xp_earned, duration_ms` |
| `session_abandoned` | Sesi ditinggal (app close paksa/keluar tanpa selesai) | `session_id, rounds_completed, level_at_exit` |
| `streak_event` | Streak lanjut, putus, atau pakai freeze token | `streak_before, action: continued\|broken\|frozen` |
| `daily_challenge_completed` | Daily Challenge selesai | `date, band, correct_count, rank_submitted (bool)` |
| `generation_fallback_triggered` | Question Generator jatuh ke relaxation ladder (§2 error handling spec) | `template_id, relaxation_tier` — **dev diagnostic only**, disarankan sampling rendah (kirim ~10% kejadian) karena volumenya bisa tinggi kalau ada bug template |

`question_answered` adalah event dengan volume tertinggi — ini yang jadi sumber `aggregate_accuracy_per_fact` di Daily Challenge (§8.2 core-gameplay-spec) kalau kalibrasi lintas-pemain nanti diaktifkan.

## 4. Format Event

```json
{
  "event": "question_answered",
  "timestamp": "2026-09-08T14:22:10Z",
  "player_id": "local-uuid-9f3a",
  "payload": {
    "session_id": "s_20260908_1",
    "fact_key": "7x8",
    "is_correct": true,
    "error_type": null,
    "response_time_ms": 1840,
    "level": 12,
    "band": "basic"
  }
}
```

Struktur flat `{event, timestamp, player_id, payload}` dipilih supaya satu skema log bisa menampung semua jenis event tanpa perlu tabel terpisah per event type di local DB — payload yang variabel per event, bukan kolom tabel.

## 5. Ke Mana Dikirim (v1 vs Nanti)

| Fase | Tujuan | Provider |
|---|---|---|
| v1 (sekarang) | Lokal saja — dipakai untuk debug developer & kalibrasi manual (export log, baca sendiri) | Hive box, tidak dikirim ke mana pun |
| v1.x (opsional, setelah keputusan audiens jelas — §0) | Funnel dasar (retensi, panjang sesi) | Firebase Analytics tier gratis, ATAU self-hosted (mis. PostHog self-host) kalau ingin kontrol penuh atas data anak |
| v2+ (kalau kalibrasi lintas-pemain untuk Daily Challenge diaktifkan) | `aggregate_accuracy_per_fact` per band | Endpoint sendiri, agregat sisi server — bukan raw event per pemain yang disimpan permanen |

Untuk v1, **tidak perlu Firebase sama sekali** — event lokal cukup untuk Mika memvalidasi asumsi difficulty model & DDA secara manual dari device sendiri saat playtesting.
