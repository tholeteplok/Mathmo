import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import 'chunky_button.dart';
import 'chunky_card.dart';

/// Menampilkan dialog konfirmasi saat pemain ingin keluar dari sesi gameplay aktif atau aplikasi.
///
/// Mengacu pada prinsip Neobrutalisme dan psikologi UI:
/// - Mencegah kehilangan progres ronde/level yang tidak disengaja.
/// - Menggunakan tombol berikon 'X' merah untuk batal dan check mark hijau untuk konfirmasi keluar.
Future<bool> showExitConfirmDialog(
  BuildContext context, {
  String title = 'Keluar dari Sesi?',
  String message =
      'Progres ronde pada level yang sedang berjalan ini tidak akan disimpan.',
  String confirmLabel = 'Keluar',
  String cancelLabel = 'Batal',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ExitConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
  return result ?? false;
}

/// Widget dialog konfirmasi keluar bergaya Neobrutalism terpusat.
class ExitConfirmDialog extends StatelessWidget {
  const ExitConfirmDialog({
    super.key,
    this.title = 'Keluar dari Sesi?',
    this.message =
        'Progres ronde pada level yang sedang berjalan ini tidak akan disimpan.',
    this.confirmLabel = 'Keluar',
    this.cancelLabel = 'Batal',
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ChunkyCard(
        backgroundColor: const Color(0xFFFAFDF5),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Judul Dialog
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkBorder,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Pesan Penjelasan
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF556050),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Baris Tombol Aksi: 'X' Merah (Batal) & Check Mark Hijau (Keluar)
            Row(
              children: [
                // Tombol Batal: Icon 'X' Merah
                Expanded(
                  child: ChunkyButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    backgroundColor: const Color(0xFFFFF0F0),
                    borderColor: AppTheme.darkBorder,
                    borderWidth: AppTokens.borderWidthDefault,
                    borderRadius: AppTokens.radiusButton,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.close_rounded,
                          color: Color(0xFFD32F2F), // Merah tegas
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cancelLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tombol Konfirmasi: Icon Check Mark Hijau
                Expanded(
                  child: ChunkyButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    backgroundColor: const Color(0xFFF0FDF4),
                    borderColor: AppTheme.darkBorder,
                    borderWidth: AppTokens.borderWidthDefault,
                    borderRadius: AppTokens.radiusButton,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF2E7D32), // Hijau tegas
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          confirmLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
