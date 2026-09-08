# Speed Math Game — Navigation Spec

## 1. Peta Layar

```
Home (/) ──┬──> Game (/game/:mode)          mode: normal | practice | sprint
            ├──> DailyChallenge (/daily)
            └──> Results (/results)          hanya dicapai lewat navigasi internal dari Game/DailyChallenge, tidak dari deep link luar
```

**Rekomendasi**: `go_router` — deklaratif, native mendukung deep link (§4), dan integrasi `ShellRoute` cocok untuk header persisten (kanvas warna per band, badge streak/XP) yang perlu tetap ada lintas Home ↔ Game tanpa rebuild ulang saat transisi.

```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/game/:mode',
      builder: (_, state) => GameScreen(mode: GameMode.fromPath(state.pathParameters['mode']!)),
    ),
    GoRoute(path: '/daily', builder: (_, __) => const DailyChallengeScreen()),
    GoRoute(
      path: '/results',
      builder: (_, state) => ResultsScreen(result: state.extra as SessionResult),
    ),
  ],
);
```

`Results` sengaja terima `SessionResult` lewat `extra` (bukan query param) — hasil sesi adalah objek kompleks hasil komputasi, bukan data yang valid untuk di-deep-link dari luar (lihat §3, tidak boleh diakses tanpa sesi yang benar-benar baru selesai).

## 2. Back Button di Tengah Gameplay

Ini titik yang paling gampang salah kalau tidak dispesifikasi — perilaku berbeda tergantung state gameplay saat ini:

| State saat back ditekan | Perilaku |
|---|---|
| `ShowQuestion` / `Active` | **Trigger `Paused`** (bukan langsung keluar) — sama seperti app masuk background (§3.1 `math-speed-game-state-management.md`). Tampilkan dialog konfirmasi: "Keluar dari sesi? Progres level ini akan hilang" dengan pilihan Lanjut / Keluar. |
| `Feedback` | Tunda back sampai transisi feedback selesai (±400ms) — hindari state race antara animasi feedback dan navigasi keluar |
| `Paused` (sudah ter-pause, mis. dari app background lalu pemain buka dialog back) | Back kedua = konfirmasi keluar langsung (tidak perlu pause dua kali) |
| `SessionEnded` (sudah di Results) | Back = kembali ke Home biasa, tanpa dialog — sesi sudah selesai, tidak ada progres yang bisa hilang |

**Kenapa dialog konfirmasi, bukan langsung keluar**: keluar dari `Active` tanpa konfirmasi berarti kehilangan progres level yang sedang berjalan tanpa peringatan — bertentangan dengan prinsip anti-frustrasi yang dipegang di seluruh desain ini. Progres yang sudah tersimpan (Mastery Bank, XP dari ronde-ronde sebelumnya di sesi ini) tetap aman karena `onAnswerSubmit` sudah persist tiap jawaban (§4.3 core-gameplay-spec) — yang hilang cuma progres level *yang sedang berjalan*, bukan seluruh riwayat.

```dart
Future<bool> onWillPop(GameSessionState state) async {
  if (state is Feedback) return false; // tunda, jangan biarkan pop di tengah animasi
  if (state is Active || state is ShowQuestion) {
    gameSessionNotifier.pause();
    final shouldExit = await showExitConfirmDialog(context);
    if (!shouldExit) {
      gameSessionNotifier.resume();
      return false;
    }
    return true;
  }
  return true; // Paused, SessionEnded — boleh langsung pop
}
```

## 3. Guard: Results Tidak Boleh Diakses Langsung

`/results` bukan tujuan deep link yang valid — kalau pemain (atau OS lewat "recent apps" restore) mencoba membuka layar ini tanpa `SessionResult` yang baru dihasilkan, redirect ke Home:

```dart
GoRoute(
  path: '/results',
  redirect: (context, state) {
    if (state.extra is! SessionResult) return '/';
    return null;
  },
  builder: (_, state) => ResultsScreen(result: state.extra as SessionResult),
),
```

## 4. Deep Link Daily Challenge

`/daily` **aman untuk deep link eksternal** (notifikasi push "Daily Challenge hari ini sudah siap!", share link antar pemain) — berbeda dari `/results`, karena kontennya deterministik dari tanggal + band (§8.1 core-gameplay-spec), bukan hasil komputasi sesi yang harus baru terjadi.

```dart
GoRoute(
  path: '/daily',
  builder: (_, __) => const DailyChallengeScreen(),
  // Tidak perlu extra/redirect — layar ini generate konten sendiri
  // dari tanggal device + band pemain saat ini (lihat §3 error-handling-spec:
  // konten Daily Challenge tidak bergantung data yang dikirim lewat navigasi)
),
```

Kalau pemain belum pernah main sama sekali (level belum ada / `PlayerProfile` belum tercipta) dan membuka deep link `/daily` langsung dari notifikasi push: redirect dulu ke onboarding minimal (lihat `math-speed-game-future-specs.md` §1) sebelum bisa menentukan band yang sesuai.

## 5. Header Persisten (ShellRoute)

Badge streak/XP dan kanvas warna per band (§5 `math-speed-game-state-management.md`) tampil di Home dan Game, tapi **tidak** perlu di-rebuild ulang saat pindah dari Home ke Game — `ShellRoute` menjaga widget header tetap hidup lintas transisi:

```dart
ShellRoute(
  builder: (context, state, child) => AppShell(child: child),
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/game/:mode', builder: (_, state) => GameScreen(/* ... */)),
  ],
),
```

Ini juga yang membuat transisi kanvas warna (§6 `math-speed-game-visual-design-spec.md`, animasi ±300ms) terasa mulus antar layar — kalau tidak pakai `ShellRoute`, tiap navigasi akan membangun ulang `levelBandThemeProvider` listener dari nol dan animasi transisinya terpotong.
