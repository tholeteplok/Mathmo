import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/chunky_card.dart';
import '../providers/account_status_provider.dart';
import 'set_username_dialog.dart';

class CreateAccountCta extends ConsumerStatefulWidget {
  const CreateAccountCta({super.key, required this.accountState});

  final AccountState accountState;

  @override
  ConsumerState<CreateAccountCta> createState() => _CreateAccountCtaState();
}

class _CreateAccountCtaState extends ConsumerState<CreateAccountCta> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final result = await ref.read(accountStatusProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is RepoSuccess<AccountState>) {
      await handlePostSignInFlow(context, ref, accountState: result.value);
    } else {
      final reason = (result as RepoFailure).reason;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reason)),
      );
    }
  }

  Future<void> _handleAnonymousSignIn() async {
    setState(() => _isLoading = true);
    final result = await ref.read(accountStatusProvider.notifier).signInAnonymously();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is RepoSuccess<AccountState>) {
      await handlePostSignInFlow(context, ref, accountState: result.value);
    } else {
      final reason = (result as RepoFailure).reason;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reason)),
      );
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Progres gameplay lokalmu tetap aman di perangkat ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Keluar', style: TextStyle(color: AppTheme.colorCoral)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(accountStatusProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.accountState.isGuest) {
      return ChunkyCard(
        variant: ChunkyCardVariant.woodBoard,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              AppIcons.trophy,
              size: 36,
              color: Color(0xFFD48B00),
            ),
            const SizedBox(height: 10),
            Text(
              'Buka Papan Peringkat!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.colorEspresso,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Hubungkan akunmu untuk bersaing di leaderboard harian dan amankan progres petualanganmu.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.colorTaupe,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ChunkyButton(
              onPressed: _isLoading ? null : _handleGoogleSignIn,
              backgroundColor: AppTheme.colorSage,
              borderColor: const Color(0xFF43733A),
              shadowColor: const Color(0xFF43733A),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.profile, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Masuk dengan Google',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ChunkyButton(
              onPressed: _isLoading ? null : _handleAnonymousSignIn,
              backgroundColor: AppTheme.colorWoodMedium,
              borderColor: AppTheme.colorWoodDark,
              shadowColor: AppTheme.colorWoodDark,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.cloudSync, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Masuk Cepat (Anonim)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Terhubung (Logged In)
    return ChunkyCard(
      variant: ChunkyCardVariant.woodBoard,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ChunkyButton(
                  onPressed: () => showSetUsernameDialog(
                    context,
                    currentUsername: widget.accountState.username,
                  ),
                  backgroundColor: AppTheme.colorWoodMedium,
                  borderColor: AppTheme.colorWoodDark,
                  shadowColor: AppTheme.colorWoodDark,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Text(
                    'Ubah Username',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChunkyButton(
                  onPressed: _handleSignOut,
                  backgroundColor: const Color(0xFFC04A38),
                  borderColor: const Color(0xFF8B2C1E),
                  shadowColor: const Color(0xFF8B2C1E),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Text(
                    'Keluar Akun',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
