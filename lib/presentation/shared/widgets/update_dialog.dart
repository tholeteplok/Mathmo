import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/services/update_service.dart';
import 'chunky_button.dart';
import 'chunky_card.dart';

/// Membuka dialog notifikasi pembaruan aplikasi bergaya Cozy Woodwork.
Future<void> showUpdateNotificationDialog({
  required BuildContext context,
  required AppUpdateInfo info,
  required VoidCallback onUpdate,
  VoidCallback? onLater,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => UpdateNotificationDialog(
      info: info,
      onUpdate: () {
        Navigator.pop(dialogContext);
        onUpdate();
      },
      onLater: () {
        Navigator.pop(dialogContext);
        onLater?.call();
      },
    ),
  );
}

/// Membuka dialog proses pengunduhan APK dan instalasi otomatis.
Future<void> showUpdateProgressDialog({
  required BuildContext context,
  required AppUpdateInfo info,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => UpdateProgressDialog(info: info),
  );
}

/// Dialog notifikasi rilis versi terbaru iTHUNG.
class UpdateNotificationDialog extends StatelessWidget {
  const UpdateNotificationDialog({
    super.key,
    required this.info,
    required this.onUpdate,
    this.onLater,
  });

  final AppUpdateInfo info;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: ChunkyCard(
          variant: ChunkyCardVariant.woodBoard,
          padding: const EdgeInsets.fromLTRB(22, 32, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Ikon Roket Bernyawa
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.colorSage.withValues(alpha: 0.18),
                  border: Border.all(
                    color: AppTheme.colorSage.withValues(alpha: 0.40),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    AppIcons.rocket,
                    color: AppTheme.colorSage,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Judul & Versi Baru
              Text(
                'Pembaruan Tersedia 🚀',
                style: GoogleFonts.quicksand(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.colorEspresso,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Versi ${info.latestVersion}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colorTaupe,
                ),
              ),
              const SizedBox(height: 12),

              // Badges Info Ukuran & Arsitektur CPU
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  if (info.formattedSize.isNotEmpty)
                    _buildBadge(
                      icon: AppIcons.download,
                      label: info.formattedSize,
                      accentColor: AppTheme.colorSage,
                    ),
                  if (info.matchedAbi.isNotEmpty)
                    _buildBadge(
                      icon: AppIcons.cpu,
                      label: info.matchedAbi == 'universal'
                          ? 'Universal APK'
                          : info.matchedAbi,
                      accentColor: AppTheme.colorHoney,
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Catatan Rilis (Release Notes)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Catatan Rilis:',
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.colorWoodDark,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _buildFriendlyReleaseNotes(info.releaseNotes),
              const SizedBox(height: 18),

              // Tombol Aksi Utama (Perbarui Sekarang)
              ChunkyButton(
                onPressed: onUpdate,
                backgroundColor: AppTheme.colorSage,
                width: double.infinity,
                child: const Text(
                  'Perbarui Sekarang',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),

              // Tombol Batal / Nanti Saja
              TextButton(
                onPressed: onLater,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Nanti Saja',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.colorTaupe,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: AppTokens.borderWidthSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accentColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.colorWoodDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendlyReleaseNotes(String rawNotes) {
    final service = UpdateService();
    final items = service.parseReleaseNotes(rawNotes);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.colorVanillaCard,
        borderRadius: BorderRadius.circular(AppTokens.radiusIcon),
        border: Border.all(
          color: AppTheme.colorWoodBorder.withValues(alpha: 0.6),
          width: AppTokens.borderWidthSubtle,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2.5),
                    child: _buildPriorityDot(item.category),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.text,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.colorWoodDark,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPriorityDot(ReleaseCategory category) {
    final Color pastelColor;
    switch (category) {
      case ReleaseCategory.fix:
        pastelColor = AppTheme.colorPastelCoral;
      case ReleaseCategory.feat:
        pastelColor = AppTheme.colorPastelSage;
      case ReleaseCategory.perf:
        pastelColor = AppTheme.colorPastelHoney;
      case ReleaseCategory.ui:
        pastelColor = AppTheme.colorPastelSky;
      case ReleaseCategory.general:
        pastelColor = AppTheme.colorPastelClay;
    }

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: pastelColor.withValues(alpha: 0.32),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: pastelColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Dialog proses pengunduhan file APK dan instalasi otomatis.
class UpdateProgressDialog extends ConsumerStatefulWidget {
  const UpdateProgressDialog({super.key, required this.info});

  final AppUpdateInfo info;

  @override
  ConsumerState<UpdateProgressDialog> createState() =>
      _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends ConsumerState<UpdateProgressDialog> {
  double _downloadProgress = 0.0;
  int _receivedBytes = 0;
  late int _totalBytes;
  String _statusMessage = 'Menghubungi server rilis...';
  String? _errorMessage;
  int _lastUiUpdateTime = 0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _totalBytes = widget.info.downloadSizeBytes;
    _initAndStartDownload();
  }

  Future<void> _initAndStartDownload() async {
    try {
      final updateService = ref.read(updateServiceProvider);
      final existing =
          await updateService.getDownloadedApkBytes(widget.info.latestVersion);
      if (existing > 0 && mounted) {
        setState(() {
          _receivedBytes = existing;
          if (_totalBytes > 0) {
            _downloadProgress = (existing / _totalBytes).clamp(0.0, 1.0);
            final pct = (_downloadProgress * 100).toInt();
            _statusMessage = 'Melanjutkan unduhan $pct%...';
          }
        });
      }
    } catch (_) {}
    _startDownload();
  }

  Future<void> _startDownload() async {
    if (_isDownloading) return;
    try {
      final updateService = ref.read(updateServiceProvider);
      if (mounted) {
        setState(() {
          _isDownloading = true;
          _errorMessage = null;
          _statusMessage = _receivedBytes > 0
              ? 'Melanjutkan unduhan...'
              : 'Mengunduh pembaruan...';
        });
      }

      final file = await updateService.downloadApk(
        downloadUrl: widget.info.downloadUrl,
        version: widget.info.latestVersion,
        expectedTotalBytes: widget.info.downloadSizeBytes,
        onProgress: (progress, received, total) {
          if (!mounted) return;

          final now = DateTime.now().millisecondsSinceEpoch;
          _receivedBytes = math.max(_receivedBytes, received);
          if (total > 0) {
            _totalBytes = total;
          }
          if (progress > 0) {
            _downloadProgress = math.max(_downloadProgress, progress);
          }

          // Throttle pembaruan UI ~60ms agar performa tetap 60 FPS
          final shouldUpdateUi =
              (now - _lastUiUpdateTime > 60) || progress >= 1.0;
          if (shouldUpdateUi) {
            _lastUiUpdateTime = now;
            setState(() {
              if (_downloadProgress >= 1.0) {
                _statusMessage = 'Memverifikasi paket instalasi...';
              } else if (_downloadProgress > 0) {
                final pct = (_downloadProgress * 100).toInt();
                _statusMessage = 'Mengunduh $pct%...';
              }
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _isDownloading = false;
        _downloadProgress = 1.0;
        _statusMessage = 'Membuka Penginstal Paket Android...';
      });

      final installed = await updateService.installApk(file.path);
      if (!installed && mounted) {
        setState(() {
          _errorMessage =
              'Tidak dapat membuka penginstal secara otomatis. Silakan buka file di folder unduhan atau perbarui via browser.';
        });
      } else if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final errText = e.toString().replaceFirst('Exception: ', '').trim();
        setState(() {
          _isDownloading = false;
          _errorMessage = errText;
          _statusMessage = 'Unduhan dijeda';
        });
      }
    }
  }

  Future<void> _openFallbackUrl() async {
    final uri = Uri.parse(widget.info.htmlUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final receivedMb = (_receivedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMb = _totalBytes > 0
        ? (_totalBytes / (1024 * 1024)).toStringAsFixed(1)
        : '?';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: ChunkyCard(
          variant: ChunkyCardVariant.woodBoard,
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mengunduh iTHUNG',
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.colorEspresso,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _statusMessage,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colorTaupe,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // Tactical Progress Bar Berpola Kayu
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.colorWoodPlank,
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  border: Border.all(
                    color: AppTheme.colorWoodBorder,
                    width: AppTokens.borderWidthSubtle,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final fillWidth =
                        constraints.maxWidth * _downloadProgress.clamp(0.0, 1.0);
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: fillWidth,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.colorHoney,
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusPill),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Detail Ukuran Byte
              Text(
                '$receivedMb MB / $totalMb MB',
                style: AppTheme.statNumberStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colorWoodDark,
                ),
              ),

              // Pesan Error jika Gagal / Terputus
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.colorDangerSoft,
                    borderRadius: BorderRadius.circular(AppTokens.radiusIcon),
                    border: Border.all(
                      color: AppTheme.colorCoral.withValues(alpha: 0.35),
                      width: AppTokens.borderWidthSubtle,
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.colorCoral,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 14),
                ChunkyButton(
                  key: const Key('btn_resume_download'),
                  onPressed: _isDownloading ? null : _startDownload,
                  backgroundColor: AppTheme.colorSage,
                  width: double.infinity,
                  child: const Text(
                    'Lanjutkan Unduhan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _openFallbackUrl,
                      icon: const Icon(Icons.open_in_browser,
                          size: 15, color: AppTheme.colorTaupe),
                      label: const Text(
                        'Buka di Browser',
                        style: TextStyle(
                          color: AppTheme.colorTaupe,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
                          color: AppTheme.colorTaupe,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
