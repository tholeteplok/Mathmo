import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Status visual sebuah node level pada peta progres.
enum LevelNodeStatus { completed, active, locked }

/// Node individual pada peta jalur level di HomeScreen.
///
/// Menggunakan desain 3D Tactile Stepping Stone / Wooden Disc:
/// - Memiliki silinder kedalaman 3D fisik (extruded base lip).
/// - Memberikan animasi spring elastic bounce saat ditekan (cap turun ke alas silinder).
/// - 100% konsisten dengan tema Cozy Woodwork tanpa keterbatasan sudut NeoPOP.
class LevelNode extends StatelessWidget {
  const LevelNode({
    super.key,
    required this.level,
    required this.status,
    required this.onTap,
    this.accentColor = const Color(0xFF639922),
    this.starCount = 0,
  });

  final int level;
  final LevelNodeStatus status;
  final VoidCallback onTap;
  final Color accentColor;
  final int starCount;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      LevelNodeStatus.completed => _buildCompletedNode(),
      LevelNodeStatus.active => _buildActiveNode(context),
      LevelNodeStatus.locked => _buildLockedNode(),
    };
  }

  Widget _buildCompletedNode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TactileWoodToken(
          assetPath: AppAssets.woodTokenChecked,
          width: 62,
          height: 48,
          onTap: onTap,
        ),
        if (starCount > 0) ...[
          const SizedBox(height: 5),
          _buildStarsRow(starCount),
        ],
      ],
    );
  }

  Widget _buildStarsRow(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.colorVanillaCard,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(
          color: const Color(0xFFDECFA8),
          width: AppTokens.borderWidthSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.colorWoodDark.withValues(alpha: 0.12),
            offset: const Offset(0, 1.5),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          final isEarned = index < count;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Icon(
              isEarned ? AppIcons.starFilled : AppIcons.starEmpty,
              size: 11,
              color: isEarned ? AppTheme.colorHoney : const Color(0xFFC7BBA5),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveNode(BuildContext context) {
    final hsl = HSLColor.fromColor(accentColor);
    final baseColor = hsl
        .withLightness((hsl.lightness - 0.20).clamp(0.0, 1.0))
        .toColor();
    final borderColor = hsl
        .withLightness((hsl.lightness - 0.28).clamp(0.0, 1.0))
        .toColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Cincin halo ambient dinamis
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.35),
                  width: 3.5,
                ),
              ),
            ),
            // Tombol 3D Stepping Disc
            _SteppingDiscButton(
              onTap: onTap,
              diameter: 76,
              depth: 7,
              capColor: accentColor,
              baseColor: baseColor,
              borderColor: borderColor,
              child: const Icon(
                AppIcons.levelActive,
                color: Colors.white,
                size: 38,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.colorWoodPlank,
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            border: Border.all(
              color: AppTheme.colorWoodBorder,
              width: AppTokens.borderWidthSubtle,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.colorWoodDark.withValues(alpha: 0.15),
                offset: const Offset(0, 1.5),
                blurRadius: 2,
              ),
            ],
          ),
          child: Text(
            'Level $level',
            style: AppTheme.statNumberStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.colorWoodDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedNode() {
    return const _TactileWoodToken(
      assetPath: AppAssets.woodTokenLocked,
      width: 56,
      height: 43,
      onTap: null,
    );
  }
}

/// Widget interaktif untuk token kayu isometrik alami (completed / locked) dengan respons taktil halus.
class _TactileWoodToken extends StatefulWidget {
  const _TactileWoodToken({
    required this.assetPath,
    required this.width,
    required this.height,
    this.onTap,
  });

  final String assetPath;
  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  State<_TactileWoodToken> createState() => _TactileWoodTokenState();
}

class _TactileWoodTokenState extends State<_TactileWoodToken> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    HapticFeedback.selectionClick();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOutQuad,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Image.asset(
            widget.assetPath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// Komponen tombol 3D stepping disc silinder fisik dengan animasi pegas empuk.
class _SteppingDiscButton extends StatefulWidget {
  const _SteppingDiscButton({
    required this.onTap,
    required this.diameter,
    required this.depth,
    required this.capColor,
    required this.baseColor,
    required this.borderColor,
    required this.child,
  });

  final VoidCallback? onTap;
  final double diameter;
  final double depth;
  final Color capColor;
  final Color baseColor;
  final Color borderColor;
  final Widget child;

  @override
  State<_SteppingDiscButton> createState() => _SteppingDiscButtonState();
}

class _SteppingDiscButtonState extends State<_SteppingDiscButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    HapticFeedback.selectionClick();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isPressed = _isPressed;
    final totalHeight = widget.diameter + widget.depth;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: SizedBox(
        width: widget.diameter,
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Alas Silinder 3D (Extruded Base Lip) + Ambient Shadow
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: widget.diameter,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.baseColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.borderColor,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.colorWoodDark.withValues(alpha: 0.20),
                      offset: const Offset(0, 4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),

            // 2. Permukaan Cap (Moving Top Face)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 70),
              curve: Curves.easeOutQuad,
              top: isPressed ? widget.depth : 0.0,
              left: 0,
              right: 0,
              height: widget.diameter,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.capColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.borderColor,
                    width: 2.0,
                  ),
                  gradient: RadialGradient(
                    center: const Alignment(-0.2, -0.4),
                    radius: 0.85,
                    colors: [
                      Colors.white.withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(child: widget.child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
