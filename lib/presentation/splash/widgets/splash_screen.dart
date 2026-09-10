import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Layar pembuka (SplashScreen) iTHUNG.
///
/// Menampilkan:
/// - Judul aplikasi "iTHUNG" ber-font kustom [Baberry] dengan efek 3D Neobrutalism (stroke & solid shadow)
/// - Tagline resmi "Fast Math. Sharp Mind." dalam pill badge Neobrutalism
/// - Animasi pop-in elastis dan progress bar pemuatan
/// - Transisi otomatis menuju rute utama ('/')
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Animasi pop-in elastis untuk logo dan judul "iTHUNG"
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );

    // Animasi fade-in untuk tagline dan progress bar
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.70, curve: Curves.easeIn),
    );

    // Animasi progress bar pengisian dari 0% ke 100%
    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.95, curve: Curves.easeInOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted && GoRouter.maybeOf(context) != null) {
          context.go('/');
        }
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorSandyCanvas,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // 1. Hero Logo & Title "iTHUNG" (Baberry Font)
              ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge Ikon Maskot iTHUNG
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.colorVanillaCard,
                        borderRadius: BorderRadius.circular(AppTokens.radiusButton),
                        border: Border.all(
                          color: AppTheme.colorCardBorder,
                          width: AppTokens.borderWidthDefault,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppTheme.colorWoodDark.withValues(alpha: 0.15),
                            offset: const Offset(0, 4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTokens.radiusButton),
                        child: Image.asset(
                          'assets/icon/app_launcher.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Teks Judul "iTHUNG" dengan Stroke Outline & Warm 3D Shadow
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Bayangan Solid Bawah Kayu/Espresso (Offset 0, 5)
                        Transform.translate(
                          offset: const Offset(0, 5),
                          child: Text(
                            'iTHUNG',
                            style: AppTheme.brandTitleStyle(
                              fontSize: 66,
                              color: AppTheme.colorWoodDark,
                            ),
                          ),
                        ),
                        // Stroke Outline Gelap
                        Text(
                          'iTHUNG',
                          style: TextStyle(
                            fontFamily: 'Baberry',
                            fontSize: 66,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 6.5
                              ..color = AppTheme.colorWoodDark,
                          ),
                        ),
                        // Fill Warna Warm Honey Gold
                        Text(
                          'iTHUNG',
                          style: AppTheme.brandTitleStyle(
                            fontSize: 66,
                            color: AppTheme.colorHoney,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 2. Tagline Resmi "Fast Math. Sharp Mind." dalam Pill Cozy
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.colorVanillaCard,
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    border: Border.all(
                      color: AppTheme.colorCardBorder,
                      width: AppTokens.borderWidthDefault,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.colorWoodDark.withValues(alpha: 0.10),
                        offset: const Offset(0, 3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    'Fast Math. Sharp Mind.',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: AppTheme.colorWoodMedium,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // 3. Mini Cozy Progress Bar
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 170,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppTheme.colorVanillaCard,
                            borderRadius: BorderRadius.circular(AppTokens.radiusBar),
                            border: Border.all(
                              color: AppTheme.colorCardBorder,
                              width: AppTokens.borderWidthSubtle,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.colorWoodDark
                                    .withValues(alpha: 0.10),
                                offset: const Offset(0, 2),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor:
                                  _progressAnimation.value.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.colorHoney,
                                  borderRadius: BorderRadius.circular(AppTokens.radiusMini),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Preparing your adventure...',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.colorTaupe,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
