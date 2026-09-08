import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Kartu bergaya "chunky playful" dengan border tegas dan solid offset shadow (tanpa blur).
///
/// Komponen ini tersentralisasi untuk semua kartu soal, kartu skor, dan kontainer dialog
/// di aplikasi Mathmo, memastikan konsistensi visual penuh antar layar tanpa hardcoding.
class ChunkyCard extends StatelessWidget {
  const ChunkyCard({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.borderColor = AppTheme.darkBorder,
    this.borderRadius = AppTokens.radiusCard,
    this.borderWidth = AppTokens.borderWidthDefault,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.rotation = 0.0,
    this.width,
    this.height,
  });

  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  /// Rotasi sudut elemen dalam radian (mis. [AppTokens.rotationSubtleNegative]).
  final double rotation;

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: ChunkyShadow.container(borderColor),
      ),
      child: child,
    );

    if (rotation != 0.0) {
      card = Transform.rotate(angle: rotation, child: card);
    }

    return card;
  }
}
