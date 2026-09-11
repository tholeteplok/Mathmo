import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/sfx_service.dart';
import '../../../core/theme/app_icons.dart';
import '../../settings/providers/settings_provider.dart';

/// Widget animasi bintang untuk [ResultsScreen].
///
/// Menampilkan 3 slot bintang dengan bintang tengah yang lebih besar dan terangkat (podium aesthetic).
/// Bintang yang berhasil didapat akan muncul secara sekuensial (staggered) dengan animasi
/// membal ([Curves.elasticOut]) dan umpan balik suara per bintang.
class AnimatedStarRating extends ConsumerStatefulWidget {
  const AnimatedStarRating({
    super.key,
    required this.starCount,
    this.playSfx = true,
  });

  /// Jumlah bintang yang diperoleh (0..3).
  final int starCount;

  /// Apakah memutar SFX saat bintang muncul.
  final bool playSfx;

  @override
  ConsumerState<AnimatedStarRating> createState() => _AnimatedStarRatingState();
}

class _AnimatedStarRatingState extends ConsumerState<AnimatedStarRating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _starAnimations;
  final Set<int> _playedSfxIndices = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Staggered intervals per bintang
    const intervals = [
      Interval(0.08, 0.45, curve: Curves.elasticOut),
      Interval(0.35, 0.72, curve: Curves.elasticOut),
      Interval(0.62, 0.99, curve: Curves.elasticOut),
    ];

    _starAnimations = List.generate(3, (i) {
      final anim = CurvedAnimation(parent: _controller, curve: intervals[i]);
      anim.addListener(() {
        if (widget.playSfx &&
            i < widget.starCount &&
            anim.value >= 0.3 &&
            !_playedSfxIndices.contains(i)) {
          _playedSfxIndices.add(i);
          ref.read(sfxServiceProvider).play(SfxType.correct);
        }
      });
      return anim;
    });

    if (widget.starCount > 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildStarItem(index: 0, baseSize: 44, offsetY: 0),
          const SizedBox(width: 14),
          _buildStarItem(index: 1, baseSize: 56, offsetY: -8),
          const SizedBox(width: 14),
          _buildStarItem(index: 2, baseSize: 44, offsetY: 0),
        ],
      ),
    );
  }

  Widget _buildStarItem({
    required int index,
    required double baseSize,
    required double offsetY,
  }) {
    final isEarned = index < widget.starCount;

    return Transform.translate(
      offset: Offset(0, offsetY),
      child: SizedBox(
        width: baseSize,
        height: baseSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Slot bintang kosong di latar belakang
            Icon(
              AppIcons.starEmpty,
              size: baseSize,
              color: const Color(0xFFD5C4A1).withValues(alpha: 0.6),
            ),

            // Bintang emas terisi yang muncul dengan animasi scale bounce
            if (isEarned)
              AnimatedBuilder(
                animation: _starAnimations[index],
                builder: (context, child) {
                  final scale = _starAnimations[index].value.clamp(0.0, 1.25);
                  if (scale <= 0.01) return const SizedBox.shrink();
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x3DF59E0B),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    AppIcons.starFilled,
                    size: baseSize,
                    color: const Color(0xFFF59E0B), // Golden Honey
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
