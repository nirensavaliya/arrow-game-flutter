
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/game_controller.dart';
import '../../modes/game_mode.dart';
import '../../modes/game_mode_config.dart';
import '../../storage/game_storage.dart';
import '../../storage/settings_storage.dart';
import '../../services/vibration_service.dart';
import '../level/level_design.dart';
import '../level/level_screen.dart';
import '../settings/settings_screen.dart';

class GameIntroScreen extends StatefulWidget {
  const GameIntroScreen({super.key});

  @override
  State<GameIntroScreen> createState() => _GameIntroScreenState();
}

class _GameIntroScreenState extends State<GameIntroScreen>
    with TickerProviderStateMixin {
  static const Color _darkBg = Color(0xFF07080F);
  static const Color _darkSurface = Color(0xFF12141F);
  static const Color _darkTextPrimary = Color(0xFFF7F7FC);
  static const Color _darkTextSecondary = Color(0xFF8E92AB);

  static const Color _lightBg = Color(0xFFF4F5FA);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightTextPrimary = Color(0xFF14162A);
  static const Color _lightTextSecondary = Color(0xFF6F7390);

  static const Color _gold = Color(0xFFFFC857);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bg => _isDark ? _darkBg : _lightBg;
  Color get _surface => _isDark ? _darkSurface : _lightSurface;
  Color get _textPrimary => _isDark ? _darkTextPrimary : _lightTextPrimary;
  Color get _textSecondary =>
      _isDark ? _darkTextSecondary : _lightTextSecondary;
  Color get _hairline => _isDark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.black.withValues(alpha: 0.07);

  int _coinCount = GameStorage.totalCoins();
  int _selectedMode = 0;

  late final AnimationController _intro;
  late final AnimationController _ambient;
  late final PageController _pageController;

  final List<_GameMode> _modes = [
    _GameMode(
      title: 'Normal Mode',
      tagline: 'PLAY YOUR WAY',
      subtitle: 'Take your time, read the maze and find the perfect path.',
      detail: '${GameModeConfig.forMode(GameMode.normal).startingLives} lives',
      detailIcon: Icons.favorite_rounded,
      icon: Icons.explore_rounded,
      color: const Color(0xFF8175FF),
      colorDeep: const Color(0xFF4B3FD1),
      features: const [
        'No timer',
        'Lives system',
        'Relaxed pace',
      ],
      cta: 'Start playing',
      ctaIcon: Icons.play_arrow_rounded,
    ),
    _GameMode(
      title: 'Timed Challenge',
      tagline: 'RACE THE CLOCK',
      subtitle:
      'Every level is a race against time. Plan quickly and stay sharp.',
      detail: 'Time limit per level',
      detailIcon: Icons.hourglass_bottom_rounded,
      icon: Icons.timer_rounded,
      color: const Color(0xFFFFB34F),
      colorDeep: const Color(0xFFD9681C),
      features: const [
        'Countdown',
        'Quick decisions',
        'Beat the clock',
      ],
      cta: 'Start challenge',
      ctaIcon: Icons.timer_rounded,
    ),
    _GameMode(
      title: 'Speed Run',
      tagline: 'GO ALL IN',
      subtitle:
      'Clear as many puzzles as possible before your session ends.',
      detail:
      '${GameModeConfig.forMode(GameMode.speedRun).sessionDurationSeconds} seconds',
      detailIcon: Icons.bolt_rounded,
      icon: Icons.bolt_rounded,
      color: const Color(0xFF35D68A),
      colorDeep: const Color(0xFF0C7F52),
      features: const [
        'One session',
        'Endless puzzles',
        'Beat your record',
      ],
      cta: 'Start speed run',
      ctaIcon: Icons.bolt_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _loadDefaultMode();

    _pageController = PageController(
      initialPage: _selectedMode,
      viewportFraction: 0.86,
    );

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();

    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _loadDefaultMode() {
    final savedMode = SettingsStorage.getDefaultGameMode();

    switch (savedMode) {
      case 'Timed Challenge':
        _selectedMode = 1;
        break;
      case 'Speed Run':
        _selectedMode = 2;
        break;
      default:
        _selectedMode = 0;
    }
  }

  GameMode _gameModeAt(int index) {
    switch (index) {
      case 1:
        return GameMode.timedChallenge;
      case 2:
        return GameMode.speedRun;
      default:
        return GameMode.normal;
    }
  }

  GameMode get _selectedGameMode => _gameModeAt(_selectedMode);

  // --------------------------------------------------
  // LEVEL PROGRESS (per mode)
  // --------------------------------------------------

  _ModeProgress _progressFor(GameMode mode) {
    final int totalLevels = LevelDesigns.totalLevels;

    final saved = GameStorage.loadProgress(mode.name);
    final int cleared =
    ((saved?['levelsCompleted'] as num?)?.toInt() ?? 0)
        .clamp(0, totalLevels)
        .toInt();

    final int current =
    GameStorage.unlockedLevel(mode.name).clamp(1, totalLevels).toInt();

    return _ModeProgress(
      currentLevel: current,
      clearedLevels: cleared,
      totalLevels: totalLevels,
    );
  }

  Future<void> _startGame() async {
    VibrationService.tap();

    final mode = _selectedGameMode;

    final controller = Get.isRegistered<GameController>()
        ? Get.find<GameController>()
        : Get.put(GameController());

    controller.startMode(mode);

    await Get.to(
          () => const LevelScreen(),
      arguments: {'mode': mode.name},
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 350),
    );

    if (!mounted) return;

    setState(() {
      _coinCount = GameStorage.totalCoins();
    });
  }

  void _selectMode(int index) {
    if (index == _selectedMode) return;

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    } else {
      VibrationService.tap();
      setState(() {
        _selectedMode = index;
      });
    }
  }

  void _onPageChanged(int index) {
    if (index == _selectedMode) return;

    VibrationService.tap();

    setState(() {
      _selectedMode = index;
    });
  }

  Future<void> _openSettings() async {
    VibrationService.tap();

    await Get.to(() => const SettingsScreen());

    if (!mounted) return;

    final savedMode = SettingsStorage.getDefaultGameMode();

    final int newIndex;

    switch (savedMode) {
      case 'Timed Challenge':
        newIndex = 1;
        break;
      case 'Speed Run':
        newIndex = 2;
        break;
      default:
        newIndex = 0;
    }

    if (newIndex != _selectedMode) {
      setState(() {
        _selectedMode = newIndex;
      });

      if (_pageController.hasClients) {
        _pageController.jumpToPage(newIndex);
      }
    }
  }

  // --------------------------------------------------
  // REFINED SCREEN REVEAL ANIMATION
  // --------------------------------------------------

  Widget _reveal(double start, Widget child) {
    final animation = CurvedAnimation(
      parent: _intro,
      curve: Interval(
        start,
        math.min(1.0, start + 0.48),
        curve: Curves.easeOutQuart,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final value = animation.value;

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: Transform.scale(
              scale: 0.985 + (0.015 * value),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = _modes[_selectedMode];

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground(mode)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                  child: _reveal(0.0, _buildTopBar(mode)),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final carouselHeight =
                      (constraints.maxHeight * 0.78).clamp(340.0, 468.0);

                      return SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 12, bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                              child: _reveal(0.06, _buildHeading()),
                            ),
                            const SizedBox(height: 18),
                            _reveal(
                              0.16,
                              _buildCarousel(height: carouselHeight),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                _reveal(0.42, _buildBottomBar(mode)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // BACKGROUND
  // --------------------------------------------------

  Widget _buildBackground(_GameMode mode) {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, _) {
        final drift = math.sin(_ambient.value * math.pi) * 16;

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _MazePainter(
                  color: (_isDark ? Colors.white : Colors.black)
                      .withValues(alpha: _isDark ? 0.03 : 0.035),
                ),
              ),
            ),
            Positioned(
              top: -150 + drift,
              right: -120,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      mode.color.withValues(alpha: _isDark ? 0.28 : 0.16),
                      mode.color.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -140 - drift,
              left: -150,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      mode.colorDeep.withValues(alpha: _isDark ? 0.20 : 0.11),
                      mode.colorDeep.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------
  // TOP BAR
  // --------------------------------------------------

  Widget _buildTopBar(_GameMode mode) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [mode.color, mode.colorDeep],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: mode.color.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.route_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Arrow Escape',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  letterSpacing: -0.6,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Think • Trace • Escape',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 11,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _buildCoinPill(),
        const SizedBox(width: 9),
        _glassIconButton(
          icon: Icons.settings_rounded,
          onTap: _openSettings,
        ),
      ],
    );
  }

  Widget _buildCoinPill() {
    return Container(
      height: 40,
      padding: const EdgeInsets.fromLTRB(5, 0, 13, 0),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: _isDark ? 0.75 : 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFE9A0),
                  Color(0xFFFFB52E),
                  Color(0xFFE07F0E),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFF7A3F00),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$_coinCount',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 14,
              letterSpacing: -0.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _surface.withValues(alpha: _isDark ? 0.75 : 0.95),
      shape: CircleBorder(side: BorderSide(color: _hairline)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: _textPrimary),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // HEADING
  // --------------------------------------------------

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How do you want\nto play today?',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 30,
            height: 1.07,
            letterSpacing: -1.3,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Swipe to explore modes. Progress is saved separately.',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // CAROUSEL
  // --------------------------------------------------

  Widget _buildCarousel({required double height}) {
    return SizedBox(
      height: height,
      child: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        itemCount: _modes.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double page = _selectedMode.toDouble();

              if (_pageController.position.haveDimensions) {
                page = _pageController.page ?? page;
              }

              final distance = (page - index).abs().clamp(0.0, 1.0);

              final curvedDistance =
              Curves.easeOutCubic.transform(distance);

              final scale = 1 - (curvedDistance * 0.055);
              final opacity = 1 - (curvedDistance * 0.42);
              final verticalOffset = curvedDistance * 5;

              return Center(
                child: Transform.translate(
                  offset: Offset(0, verticalOffset),
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: child,
                    ),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 6,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _buildModeCard(_modes[index], index),
                  ),
                  _buildConnector(_modes[index]),
                  _buildProgressCard(_modes[index], index),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnector(_GameMode mode) {
    return SizedBox(
      height: 20,
      child: Center(
        child: Container(
          width: 3,
          height: 19,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                mode.colorDeep.withValues(alpha: 0.9),
                mode.color.withValues(alpha: 0.35),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(_GameMode mode, int index) {
    final selected = index == _selectedMode;

    return GestureDetector(
      onTap: () => _selectMode(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [mode.color, mode.colorDeep],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: selected ? 0.50 : 0.16),
            width: selected ? 0.5 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: mode.color.withValues(
                alpha: selected ? (_isDark ? 0.42 : 0.34) : 0.10,
              ),
              blurRadius: selected ? 32 : 14,
              spreadRadius: selected ? -6 : -2,
              offset: Offset(0, selected ? 16 : 6),
            ),
            BoxShadow(
              color: mode.colorDeep.withValues(alpha: selected ? 0.35 : 0.12),
              blurRadius: selected ? 12 : 6,
              offset: Offset(0, selected ? 6 : 3),
            ),
            BoxShadow(
              color: Colors.black.withValues(
                alpha: _isDark
                    ? (selected ? 0.35 : 0.20)
                    : (selected ? 0.08 : 0.04),
              ),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(29),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _MazePainter(
                    color: Colors.white.withValues(alpha: 0.09),
                    cell: 28,
                    seed: index + 4,
                  ),
                ),
              ),
              Positioned(
                right: -30,
                bottom: 30,
                child: Icon(
                  mode.icon,
                  size: 190,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 110,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 130,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: 0.22),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.32),
                            ),
                          ),
                          child: Icon(mode.icon, color: Colors.white, size: 27),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            mode.tagline,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      mode.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.05,
                        letterSpacing: -1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mode.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13,
                        height: 1.42,
                      ),
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final feature in mode.features)
                          _featureChip(feature),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 9, 9, 9),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(mode.detailIcon, size: 18, color: Colors.white),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              mode.detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                letterSpacing: -0.1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  selected
                                      ? Icons.check_rounded
                                      : Icons.swipe_rounded,
                                  size: 13,
                                  color:
                                  selected ? mode.colorDeep : Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  selected ? 'Selected' : 'Select',
                                  style: TextStyle(
                                    color: selected
                                        ? mode.colorDeep
                                        : Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.26),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // PROGRESS CARD
  // --------------------------------------------------

  Widget _buildProgressCard(_GameMode mode, int index) {
    final progress = _progressFor(_gameModeAt(index));
    final percent = progress.totalLevels == 0
        ? 0.0
        : (progress.clearedLevels / progress.totalLevels).clamp(0.0, 1.0);
    final left = math.max(0, progress.totalLevels - progress.clearedLevels);

    return Container(
      height: 110,
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Color.lerp(_surface, mode.color, _isDark ? 0.10 : 0.05),
        border: Border.all(
          color: mode.color.withValues(alpha: _isDark ? 0.40 : 0.30),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: mode.color.withValues(alpha: _isDark ? 0.10 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: percent),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return SizedBox(
                width: 64,
                height: 64,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: value,
                    color: mode.color,
                    colorDeep: mode.colorDeep,
                    track: _isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.07),
                    stroke: 6.5,
                  ),
                  child: Center(
                    child: Text(
                      '${(value * 100).round()}%',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 13,
                        letterSpacing: -0.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      'Level progress',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: mode.color.withValues(
                          alpha: _isDark ? 0.18 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Level ${progress.currentLevel}',
                        style: TextStyle(
                          color: mode.color,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${progress.clearedLevels} of ${progress.totalLevels} cleared',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    letterSpacing: -0.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: percent),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          Container(
                            height: 6,
                            color: _isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.07),
                          ),
                          FractionallySizedBox(
                            widthFactor: value,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [mode.color, mode.colorDeep],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 5),
                Text(
                  left == 0
                      ? 'All levels cleared'
                      : left == 1
                      ? '1 level to go'
                      : '$left levels to go',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // BOTTOM START BUTTON
  // --------------------------------------------------

  Widget _buildBottomBar(_GameMode mode) {
    final progress = _progressFor(_selectedGameMode);

    final bool hasPlayed =
        progress.clearedLevels > 0 || progress.currentLevel > 1;

    final String buttonLabel = hasPlayed
        ? 'Continue Level ${progress.currentLevel}'
        : mode.cta;

    final IconData buttonIcon =
    hasPlayed ? Icons.play_circle_outline_rounded : mode.ctaIcon;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
      decoration: BoxDecoration(
        color: _bg.withValues(alpha: _isDark ? 0.97 : 0.98),
        border: Border(
          top: BorderSide(color: _hairline),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 58,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [mode.color, mode.colorDeep],
              ),
              boxShadow: [
                BoxShadow(
                  color: mode.color.withValues(
                    alpha: _isDark ? 0.35 : 0.25,
                  ),
                  blurRadius: 22,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.12),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Row(
                  key: ValueKey('$_selectedMode-$buttonLabel'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(buttonIcon, size: 22),
                    const SizedBox(width: 7),
                    Text(
                      buttonLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16.5,
                        letterSpacing: -0.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// MAZE TEXTURE PAINTER
// --------------------------------------------------

class _MazePainter extends CustomPainter {
  final Color color;
  final double cell;
  final int seed;

  const _MazePainter({
    required this.color,
    this.cell = 36,
    this.seed = 11,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final rnd = math.Random(seed);

    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        if (rnd.nextBool()) {
          canvas.drawLine(Offset(x, y), Offset(x + cell, y), paint);
        } else {
          canvas.drawLine(Offset(x, y), Offset(x, y + cell), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MazePainter old) =>
      old.color != color || old.cell != cell || old.seed != seed;
}

// --------------------------------------------------
// PROGRESS RING PAINTER
// --------------------------------------------------

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color colorDeep;
  final Color track;
  final double stroke;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.colorDeep,
    required this.track,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [colorDeep, color, colorDeep],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
          old.color != color ||
          old.colorDeep != colorDeep ||
          old.track != track ||
          old.stroke != stroke;
}

// --------------------------------------------------
// PROGRESS MODEL
// --------------------------------------------------

class _ModeProgress {
  final int currentLevel;
  final int clearedLevels;
  final int totalLevels;

  const _ModeProgress({
    required this.currentLevel,
    required this.clearedLevels,
    required this.totalLevels,
  });
}

// --------------------------------------------------
// GAME MODE MODEL
// --------------------------------------------------

class _GameMode {
  final String title;
  final String tagline;
  final String subtitle;
  final String detail;
  final IconData detailIcon;
  final IconData icon;
  final Color color;
  final Color colorDeep;
  final List<String> features;
  final String cta;
  final IconData ctaIcon;

  const _GameMode({
    required this.title,
    required this.tagline,
    required this.subtitle,
    required this.detail,
    required this.detailIcon,
    required this.icon,
    required this.color,
    required this.colorDeep,
    required this.features,
    required this.cta,
    required this.ctaIcon,
  });
}
