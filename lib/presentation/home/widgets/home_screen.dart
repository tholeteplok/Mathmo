import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../game/providers/level_band_theme_provider.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/chunky_button.dart';
import '../providers/level_stars_provider.dart';
import '../providers/player_profile_provider.dart';
import 'avatar_callout_pin.dart';
import 'level_node.dart';
import 'milestone_chest_node.dart';

/// Koordinat piksel tetap terkalibrasi pada kanvas 768 x 1376 px.
/// Menjamin node level duduk 100% tepat di tengah lekukan jalan setapak berbatu (cobblestone S-curve).
const List<Offset> kDefaultNodeAnchors = [
  Offset(265, 1020), // Level 1 (lekukan bawah)
  Offset(510, 848), // Level 2 (belokan kanan)
  Offset(270, 724), // Level 3 (belokan kiri tengah)
  Offset(475, 556), // Level 4 (belokan kanan atas)
  Offset(265, 450), // Level 5 (belokan kiri atas)
];

/// Koordinat piksel tetap terkalibrasi untuk Peti Harta Milestone di gerbang puncak stage.
const Offset kDefaultChestAnchor = Offset(380, 360);

/// Data konfigurasi satu stage zona (berisi 5 level per gambar kanvas).
class StageData {
  const StageData({
    required this.stageIndex,
    required this.startLevel,
    required this.endLevel,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.assetPath,
    required this.accentColor,
    this.nodeAnchors = kDefaultNodeAnchors,
    this.chestAnchor = kDefaultChestAnchor,
  });

  final int stageIndex;
  final int startLevel;
  final int endLevel;
  final String title;
  final String subtitle;
  final String icon;
  final String assetPath;
  final Color accentColor;
  final List<Offset> nodeAnchors;
  final Offset chestAnchor;
}

/// Daftar definisi stage petualangan mencakup seluruh 5 Level Band (Level 1 hingga 60+).
final List<StageData> kMathmoStages = [
  // Band 1: Onboarding (Level 1–5)
  const StageData(
    stageIndex: 0,
    startLevel: 1,
    endLevel: 5,
    title: 'Fresh Sprout Meadow',
    subtitle: 'Zona 1 • Level 1–5',
    icon: '🌱',
    assetPath: 'assets/images/meadow_canvas.jpg',
    accentColor: Color(0xFF639922),
  ),

  // Band 2: Basic (Level 6–15)
  const StageData(
    stageIndex: 1,
    startLevel: 6,
    endLevel: 10,
    title: 'Golden Sun Canyon',
    subtitle: 'Zona 2 • Level 6–10',
    icon: '🏜️',
    assetPath: 'assets/images/canyon_canvas.jpg',
    accentColor: Color(0xFFBA7517),
  ),
  const StageData(
    stageIndex: 2,
    startLevel: 11,
    endLevel: 15,
    title: 'Golden Sun Canyon',
    subtitle: 'Zona 2 • Level 11–15',
    icon: '🏜️',
    assetPath: 'assets/images/canyon_canvas.jpg',
    accentColor: Color(0xFFBA7517),
  ),

  // Band 3: Intermediate (Level 16–30)
  const StageData(
    stageIndex: 3,
    startLevel: 16,
    endLevel: 20,
    title: 'Coral Sunset Ridge',
    subtitle: 'Zona 3 • Level 16–20',
    icon: '🍂',
    assetPath: 'assets/images/ridge_canvas.jpg',
    accentColor: Color(0xFFD85A30),
  ),
  const StageData(
    stageIndex: 4,
    startLevel: 21,
    endLevel: 25,
    title: 'Coral Sunset Ridge',
    subtitle: 'Zona 3 • Level 21–25',
    icon: '🍂',
    assetPath: 'assets/images/ridge_canvas.jpg',
    accentColor: Color(0xFFD85A30),
  ),
  const StageData(
    stageIndex: 5,
    startLevel: 26,
    endLevel: 30,
    title: 'Coral Sunset Ridge',
    subtitle: 'Zona 3 • Level 26–30',
    icon: '🍂',
    assetPath: 'assets/images/ridge_canvas.jpg',
    accentColor: Color(0xFFD85A30),
  ),

  // Band 4: Advanced (Level 31–50)
  const StageData(
    stageIndex: 6,
    startLevel: 31,
    endLevel: 35,
    title: 'Twilight Forest',
    subtitle: 'Zona 4 • Level 31–35',
    icon: '✨',
    assetPath: 'assets/images/twilight_canvas.jpg',
    accentColor: Color(0xFFD4537E),
  ),
  const StageData(
    stageIndex: 7,
    startLevel: 36,
    endLevel: 40,
    title: 'Twilight Forest',
    subtitle: 'Zona 4 • Level 36–40',
    icon: '✨',
    assetPath: 'assets/images/twilight_canvas.jpg',
    accentColor: Color(0xFFD4537E),
  ),
  const StageData(
    stageIndex: 8,
    startLevel: 41,
    endLevel: 45,
    title: 'Twilight Forest',
    subtitle: 'Zona 4 • Level 41–45',
    icon: '✨',
    assetPath: 'assets/images/twilight_canvas.jpg',
    accentColor: Color(0xFFD4537E),
  ),
  const StageData(
    stageIndex: 9,
    startLevel: 46,
    endLevel: 50,
    title: 'Twilight Forest',
    subtitle: 'Zona 4 • Level 46–50',
    icon: '✨',
    assetPath: 'assets/images/twilight_canvas.jpg',
    accentColor: Color(0xFFD4537E),
  ),

  // Band 5: Expert (Level 51+)
  const StageData(
    stageIndex: 10,
    startLevel: 51,
    endLevel: 55,
    title: 'Cosmic Mystic Peak',
    subtitle: 'Zona 5 • Level 51–55',
    icon: '🌌',
    assetPath: 'assets/images/cosmic_canvas.jpg',
    accentColor: Color(0xFF7F77DD),
  ),
  const StageData(
    stageIndex: 11,
    startLevel: 56,
    endLevel: 60,
    title: 'Cosmic Mystic Peak',
    subtitle: 'Zona 5 • Level 56–60',
    icon: '🌌',
    assetPath: 'assets/images/cosmic_canvas.jpg',
    accentColor: Color(0xFF7F77DD),
  ),
];

