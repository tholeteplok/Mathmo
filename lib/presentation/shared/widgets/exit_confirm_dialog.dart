import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'chunky_button.dart';
import 'chunky_card.dart';

/// Menampilkan dialog konfirmasi saat pemain ingin keluar dari sesi gameplay aktif.
///
/// Mengacu pada `math-speed-game-navigation-spec.md` §2:
/// Keluar tanpa konfirmasi dapat menyebabkan frustrasi kehilangan progres level berjalan.
Future<bool> showExitConfirmDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const ExitConfirmDialog(),
  );
  return result ?? false;
}

/// Widget dialog konfirmasi keluar dari sesi permainan.
class ExitConfirmDialog extends StatelessWidget {
  const ExitConfirmDialog({super.key});

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
            const Text(
              'Keluar dari Sesi?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkBorder,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Progres ronde pada level yang sedang berjalan ini tidak akan disimpan.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF556050),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // Tombol Keluar (Merah / Abu)
                Expanded(
                  child: ChunkyButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    backgroundColor: const Color(0xFFFAECE7),
                    borderColor: const Color(0xFFD85A30),
                    child: const Text(
                      'Keluar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD85A30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Tombol Lanjut Main (Hijau Aksen)
                Expanded(
                  child: ChunkyButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    backgroundColor: const Color(0xFF639922),
                    borderColor: AppTheme.darkBorder,
                    child: const Text(
                      'Lanjut',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
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
