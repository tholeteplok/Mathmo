import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../home/providers/player_profile_provider.dart';
import '../providers/account_status_provider.dart';
import '../../shared/widgets/avatar_frame.dart';
import 'avatar_selection_dialog.dart';
import 'set_username_dialog.dart';

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({
    super.key,
    required this.accountState,
    required this.currentLevel,
  });

  final AccountState accountState;
  final int currentLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileProvider).valueOrNull;
    final avatarId = profile?.avatarId;
    final avatarAsset = AppAssets.avatarPath(avatarId);
    final initialLetter = accountState.hasUsername
        ? accountState.username![0].toUpperCase()
        : 'P';

    final (badgeText, badgeBg, badgeColor, badgeIcon) = switch (accountState.status) {
      AccountStatus.guest => (
        'Akun Tamu · Main Lokal',
        AppTheme.badgeGuestBg,
        AppTheme.colorTaupe,
        AppIcons.shield,
      ),
      AccountStatus.anonymous => (
        'Akun Anonim (Cloud)',
        AppTheme.badgeInfoBg,
        AppTheme.badgeInfoFg,
        AppIcons.cloudSync,
      ),
      AccountStatus.linked => (
        'Terhubung dengan Google',
        AppTheme.colorSuccessSoft,
        AppTheme.colorSage,
        AppIcons.check,
      ),
    };

    final displayHandle = accountState.hasUsername
        ? '@${accountState.username}'
        : (accountState.status == AccountStatus.guest
            ? 'Petualang iTHUNG'
            : 'Belum ada username');

    return Column(
      children: [
        // Avatar Frame dengan Tombol Edit
        GestureDetector(
          onTap: () => showAvatarSelectionDialog(
            context,
            currentAvatarId: avatarId,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomRight,
            children: [
              AvatarFrame(
                avatarAsset: avatarAsset,
                initialLetter: initialLetter,
                size: 92,
              ),

              // Badge Edit Avatar (Top-Right)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppTheme.colorHoney,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.darkBorder,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    AppIcons.edit,
                    size: 13,
                    color: AppTheme.colorEspresso,
                  ),
                ),
              ),

              // Badge Level (Bottom-Right)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.colorWoodDark,
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  border: Border.all(
                    color: Colors.white,
                    width: AppTokens.borderWidthSubtle,
                  ),
                ),
                child: Text(
                  'Lv.$currentLevel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Display Name & Edit Username
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayHandle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.colorEspresso,
                  ),
            ),
            if (!accountState.isGuest) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => showSetUsernameDialog(
                  context,
                  currentUsername: accountState.username,
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.colorVanillaCard,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMini),
                    border: Border.all(
                      color: AppTheme.darkBorder,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    AppIcons.settings,
                    size: 14,
                    color: AppTheme.colorWoodDark,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),

        // Account Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            border: Border.all(
              color: badgeColor.withValues(alpha: 0.4),
              width: AppTokens.borderWidthSubtle,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(badgeIcon, size: 13, color: badgeColor),
              const SizedBox(width: 6),
              Text(
                badgeText,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
