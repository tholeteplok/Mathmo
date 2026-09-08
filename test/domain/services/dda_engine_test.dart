import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/services/dda_engine.dart';

void main() {
  const dda = DdaEngine();

  group('DdaEngine.updateConfidenceScore', () {
    test('increments confidence by 1 on fast correct response (<50% time)', () {
      final score = dda.updateConfidenceScore(
        currentConfidenceScore: 0,
        isCorrect: true,
        responseTimeMs: 1200,
        totalTimeMs: 3000, // 1200 < 1500 (50%)
      );

      expect(score, equals(1));
    });

    test('maintains confidence on close correct response (>=50% time)', () {
      final score = dda.updateConfidenceScore(
        currentConfidenceScore: 2,
        isCorrect: true,
        responseTimeMs: 2000,
        totalTimeMs: 3000, // 2000 >= 1500
      );

      expect(score, equals(2));
    });

    test('decrements confidence by 1 on wrong or timeout response', () {
      final score = dda.updateConfidenceScore(
        currentConfidenceScore: 1,
        isCorrect: false,
        responseTimeMs: 2500,
        totalTimeMs: 3000,
      );

      expect(score, equals(0));
    });

    test('clamps confidence score between -5 and 5', () {
      final clampedMin = dda.updateConfidenceScore(
        currentConfidenceScore: -5,
        isCorrect: false,
        responseTimeMs: 3000,
        totalTimeMs: 3000,
      );
      expect(clampedMin, equals(-5));

      final clampedMax = dda.updateConfidenceScore(
        currentConfidenceScore: 5,
        isCorrect: true,
        responseTimeMs: 500,
        totalTimeMs: 3000,
      );
      expect(clampedMax, equals(5));
    });
  });

  group('DdaEngine.adjustTimerDuration', () {
    test('extends timer by 15% when confidence <= -2', () {
      final adjusted = dda.adjustTimerDuration(
        baseSec: 4.0,
        confidenceScore: -2,
      );

      expect(adjusted, closeTo(4.6, 0.001)); // 4.0 * 1.15 = 4.6
    });

    test('tightens timer slightly when confidence >= 3', () {
      final adjusted = dda.adjustTimerDuration(
        baseSec: 4.0,
        confidenceScore: 3,
      );

      expect(adjusted, closeTo(3.8, 0.001)); // 4.0 * 0.95 = 3.8
    });

    test('leaves timer unchanged under neutral confidence', () {
      final adjusted = dda.adjustTimerDuration(
        baseSec: 4.0,
        confidenceScore: 0,
      );

      expect(adjusted, equals(4.0));
    });
  });

  group('DdaEngine.shouldInterleaveWeakFact', () {
    test('returns false if no weak facts available', () {
      final shouldInterleave = dda.shouldInterleaveWeakFact(
        questionIndex: 6,
        hasWeakFactsAvailable: false,
      );
      expect(shouldInterleave, isFalse);
    });

    test('returns true on 6th question index if weak facts exist', () {
      final shouldInterleave = dda.shouldInterleaveWeakFact(
        questionIndex: 6,
        hasWeakFactsAvailable: true,
      );
      expect(shouldInterleave, isTrue);
    });
  });
}
