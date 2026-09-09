import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/core/theme/app_theme.dart';
import 'package:mathmo_app/presentation/shared/widgets/exit_confirm_dialog.dart';

void main() {
  group('ExitConfirmDialog Widget Tests', () {
    testWidgets('renders title, message, red X icon, and green check icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ExitConfirmDialog(
              title: 'Keluar dari Sesi?',
              message: 'Progres ronde tidak akan disimpan.',
              cancelLabel: 'Batal',
              confirmLabel: 'Keluar',
            ),
          ),
        ),
      );

      // Verify title and message
      expect(find.text('Keluar dari Sesi?'), findsOneWidget);
      expect(find.text('Progres ronde tidak akan disimpan.'), findsOneWidget);

      // Verify button labels
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);

      // Verify Red "X" icon and Green Checkmark icon
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      final cancelIcon = tester.widget<Icon>(find.byIcon(Icons.close_rounded));
      expect(cancelIcon.color, equals(const Color(0xFFD32F2F)));

      final confirmIcon = tester.widget<Icon>(find.byIcon(Icons.check_rounded));
      expect(confirmIcon.color, equals(const Color(0xFF2E7D32)));
    });

    testWidgets('tapping cancel button pops with false', (tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showExitConfirmDialog(
                    context,
                    title: 'Keluar?',
                    message: 'Yakin keluar?',
                    cancelLabel: 'Batal',
                    confirmLabel: 'Ya',
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Keluar?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      // Tap Cancel button (Red X)
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Keluar?'), findsNothing);
      expect(dialogResult, isFalse);
    });

    testWidgets('tapping confirm button pops with true', (tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showExitConfirmDialog(
                    context,
                    title: 'Keluar dari iTHUNG?',
                    message: 'Apakah kamu yakin ingin menutup aplikasi?',
                    cancelLabel: 'Batal',
                    confirmLabel: 'Keluar',
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Keluar dari iTHUNG?'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);

      // Tap Confirm button (Green Check)
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      expect(find.text('Keluar dari iTHUNG?'), findsNothing);
      expect(dialogResult, isTrue);
    });
  });
}
