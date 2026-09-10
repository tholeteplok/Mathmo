# Speed Math Game — Social & Cloud Sync Spec (Supabase)

## 0. Prinsip

- **Lokal tetap default.** App sepenuhnya bisa dimainkan tanpa akun sama sekali — Hive (`math-speed-game-state-management.md`, `math-speed-game-error-handling-spec.md`) tetap source of truth untuk gameplay. Supabase adalah lapisan opsional yang menambah fitur (leaderboard, sync lintas device, cosmetics), bukan prasyarat bermain.
- **Tidak ada data pribadi wajib.** Jalur signup default (username+password) tidak menyimpan data asli sama sekali. Email/nomor HP tersedia sebagai *pilihan* untuk pemulihan akun, bukan keharusan.
- **Gate di level UI, bukan arsitektur.** Kalau nanti ada fitur berbayar, cek `supabase.auth.currentUser != null` cukup — gameplay inti tidak pernah tersentuh keputusan bisnis ini.

## 1. Tiga Jalur Signup

```
Signup
  ├─ Username + Password    → email sintetis, TANPA recovery
  ├─ Email + Password       → Supabase native, recovery via reset email
  └─ Nomor HP + Password    → Supabase native, recovery via OTP SMS (berbayar)
```

Ketiganya bermuara ke `profiles` table yang sama (§4) — bedanya cuma cara `auth.users.email`/`phone` terisi saat signup. Tidak ada percabangan logic untuk fitur setelahnya (leaderboard, sync, cosmetics).

### 1.1 Username + Password (email sintetis)

Supabase Auth (GoTrue) secara fundamental butuh email/telepon sebagai identifier — tidak ada field "username" native. Solusinya: email sintetis deterministik dari username, bukan email asli siapa pun.

```dart
String _syntheticEmail(String username) =>
    '${username.toLowerCase()}@users.mathmo.internal';

Future<void> signUpWithUsername(String username, String password) async {
  try {
    await supabase.auth.signUp(
      email: _syntheticEmail(username),
      password: password,
      data: {'username': username}, // metadata untuk trigger isi tabel profiles
    );
  } on AuthException catch (e) {
    if (e.message.contains('already registered')) {
      throw UsernameTakenException(username); // uniqueness otomatis dari constraint email
    }
    rethrow;
  }
}

Future<void> loginWithUsername(String username, String password) =>
    supabase.auth.signInWithPassword(
      email: _syntheticEmail(username), // deterministik, tidak perlu query lookup
      password: password,
    );
```

**Konfigurasi wajib**: matikan "Confirm email" di Supabase Auth dashboard — domain `users.mathmo.internal` tidak bisa menerima email sama sekali, jadi konfirmasi email harus di-skip total untuk jalur ini.

**Batasan yang diterima**: tanpa email/telepon asli, tidak ada mekanisme lupa password standar. Kalau password hilang, akun (dan progres cloud-nya) hilang — progres lokal di device tetap aman karena Hive tidak tersentuh oleh hilangnya akses cloud.

### 1.2 Email / Nomor HP + Password

```dart
Future<void> signUpWithEmail(String email, String password) =>
    supabase.auth.signUp(email: email, password: password);

Future<void> signUpWithPhone(String phone, String password) =>
    supabase.auth.signUp(phone: phone, password: password); // + OTP sekali saat signup
```

**Catatan biaya nomor HP**: verifikasi OTP SMS butuh provider berbayar (terintegrasi Supabase, mis. Twilio) — biaya berulang per signup, bukan sekali bayar. OTP cukup dipakai **sekali saat signup** untuk verifikasi; login berikutnya pakai password biasa, supaya biaya SMS tidak berulang tiap kali pemain buka app.

### 1.3 Upgrade: Pseudonymous → Tambah Kontak Pemulihan

Pemain yang mulai dari username-only bisa upgrade ke email/HP asli tanpa akun baru:

```dart
Future<void> addRecoveryEmail(String realEmail) =>
    supabase.auth.updateUser(UserAttributes(email: realEmail));
    // Setelah dikonfirmasi, email sintetis tergantikan — auth.uid() tetap sama,
    // tidak ada migrasi data yang perlu dilakukan

bool get isPseudonymous =>
    supabase.auth.currentUser?.email?.endsWith('@users.mathmo.internal') ?? true;
```

Kalau `isPseudonymous == true`, tampilkan banner **opsional** di halaman profil ("Amankan akunmu — tambah email pemulihan") — tidak wajib, tidak mengganggu alur utama, selaras prinsip anti-frustrasi yang dipegang di seluruh desain gameplay.

### 1.4 Ringkasan

| Jalur | Data disimpan | Recovery | Biaya |
|---|---|---|---|
| Username + password | Tidak ada data asli | Tidak ada (kecuali upgrade §1.3) | Gratis |
| Email + password | Email asli | Ya, standar | Gratis |
| Nomor HP + password | Nomor asli | Ya, via OTP | Berbayar (SMS) |

## 2. Kapan Akun Dibuat

**Tidak otomatis di hari pertama.** Berbeda dari draf awal (anonymous auth otomatis), sekarang benar-benar tidak ada sesi Supabase sampai pemain sendiri memilih "buat akun" — biasanya dipicu saat mau lihat leaderboard, sinkron lintas device, atau akses cosmetics. `player_id` lokal (UUID buatan sendiri, §7 `math-speed-game-json-structures.md`) tetap identitas default selama pemain belum opt-in.

## 3. Migrasi Progres: Lokal → Cloud

Saat akun baru dibuat setelah pemain sudah main secara lokal, progres yang sudah ada (`PlayerProfile`, `MasteryRecord`) harus naik ke cloud sebagai baseline pertama, bukan hilang:

