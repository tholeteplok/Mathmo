import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mathmo_app/core/theme/app_theme.dart';
import 'package:mathmo_app/presentation/splash/widgets/splash_screen.dart';

void main() {
  group('SplashScreen Widget Tests', () {
    test('AppTheme.brandTitleStyle uses Baberry font', () {
      final style = AppTheme.brandTitleStyle(fontSize: 60);
      expect(style.fontFamily, equals('Baberry'));
      expect(style.fontSize, equals(60));
      expect(style.color, equals(AppTheme.colorHoney));
    });

    testWidgets('renders iTHUNG title, tagline, and progress bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        ),
      );

      // Verify title "iTHUNG" and app launcher icon are rendered
      expect(find.text('iTHUNG'), findsWidgets);
      expect(find.byType(Image), findsWidgets);

      // Verify tagline is rendered
      expect(find.text('Fast Math. Sharp Mind.'), findsOneWidget);

      // Verify progress caption is rendered
      expect(find.text('Preparing your adventure...'), findsOneWidget);

      // Advance animation partially
      await tester.pump(const Duration(milliseconds: 900));

      // Advance animation to completion
      await tester.pump(const Duration(milliseconds: 1000));
    });

    testWidgets('transitions to root path when animation completes', (tester) async {
      var navigatedToHome = false;

      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) {
              navigatedToHome = true;
              return const Scaffold(body: Text('Home Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(find.text('Fast Math. Sharp Mind.'), findsOneWidget);
      expect(navigatedToHome, isFalse);

      // Advance past duration to trigger onCompleted -> context.go('/')
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      expect(navigatedToHome, isTrue);
      expect(find.text('Home Screen'), findsOneWidget);
    });
  });
}
