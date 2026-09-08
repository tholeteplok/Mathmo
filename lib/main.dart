import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'domain/models/session_result.dart';
import 'presentation/daily_challenge/widgets/daily_challenge_screen.dart';
import 'presentation/game/widgets/game_screen.dart';
import 'presentation/home/widgets/home_screen.dart';
import 'presentation/results/widgets/results_screen.dart';
import 'presentation/shared/widgets/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Hive CE storage
  await Hive.initFlutter();

  runApp(const ProviderScope(child: MathmoApp()));
}

/// Konfigurasi rute navigasi terpusat aplikasi Mathmo.
///
/// Mengacu pada `math-speed-game-navigation-spec.md` §1 - §5:
/// - ShellRoute membungkus transisi antar layar agar kanvas warna tetap persisten
/// - Guard redirect pada `/results` mencegah akses langsung tanpa hasil sesi
/// - Mendukung deep link `/daily`
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/game/:level',
          builder: (context, state) {
            final level =
                int.tryParse(state.pathParameters['level'] ?? '1') ?? 1;
            return GameScreen(level: level);
          },
        ),
        GoRoute(
          path: '/daily',
          builder: (context, state) => const DailyChallengeScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/results',
      redirect: (context, state) {
        if (state.extra is! SessionResult) return '/';
        return null;
      },
      builder: (context, state) =>
          ResultsScreen(result: state.extra as SessionResult),
    ),
  ],
);

class MathmoApp extends StatelessWidget {
  const MathmoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mathmo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
