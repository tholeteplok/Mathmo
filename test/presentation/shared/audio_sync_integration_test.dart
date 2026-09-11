import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/core/services/bgm_service.dart';
import 'package:mathmo_app/core/services/sfx_service.dart';
import 'package:mathmo_app/domain/models/audio_settings.dart';
import 'package:mathmo_app/domain/models/player_profile.dart';
import 'package:mathmo_app/domain/repositories/audio_settings_repository.dart';
import 'package:mathmo_app/domain/repositories/repo_result.dart';
import 'package:mathmo_app/presentation/game/providers/game_dependencies_provider.dart';
import 'package:mathmo_app/presentation/home/providers/player_profile_provider.dart';
import 'package:mathmo_app/presentation/home/widgets/home_screen.dart';
import 'package:mathmo_app/presentation/settings/providers/settings_provider.dart';
import 'package:mathmo_app/presentation/settings/widgets/settings_screen.dart';

class _MockAudioSettingsRepository implements AudioSettingsRepository {
  _MockAudioSettingsRepository([AudioSettings? initial])
      : currentSettings = initial ?? AudioSettings.initial;

  AudioSettings currentSettings;
  int saveCount = 0;

  @override
  Future<RepoResult<AudioSettings>> getSettings() async {
    return RepoSuccess(currentSettings);
  }

  @override
  Future<RepoResult<void>> saveSettings(AudioSettings settings) async {
    currentSettings = settings;
    saveCount++;
    return const RepoSuccess(null);
  }
}

class _FakeBgmService implements BgmService {
  bool muted = false;
  String? track;

  @override
  String? get currentTrack => track;

  @override
  bool get isMuted => muted;

  @override
  Future<void> setMuted(bool mute) async {
    muted = mute;
  }

  @override
  Future<void> toggleMute() async {
    muted = !muted;
  }

  @override
  Future<void> playTrack(String assetPath) async {
    track = assetPath;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  void dispose() {}
}

class _FakeSfxService implements SfxService {
  bool muted = false;
  double vol = 1.0;

  @override
  bool get isMuted => muted;

  @override
  double get volume => vol;

  @override
  Future<void> setMuted(bool mute) async {
    muted = mute;
  }

  @override
  Future<void> setVolume(double volume) async {
    vol = volume;
  }

  @override
  Future<void> play(SfxType type) async {}

  @override
  void dispose() {}
}

class _FakePlayerProfileNotifier extends PlayerProfileNotifier {
  @override
  Future<PlayerProfile> build() async {
    return PlayerProfile(
      playerId: 'test_player',
      currentLevel: 1,
      totalXp: 0,
      streak: const StreakState(currentStreak: 0, freezeTokens: 1),
      confidenceScore: 0,
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Audio Synchronization & Hive Persistence Tests', () {
    late _MockAudioSettingsRepository mockRepo;
    late _FakeBgmService fakeBgm;
    late _FakeSfxService fakeSfx;

    setUp(() {
      mockRepo = _MockAudioSettingsRepository();
      fakeBgm = _FakeBgmService();
      fakeSfx = _FakeSfxService();
    });

    testWidgets(
        'Toggling BGM in HomeScreen updates audioSettingsProvider and repository',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          audioSettingsRepositoryProvider.overrideWithValue(mockRepo),
          bgmServiceProvider.overrideWithValue(fakeBgm),
          sfxServiceProvider.overrideWithValue(fakeSfx),
          playerProfileProvider.overrideWith(_FakePlayerProfileNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initially unmuted: icon is volume_up_rounded
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(container.read(audioSettingsProvider).bgmMuted, isFalse);

      // Tap mute toggle in HomeScreen
      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Now muted: icon changed to volume_off_rounded
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
      expect(container.read(audioSettingsProvider).bgmMuted, isTrue);
      expect(mockRepo.currentSettings.bgmMuted, isTrue);
      expect(mockRepo.saveCount, greaterThanOrEqualTo(1));
    });

    testWidgets(
        'Mutually synchronized between HomeScreen and SettingsScreen',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          audioSettingsRepositoryProvider.overrideWithValue(mockRepo),
          bgmServiceProvider.overrideWithValue(fakeBgm),
          sfxServiceProvider.overrideWithValue(fakeSfx),
          playerProfileProvider.overrideWith(_FakePlayerProfileNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      // 1. Render HomeScreen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Mute via HomeScreen
      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

      // 2. Navigate to SettingsScreen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In SettingsScreen, BGM switch must already be muted (true)
      expect(container.read(audioSettingsProvider).bgmMuted, isTrue);

      // Toggle BGM ON in SettingsScreen using key
      expect(find.byKey(const Key('switch_bgm')), findsOneWidget);
      await tester.tap(find.byKey(const Key('switch_bgm')));
      await tester.pumpAndSettle();

      // Now unmuted in provider and repo
      expect(container.read(audioSettingsProvider).bgmMuted, isFalse);
      expect(mockRepo.currentSettings.bgmMuted, isFalse);

      // 3. Return to HomeScreen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // HomeScreen icon must now immediately show volume_up_rounded!
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });

    test('AudioSettingsNotifier restores persisted settings on initialization',
        () async {
      const persistedSettings = AudioSettings(
        bgmMuted: true,
        sfxMuted: true,
        bgmVolume: 0.5,
        sfxVolume: 0.7,
        hapticEnabled: false,
      );
      final preloadedRepo = _MockAudioSettingsRepository(persistedSettings);

      final container = ProviderContainer(
        overrides: [
          audioSettingsRepositoryProvider.overrideWithValue(preloadedRepo),
          bgmServiceProvider.overrideWithValue(fakeBgm),
          sfxServiceProvider.overrideWithValue(fakeSfx),
        ],
      );
      addTearDown(container.dispose);

      // Await initialization future from repository
      final notifier = container.read(audioSettingsProvider.notifier);
      await notifier.initializationFuture;

      final state = container.read(audioSettingsProvider);
      expect(state.bgmMuted, isTrue);
      expect(state.sfxMuted, isTrue);
      expect(state.bgmVolume, equals(0.5));
      expect(state.sfxVolume, equals(0.7));
      expect(state.hapticEnabled, isFalse);
      expect(fakeBgm.isMuted, isTrue);
      expect(fakeSfx.isMuted, isTrue);
      expect(fakeSfx.volume, equals(0.7));
    });
  });
}
