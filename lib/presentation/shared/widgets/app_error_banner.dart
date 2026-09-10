import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Banner pesan kesalahan terpusat dengan gaya Cozy Neobrutalism.
///
/// Digunakan untuk menampilkan pesan kegagalan/error secara seragam,
/// jelas, dan ramah pengguna di seluruh dialog dan layar aplikasi.
class AppErrorBanner extends StatelessWidget {
  const AppErrorBanner({
    super.key,
    required this.message,
    this.icon = AppIcons.warning,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  });

  final String message;
  final IconData icon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.colorCoral.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        border: Border.all(
          color: AppTheme.colorCoral,
          width: AppTokens.borderWidthDefault,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.colorCoral,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.colorEspresso,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
