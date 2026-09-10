import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/presentation/game/widgets/countdown_progress_bar.dart';

void main() {
  group('CountdownProgressBar Widget Tests', () {
    testWidgets('renders with full width (> 0) inside an unconstrained Column', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: Column(
                  children: [
                    CountdownProgressBar(
                      duration: const Duration(seconds: 5),
                      onTimeout: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Temukan render object CountdownProgressBar
      final barFinder = find.byType(CountdownProgressBar);
      expect(barFinder, findsOneWidget);

      final size = tester.getSize(barFinder);
      expect(size.width, equals(300.0));
      expect(size.height, equals(16.0));
    });

    testWidgets('calls onTimeout when duration elapses', (tester) async {
      var timeoutCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownProgressBar(
              duration: const Duration(milliseconds: 500),
              onTimeout: () {
                timeoutCalled = true;
              },
            ),
          ),
        ),
      );

      expect(timeoutCalled, isFalse);

      // Advance clock past 500ms
      await tester.pump(const Duration(milliseconds: 250));
      expect(timeoutCalled, isFalse);

      await tester.pump(const Duration(milliseconds: 300));
      expect(timeoutCalled, isTrue);
    });

    testWidgets('resets animation when resetToken changes', (tester) async {
      var timeoutCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownProgressBar(
              key: const ValueKey('same_key'),
              resetToken: 1,
              duration: const Duration(milliseconds: 600),
              onTimeout: () {
                timeoutCount++;
              },
            ),
          ),
        ),
      );

      // Advance by 400ms (more than halfway)
      await tester.pump(const Duration(milliseconds: 400));
      expect(timeoutCount, equals(0));

      // Now update resetToken to 2 with the same key and same duration
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownProgressBar(
              key: const ValueKey('same_key'),
              resetToken: 2,
              duration: const Duration(milliseconds: 600),
              onTimeout: () {
                timeoutCount++;
              },
            ),
          ),
        ),
      );

      // Advance by 300ms from the reset point (total elapsed since start = 700ms)
      // If it hadn't reset, it would have timed out at 600ms total.
      await tester.pump(const Duration(milliseconds: 300));
      expect(timeoutCount, equals(0)); // Still not timed out because it restarted!

      // Advance another 350ms (total 650ms from restart)
      await tester.pump(const Duration(milliseconds: 350));
      expect(timeoutCount, equals(1));
    });

    testWidgets('initialProgress starts animation from partial position and expires in proportional time', (tester) async {
      var timeoutCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownProgressBar(
              duration: const Duration(milliseconds: 1000),
              initialProgress: 0.4, // 40% time remaining -> 400ms remaining
              onTimeout: () {
                timeoutCalled = true;
              },
            ),
          ),
        ),
      );

      // Advance by 300ms (less than 400ms)
      await tester.pump(const Duration(milliseconds: 300));
      expect(timeoutCalled, isFalse);

      // Advance by another 150ms (total 450ms > 400ms remaining)
      await tester.pump(const Duration(milliseconds: 150));
      expect(timeoutCalled, isTrue);
    });
  });
}

