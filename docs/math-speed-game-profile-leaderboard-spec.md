# Speed Math Game — Profile & Leaderboard Screen Spec

Mengacu ke mockup Visualizer yang sudah disetujui: `math_speed_game_profile_screen`, `math_speed_game_leaderboard_screen`, `math_speed_game_leaderboard_locked_state`. Nama file/provider mengikuti konvensi yang sudah dipakai di `github.com/tholeteplok/Mathmo` (`RepoResult`/`RepoSuccess`/`RepoFailure`, pola provider derivatif seperti `dailyChallengeCompletionProvider`).

## 1. Profile Screen

### 1.1 Rute

```
GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())
```

Diakses dari tombol/ikon profil di `AppShell` (header persisten, §5 `math-speed-game-navigation-spec.md`) — bukan bagian dari `ShellRoute` utama karena bukan layar yang sering bolak-balik dengan Game/Home.

### 1.2 Sumber Data

| Elemen di mockup | Sumber | Sudah ada / baru |
|---|---|---|
| Avatar, level, XP progress bar | `playerProfileProvider` (`currentLevel`, `totalXp`) | Sudah ada |
| Badge status akun ("Akun tamu" / "@username") | `supabase.auth.currentUser` (null = tamu) | Baru — provider tipis, lihat §1.3 |
| Skor total | `playerProfileProvider.totalScore` | Baru (field ditambahkan di `math-speed-game-replay-score-daily-lock-spec.md` §1.4) |
| Akurasi rata-rata | Agregat dari riwayat sesi | **Baru** — belum ada provider ini, lihat §1.4 |
| Fakta dikuasai | Hitung `MasteryRecord` dengan `box == 5` | **Baru** — belum ada provider ini, lihat §1.4 |
| Streak terpanjang | `playerProfileProvider.streak` (perlu field `longestStreak` terpisah dari `currentStreak` kalau belum ada — cek model saat implementasi) | Perlu verifikasi |
| Tombol "buat akun" | Navigasi ke alur signup (`math-speed-game-social-cloud-spec.md` §1) | Sudah dispesifikasikan, belum di-wire ke UI |

### 1.3 Provider Status Akun

```dart
final accountStatusProvider = Provider<AccountStatus>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return AccountStatus.guest;
  final isPseudo = user.email?.endsWith('@users.mathmo.internal') ?? false;
  return isPseudo ? AccountStatus.pseudonymous : AccountStatus.linked;
});

enum AccountStatus { guest, pseudonymous, linked }
```

Tiga state ini yang menentukan badge di header profil: `guest` → "Akun tamu · main lokal" (seperti mockup), `pseudonymous` → nama username tanpa indikator tambahan, `linked` → bisa ditambah ikon centang kecil (opsional, tidak wajib di v1).

### 1.4 Provider Agregat Baru (Belum Ada di Codebase)

```dart
// lib/domain/services/profile_stats_service.dart — PURE DART, tanpa import Flutter/Riverpod
class ProfileStatsService {
  ProfileStatsAggregate computeAggregate({
    required List<SessionResult> recentSessions,
    required Map<String, MasteryRecord> masteryBank,
  }) {
    final avgAccuracy = recentSessions.isEmpty
        ? 0.0
        : recentSessions.map((s) => s.accuracy).reduce((a, b) => a + b) /
            recentSessions.length;

    final masteredCount =
        masteryBank.values.where((r) => r.box == 5).length;

    return ProfileStatsAggregate(
      averageAccuracy: avgAccuracy,
      factsMastered: masteredCount,
    );
  }
}
```

```dart
// lib/presentation/profile/providers/profile_stats_provider.dart
final profileStatsProvider = FutureProvider<ProfileStatsAggregate>((ref) async {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final masteryRepo = ref.watch(masteryRepositoryProvider);

  final sessionsResult = await sessionRepo.getRecentSessions(limit: 100); // method sama dengan levelStarsProvider
  final masteryResult = await masteryRepo.getAllRecords();

  final sessions = switch (sessionsResult) {
    RepoSuccess(:final value) => value,
    RepoFailure() => <SessionResult>[],
  };
  final mastery = switch (masteryResult) {
    RepoSuccess(:final value) => value,
    RepoFailure() => <String, MasteryRecord>{},
  };

  return ProfileStatsService().computeAggregate(
    recentSessions: sessions,
    masteryBank: mastery,
  );
});
```

**Catatan**: `getRecentSessions(limit: 100)` sudah dipakai `levelStarsProvider` — provider ini menggunakan pemanggilan yang sama, bukan query baru ke Hive. Kalau nanti riwayat sesi bertambah banyak dan limit 100 mulai terasa tidak representatif untuk "akurasi rata-rata sepanjang waktu", pertimbangkan simpan `runningAverageAccuracy` langsung di `PlayerProfile` (di-update tiap sesi selesai, sama pola dengan `totalXp`) — dijadikan catatan optimasi, bukan blocking untuk v1.

### 1.5 Struktur Widget

