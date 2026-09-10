import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/models/daily_challenge.dart';
import 'package:mathmo_app/presentation/daily_challenge/providers/daily_challenge_provider.dart';
import 'package:mathmo_app/presentation/daily_challenge/widgets/daily_challenge_screen.dart';

void main() {
  group('DailyChallengeGate', () {
    testWidgets(
      'renders CircularProgressIndicator when loading',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dailyChallengeCompletionProvider.overrideWith(
                (ref) => Completer<DailyChallengeResult?>().future,
              ),
            ],
            child: const MaterialApp(
              home: DailyChallengeGate(),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'renders DailyChallengeLockedView when challenge is completed today',
      (tester) async {
        final completedResult = DailyChallengeResult(
          playerId: 'test_p',
          date: DateTime.now(),
          band: 'basic',
          correctCount: 11,
          totalTimeMs: 24500,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dailyChallengeCompletionProvider.overrideWith(
                (ref) async => completedResult,
              ),
            ],
            child: const MaterialApp(
              home: DailyChallengeGate(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(DailyChallengeLockedView), findsOneWidget);
        expect(find.text('Tantangan Hari Ini Selesai!'), findsOneWidget);
        expect(find.text('Skor Akhir: 11 / 12 Benar'), findsOneWidget);
        expect(find.text('Total Waktu: 24.5 detik'), findsOneWidget);
        expect(find.text('Kembali ke Beranda'), findsOneWidget);
      },
    );

    testWidgets(
      'renders DailyChallengeScreen when challenge is not completed today (null)',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dailyChallengeCompletionProvider.overrideWith(
                (ref) async => null,
              ),
              dailyChallengeProvider.overrideWith(
                (ref) => Completer<DailyChallenge>().future,
              ),
            ],
            child: const MaterialApp(
              home: DailyChallengeGate(),
            ),
          ),
        );

        await tester.pump();

        expect(find.byType(DailyChallengeScreen), findsOneWidget);
        expect(find.byType(DailyChallengeLockedView), findsNothing);
      },
    );

    testWidgets(
      'renders DailyChallengeScreen (fail-open) on error',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dailyChallengeCompletionProvider.overrideWith(
                (ref) async => throw Exception('Hive error'),
              ),
              dailyChallengeProvider.overrideWith(
                (ref) => Completer<DailyChallenge>().future,
              ),
            ],
            child: const MaterialApp(
              home: DailyChallengeGate(),
            ),
          ),
        );

        await tester.pump();

        expect(find.byType(DailyChallengeScreen), findsOneWidget);
        expect(find.byType(DailyChallengeLockedView), findsNothing);
      },
    );
  });
}
