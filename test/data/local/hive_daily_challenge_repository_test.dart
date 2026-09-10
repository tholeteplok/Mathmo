import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mathmo_app/data/local/hive_daily_challenge_repository.dart';
import 'package:mathmo_app/domain/models/daily_challenge.dart';
import 'package:mathmo_app/domain/repositories/repo_result.dart';

void main() {
  late Directory tempDir;
  late Box<Map> challengeBox;
  late Box<Map> resultBox;
  late Box<Map> pendingBox;
  late HiveDailyChallengeRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_dc_test_');
    Hive.init(tempDir.path);
    challengeBox = await Hive.openBox<Map>(HiveDailyChallengeRepository.challengeBoxName);
    resultBox = await Hive.openBox<Map>(HiveDailyChallengeRepository.resultBoxName);
    pendingBox = await Hive.openBox<Map>(HiveDailyChallengeRepository.pendingBoxName);

    repository = HiveDailyChallengeRepository(challengeBox, resultBox, pendingBox);
  });

  tearDown(() async {
    await challengeBox.close();
    await resultBox.close();
    await pendingBox.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HiveDailyChallengeRepository Tests', () {
    test('saveResult and getResult match key format with date and band', () async {
      final date = DateTime(2026, 9, 10, 13, 30, 45);
      final result = DailyChallengeResult(
        playerId: 'player-1',
        date: date,
        band: 'basic',
        correctCount: 11,
        totalTimeMs: 14500,
      );

      final saveRes = await repository.saveResult(result);
      expect(saveRes, isA<RepoSuccess<void>>());

      final queryDate = DateTime(2026, 9, 10, 20, 0, 0);
      final getRes = await repository.getResult(queryDate, 'basic');
      expect(getRes, isA<RepoSuccess<DailyChallengeResult?>>());

      final retrieved = (getRes as RepoSuccess<DailyChallengeResult?>).value;
      expect(retrieved, isNotNull);
      expect(retrieved!.correctCount, equals(11));
      expect(retrieved.band, equals('basic'));
      expect(retrieved.totalTimeMs, equals(14500));
    });

    test('getResult returns null when date does not match', () async {
      final date = DateTime(2026, 9, 10);
      final result = DailyChallengeResult(
        playerId: 'player-1',
        date: date,
        band: 'basic',
        correctCount: 10,
        totalTimeMs: 15000,
      );

      await repository.saveResult(result);

      final tomorrow = DateTime(2026, 9, 11);
      final getRes = await repository.getResult(tomorrow, 'basic');
      expect((getRes as RepoSuccess<DailyChallengeResult?>).value, isNull);
    });
  });
}