```
lib/presentation/profile/
  providers/
    profile_stats_provider.dart   // BARU
    account_status_provider.dart  // BARU (§1.3)
  widgets/
    profile_screen.dart
    profile_header.dart           // avatar + badge status akun
    level_progress_card.dart      // reuse pola dari CountdownProgressBar-style container, bukan komponen sama
    stats_grid.dart                // 2x2, reuse AppTokens.radiusCard/borderWidthSubtle
    create_account_cta.dart        // tombol + caption, hanya tampil kalau accountStatusProvider == guest
```

`create_account_cta.dart` di-render kondisional — kalau `AccountStatus.linked`, ganti jadi tombol sekunder "kelola akun" (bukan dihilangkan total, supaya pemain yang sudah linked tetap punya akses ke pengaturan akun dari layar ini).

## 2. Leaderboard Screen

### 2.1 Rute

```
GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen())
```

### 2.2 Tiga State (sesuai tiga mockup)

```dart
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountStatus = ref.watch(accountStatusProvider);

    if (accountStatus == AccountStatus.guest) {
      return const LeaderboardLockedView(); // math_speed_game_leaderboard_locked_state
    }

    final selectedBand = ref.watch(leaderboardSelectedBandProvider);
    final entriesAsync = ref.watch(leaderboardEntriesProvider(selectedBand));

    return entriesAsync.when(
      loading: () => const LeaderboardLoadingView(),
      error: (_, __) => const LeaderboardErrorView(), // retry, BUKAN locked state — beda penyebab
      data: (entries) => LeaderboardListView(entries: entries), // math_speed_game_leaderboard_screen
    );
  }
}
```

**Kenapa error state dipisah dari locked state**: keduanya terlihat "kosong" tapi penyebabnya beda total — locked karena memang belum ada akun (solusinya CTA buat akun), error karena gagal fetch dari Supabase (solusinya tombol coba lagi). Menyamakan keduanya jadi satu tampilan generik bikin pemain yang sudah punya akun tapi lagi offline melihat ajakan "buat akun" yang membingungkan — mereka sudah punya akun.

### 2.3 Provider

```dart
final leaderboardSelectedBandProvider = StateProvider<String>((ref) {
  final level = ref.watch(playerProfileProvider).valueOrNull?.currentLevel ?? 1;
  final config = ref.watch(levelBandsConfigProvider).valueOrNull;
  return config?.bandForLevel(level).id ?? 'onboarding';
});

final leaderboardEntriesProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>((ref, band) async {
  final repo = ref.watch(supabaseLeaderboardRepositoryProvider); // math-speed-game-social-cloud-spec.md §5
  return repo.fetchTopEntries(band: band, limit: 50);
});
```

`leaderboardSelectedBandProvider` default ke band level pemain saat ini (persis seperti tab "basic" yang ter-select duluan di mockup), tapi tetap `StateProvider` (bukan derived murni) supaya pemain bisa **pindah tab** ke band lain untuk sekadar lihat-lihat, tanpa itu mengubah band aktualnya.

### 2.4 Model Baru

```dart
// lib/domain/models/leaderboard_entry.dart — pure dart
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.displayName,
    required this.score,
    required this.isCurrentPlayer,
  });

  final int rank;
  final String displayName;
  final int score;
  final bool isCurrentPlayer; // dipakai widget untuk styling row aksen (§ mockup "mika (kamu)")
}
```

Query di `supabaseLeaderboardRepositoryProvider` bertanggung jawab menandai `isCurrentPlayer` (bandingkan `player_id` row dengan `auth.uid()` sendiri) dan **selalu menyisipkan** entry pemain sendiri di hasil meski di luar top-N yang di-fetch (perlu query kedua khusus posisi sendiri kalau tidak masuk top 50 — lihat §2.5) — bukan tanggung jawab widget.

### 2.5 Query Posisi Sendiri (Kalau di Luar Top-N)

```sql
-- RPC di Supabase, dipanggil terpisah dari fetch top-N
create or replace function get_player_rank(p_band text, p_player_id uuid, p_date date)
returns int language sql stable as $$
  select rank from (
    select player_id, rank() over (order by correct_count desc, total_time_ms asc) as rank
    from daily_challenge_results
    where band = p_band and date = p_date
  ) ranked
  where player_id = p_player_id;
$$;
```

Dipakai untuk kasus di mockup (`mika` rank #18, jauh di luar 5 besar yang di-fetch) — daripada fetch seluruh leaderboard untuk cari posisi sendiri (mahal kalau pemainnya banyak), satu RPC ringan khusus untuk itu.

## 3. File yang Terdampak (Ringkasan)

| File | Perubahan |
|---|---|
| `lib/domain/services/profile_stats_service.dart` | **Baru** |
| `lib/domain/models/leaderboard_entry.dart` | **Baru** |
| `lib/presentation/profile/**` | **Baru** — seluruh folder (§1.5) |
| `lib/presentation/leaderboard/**` | **Baru** — screen, providers, widgets state (locked/loading/error/list) |
| `lib/data/remote/supabase_leaderboard_repository.dart` | **Baru**, dari `math-speed-game-social-cloud-spec.md` §5 |
| `lib/core/router/app_router.dart` (atau lokasi `go_router` didefinisikan) | Tambah rute `/profile` dan `/leaderboard` |
| `PlayerProfile` model | Verifikasi field `longestStreak` ada atau perlu ditambah (§1.2) |
