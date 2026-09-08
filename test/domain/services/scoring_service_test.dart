import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/services/scoring_service.dart';

void main() {
  const scoringService = ScoringService();

  group('ScoringService.computeRoundScore', () {
    test('returns 0 score when answer is wrong', () {
      final result = scoringService.computeRoundScore(
        level: 1,
        timeLeftMs: 3000,
        timeTotalMs: 4000,
        streakCorrect: 5,
        isCorrect: false,
      );

      expect(result.roundScore, equals(0));
      expect(result.breakdown.total, equals(0));
    });

    test(
      'calculates correct base points, speed bonus, streak bonus for correct answer',
      () {
        // Level 1: base = 10
        // timeLeft = 2000 / 4000 = 0.5 ratio
        // speed_bonus = round(10 * 0.3 * 0.5) = round(1.5) = 2
        // streak = 3 -> streakBonus = min(3*2, 20) = 6
        // masteryBonus = 0 (no factBox)
        // total = 10 + 2 + 0 + 6 = 18
        final result = scoringService.computeRoundScore(
          level: 1,
          timeLeftMs: 2000,
          timeTotalMs: 4000,
          streakCorrect: 3,
          isCorrect: true,
        );

        expect(result.breakdown.basePoints, equals(10));
        expect(result.breakdown.speedBonus, equals(2));
        expect(result.breakdown.streakBonus, equals(6));
        expect(result.breakdown.masteryBonus, equals(0));
        expect(result.roundScore, equals(18));
      },
    );

    test('awards mastery bonus of 8 points when factBox <= 2', () {
      final result = scoringService.computeRoundScore(
        level: 5,
        timeLeftMs: 1000,
        timeTotalMs: 4000,
        streakCorrect: 0,
        isCorrect: true,
        factBox: 2,
      );

      expect(result.breakdown.masteryBonus, equals(8));
      expect(result.roundScore, greaterThan(8));
    });

    test('caps streak bonus at 20', () {
      final result = scoringService.computeRoundScore(
        level: 1,
        timeLeftMs: 0,
        timeTotalMs: 4000,
        streakCorrect: 15, // 15 * 2 = 30 -> capped at 20
        isCorrect: true,
      );

      expect(result.breakdown.streakBonus, equals(20));
    });
  });

  group('ScoringService.computeSessionXp', () {
    test('computes XP independent of speed', () {
      // (4 distinct * 2) + (2 moved up * 5) + (completed ? 10 : 0)
      // = 8 + 10 + 10 = 28
      final result = scoringService.computeSessionXp(
        distinctFactsPracticed: 4,
        factsMovedUpABox: 2,
        sessionCompleted: true,
      );

      expect(result.totalXp, equals(28));
      expect(result.breakdown.distinctFactsPracticed, equals(4));
      expect(result.breakdown.factsMovedUpABox, equals(2));
      expect(result.breakdown.sessionCompletedBonus, equals(10));
    });

    test('omits sessionCompleted bonus if session was abandoned', () {
      final result = scoringService.computeSessionXp(
        distinctFactsPracticed: 3,
        factsMovedUpABox: 1,
        sessionCompleted: false,
      );

      // (3 * 2) + (1 * 5) + 0 = 11
      expect(result.totalXp, equals(11));
      expect(result.breakdown.sessionCompletedBonus, equals(0));
    });
  });
}