/// Layar beranda (HomeScreen) berbasis Immersive Fullscreen Scenic Canvas Map.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PageController _pageController;
  int _currentStageIndex = 0;
  bool _initializedPage = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(playerProfileProvider);
    final themeAsync = ref.watch(levelBandThemeProvider);
    final starsAsync = ref.watch(levelStarsProvider);

    final currentLevel = profileAsync.valueOrNull?.currentLevel ?? 1;
    final currentStreak = profileAsync.valueOrNull?.streak.currentStreak ?? 0;
    final totalXp = profileAsync.valueOrNull?.totalXp ?? 0;
    final accentColor =
        themeAsync.valueOrNull?.accentColor ?? const Color(0xFF639922);
    final canvasColor =
        themeAsync.valueOrNull?.canvasColor ?? const Color(0xFFEAF3DE);
    final starsMap = starsAsync.valueOrNull ?? const {};

    // Fokus otomatis ke stage tempat level aktif pemain berada saat pertama kali load
    if (!_initializedPage && profileAsync.hasValue) {
      _initializedPage = true;
      final targetStage =
          ((currentLevel - 1) ~/ 5).clamp(0, kMathmoStages.length - 1);
      _currentStageIndex = targetStage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(targetStage);
        }
      });
    }

    final activeStage = kMathmoStages[_currentStageIndex];

    return AnimatedContainer(
      duration: AppTokens.canvasColorTransition,
      color: canvasColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 1. Scenic Canvas Background (Fullscreen 100% Edge-to-Edge)
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: kMathmoStages.length,
                onPageChanged: (page) {
                  setState(() => _currentStageIndex = page);
                },
                itemBuilder: (context, index) {
                  final stage = kMathmoStages[index];
                  return _StageCanvasView(
                    stage: stage,
                    currentLevel: currentLevel,
                    accentColor: accentColor,
                    starsMap: starsMap,
                  );
                },
              ),
            ),

            // 2. Floating Top Bar Overlay (Header + Stage Navigator Bar)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header: Avatar, Streak, XP
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: AppHeader(
                        streak: currentStreak,
                        xp: totalXp,
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.darkBorder,
                              width: AppTokens.borderWidthDefault,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppTheme.darkBorder,
                                offset: Offset(0, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'M',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.darkBorder,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Stage Navigator Bar (Neobrutalist)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusContainer,
                          ),
                          border: Border.all(
                            color: AppTheme.darkBorder,
                            width: AppTokens.borderWidthDefault,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.darkBorder,
                              offset: Offset(0, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Tombol Previous Stage
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.chevron_left, size: 28),
                              color: _currentStageIndex > 0
                                  ? AppTheme.darkBorder
                                  : Colors.grey.shade400,
                              onPressed: _currentStageIndex > 0
                                  ? () {
                                      _pageController.previousPage(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  : null,
                            ),
                            const SizedBox(width: 4),
                            // Teks Judul Stage
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        activeStage.icon,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          activeStage.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.darkBorder,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    activeStage.subtitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Tombol Next Stage
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.chevron_right, size: 28),
                              color: _currentStageIndex <
                                      kMathmoStages.length - 1
                                  ? AppTheme.darkBorder
                                  : Colors.grey.shade400,
                              onPressed: _currentStageIndex <
                                      kMathmoStages.length - 1
                                  ? () {
                                      _pageController.nextPage(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Floating Bottom Bar Overlay: Daily Challenge
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ChunkyButton(
                    onPressed: () => context.go('/daily'),
                    backgroundColor: const Color(0xFFBA7517), // Amber
                    borderColor: AppTheme.darkBorder,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          AppIcons.calendar,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Daily Challenge Hari Ini',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget yang merender 1 lembar kanvas pemandangan dengan koordinat piksel terpadu 768 x 1376 px.
class _StageCanvasView extends StatelessWidget {
  const _StageCanvasView({
    required this.stage,
    required this.currentLevel,
    required this.accentColor,
    required this.starsMap,
  });

  final StageData stage;
  final int currentLevel;
  final Color accentColor;
  final Map<int, int> starsMap;

  static const double canvasWidth = 768.0;
  static const double canvasHeight = 1376.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.center,
        child: SizedBox(
          width: canvasWidth,
          height: canvasHeight,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              // 1. Scenic Canvas Background Image (768 x 1376 px)
              Image.asset(
                stage.assetPath,
                width: canvasWidth,
                height: canvasHeight,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: stage.accentColor.withValues(alpha: 0.15),
                    child: Center(
                      child: Text(
                        stage.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),

              // 2. Dynamic Interactive Level Nodes Overlay at exact calibrated pixel positions
              for (var i = 0; i < 5; i++)
                _buildNodeItem(
                  context: context,
                  level: stage.startLevel + i,
                  pos: stage.nodeAnchors[i],
                ),

              // 3. Milestone Chest Node at summit destination
              Positioned(
                left: stage.chestAnchor.dx - 26,
                top: stage.chestAnchor.dy - 26,
                width: 52,
                height: 52,
                child: MilestoneChestNode(
                  level: stage.endLevel,
                  isUnlocked: stage.endLevel <= currentLevel,
                  accentColor: stage.accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNodeItem({
    required BuildContext context,
    required int level,
    required Offset pos,
  }) {
    final status = level < currentLevel
        ? LevelNodeStatus.completed
        : level == currentLevel
        ? LevelNodeStatus.active
        : LevelNodeStatus.locked;

    final starCount = starsMap[level] ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Level Node (Center positioned around pos)
        Positioned(
          left: pos.dx - 75,
          top: status == LevelNodeStatus.active
              ? pos.dy - 43
              : (status == LevelNodeStatus.completed
                  ? pos.dy - 29
                  : pos.dy - 27),
          width: 150,
          child: Align(
            alignment: Alignment.topCenter,
            child: LevelNode(
              level: level,
              status: status,
              accentColor: stage.accentColor,
              starCount: starCount,
              onTap: () {
                if (status != LevelNodeStatus.locked) {
                  context.go('/game/$level');
                }
              },
            ),
          ),
        ),

        // Avatar Callout Pin ("Mulai di Sini!") di atas active node
        if (status == LevelNodeStatus.active)
          Positioned(
            left: pos.dx - 100,
            top: pos.dy - 98,
            width: 200,
            child: Center(
              child: AvatarCalloutPin(
                accentColor: stage.accentColor,
                onTap: () => context.go('/game/$level'),
              ),
            ),
          ),
      ],
    );
  }
}

