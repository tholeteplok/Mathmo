import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/developer_contact.dart';
import '../../../core/services/external_link_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/chunky_card.dart';
import '../providers/settings_provider.dart';

/// Layar pengaturan preferensi audio, haptik, dan informasi aplikasi iTHUNG.
///
/// Dirancang dengan Neobrutalism terpusat menggunakan [ChunkyCard], [ChunkyButton],
/// serta token desain [AppTokens] dan [AppTheme] tanpa hardcoding.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(audioSettingsProvider);
    final settingsNotifier = ref.read(audioSettingsProvider.notifier);

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
              // Header terpusat
              AppHeader(
                title: 'Pengaturan',
                showStats: false,
                onBackTap: () => context.go('/'),
              ),

              // Konten Pengaturan Scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── KARTU 1: AUDIO & SUARA ─────────────────────────
                      _AudioCard(
                        settings: settings,
                        notifier: settingsNotifier,
                      ),
                      const SizedBox(height: 16),

                      // ── KARTU 2: PREFERENSI GAMEPLAY & HAPTIK ──────────
                      _GameplayCard(
                        settings: settings,
                        notifier: settingsNotifier,
                      ),
                      const SizedBox(height: 16),

                      // ── KARTU 3: TENTANG APLIKASI ──────────────────────
                      const _AboutCard(),
                      const SizedBox(height: 20),

                      // ── KONTAK DEVELOPER (MINIMALIS) ─────────────────
                      const _ContactSection(),
                      const SizedBox(height: 24),
                    ],
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

/// Kartu pengaturan musik latar (BGM) dan efek suara (SFX).
class _AudioCard extends ConsumerWidget {
  const _AudioCard({
    required this.settings,
    required this.notifier,
  });

  final AudioSettingsState settings;
  final AudioSettingsNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChunkyCard(
      variant: ChunkyCardVariant.wood,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.colorSuccessSoft,
                  borderRadius: BorderRadius.circular(AppTokens.radiusIcon),
                  border: Border.all(
                    color: AppTheme.darkBorder,
                    width: AppTokens.borderWidthSubtle,
                  ),
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: AppTheme.colorSuccess,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Musik & Suara',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkBorder,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.darkBorder, height: 1),
          const SizedBox(height: 16),

          // Baris BGM Switch & Slider
          _AudioControlRow(
            title: 'Musik Latar (BGM)',
            subtitle: 'Lagu suasana tema adaptif di setiap zona',
            icon: Icons.music_note_rounded,
            isMuted: settings.bgmMuted,
            volume: settings.bgmVolume,
            onToggle: () => notifier.toggleBgm(),
            onVolumeChanged: (val) => notifier.setBgmVolume(val),
          ),
          const SizedBox(height: 20),

          // Baris SFX Switch & Slider
          _AudioControlRow(
            title: 'Efek Suara (SFX)',
            subtitle: 'Respon ketukan, jawaban benar/salah, & hadiah',
            icon: Icons.graphic_eq_rounded,
            isMuted: settings.sfxMuted,
            volume: settings.sfxVolume,
            onToggle: () => notifier.toggleSfx(),
            onVolumeChanged: (val) => notifier.setSfxVolume(val),
          ),
        ],
      ),
    );
  }
}

