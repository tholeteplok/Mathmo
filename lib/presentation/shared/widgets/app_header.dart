import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import 'badge_pill.dart';
import 'chunky_button.dart';

/// Header persisten untuk GameScreen, HomeScreen, dan ShellRoute.
///
/// Menampilkan badge streak harian di sisi kiri dan badge XP di sisi kanan.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.streak,
    required this.xp,
    this.leading,
    this.title,
    this.actions,
    this.onBackTap,
    this.backgroundColor = Colors.transparent,
  });

  final int streak;
  final int xp;
  final Widget? leading;
  final String? title;
  final List<Widget>? actions;
  final VoidCallback? onBackTap;
  final Color backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Sisi Kiri: Tombol Back (jika ada) atau Streak Pill
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onBackTap != null) ...[
                  ChunkyButton(
                    onPressed: onBackTap,
                    width: 40,
                    height: 40,
                    padding: EdgeInsets.zero,
                    borderRadius: 12,
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: AppTheme.darkBorder,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 8),
                ],
                BadgePill(
                  icon: AppIcons.streak,
                  value: '$streak',
                  iconColor: AppTheme.colorCoral,
                ),
              ],
            ),

            // Judul Tengah (opsional)
            if (title != null)
              Expanded(
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.colorEspresso,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Sisi Kanan: XP Pill & Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BadgePill(
                  icon: AppIcons.xp,
                  value: '$xp',
                  iconColor: AppTheme.colorHoney,
                ),
                if (actions != null) ...[
                  const SizedBox(width: 8),
                  ...actions!,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
