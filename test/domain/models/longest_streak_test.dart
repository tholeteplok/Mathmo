import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/models/player_profile.dart';

void main() {
  group('StreakState.longestStreak', () {
    test('initial factory sets longestStreak to 0', () {
      expect(StreakState.initial.longestStreak, equals(0));
    });

    test('first recordActivity updates both currentStreak and longestStreak to 1', () {
      final initial = StreakState.initial;
      final today = DateTime.utc(2026, 9, 10);
      final updated = initial.recordActivity(today);

      expect(updated.currentStreak, equals(1));
      expect(updated.longestStreak, equals(1));
    });

    test('consecutive days increment currentStreak and longestStreak', () {
      var state = StreakState.initial.recordActivity(DateTime.utc(2026, 9, 1));
      expect(state.currentStreak, equals(1));
      expect(state.longestStreak, equals(1));

      state = state.recordActivity(DateTime.utc(2026, 9, 2));
      expect(state.currentStreak, equals(2));
      expect(state.longestStreak, equals(2));

      state = state.recordActivity(DateTime.utc(2026, 9, 3));
      expect(state.currentStreak, equals(3));
      expect(state.longestStreak, equals(3));
    });

    test('broken streak resets currentStreak to 1 but preserves longestStreak', () {
      var state = const StreakState(
        currentStreak: 5,
        freezeTokens: 0,
        longestStreak: 5,
        lastPlayedDate: null,
      );

      // Main di hari 1
      state = state.recordActivity(DateTime.utc(2026, 9, 1));
      expect(state.longestStreak, equals(5));

      // Absen 3 hari tanpa freeze token -> streak putus
      state = state.recordActivity(DateTime.utc(2026, 9, 5));
      expect(state.currentStreak, equals(1));
      expect(state.longestStreak, equals(5)); // Tetap 5, tidak ter-reset
    });

    test('onDayMissed preserves longestStreak', () {
      const state = StreakState(
        currentStreak: 4,
        freezeTokens: 1,
        longestStreak: 4,
      );

      final missedWithToken = state.onDayMissed();
      expect(missedWithToken.longestStreak, equals(4));
      expect(missedWithToken.freezeTokens, equals(0));

      final missedWithoutToken = missedWithToken.onDayMissed();
      expect(missedWithoutToken.longestStreak, equals(4));
      expect(missedWithoutToken.currentStreak, equals(0));
    });

    test('toJson and fromJson serialize longest_streak correctly', () {
      const state = StreakState(
        currentStreak: 3,
        freezeTokens: 2,
        longestStreak: 10,
      );

      final json = state.toJson();
      expect(json['current_streak'], equals(3));
      expect(json['longest_streak'], equals(10));

      final deserialized = StreakState.fromJson(json);
      expect(deserialized.longestStreak, equals(10));
      expect(deserialized.currentStreak, equals(3));
    });

    test('fromJson falls back to current_streak if longest_streak is missing', () {
      final json = {
        'current_streak': 7,
        'freeze_tokens': 1,
        'last_played_date': null,
      };

      final deserialized = StreakState.fromJson(json);
      expect(deserialized.currentStreak, equals(7));
      expect(deserialized.longestStreak, equals(7));
    });
  });
}
