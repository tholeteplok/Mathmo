import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../game/providers/level_band_theme_provider.dart';

/// Shell pembungkus aplikasi untuk navigasi via ShellRoute.
///
/// Mengacu pada `math-speed-game-navigation-spec.md` §5:
/// Mengelola transisi warna kanvas latar belakang dinamis (±300ms) tanpa terputus
/// saat berpindah layar (Home ↔ Game).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(levelBandThemeProvider);
    final canvasColor =
        themeAsync.valueOrNull?.canvasColor ?? const Color(0xFFEAF3DE);

    return AnimatedContainer(
      duration: AppTokens.canvasColorTransition,
      curve: Curves.easeInOut,
      color: canvasColor,
      child: child,
    );
  }
}
