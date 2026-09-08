import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/models/models.dart';
import 'package:mathmo_app/domain/services/distractor_generator.dart';

void main() {
  const generator = DistractorGenerator();

  group('DistractorGenerator.generate', () {
    test(
      'produces exactly 3 distinct distractors and valid shuffledIndices',
      () {
        final question = Question(
          id: 'q_7x8',
          factKey: '7x8',
          operation: Operation.multiply,
          operands: const [7, 8],
          correctAnswer: 56,
          difficulty: const QuestionDifficulty(
            operandMagnitude: OperandMagnitude.oneDigit,
            structuralProperty: StructuralProperty.none,
            strategyTag: StrategyTag.retrieval,
            stepCount: 1,
          ),
          levelBand: 'basic',
          level: 10,
        );

        final distractorSet = generator.generate(question);

        expect(distractorSet.distractors.length, equals(3));
        final allValues = [
          question.correctAnswer,
          ...distractorSet.distractors.map((d) => d.value),
        ];

        // Semua nilai harus unik
        expect(allValues.toSet().length, equals(4));

        // Semua nilai harus positif
        for (final v in allValues) {
          expect(v, greaterThan(0));
        }

        // Shuffled indices harus berisi permutasi [0, 1, 2, 3]
        expect(distractorSet.shuffledIndices.length, equals(4));
        expect(distractorSet.shuffledIndices.toSet(), equals({0, 1, 2, 3}));
      },
    );

    test('generates expected error types for addition with carry', () {
      final question = Question(
        id: 'q_27+18',
        factKey: '27+18',
        operation: Operation.add,
        operands: const [27, 18],
        correctAnswer: 45,
        difficulty: const QuestionDifficulty(
          operandMagnitude: OperandMagnitude.twoDigit,
          structuralProperty: StructuralProperty.requiresCarry,
          strategyTag: StrategyTag.procedural,
          stepCount: 1,
        ),
        levelBand: 'basic',
        level: 8,
      );

      final distractorSet = generator.generate(question);

      expect(distractorSet.distractors.length, equals(3));
      expect(
        distractorSet.distractors.any((d) => d.value == 45),
        isFalse,
        reason: 'Jawaban benar tidak boleh muncul dalam daftar distractor',
      );
    });

    test('generates expected error types for subtraction', () {
      final question = Question(
        id: 'q_32-17',
        factKey: '32-17',
        operation: Operation.subtract,
        operands: const [32, 17],
        correctAnswer: 15,
        difficulty: const QuestionDifficulty(
          operandMagnitude: OperandMagnitude.twoDigit,
          structuralProperty: StructuralProperty.requiresBorrow,
          strategyTag: StrategyTag.procedural,
          stepCount: 1,
        ),
        levelBand: 'basic',
        level: 8,
      );

      final distractorSet = generator.generate(question);

      expect(distractorSet.distractors.length, equals(3));
      for (final d in distractorSet.distractors) {
        expect(d.value, isNot(equals(15)));
        expect(d.value, greaterThan(0));
      }
    });
  });
}