/// Baris kontrol audio dengan switch on/off dan slider volume.
class _AudioControlRow extends StatelessWidget {
  const _AudioControlRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isMuted,
    required this.volume,
    required this.onToggle,
    required this.onVolumeChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isMuted;
  final double volume;
  final VoidCallback onToggle;
  final ValueChanged<double> onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isMuted ? Colors.grey.shade400 : AppTheme.darkBorder,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkBorder,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Neobrutalist Toggle Switch
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 52,
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isMuted
                      ? const Color(0xFFE0E0E0)
                      : AppTheme.fallbackAccent,
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  border: Border.all(
                    color: AppTheme.darkBorder,
                    width: AppTokens.borderWidthDefault,
                  ),
                ),
                alignment:
                    isMuted ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.darkBorder,
                      width: AppTokens.borderWidthSubtle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (!isMuted) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                volume == 0 ? Icons.volume_mute_rounded : Icons.volume_down_rounded,
                size: 18,
                color: Colors.grey.shade700,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.fallbackAccent,
                    inactiveTrackColor: const Color(0xFFDCEDC8),
                    thumbColor: Colors.white,
                    overlayColor: AppTheme.fallbackAccent.withValues(alpha: 0.2),
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                      elevation: 2,
                    ),
                  ),
                  child: Slider(
                    value: volume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: onVolumeChanged,
                  ),
                ),
              ),
              Text(
                '${(volume * 100).round()}%',
                style: AppTheme.statNumberStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Kartu preferensi gameplay dan haptic (persiapan fitur mendatang).
class _GameplayCard extends StatelessWidget {
  const _GameplayCard({
    required this.settings,
    required this.notifier,
  });

  final AudioSettingsState settings;
  final AudioSettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return ChunkyCard(
      variant: ChunkyCardVariant.wood,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(AppTokens.radiusIcon),
                  border: Border.all(
                    color: AppTheme.darkBorder,
                    width: AppTokens.borderWidthSubtle,
                  ),
                ),
                child: const Icon(
                  Icons.sports_esports_rounded,
                  color: Color(0xFFE65100),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Preferensi Permainan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkBorder,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.darkBorder, height: 1),
          const SizedBox(height: 16),

          // Getaran Haptik
          Row(
            children: [
              const Icon(
                Icons.vibration_rounded,
                size: 20,
                color: AppTheme.darkBorder,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Getaran Haptik',
                      style: GoogleFonts.quicksand(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkBorder,
                      ),
                    ),
                    Text(
                      'Sensasi getaran taktil saat menekan tombol',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => notifier.toggleHaptic(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 52,
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: settings.hapticEnabled
                        ? AppTheme.fallbackAccent
                        : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    border: Border.all(
                      color: AppTheme.darkBorder,
                      width: AppTokens.borderWidthDefault,
                    ),
                  ),
                  alignment: settings.hapticEnabled
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.darkBorder,
                        width: AppTokens.borderWidthSubtle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mode Tampilan & Animasi Dinamis (Persiapan)
          Row(
            children: [
              const Icon(
                Icons.speed_rounded,
                size: 20,
                color: AppTheme.darkBorder,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Animasi Dinamis',
                      style: GoogleFonts.quicksand(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkBorder,
                      ),
                    ),
                    Text(
                      'Transisi halus & responsif gaya Neobrutalis',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEDC8),
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  border: Border.all(
                    color: AppTheme.darkBorder,
                    width: AppTokens.borderWidthSubtle,
                  ),
                ),
                child: Text(
                  'Aktif',
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.colorSuccess,
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

/// Kartu identitas brand dan informasi versi aplikasi iTHUNG.
class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return ChunkyCard(
      variant: ChunkyCardVariant.wood,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Ikon Aplikasi iTHUNG
          Container(
            width: 68,
            height: 68,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.colorVanillaCard,
              borderRadius: BorderRadius.circular(AppTokens.radiusButton),
              border: Border.all(
                color: AppTheme.colorCardBorder,
                width: AppTokens.borderWidthDefault,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.colorWoodDark.withValues(alpha: 0.12),
                  offset: const Offset(0, 3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              child: Image.asset(
                'assets/icon/app_launcher.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Logo Brand iTHUNG (Baberry Font)
          Text(
            'iTHUNG',
            style: AppTheme.brandTitleStyle(
              fontSize: 44,
              color: AppTheme.colorHoney,
            ),
          ),
          const SizedBox(height: 4),

          // Tagline Resmi
          Text(
            'Fast Math. Sharp Mind.',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.colorWoodMedium,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),

          // Versi Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.colorWoodPlank,
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              border: Border.all(
                color: AppTheme.colorCardBorder,
                width: AppTokens.borderWidthSubtle,
              ),
            ),
            child: Text(
              'Versi 0.1.0 (Beta)',
              style: AppTheme.statNumberStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.darkBorder, height: 1),
          const SizedBox(height: 12),

          // Lisensi Audio Open Source CC0
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 16,
                color: AppTheme.colorSuccess,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Aset Audio & SFX: Creative Commons CC0',
                  style: GoogleFonts.quicksand(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bagian kontak developer minimalis — icon Telegram & WhatsApp yang ringkas dan tidak dominan.
///
/// URL/handle terpusat di [DeveloperContact]; pembuka link via
/// [externalLinkServiceProvider] agar testable.
class _ContactSection extends ConsumerWidget {
  const _ContactSection();

  Future<void> _open(BuildContext context, WidgetRef ref, Uri uri) async {
    final opened = await ref.read(externalLinkServiceProvider).open(uri);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka link kontak')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Hubungi Developer',
          style: GoogleFonts.quicksand(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Telegram
            Tooltip(
              message: 'Telegram (${DeveloperContact.telegramHandle})',
              child: ChunkyButton(
                key: const ValueKey('btn_contact_telegram'),
                onPressed: () => _open(
                  context,
                  ref,
                  DeveloperContact.telegramUrl,
                ),
                width: 44,
                height: 44,
                padding: EdgeInsets.zero,
                borderRadius: AppTokens.radiusIcon,
                child: Image.asset(
                  'assets/icon/ic_tele.png',
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Icon WhatsApp
            Tooltip(
              message: 'WhatsApp (${DeveloperContact.whatsappDisplay})',
              child: ChunkyButton(
                key: const ValueKey('btn_contact_whatsapp'),
                onPressed: () => _open(
                  context,
                  ref,
                  DeveloperContact.whatsappUrl,
                ),
                width: 44,
                height: 44,
                padding: EdgeInsets.zero,
                borderRadius: AppTokens.radiusIcon,
                child: Image.asset(
                  'assets/icon/ic_wa.png',
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
