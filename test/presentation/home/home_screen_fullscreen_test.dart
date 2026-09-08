import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/presentation/home/widgets/home_screen.dart';
import 'package:mathmo_app/presentation/home/widgets/level_node.dart';
import 'package:mathmo_app/presentation/home/widgets/milestone_chest_node.dart';

void main() {
  group('HomeScreen Fullscreen & Stage Configuration', () {
    test('kMathmoStages covers all 5 bands with calibrated anchors', () {
      expect(kMathmoStages.length, greaterThanOrEqualTo(12));

      // Meadow (Band 1)
      expect(kMathmoStages[0].title, equals('Fresh Sprout Meadow'));
      expect(kMathmoStages[0].startLevel, equals(1));
      expect(kMathmoStages[0].endLevel, equals(5));
      expect(kMathmoStages[0].assetPath, contains('meadow_canvas.jpg'));

      // Canyon (Band 2)
      expect(kMathmoStages[1].title, equals('Golden Sun Canyon'));
      expect(kMathmoStages[1].startLevel, equals(6));
      expect(kMathmoStages[1].endLevel, equals(10));
      expect(kMathmoStages[1].assetPath, contains('canyon_canvas.jpg'));

      // Ridge (Band 3)
      expect(kMathmoStages[3].title, equals('Coral Sunset Ridge'));
      expect(kMathmoStages[3].startLevel, equals(16));
      expect(kMathmoStages[3].endLevel, equals(20));
      expect(kMathmoStages[3].assetPath, contains('ridge_canvas.jpg'));

      // Twilight (Band 4)
      expect(kMathmoStages[6].title, equals('Twilight Forest'));
      expect(kMathmoStages[6].startLevel, equals(31));
      expect(kMathmoStages[6].endLevel, equals(35));
      expect(kMathmoStages[6].assetPath, contains('twilight_canvas.jpg'));

      // Cosmic (Band 5)
      expect(kMathmoStages[10].title, equals('Cosmic Mystic Peak'));
      expect(kMathmoStages[10].startLevel, equals(51));
      expect(kMathmoStages[10].endLevel, equals(55));
      expect(kMathmoStages[10].assetPath, contains('cosmic_canvas.jpg'));

      // Calibrated anchors
      for (final stage in kMathmoStages) {
        expect(stage.nodeAnchors.length, equals(5));
        expect(stage.nodeAnchors[0], equals(const Offset(265, 1020)));
        expect(stage.nodeAnchors[4], equals(const Offset(265, 450)));
        expect(stage.chestAnchor, equals(const Offset(380, 360)));
      }
    });

    testWidgets('Renders PageView and floating Daily Challenge button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('Daily Challenge Hari Ini'), findsOneWidget);
      expect(find.byType(LevelNode), findsWidgets);
      expect(find.byType(MilestoneChestNode), findsWidgets);
    });
  });
}
