# Speed Math Game — State Management Architecture

## 1. Pilihan: Riverpod

**Riverpod** (bukan Provider/GetX/plain Bloc) untuk proyek ini, dengan alasan spesifik ke kebutuhan game ini — bukan preferensi generik:

- State machine gameplay (§1 `math-speed-game-spec.md`) punya banyak transisi eksplisit (SHOW_QUESTION → ACTIVE → CORRECT/WRONG/TIMEOUT → RETRY) — cocok dengan `StateNotifier` yang memaksa transisi lewat method terdefinisi, bukan `setState` bebas yang gampang membuat state tidak konsisten
- Banyak provider saling bergantung dan butuh di-inject untuk testing terpisah (`QuestionGenerator`, `DistractorGenerator`, `MasteryRepository`, `DDAEngine`) — dependency injection Riverpod (`ref.watch`, `ref.read`) native tanpa boilerplate `BuildContext` seperti Provider biasa
- Tidak butuh `BuildContext` untuk mengakses state di luar widget tree (penting untuk `Ticker`/`AnimationController` timer yang perlu update state dari luar build method)
- Testable murni: `ProviderContainer` bisa override dependency (mis. mock `MasteryRepository`) tanpa perlu widget test penuh

## 2. Struktur Layer

```
lib/
  core/
    theme/
      level_band_theme.dart        // §3 dokumen ini
  domain/                          // PURE DART — tidak ada import flutter/riverpod
    models/
      question.dart
      distractor.dart
      round_result.dart
      session_result.dart
      mastery_record.dart
      player_profile.dart
      daily_challenge.dart
      level_band_config.dart
    services/
      question_generator.dart
      distractor_generator.dart
      mastery_update_service.dart
      dda_engine.dart
      scoring_service.dart
    repositories/                  // ABSTRAK — interface saja, tidak ada implementasi
      mastery_repository.dart
      player_repository.dart
      daily_challenge_repository.dart
  data/                            // implementasi konkret dari repository di atas
    local/
      hive_mastery_repository.dart
      hive_player_repository.dart
    remote/
      daily_challenge_api.dart     // kalau daily challenge butuh sync server, opsional untuk v1
  presentation/
    game/
      providers/
        game_session_provider.dart     // StateNotifierProvider — state machine inti
        game_dependencies_provider.dart // provider untuk semua service/repository domain
      state/
        game_session_state.dart        // sealed class, sesuai §9 JSON structures
      widgets/
        game_screen.dart
        countdown_progress_bar.dart
        answer_grid.dart
        feedback_overlay.dart
    home/
      providers/
        player_profile_provider.dart
        level_path_provider.dart
      widgets/
        home_screen.dart
    results/
      providers/
        session_result_provider.dart
      widgets/
        results_screen.dart
    daily_challenge/
      providers/
        daily_challenge_provider.dart
      widgets/
        daily_challenge_screen.dart
```

**Aturan tegas**: `domain/` tidak boleh import apa pun dari Flutter atau Riverpod. Ini yang membuat `QuestionGenerator`, `DistractorGenerator`, `MasteryUpdateService` bisa di-unit-test sebagai pure Dart tanpa widget test — sesuai catatan testability di spec teknis sebelumnya.

## 3. State Machine sebagai StateNotifier

```dart
// presentation/game/state/game_session_state.dart
sealed class GameSessionState {
  const GameSessionState();
}

class ShowQuestion extends GameSessionState {
  final Question question;
  const ShowQuestion(this.question);
}

class Active extends GameSessionState {
  final Question question;
  final List<Distractor> distractors;
  final List<int> shuffledIndices; // permutasi indeks dari [correct, ...distractors]
  final int timeRemainingMs;
  const Active({
    required this.question,
    required this.distractors,
    required this.shuffledIndices,
    required this.timeRemainingMs,
  });
}

class Feedback extends GameSessionState {
  final bool isCorrect;
  final int? selectedAnswer;
  const Feedback({required this.isCorrect, this.selectedAnswer});
}

class Paused extends GameSessionState {
  final Active pausedFrom; // state Active persis sebelum di-pause, termasuk timeRemainingMs beku
  const Paused(this.pausedFrom);
}

class SessionEnded extends GameSessionState {
  final SessionResult result;
  const SessionEnded(this.result);
}
```

### 3.1 App Lifecycle — Pause/Resume Timer

Timer soal **wajib di-pause**, bukan tetap berjalan, saat app masuk background. Kalau tidak, pemain yang menerima notifikasi/telepon di tengah soal otomatis kena timeout tidak adil — bertentangan dengan prinsip anti-frustrasi yang dipegang sejak awal desain.

