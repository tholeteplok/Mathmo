import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/firebase_error_mapper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/models/leaderboard_entry.dart';
import '../../game/providers/level_band_theme_provider.dart';
import '../../profile/providers/account_status_provider.dart';
import '../../profile/widgets/set_username_dialog.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/chunky_card.dart';
import '../providers/leaderboard_provider.dart';

/// Layar Papan Peringkat Global / Kohor Harian (LeaderboardScreen - /leaderboard).
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountStatusProvider).valueOrNull ??
        const AccountState(status: AccountStatus.guest);

    // 1. Jika masih mode Guest (belum buat akun / username), tampilkan Locked State
    if (accountState.isGuest || !accountState.hasUsername) {
      return LeaderboardLockedView(accountState: accountState);
    }

    // 2. Jika sudah terhubung, tampilkan Leaderboard dengan mode toggle
    final mode = ref.watch(leaderboardModeProvider);
    final selectedBand = ref.watch(leaderboardSelectedBandProvider);

    final entriesAsync = mode == LeaderboardMode.daily
        ? ref.watch(leaderboardEntriesProvider(selectedBand))
        : ref.watch(allTimeEntriesProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.colorSandyCanvas,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    ChunkyButton(
                      onPressed: () => context.go('/'),
                      backgroundColor: AppTheme.colorVanillaCard,
                      borderColor: AppTheme.darkBorder,
                      shadowColor: AppTheme.darkBorder,
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        AppIcons.back,
                        size: 20,
                        color: AppTheme.colorWoodDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Papan Peringkat',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.colorEspresso,
                          ),
                    ),
                  ],
                ),
              ),

              // Mode Toggle Pill (Harian / Semua Waktu)
              const _ModeToggle(),
              const SizedBox(height: 6),

              // Band Tabs Selector — hanya tampil di mode daily
              if (mode == LeaderboardMode.daily) ...[
                const _BandTabsSelector(),
                const SizedBox(height: 8),
              ] else
                const SizedBox(height: 4),

              // Konten State Leaderboard
              Expanded(
                child: entriesAsync.when(
                  loading: () => const LeaderboardLoadingView(),
                  error: (err, _) => LeaderboardErrorView(
                    error: err,
                    onRetry: () {
                      if (mode == LeaderboardMode.daily) {
                        ref.invalidate(leaderboardEntriesProvider(selectedBand));
                      } else {
                        ref.invalidate(allTimeEntriesProvider);
                      }
                    },
                  ),
                  data: (entries) => LeaderboardListView(
                    entries: entries,
                    mode: mode,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toggle pill untuk memilih mode leaderboard (Harian / Semua Waktu).
class _ModeToggle extends ConsumerWidget {
  const _ModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(leaderboardModeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.colorVanillaCard,
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          border: Border.all(
            color: AppTheme.darkBorder,
            width: AppTokens.borderWidthDefault,
          ),
        ),
        child: Row(
          children: [
            _ModeTab(
              label: '🏆  Harian',
              isSelected: mode == LeaderboardMode.daily,
              onTap: () => ref.read(leaderboardModeProvider.notifier).state =
                  LeaderboardMode.daily,
            ),
            _ModeTab(
              label: '⭐  Semua Waktu',
              isSelected: mode == LeaderboardMode.allTime,
              onTap: () => ref.read(leaderboardModeProvider.notifier).state =
                  LeaderboardMode.allTime,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.colorWoodMedium : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTokens.radiusButton - 4),
            boxShadow: isSelected
                ? [
                    const BoxShadow(
                      color: AppTheme.colorWoodDark,
                      offset: Offset(0, 2),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : AppTheme.colorTaupe,
            ),
          ),
        ),
      ),
    );
  }
}

/// Selector tab band horizontal
class _BandTabsSelector extends ConsumerWidget {
  const _BandTabsSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bandsAsync = ref.watch(levelBandsConfigProvider);
    final selectedBand = ref.watch(leaderboardSelectedBandProvider);

    return bandsAsync.when(
      loading: () => const SizedBox(height: 40),
      error: (err, stack) => const SizedBox.shrink(),
      data: (config) {
        final bands = config.bands;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: bands.map((band) {
              final isSelected = band.id == selectedBand;
              final bandLabel = band.id.isNotEmpty
                  ? '${band.id[0].toUpperCase()}${band.id.substring(1)}'
                  : band.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    ref.read(leaderboardSelectedBandProvider.notifier).state =
                        band.id;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.colorWoodMedium
                          : AppTheme.colorVanillaCard,
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusPill),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.colorWoodDark
                            : AppTheme.darkBorder,
                        width: AppTokens.borderWidthDefault,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppTheme.colorWoodDark
                              : AppTheme.darkBorder,
                          offset: const Offset(0, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      bandLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : AppTheme.colorWoodDark,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// State saat papan peringkat terkunci karena user belum login atau belum memiliki username.
class LeaderboardLockedView extends ConsumerWidget {
  const LeaderboardLockedView({super.key, required this.accountState});

  final AccountState accountState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = accountState.isGuest;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.colorSandyCanvas,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: ChunkyButton(
                  onPressed: () => context.go('/'),
                  backgroundColor: AppTheme.colorVanillaCard,
                  borderColor: AppTheme.darkBorder,
                  shadowColor: AppTheme.darkBorder,
                  padding: const EdgeInsets.all(10),
                  child: const Icon(
                    AppIcons.back,
                    size: 20,
                    color: AppTheme.colorWoodDark,
                  ),
                ),
              ),
              const Spacer(),
              ChunkyCard(
                variant: ChunkyCardVariant.woodBoard,
                padding: const EdgeInsets.fromLTRB(26, 40, 26, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      AppIcons.trophy,
                      size: 54,
                      color: Color(0xFFD48B00),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Papan Peringkat Terkunci',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.colorEspresso,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isGuest
                          ? 'Hubungkan akunmu dan buat username unik untuk melihat ranking dan bersaing dengan pemain lain.'
                          : 'Kamu perlu menetapkan username unik (minimal 4 karakter) sebelum dapat melihat dan bersaing di papan peringkat.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.colorTaupe,
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (isGuest) ...[
                      ChunkyButton(
                        onPressed: () async {
                          final res = await ref
                              .read(accountStatusProvider.notifier)
                              .signInWithGoogle();
                          if (res.isSuccess && context.mounted) {
                            await showSetUsernameDialog(context);
                          }
                        },
                        backgroundColor: AppTheme.colorSage,
                        borderColor: const Color(0xFF43733A),
                        shadowColor: const Color(0xFF43733A),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 20,
                        ),
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
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ChunkyButton(
                        onPressed: () async {
                          final res = await ref
                              .read(accountStatusProvider.notifier)
                              .signInAnonymously();
                          if (res.isSuccess && context.mounted) {
                            await showSetUsernameDialog(context);
                          }
                        },
                        backgroundColor: AppTheme.colorWoodMedium,
                        borderColor: AppTheme.colorWoodDark,
                        shadowColor: AppTheme.colorWoodDark,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 20,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(AppIcons.cloudSync, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Masuk Cepat & Buat Username',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ChunkyButton(
                        onPressed: () => showSetUsernameDialog(context),
                        backgroundColor: AppTheme.colorSage,
                        borderColor: const Color(0xFF43733A),
                        shadowColor: const Color(0xFF43733A),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 24,
                        ),
                        child: const Text(
                          'Buat Username Sekarang',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    ),
  );
}
}

/// Loading view
class LeaderboardLoadingView extends StatelessWidget {
  const LeaderboardLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.colorWoodMedium),
    );
  }
}

/// Error view dengan tombol coba lagi dan pesan dinamis informatif
class LeaderboardErrorView extends StatelessWidget {
  const LeaderboardErrorView({
    super.key,
    this.error,
    required this.onRetry,
  });

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error != null
        ? FirebaseErrorMapper.map(
            error!,
            defaultMessage: 'Gagal memuat papan peringkat. Silakan periksa koneksi atau coba lagi nanti.',
          )
        : 'Periksa koneksi internetmu dan coba kembali.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppTheme.colorTaupe,
            ),
            const SizedBox(height: 12),
            Text(
              'Gagal Memuat Papan Peringkat',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.colorEspresso,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                color: AppTheme.colorTaupe,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ChunkyButton(
              onPressed: onRetry,
              backgroundColor: AppTheme.colorWoodMedium,
              borderColor: AppTheme.colorWoodDark,
              shadowColor: AppTheme.colorWoodDark,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tampilan daftar skor leaderboard — mendukung mode daily & all-time
class LeaderboardListView extends StatelessWidget {
  const LeaderboardListView({
    super.key,
    required this.entries,
    required this.mode,
  });

  final List<LeaderboardEntry> entries;
  final LeaderboardMode mode;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      final emptyTitle = mode == LeaderboardMode.allTime
          ? 'Belum Ada Pemain'
          : 'Belum Ada Skor Hari Ini';
      final emptySubtitle = mode == LeaderboardMode.allTime
          ? 'Selesaikan tantangan harian untuk mencatat rekor skor!'
          : 'Jadilah petualang pertama yang menaklukkan tantangan ini!';

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                AppIcons.trophy,
                size: 48,
                color: Color(0xFFDECFA8),
              ),
              const SizedBox(height: 12),
              Text(
                emptyTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.colorEspresso,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                emptySubtitle,
                style: const TextStyle(color: AppTheme.colorTaupe, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _LeaderboardRowItem(entry: entry, mode: mode);
      },
    );
  }
}

class _LeaderboardRowItem extends StatelessWidget {
  const _LeaderboardRowItem({required this.entry, required this.mode});

  final LeaderboardEntry entry;
  final LeaderboardMode mode;

  @override
  Widget build(BuildContext context) {
    final (rankColor, rankBg) = switch (entry.rank) {
      1 => (const Color(0xFF7D5700), const Color(0xFFFFE082)), // Emas
      2 => (const Color(0xFF424242), const Color(0xFFE0E0E0)), // Perak
      3 => (const Color(0xFF5D3A1A), const Color(0xFFFFCCBC)), // Perunggu
      _ => (AppTheme.colorWoodDark, AppTheme.colorSandyCanvas),
    };

    // Skor yang ditampilkan berbeda per mode
    final scoreLabel = mode == LeaderboardMode.allTime
        ? '${entry.totalScore ?? 0} pts'
        : '${entry.correctCount}/12';
    final scoreColor = mode == LeaderboardMode.allTime
        ? AppTheme.colorCoral
        : AppTheme.colorSage;

    // Sub-info berbeda per mode
    final subInfo = mode == LeaderboardMode.allTime
        ? 'Total Skor'
        : 'Waktu: ${entry.formattedTime}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isCurrentPlayer
            ? const Color(0xFFFFF9E6)
            : AppTheme.colorVanillaCard,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(
          color: entry.isCurrentPlayer
              ? const Color(0xFFD48B00)
              : AppTheme.darkBorder,
          width: entry.isCurrentPlayer
              ? AppTokens.borderWidthDefault
              : AppTokens.borderWidthSubtle,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.darkBorder,
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.darkBorder,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: rankColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Avatar (Preset image or initial letter)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.colorVanillaCard,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.darkBorder,
                width: 1.5,
              ),
            ),
            child: AppAssets.avatarPath(entry.avatarId) != null
                ? ClipOval(
                    child: Image.asset(
                      AppAssets.avatarPath(entry.avatarId)!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      entry.username.isNotEmpty
                          ? entry.username[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppTheme.colorEspresso,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),

          // Username & Player Indicator
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '@${entry.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: entry.isCurrentPlayer
                              ? FontWeight.w900
                              : FontWeight.w800,
                          color: AppTheme.colorEspresso,
                        ),
                      ),
                    ),
                    if (entry.isCurrentPlayer) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.colorWoodDark,
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusPill),
                        ),
                        child: const Text(
                          'Kamu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subInfo,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.colorTaupe,
                  ),
                ),
              ],
            ),
          ),

          // Skor Utama (dinamis per mode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              border: Border.all(
                color: scoreColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Text(
              scoreLabel,
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

