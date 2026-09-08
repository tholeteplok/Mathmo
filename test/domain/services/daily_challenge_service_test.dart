import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/models/level_band_config.dart';
import 'package:mathmo_app/domain/models/question.dart';
import 'package:mathmo_app/domain/services/daily_challenge_service.dart';

void main() {
  const service = DailyChallengeService();

  const mockBand = LevelBand(
    id: 'basic',
    levelStart: 6,
    levelEnd: 15,
    operations: [Operation.add, Operation.subtract, Operation.multiply],
    digitRange: '1-2-digit',
    timerBaseSec: 6.0,
    canvasColorHex: '#EAF3DE',
    canvasColorEndHex: '#DCEACB',
    accentColorHex: '#639922',
  );

  group('DailyChallengeService', () {
    test(
      'generates exactly 12 deterministic questions for the same date and band',
      () {
        final date = DateTime(2026, 9, 8);

        final challenge1 = service.generateDailyChallenge(
          date: date,
          band: mockBand,
        );
        final challenge2 = service.generateDailyChallenge(
          date: date,
          band: mockBand,
        );

        expect(challenge1.questions.length, equals(12));
        expect(challenge2.questions.length, equals(12));

        // Harus 100% identik (deterministik)
        expect(challenge1.seed, equals(challenge2.seed));
        for (var i = 0; i < 12; i++) {
          expect(
            challenge1.questions[i].factKey,
            equals(challenge2.questions[i].factKey),
          );
          expect(
            challenge1.questions[i].correctAnswer,
            equals(challenge2.questions[i].correctAnswer),
          );
        }
      },
    );

    test('generates different questions for different dates', () {
      final date1 = DateTime(2026, 9, 8);
      final date2 = DateTime(2026, 9, 9);

      final challenge1 = service.generateDailyChallenge(
        date: date1,
        band: mockBand,
      );
      final challenge2 = service.generateDailyChallenge(
        date: date2,
        band: mockBand,
      );

      expect(challenge1.seed, isNot(equals(challenge2.seed)));
    });

    test('generates deterministic distractors for question', () {
      final date = DateTime(2026, 9, 8);
      final challenge = service.generateDailyChallenge(
        date: date,
        band: mockBand,
      );
      final q = challenge.questions.first;

      final dist1 = service.generateDistractorsForQuestion(q, challenge.seed);
      final dist2 = service.generateDistractorsForQuestion(q, challenge.seed);

      expect(dist1.shuffledIndices, equals(dist2.shuffledIndices));
      expect(dist1.distractors.length, equals(dist2.distractors.length));
      for (var i = 0; i < dist1.distractors.length; i++) {
        expect(dist1.distractors[i].value, equals(dist2.distractors[i].value));
      }
    });
  });
}
