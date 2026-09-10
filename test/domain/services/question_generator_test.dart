import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/models/models.dart';
import 'package:mathmo_app/domain/services/question_generator.dart';

void main() {
  const generator = QuestionGenerator();

  group('QuestionGenerator.generateForLevel', () {
    test('generates valid onboarding questions (Level 1-5)', () {
      for (var level = 1; level <= 5; level++) {
        final q = generator.generateForLevel(level);

        expect(q.level, equals(level));
        expect(q.levelBand, equals('onboarding'));
        expect([Operation.add, Operation.subtract], contains(q.operation));
        expect(q.operands.length, equals(2));
        expect(q.correctAnswer, greaterThan(0));

        // Verifikasi hasil hitungan benar
        if (q.operation == Operation.add) {
          expect(q.correctAnswer, equals(q.operands[0] + q.operands[1]));
        } else if (q.operation == Operation.subtract) {
          expect(q.correctAnswer, equals(q.operands[0] - q.operands[1]));
        }
      }
    });

    test('generates valid basic questions (Level 6-15)', () {
      for (var level = 6; level <= 15; level++) {
        final q = generator.generateForLevel(level);

        expect(q.level, equals(level));
        expect(q.levelBand, equals('basic'));
        expect([
          Operation.add,
          Operation.subtract,
          Operation.multiply,
        ], contains(q.operation));
        expect(q.correctAnswer, greaterThan(0));

        if (q.operation == Operation.multiply) {
          expect(q.correctAnswer, equals(q.operands[0] * q.operands[1]));
        }
      }
    });

    test('generates valid intermediate questions (Level 16-30)', () {
      for (var level = 16; level <= 30; level++) {
        final q = generator.generateForLevel(level);

        expect(q.level, equals(level));
        expect(q.levelBand, equals('intermediate'));
        expect(q.correctAnswer, greaterThan(0));

        if (q.operation == Operation.divide) {
          expect(
            q.operands[0] % q.operands[1],
            equals(0),
          ); // Pembagian harus exact
          expect(q.correctAnswer, equals(q.operands[0] ~/ q.operands[1]));
        }
      }
    });

    test(
      'relaxation ladder always returns a valid question even for impossible constraints',
      () {
        // Buat template dengan constraint yang mustahil (requireCarry: true untuk angka 1 digit max 2)
        const impossibleTemplate = QuestionTemplate(
          operation: Operation.add,
          rangeA: OperandRange(min: 1, max: 2),
          rangeB: OperandRange(min: 1, max: 2),
          strategyTag: StrategyTag.retrieval,
          levelBand: 'test',
          level: 1,
          requireCarry: true, // 1+1, 1+2, 2+1, 2+2 tidak ada yang carry
        );

        final q = generator.generateFromTemplate(impossibleTemplate);

        expect(q, isNotNull);
        expect(q.correctAnswer, greaterThan(0));
        expect(q.operands.length, equals(2));
      },
    );

    test('generates mixedMultistep questions at expert levels', () {
      var found = 0;
      for (var i = 0; i < 200; i++) {
        final q = generator.generateForLevel(60);
        if (q.operation == Operation.mixedMultistep) {
          found++;
          expect(q.operands.length, equals(3));
          expect(q.difficulty.stepCount, equals(2));
          final a = q.operands[0];
          final b = q.operands[1];
          final c = q.operands[2];
          final inner = q.factKey.contains('($a+$b)') ? a + b : (a - b).abs();
          expect(q.correctAnswer, equals(inner * c));
          expect(q.correctAnswer, greaterThan(0));
          expect(q.displayExpression, contains('× $c'));
        }
      }
      expect(found, greaterThan(0));
    });
  });
}