```dart
// presentation/game/providers/game_session_provider.dart
class GameSessionNotifier extends StateNotifier<GameSessionState>
    with WidgetsBindingObserver {
  GameSessionNotifier(this._deps) : super(_deps.buildInitialQuestion()) {
    WidgetsBinding.instance.addObserver(this);
  }

  final GameDependencies _deps;
  Timer? _questionShowTimer;
  Ticker? _roundTicker;

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    final current = state;
    if (lifecycleState == AppLifecycleState.paused && current is Active) {
      _roundTicker?.stop();
      state = Paused(current); // timeRemainingMs dibekukan apa adanya
    } else if (lifecycleState == AppLifecycleState.resumed && current is Paused) {
      state = current.pausedFrom; // kembali ke Active, waktu tersisa sama persis
      _roundTicker?.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _questionShowTimer?.cancel();
    _roundTicker?.dispose();
    super.dispose();
  }

  void startRound() {
    // ShowQuestion -> (delay ~600ms) -> Active
  }

  void submitAnswer(int selectedIndex) {
    final active = state as Active; // guard: hanya valid dipanggil saat Active
    final question = active.question;
    // benar jika slot yang dipilih menunjuk ke indeks 0 di array virtual
    // [correct, ...distractors] — lihat math-speed-game-json-structures.md §2
    final isCorrect = active.shuffledIndices[selectedIndex] == 0;
    final errorType = isCorrect
        ? null
        : active.distractors[active.shuffledIndices[selectedIndex] - 1].errorType;

    _deps.masteryUpdateService.onAnswerSubmit(
      factKey: question.factKey,
      isCorrect: isCorrect,
      responseTimeMs: /* dihitung dari ticker */,
      errorType: errorType,
    );

    state = Feedback(isCorrect: isCorrect, selectedAnswer: selectedIndex);
    // setelah ±400ms -> lanjut soal berikutnya atau RETRY
  }
}

final gameSessionProvider =
    StateNotifierProvider.autoDispose<GameSessionNotifier, GameSessionState>(
  (ref) => GameSessionNotifier(ref.watch(gameDependenciesProvider)),
);
```

`autoDispose` penting di sini — state gameplay tidak boleh bertahan setelah pemain keluar dari layar game, supaya `Ticker` di-dispose otomatis dan tidak jadi memory leak.

## 4. Dependency Wiring

```dart
// presentation/game/providers/game_dependencies_provider.dart
class GameDependencies {
  GameDependencies({
    required this.questionGenerator,
    required this.distractorGenerator,
    required this.masteryUpdateService,
    required this.ddaEngine,
    required this.scoringService,
  });

  final QuestionGenerator questionGenerator;
  final DistractorGenerator distractorGenerator;
  final MasteryUpdateService masteryUpdateService;
  final DDAEngine ddaEngine;
  final ScoringService scoringService;
}

final gameDependenciesProvider = Provider<GameDependencies>((ref) {
  return GameDependencies(
    questionGenerator: QuestionGenerator(),
    distractorGenerator: DistractorGenerator(),
    masteryUpdateService: MasteryUpdateService(ref.watch(masteryRepositoryProvider)),
    ddaEngine: DDAEngine(),
    scoringService: ScoringService(),
  );
});

final masteryRepositoryProvider = Provider<MasteryRepository>((ref) {
  return HiveMasteryRepository(); // implementasi konkret, gampang di-override saat test
});

/// Dimuat SEKALI dari `assets/level_bands.json` (lihat `level_band_theme.dart`
/// yang sudah direvisi) — satu sumber kebenaran untuk warna & rentang band,
/// tidak ada duplikasi hardcoded di kode.
final levelBandsConfigProvider = FutureProvider<LevelBandsConfig>((ref) async {
  return LevelBandsConfig.load();
});

/// Turunan dari [levelBandsConfigProvider] + level pemain saat ini. `.when()`
/// dipakai widget untuk menangani state loading (mis. tampilkan kanvas netral
/// sekejap) sebelum JSON asset selesai dimuat — biasanya hanya beberapa ms.
final levelBandThemeProvider = Provider<AsyncValue<LevelBandTheme>>((ref) {
  final level = ref.watch(playerProfileProvider).valueOrNull?.currentLevel ?? 1;
  final configAsync = ref.watch(levelBandsConfigProvider);
  return configAsync.whenData((config) => resolveLevelBandTheme(config, level));
});
```

Semua service domain di-construct lewat provider, bukan langsung `new` di widget — supaya di test bisa `ProviderContainer(overrides: [masteryRepositoryProvider.overrideWithValue(FakeMasteryRepository())])`.

## 5. Provider Map per Layar

| Layar | Provider utama | Sumber data |
|---|---|---|
| Game (gameplay) | `gameSessionProvider` (StateNotifier, autoDispose) | `GameDependencies` |
| Home / peta level | `playerProfileProvider` (AsyncNotifier, baca dari `PlayerRepository`) | Hive lokal |
| Hasil sesi | `sessionResultProvider` — terima `SessionResult` dari navigasi, bukan re-fetch | hasil `gameSessionProvider` sebelum dispose |
| Daily Challenge | `dailyChallengeProvider` (AsyncNotifier — fetch/generate sekali per hari, cache) | `DailyChallengeRepository` |
| Tema kanvas per level | `levelBandThemeProvider` (derived, bergantung ke `levelBandsConfigProvider` + `playerProfileProvider`) | `assets/level_bands.json` (via `levelBandsConfigProvider`) |

## 6. Kenapa Bukan Bloc

Bloc juga valid untuk state machine eksplisit ini (event-driven cocok untuk `submitAnswer`, `startRound` sebagai event). Tapi untuk tim solo-dev, Riverpod lebih ringan boilerplate-nya (tidak perlu class Event terpisah untuk tiap aksi) sambil tetap memberi disiplin transisi state yang sama ketatnya lewat `StateNotifier`. Kalau proyek nanti berkembang jadi tim lebih besar dengan kebutuhan audit-trail event yang ketat, migrasi ke Bloc tetap masuk akal — struktur `domain/` yang sudah dipisah total dari state management membuat migrasi ini tidak menyentuh logic inti sama sekali.

## 7. Strategi Testing

```
test/
  domain/
    services/
      question_generator_test.dart      // pure function, tanpa mock
      distractor_generator_test.dart
      mastery_update_service_test.dart  // mock MasteryRepository
      dda_engine_test.dart
  presentation/
    game/
      game_session_notifier_test.dart   // ProviderContainer + override dependencies
```

Domain layer di-test tanpa `flutter_test`, cukup `test` package biasa — lebih cepat dijalankan, dan memastikan logic gameplay benar-benar independen dari Flutter.