```dart
Future<void> onAccountCreated(String newUserId) async {
  final localProfile = await hiveProfileRepo.getProfile();
  final localMastery = await hiveMasteryRepo.getAllRecords();

  await supabaseProfileRepo.upsert(newUserId, localProfile);
  await supabaseMasteryRepo.bulkUpsert(newUserId, localMastery);

  await hiveProfileRepo.updatePlayerId(newUserId); // player_id lokal diganti ke auth.uid()
}
```

### 3.1 Konflik: Login Akun Lama di Device dengan Progres Lokal Sendiri

Kasus: pemain login ke akun yang sudah pernah dipakai di device lain, padahal device saat ini sudah punya progres lokal sendiri (mis. dipinjam orang lain sebelumnya). **Jangan auto-merge diam-diam** — menggabungkan dua `MasteryRecord` dari sumber berbeda otomatis bisa menghasilkan data yang tidak masuk akal (box Leitner tercampur antar "pemain" berbeda yang sebenarnya berbeda kemampuan).

```dart
Future<void> onLoginWithExistingLocalProgress({
  required PlayerProfile localProfile,
  required PlayerProfile cloudProfile,
}) async {
  final hasNontrivialLocalProgress = localProfile.currentLevel > 1;
  if (!hasNontrivialLocalProgress) {
    await _replaceLocalWithCloud(cloudProfile);
    return;
  }

  // Tampilkan dialog pilihan — JANGAN merge otomatis
  final choice = await showProgressConflictDialog(
    localLevel: localProfile.currentLevel,
    cloudLevel: cloudProfile.currentLevel,
  );

  switch (choice) {
    case ProgressChoice.keepLocal:
      await onAccountCreated(cloudProfile.id); // treat sebagai baseline baru, timpa cloud
    case ProgressChoice.useCloud:
      await _replaceLocalWithCloud(cloudProfile);
  }
}
```

## 4. Skema Tabel

```sql
create table public.profiles (
  id uuid primary key references auth.users(id),
  username text unique not null,
  display_name text,              -- nama tampilan publik, boleh beda dari username
  current_level int not null default 1,
  total_xp int not null default 0,
  cosmetics jsonb default '{}',   -- kustomisasi masa depan, fleksibel tanpa migrasi schema
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "pemain baca profil sendiri"
  on public.profiles for select using (auth.uid() = id);

create policy "pemain update profil sendiri"
  on public.profiles for update using (auth.uid() = id);

create table public.daily_challenge_results (
  player_id uuid references auth.users(id),
  date date not null,
  band text not null,
  correct_count int not null,
  total_time_ms int not null,
  primary key (player_id, date)
);

alter table public.daily_challenge_results enable row level security;

create policy "pemain submit skor sendiri"
  on public.daily_challenge_results for insert with check (auth.uid() = player_id);

create policy "semua bisa baca leaderboard band+tanggal yang sama"
  on public.daily_challenge_results for select using (true);
```

**Catatan privasi**: policy select `using (true)` di `daily_challenge_results` sengaja terbuka (itu tujuan leaderboard), tapi query leaderboard di client **wajib join ke `display_name` saja**, tidak pernah expose `email`/`phone` dari `auth.users` — leaderboard publik tidak pernah butuh data itu. `cosmetics` sebagai `jsonb` (bukan kolom per item) supaya nambah jenis kustomisasi baru tidak perlu migrasi schema tiap fitur.

`current_level`/`total_xp` di `profiles` adalah **cermin** dari `PlayerProfile` lokal (§7 json-structures), disinkron lewat outbox (§5) — bukan sumber kebenaran utama saat gameplay berjalan.

## 5. Arsitektur Sync

Prinsip tidak berubah dari `math-speed-game-error-handling-spec.md` §3: koneksi cloud **tidak boleh** memblokir gameplay. Pola retry-queue yang sudah didesain untuk Daily Challenge submission digeneralisasi jadi outbox untuk semua sinkronisasi ke Supabase.

```
data/
  local/
    hive_mastery_repository.dart      // sudah ada, tetap source of truth
  remote/
    supabase_profile_repository.dart  // BARU
    supabase_leaderboard_repository.dart  // BARU
  sync/
    sync_outbox.dart  // generalisasi _pendingSubmissionsRepo (error-handling-spec §3)
```

`domain/repositories/` (interface abstrak, `math-speed-game-state-management.md` §2) **tidak berubah** — hanya implementasi konkret di `data/` yang bertambah. Provider baru (`playerAccountProvider`, `leaderboardProvider`) mengikuti pola Riverpod yang sama dengan provider yang sudah ada.

## 6. Anak & Kepatuhan (Carry-over dari Analytics Spec §0)

Tiga jalur signup di §1 secara langsung mendukung prinsip yang sudah ditetapkan di `math-speed-game-analytics-logging-spec.md` §0: jalur username-only **tidak pernah** minta data pribadi, jadi tetap jadi jalur default yang paling aman untuk audiens anak. Jalur email/HP asli hanya masuk akal ditawarkan ke pemain dewasa/orang tua yang secara sadar memilihnya — bukan jalur yang didorong sebagai default di UI.

## 7. Yang Belum Dibahas (Menyusul, Setelah Fondasi Ini Teruji)

- Recovery phrase untuk jalur username-only (§1.1) — masih opsi terbuka, belum diputuskan wajib atau tidak
- Detail RPC/edge function untuk `aggregate_accuracy_per_fact` (§8.2 core-gameplay-spec) — sync agregat lintas pemain untuk kalibrasi Daily Challenge
- Skema `cosmetics` yang lebih konkret (jenis item, cara didapat) — sengaja ditunda sampai ada kebutuhan nyata
