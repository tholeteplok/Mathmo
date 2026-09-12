import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/models/distractor.dart';
import 'package:mathmo_app/domain/models/mastery_record.dart';
import 'package:mathmo_app/domain/repositories/mastery_repository.dart';
import 'package:mathmo_app/domain/repositories/repo_result.dart';
import 'package:mathmo_app/domain/services/mastery_update_service.dart';

class FakeMasteryRepository implements MasteryRepository {
  final Map<String, MasteryRecord> storage = {};

  @override
  Future<RepoResult<MasteryRecord?>> get(String factKey) async {
    return RepoSuccess(storage[factKey]);
  }

  @override
  Future<RepoResult<void>> save(MasteryRecord record) async {
    storage[record.factKey] = record;
    return const RepoSuccess(null);
  }

  @override
  Future<RepoResult<Map<String, MasteryRecord>>> getAll() async {
    return RepoSuccess(Map.from(storage));
  }

  @override
  Future<RepoResult<List<MasteryRecord>>> getWeakFacts({
    int maxBox = 2,
    int limit = 10,
  }) async {
    final weak = storage.values
        .where((r) => r.box <= maxBox)
        .take(limit)
        .toList();
    return RepoSuccess(weak);
  }

  @override
  Future<RepoResult<void>> saveAll(List<MasteryRecord> records) async {
    for (final r in records) {
      storage[r.factKey] = r;
    }
    return const RepoSuccess(null);
  }

  @override
  Future<RepoResult<void>> clearAll() async {
    storage.clear();
    return const RepoSuccess(null);
  }
}

void main() {
  group('MasteryUpdateService.computeUpdatedRecord', () {
    test('creates new record with box=2 when first attempt is correct', () {
      final updated = MasteryUpdateService.computeUpdatedRecord(
        existing: null,
        factKey: '7x8',
        isCorrect: true,
        responseTimeMs: 1500,
      );

      expect(updated.factKey, equals('7x8'));
      expect(updated.attempts, equals(1));
      expect(updated.correct, equals(1));
      expect(updated.box, equals(2));
      expect(updated.recentResults, equals([true]));
      expect(updated.masteryScore, equals(1.0));
    });

    test(
      'creates new record with box=1 and logs error type when first attempt is wrong',
      () {
        final updated = MasteryUpdateService.computeUpdatedRecord(
          existing: null,
          factKey: '7x8',
          isCorrect: false,
          responseTimeMs: 2500,
          errorType: ErrorType.adjacentFactTable,
        );

        expect(updated.attempts, equals(1));
        expect(updated.correct, equals(0));
        expect(updated.box, equals(1));
        expect(updated.recentResults, equals([false]));
        expect(updated.masteryScore, equals(0.0));
        expect(
          updated.errorTypeCounts[ErrorType.adjacentFactTable.name],
          equals(1),
        );
      },
    );

    test('increases box by 1 on correct (max 5)', () {
      final initial = MasteryRecord(
        factKey: '7x8',
        attempts: 4,
        correct: 4,
        recentResults: const [true, true, true, true],
        avgResponseTimeMs: 1200,
        masteryScore: 1.0,
        box: 4,
        lastSeenAt: DateTime.now(),
        errorTypeCounts: const {},
      );

      final updated = MasteryUpdateService.computeUpdatedRecord(
        existing: initial,
        factKey: '7x8',
        isCorrect: true,
        responseTimeMs: 1000,
      );

      expect(updated.box, equals(5));
      expect(updated.attempts, equals(5));

      // Satu lagi benar: tidak boleh lebih dari 5
      final capped = MasteryUpdateService.computeUpdatedRecord(
        existing: updated,
        factKey: '7x8',
        isCorrect: true,
        responseTimeMs: 1000,
      );
      expect(capped.box, equals(5));
    });

    test('decreases box by 2 on wrong (min 1)', () {
      final initial = MasteryRecord(
        factKey: '7x8',
        attempts: 3,
        correct: 3,
        recentResults: const [true, true, true],
        avgResponseTimeMs: 1200,
        masteryScore: 1.0,
        box: 3,
        lastSeenAt: DateTime.now(),
        errorTypeCounts: const {},
      );

      final updated = MasteryUpdateService.computeUpdatedRecord(
        existing: initial,
        factKey: '7x8',
        isCorrect: false,
        responseTimeMs: 3000,
        errorType: ErrorType.offBy10,
      );

      expect(updated.box, equals(1)); // 3 - 2 = 1
      expect(updated.errorTypeCounts[ErrorType.offBy10.name], equals(1));
    });

    test('maintains sliding window max 8 items', () {
      final initial = MasteryRecord(
        factKey: '7x8',
        attempts: 8,
        correct: 8,
        recentResults: const [true, true, true, true, true, true, true, true],
        avgResponseTimeMs: 1200,
        masteryScore: 1.0,
        box: 5,
        lastSeenAt: DateTime.now(),
        errorTypeCounts: const {},
      );

      final updated = MasteryUpdateService.computeUpdatedRecord(
        existing: initial,
        factKey: '7x8',
        isCorrect: false,
        responseTimeMs: 2000,
      );

      expect(updated.recentResults.length, equals(8));
      expect(updated.recentResults.last, equals(false));
    });
  });
}
