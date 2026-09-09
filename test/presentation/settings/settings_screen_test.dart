import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/core/services/bgm_service.dart';
import 'package:mathmo_app/core/services/sfx_service.dart';
import 'package:mathmo_app/core/theme/app_theme.dart';
import 'package:mathmo_app/domain/models/player_profile.dart';
import 'package:mathmo_app/presentation/home/providers/bgm_provider.dart';
import 'package:mathmo_app/presentation/home/providers/player_profile_provider.dart';
import 'package:mathmo_app/presentation/settings/providers/settings_provider.dart';
import 'package:mathmo_app/presentation/settings/widgets/settings_screen.dart';

class MockSfxService implements SfxService {
  bool muted = false;
  double vol = 1.0;
  final List<SfxType> playedTypes = [];

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
    vol = volume.clamp(0.0, 1.0);
  }

  @override
  Future<void> play(SfxType type) async {
    playedTypes.add(type);
  }

  @override
  void dispose() {}
}

class MockBgmService implements BgmService {
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

class FakePlayerProfileNotifier extends PlayerProfileNotifier {
  @override
  FutureOr<PlayerProfile> build() {
    return PlayerProfile(
      playerId: 'test_player',
      currentLevel: 6,
      totalXp: 450,
      streak: const StreakState(currentStreak: 5, freezeTokens: 0),
      confidenceScore: 0,
      createdAt: DateTime(2026, 9, 9),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen Widget Tests', () {
    late MockSfxService mockSfx;
    late MockBgmService mockBgm;

    setUp(() {
      mockSfx = MockSfxService();
      mockBgm = MockBgmService();
    });

    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [
          sfxServiceProvider.overrideWithValue(mockSfx),
          bgmServiceProvider.overrideWithValue(mockBgm),
          playerProfileProvider.overrideWith(FakePlayerProfileNotifier.new),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SettingsScreen(),
        ),
      );
    }

    testWidgets('renders all settings cards and elements', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // Streak
      expect(find.text('450'), findsOneWidget); // XP

      // Verify Audio Card
      expect(find.text('Musik & Suara'), findsOneWidget);
      expect(find.text('Musik Latar (BGM)'), findsOneWidget);
      expect(find.text('Efek Suara (SFX)'), findsOneWidget);
      expect(find.text('Tes Efek Suara:'), findsOneWidget);

      // Verify 5 SFX preview buttons
      expect(find.text('✓ Benar'), findsOneWidget);
      expect(find.text('✗ Salah'), findsOneWidget);
      expect(find.text('★ Naik Level'), findsOneWidget);
      expect(find.text('🎁 Peti Harta'), findsOneWidget);
      expect(find.text('🔘 Tap'), findsOneWidget);

      // Verify Gameplay Card
      expect(find.text('Preferensi Permainan'), findsOneWidget);
      expect(find.text('Getaran Haptik'), findsOneWidget);
      expect(find.text('Animasi Dinamis'), findsOneWidget);
      expect(find.text('Aktif'), findsOneWidget);

      // Verify About Card
      expect(find.text('iTHUNG'), findsOneWidget);
      expect(find.text('Fast Math. Sharp Mind.'), findsOneWidget);
      expect(find.text('Versi 0.1.0 (Beta)'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(
        find.text('Aset Audio & SFX: Creative Commons CC0'),
        findsOneWidget,
      );
    });

    testWidgets('tapping audition buttons triggers corresponding SfxType', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Correct
      await tester.tap(find.text('✓ Benar'));
      await tester.pump();
      expect(mockSfx.playedTypes, contains(SfxType.correct));

      // Tap Wrong
      await tester.tap(find.text('✗ Salah'));
      await tester.pump();
      expect(mockSfx.playedTypes, contains(SfxType.wrong));

      // Tap Level Up
      await tester.tap(find.text('★ Naik Level'));
      await tester.pump();
      expect(mockSfx.playedTypes, contains(SfxType.levelUp));

      // Tap Chest Open
      await tester.tap(find.text('🎁 Peti Harta'));
      await tester.pump();
      expect(mockSfx.playedTypes, contains(SfxType.chestOpen));

      // Tap Tactile Tap
      await tester.tap(find.text('🔘 Tap'));
      await tester.pump();
      expect(mockSfx.playedTypes, contains(SfxType.tap));
    });
  });
}
