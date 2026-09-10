import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/models/leaderboard_entry.dart';
import 'package:mathmo_app/domain/models/level_band_config.dart';
import 'package:mathmo_app/domain/models/question.dart';
import 'package:mathmo_app/presentation/game/providers/level_band_theme_provider.dart';
import 'package:mathmo_app/presentation/leaderboard/providers/leaderboard_provider.dart';
import 'package:mathmo_app/presentation/leaderboard/widgets/leaderboard_screen.dart';
import 'package:mathmo_app/presentation/profile/providers/account_status_provider.dart';

class FakeAccountStatusNotifier extends AccountStatusNotifier {
  FakeAccountStatusNotifier(this._state);
  final AccountState _state;

  @override
  Future<AccountState> build() async => _state;
}

void main() {
  testWidgets('LeaderboardScreen renders locked view when user is guest', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStatusProvider.overrideWith(
            () => FakeAccountStatusNotifier(const AccountState(status: AccountStatus.guest)),
          ),
        ],
        child: const MaterialApp(
          home: LeaderboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Papan Peringkat Terkunci'), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsOneWidget);
  });

  testWidgets('LeaderboardScreen renders entries and band tabs when logged in', (tester) async {
    const mockEntries = [
      LeaderboardEntry(
        rank: 1,
        username: 'juara_satu',
        correctCount: 12,
        totalTimeMs: 19500,
        isCurrentPlayer: false,
      ),
      LeaderboardEntry(
        rank: 2,
        username: 'my_user_test',
        correctCount: 11,
        totalTimeMs: 22100,
        isCurrentPlayer: true,
      ),
    ];

    const testBand = LevelBand(
      id: 'basic',
      levelStart: 6,
      levelEnd: 15,
      operations: [Operation.add],
      digitRange: '1-digit',
      timerBaseSec: 6.0,
      canvasColorHex: '#EAF3DE',
      canvasColorEndHex: '#DCEACB',
      accentColorHex: '#639922',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStatusProvider.overrideWith(
            () => FakeAccountStatusNotifier(
              const AccountState(
                status: AccountStatus.linked,
                userId: 'user_123',
                username: 'my_user_test',
              ),
            ),
          ),
          levelBandsConfigProvider.overrideWith(
            (ref) async => const LevelBandsConfig([testBand]),
          ),
          leaderboardSelectedBandProvider.overrideWith((ref) => 'basic'),
          leaderboardEntriesProvider('basic').overrideWith(
            (ref) async => mockEntries,
          ),
        ],
        child: const MaterialApp(
          home: LeaderboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Papan Peringkat'), findsOneWidget);
    expect(find.text('@juara_satu'), findsOneWidget);
    expect(find.text('@my_user_test'), findsOneWidget);
    expect(find.text('12/12'), findsOneWidget);
    expect(find.text('11/12'), findsOneWidget);
    expect(find.text('Waktu: 19.5s'), findsOneWidget);
    expect(find.text('Waktu: 22.1s'), findsOneWidget);
    expect(find.text('Kamu'), findsOneWidget);
    expect(find.text('🏆  Harian'), findsOneWidget);
    expect(find.text('⭐  Semua Waktu'), findsOneWidget);
    expect(find.text('Zona Dasar'), findsOneWidget);
  });

  testWidgets('LeaderboardScreen renders all-time entries and hides band tabs in allTime mode', (tester) async {
    const mockAllTimeEntries = [
      LeaderboardEntry(
        rank: 1,
        username: 'legend_player',
        correctCount: 0,
        totalTimeMs: 0,
        totalScore: 9850,
        isCurrentPlayer: false,
      ),
      LeaderboardEntry(
        rank: 2,
        username: 'my_user_test',
        correctCount: 0,
        totalTimeMs: 0,
        totalScore: 5400,
        isCurrentPlayer: true,
      ),
    ];

    const testBand = LevelBand(
      id: 'basic',
      levelStart: 6,
      levelEnd: 15,
      operations: [Operation.add],
      digitRange: '1-digit',
      timerBaseSec: 6.0,
      canvasColorHex: '#EAF3DE',
      canvasColorEndHex: '#DCEACB',
      accentColorHex: '#639922',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStatusProvider.overrideWith(
            () => FakeAccountStatusNotifier(
              const AccountState(
                status: AccountStatus.linked,
                userId: 'user_123',
                username: 'my_user_test',
              ),
            ),
          ),
          levelBandsConfigProvider.overrideWith(
            (ref) async => const LevelBandsConfig([testBand]),
          ),
          leaderboardModeProvider.overrideWith((ref) => LeaderboardMode.allTime),
          allTimeEntriesProvider.overrideWith(
            (ref) async => mockAllTimeEntries,
          ),
        ],
        child: const MaterialApp(
          home: LeaderboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Papan Peringkat'), findsOneWidget);
    expect(find.text('@legend_player'), findsOneWidget);
    expect(find.text('@my_user_test'), findsOneWidget);
    expect(find.text('9850 pts'), findsOneWidget);
    expect(find.text('5400 pts'), findsOneWidget);
    expect(find.text('Total Skor'), findsNWidgets(2));
    expect(find.text('Kamu'), findsOneWidget);
    // Band tabs should NOT be rendered in all-time mode
    expect(find.text('Basic'), findsNothing);
  });
}

