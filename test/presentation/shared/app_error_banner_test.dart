import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/core/theme/app_icons.dart';
import 'package:mathmo_app/presentation/shared/widgets/app_error_banner.dart';

void main() {
  group('AppErrorBanner Widget Tests', () {
    testWidgets('renders error message and warning icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppErrorBanner(
              message: 'Layanan database sedang tidak tersedia',
            ),
          ),
        ),
      );

      expect(find.text('Layanan database sedang tidak tersedia'), findsOneWidget);
      expect(find.byIcon(AppIcons.warning), findsOneWidget);
    });
  });
}
