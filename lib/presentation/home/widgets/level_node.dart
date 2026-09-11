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
    final haloColor = accentColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Cincin halo ambient dinamis bernapas lembut
            _PulsingHalo(
              color: haloColor,
              width: 88,
              height: 68,
            ),
            // Tactile Wood Token Play (Hero CTA)
            _TactileWoodToken(
              assetPath: AppAssets.woodTokenPlay,
              width: 76,
              height: 58,
              onTap: onTap,
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

/// Cincin halo ambient yang berdenyut lembut (pulsing) di belakang token aktif.
class _PulsingHalo extends StatefulWidget {
  const _PulsingHalo({
    required this.color,
    this.width = 88,
    this.height = 68,
  });

  final Color color;
  final double width;
  final double height;

  @override
  State<_PulsingHalo> createState() => _PulsingHaloState();
}

class _PulsingHaloState extends State<_PulsingHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.20, end: 0.50).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = _scaleAnimation.value;
          final opacity = _opacityAnimation.value;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.elliptical(widget.width / 2, widget.height / 2),
                ),
                border: Border.all(
                  color: widget.color.withValues(alpha: opacity),
                  width: 3.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: opacity * 0.45),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
