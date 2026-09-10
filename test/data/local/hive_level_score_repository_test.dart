import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mathmo_app/data/local/hive_level_score_repository.dart';
import 'package:mathmo_app/domain/models/level_score_record.dart';
import 'package:mathmo_app/domain/repositories/repo_result.dart';

void main() {
  late Directory tempDir;
  late Box<Map> box;
  late HiveLevelScoreRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_level_score_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<Map>(HiveLevelScoreRepository.boxName);
    repository = HiveLevelScoreRepository(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HiveLevelScoreRepository', () {
    test('getRecord returns null if record does not exist', () async {
      final res = await repository.getRecord(1);
      expect(res, isA<RepoSuccess<LevelScoreRecord?>>());
      expect((res as RepoSuccess<LevelScoreRecord?>).value, isNull);
    });

    test('saveRecord persists record and getRecord retrieves it', () async {
      const record = LevelScoreRecord(
        level: 1,
        bestScore: 150,
        attempts: 1,
      );

      final saveRes = await repository.saveRecord(record);
      expect(saveRes, isA<RepoSuccess<void>>());

      final getRes = await repository.getRecord(1);
      expect(getRes, isA<RepoSuccess<LevelScoreRecord?>>());
      final retrieved = (getRes as RepoSuccess<LevelScoreRecord?>).value;
      expect(retrieved, equals(record));
    });

    test('getAllRecords returns all saved records mapped by level', () async {
      const r1 = LevelScoreRecord(
        level: 1,
        bestScore: 100,
        attempts: 1,
      );
      const r2 = LevelScoreRecord(
        level: 2,
        bestScore: 200,
        attempts: 3,
      );

      await repository.saveRecord(r1);
      await repository.saveRecord(r2);

      final allRes = await repository.getAllRecords();
      expect(allRes, isA<RepoSuccess<Map<int, LevelScoreRecord>>>());
      final map = (allRes as RepoSuccess<Map<int, LevelScoreRecord>>).value;
      expect(map.length, equals(2));
      expect(map[1]?.bestScore, equals(100));
      expect(map[2]?.bestScore, equals(200));
    });
  });
}
