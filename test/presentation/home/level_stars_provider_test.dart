import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/presentation/home/providers/level_stars_provider.dart';

void main() {
  group('LevelStarsProvider & Notifier Tests', () {
    test('calculateStars maps accuracy to stars correctly', () {
      expect(LevelStarsNotifier.calculateStars(1.0), 3);
      expect(LevelStarsNotifier.calculateStars(0.90), 3);
      expect(LevelStarsNotifier.calculateStars(0.89), 2);
      expect(LevelStarsNotifier.calculateStars(0.70), 2);
      expect(LevelStarsNotifier.calculateStars(0.69), 1);
      expect(LevelStarsNotifier.calculateStars(0.50), 1);
      expect(LevelStarsNotifier.calculateStars(0.49), 0);
      expect(LevelStarsNotifier.calculateStars(0.0), 0);
    });

    test('recordStars updates in-memory stars map instantly (0ms delay)', () async {
      final container = ProviderContainer(
        overrides: [
          levelStarsProvider.overrideWith(
            () => _MockLevelStarsNotifier({1: 2}),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Pastikan initial state termuat
      final initial = await container.read(levelStarsProvider.future);
      expect(initial[1], 2);

      // Record peningkatan akurasi di level 1 (dari 2 bintang menjadi 3 bintang)
      container
          .read(levelStarsProvider.notifier)
          .recordStars(level: 1, accuracy: 0.95);

      final updated = container.read(levelStarsProvider).valueOrNull;
      expect(updated?[1], 3);

      // Record level 2 baru dengan 2 bintang
      container
          .read(levelStarsProvider.notifier)
          .recordStars(level: 2, accuracy: 0.8);

      final updated2 = container.read(levelStarsProvider).valueOrNull;
      expect(updated2?[2], 2);
      expect(updated2?[1], 3);
    });

    test('restoreStars merges restored cloud stars into in-memory map', () async {
      final container = ProviderContainer(
        overrides: [
          levelStarsProvider.overrideWith(
            () => _MockLevelStarsNotifier({1: 1}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(levelStarsProvider.future);
      expect(initial[1], 1);

      // Restore from cloud: Level 1 has 3 stars, Level 2 has 2 stars
      container
          .read(levelStarsProvider.notifier)
          .restoreStars({1: 3, 2: 2});

      final updated = container.read(levelStarsProvider).valueOrNull;
      expect(updated?[1], 3);
      expect(updated?[2], 2);
    });
  });
}

class _MockLevelStarsNotifier extends LevelStarsNotifier {
  _MockLevelStarsNotifier(this._initialMap);

  final Map<int, int> _initialMap;

  @override
  Future<Map<int, int>> build() async {
    return _initialMap;
  }
}
