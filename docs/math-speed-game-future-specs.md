# Speed Math Game — Future Specs (Nice-to-Have, Arah Pengembangan)

Dokumen ini sengaja ringkas — tujuannya kerangka arah, bukan spesifikasi siap-implementasi seperti dokumen core. Detail penuh baru layak dibuat setelah core gameplay teruji lewat playtesting nyata (§9 core-gameplay-spec).

## 1. Onboarding / Tutorial Pemain Baru

**Arah**: onboarding harus mengajarkan mekanik lewat bermain langsung (learning-by-doing), bukan layar teks/carousel penjelasan di depan — selaras filosofi fluency (§0 core-gameplay-spec), pemain belajar pola soal dengan mengerjakannya, bukan membaca instruksi soal matematika.

- 3-5 soal pertama di level 1 (`onboarding` band) berjalan dengan **timer disembunyikan** atau sangat longgar (jauh di atas `t_base` normal) — murni membiasakan UI (grid jawaban, tap, feedback) sebelum tekanan waktu dikenalkan
- `PlayerProfile` tercipta saat soal pertama dijawab, bukan lewat form registrasi terpisah — tidak ada friksi sebelum pemain merasakan gameplay-nya sendiri
- Kalau app butuh nama/identitas untuk leaderboard nanti (§3), minta itu **setelah** sesi pertama selesai, bukan sebelum — pemain sudah dapat nilai dari sesi pertama sebelum diminta komitmen apa pun
- Deep link Daily Challenge untuk pemain yang belum pernah main (§4 navigation spec) → arahkan ke 3-5 soal onboarding ini dulu, baru redirect ke `/daily` setelah `PlayerProfile` tercipta

## 2. Sound Design (Haptic & Audio)

**Arah**: audio/haptic memperkuat feedback yang sudah didesain visual (§6 visual design spec), tidak menggantikannya — game harus tetap sepenuhnya bisa dimainkan dalam mode silent (banyak pemain main di sekolah/transportasi umum).

| Momen | Haptic | Audio (opsional, default ON tapi mudah dimatikan) |
|---|---|---|
| Tombol ditekan | Light impact | Klik pendek, bukan efek "chunky" berlebihan |
| Jawaban benar | Medium impact | Nada pendek naik (bukan fanfare panjang — jangan menahan pemain dari soal berikutnya) |
| Jawaban salah/timeout | Selection click (halus) | **Tanpa** buzzer keras — selaras prinsip anti-frustrasi, kesalahan terasa sebagai informasi bukan hukuman (§4.4 core-gameplay-spec) |
| Level up | Success pattern (2x medium impact) | Nada naik lebih panjang, satu-satunya momen "perayaan" yang boleh menahan pemain sejenak |
| Streak dipertahankan (Daily Challenge) | Light impact | Opsional, bisa disatukan dengan momen level up kalau bertepatan |

Implementasi: `HapticFeedback` bawaan Flutter untuk haptic (tidak perlu package tambahan), `audioplayers` atau `just_audio` untuk SFX pendek — hindari package yang berat untuk kebutuhan sesederhana ini.

## 3. Kontrak API — Leaderboard & Daily Challenge Server

**Arah**: server API minimal, hanya untuk dua hal yang genuinely butuh koordinasi lintas-pemain (§3 error-handling-spec sudah menegaskan konten Daily Challenge sendiri tidak butuh server).

```
POST /daily-challenge/results
  body: { player_id, date, band, correct_count, total_time_ms }
  → { rank_in_band, total_players_in_band }

GET /daily-challenge/leaderboard?date=&band=&limit=50
  → [{ player_id (anonim/display_name saja), correct_count, total_time_ms, rank }]

POST /daily-challenge/aggregate-accuracy
  body: { date, band, fact_key, is_correct }  (dikirim ter-batch, bukan per-request)
  → 202 Accepted (fire-and-forget dari sisi client, dipakai server untuk §8.2 core-gameplay-spec)
```

**Prinsip privasi**: endpoint ini tidak butuh autentikasi identitas nyata — `player_id` adalah UUID lokal (sama dengan §1 analytics-logging-spec), dan `display_name` (kalau ada untuk leaderboard) adalah nama yang pemain pilih sendiri, terpisah dari data personal apa pun. Selaras catatan kepatuhan anak di §0 analytics-logging-spec.

Detail penuh (auth, rate limiting, skema database server) sengaja belum dibahas — itu keputusan yang lebih baik diambil saat backend benar-benar mulai dibangun, bukan diprediksi sekarang.
