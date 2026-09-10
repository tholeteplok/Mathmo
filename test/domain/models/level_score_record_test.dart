import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/models/level_score_record.dart';

void main() {
  group('LevelScoreRecord', () {
    test('initial factory produces correct default values', () {
      final record = LevelScoreRecord.initial(5);

      expect(record.level, equals(5));
      expect(record.bestScore, equals(0));
      expect(record.attempts, equals(0));
    });

    test('applyAttempt on initial record updates bestScore and awards full delta', () {
      final initial = LevelScoreRecord.initial(1);
      final (:record, :delta) = initial.applyAttempt(120);

      expect(delta, equals(120));
      expect(record.level, equals(1));
      expect(record.bestScore, equals(120));
      expect(record.attempts, equals(1));
    });

    test('applyAttempt with lower score yields 0 delta and keeps bestScore', () {
      final initial = LevelScoreRecord.initial(1);
      final (:record, delta: _) = initial.applyAttempt(150);

      final (record: secondAttempt, :delta) = record.applyAttempt(100);

      expect(delta, equals(0));
      expect(secondAttempt.bestScore, equals(150));
      expect(secondAttempt.attempts, equals(2));
    });

    test('applyAttempt with equal score yields 0 delta and keeps bestScore', () {
      final initial = LevelScoreRecord.initial(1);
      final (:record, delta: _) = initial.applyAttempt(150);

      final (record: secondAttempt, :delta) = record.applyAttempt(150);

      expect(delta, equals(0));
      expect(secondAttempt.bestScore, equals(150));
      expect(secondAttempt.attempts, equals(2));
    });

    test('applyAttempt with higher score yields delta = newScore - oldBest', () {
      final initial = LevelScoreRecord.initial(1);
      final (:record, delta: _) = initial.applyAttempt(100);

      final (record: secondAttempt, :delta) = record.applyAttempt(160);

      expect(delta, equals(60)); // 160 - 100 = 60
      expect(secondAttempt.bestScore, equals(160));
      expect(secondAttempt.attempts, equals(2));
    });

    test('toJson and fromJson serialize and deserialize correctly', () {
      const record = LevelScoreRecord(
        level: 3,
        bestScore: 250,
        attempts: 4,
      );

      final json = record.toJson();
      expect(json['level'], equals(3));
      expect(json['best_score'], equals(250));
      expect(json['attempts'], equals(4));

      final deserialized = LevelScoreRecord.fromJson(json);
      expect(deserialized, equals(record));
    });

    test('supports copyWith and equality', () {
      final r1 = LevelScoreRecord.initial(1);
      final r2 = r1.copyWith(bestScore: 50);

      expect(r1 == r2, isFalse);
      expect(r2.bestScore, equals(50));
      expect(r2.level, equals(1));

      final r3 = r1.copyWith();
      expect(r1, equals(r3));
      expect(r1.hashCode, equals(r3.hashCode));
    });
  });
}
