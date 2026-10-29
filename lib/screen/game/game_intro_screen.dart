import 'dart:math' as math;

import 'package:arrow/screen/game/store/game_store_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/game_controller.dart';
import '../../modes/game_mode.dart';
import '../../modes/game_mode_config.dart';
import '../../services/game_storage.dart';
import '../../services/settings_storage.dart';
import '../../services/vibration_service.dart';
import '../level/level_screen.dart';
import '../settings/settings_screen.dart';

class GameIntroScreen extends StatefulWidget {
  const GameIntroScreen({super.key});

  @override
  State<GameIntroScreen> createState() => _GameIntroScreenState();
}

class _GameIntroScreenState extends State<GameIntroScreen>
    with TickerProviderStateMixin {
  // Dark theme palette
  static const Color _darkBg = Color(0xFF0A0B14);
  static const Color _darkSurface = Color(0xFF14162A);
  static const Color _darkTextPrimary = Color(0xFFF5F5FF);
  static const Color _darkTextSecondary = Color(0xFF9B9DB8);

  // Light theme palette
  static const Color _lightBg = Color(0xFFF6F7FC);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightTextPrimary = Color(0xFF17182B);
  static const Color _lightTextSecondary = Color(0xFF6F7289);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bg => _isDark ? _darkBg : _lightBg;

  Color get _surface => _isDark ? _darkSurface : _lightSurface;

  Color get _textPrimary => _isDark ? _darkTextPrimary : _lightTextPrimary;

  Color get _textSecondary =>
      _isDark ? _darkTextSecondary : _lightTextSecondary;

  // Total coins from all modes
  int _coinCount = GameStorage.totalCoins();

  // 0 = Normal, 1 = Timed Challenge, 2 = Speed Run
  int _selectedMode = 0;

  late final AnimationController _intro;
  late final AnimationController _ambient;
  late final PageController _pageController;



  final List<_GameMode> _modes = [
    _GameMode(
      title: 'Normal Mode',
      tagline: 'RELAXED',
      subtitle: 'Solve at your own pace. No clock, just you and the maze.',
      detail: '${GameModeConfig.forMode(GameMode.normal).startingLives} lives',
      detailIcon: Icons.favorite_rounded,
      icon: Icons.self_improvement_rounded,
      color: const Color(0xFF7B72FF),
      colorDeep: const Color(0xFF4B3FE0),
      features: const ['No timer', 'Lives system', 'Calm pace'],
      cta: 'Start playing',
      ctaIcon: Icons.play_arrow_rounded,
    ),
    _GameMode(
      title: 'Timed Challenge',
      tagline: 'INTENSE',
      subtitle: 'Every level has a deadline. Think fast, move faster.',
      detail: 'Time limit',
      detailIcon: Icons.hourglass_bottom_rounded,
      icon: Icons.timer_rounded,
      color: const Color(0xFFFFB347),
      colorDeep: const Color(0xFFE0701A),
      features: const ['Level countdown', 'High pressure', 'Beat the clock'],
      cta: 'Start challenge',
      ctaIcon: Icons.timer_rounded,
    ),
    _GameMode(
      title: 'Speed Run',
      tagline: 'EXTREME',
      subtitle: 'Clear as many puzzles as you can before time runs out.',
      detail:
          '${GameModeConfig.forMode(GameMode.speedRun).sessionDurationSeconds} seconds',
      detailIcon: Icons.speed_rounded,
      icon: Icons.bolt_rounded,
      color: const Color(0xFF2ED573),
      colorDeep: const Color(0xFF0E8A3E),
      features: const ['One session', 'Endless puzzles', 'Chase your best'],
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
      viewportFraction: 0.82,
    );

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Load the saved default game mode.
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

  GameMode get _selectedGameMode {
    switch (_selectedMode) {
      case 1:
        return GameMode.timedChallenge;
      case 2:
        return GameMode.speedRun;
      default:
        return GameMode.normal;
    }
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
    setState(() => _coinCount = GameStorage.totalCoins());
  }

  void _selectMode(int index) {
    if (index == _selectedMode) return;

    VibrationService.tap();

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  // Reload the saved default when returning from Settings.
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

    if (newIndex == _selectedMode) return;

    setState(() {
      _selectedMode = newIndex;
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(newIndex);
    }
  }

  // Staggered reveal driven by one controller.
  Widget _reveal(double start, Widget child) {
    final animation = CurvedAnimation(
      parent: _intro,
      curve: Interval(
        start,
        math.min(1.0, start + 0.5),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - animation.value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = _modes[_selectedMode];
    final height = MediaQuery.of(context).size.height;
    final pagerHeight = (height * 0.46).clamp(330.0, 430.0).toDouble();

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          _buildBackground(mode),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                  child: _reveal(0.0, _buildTopBar()),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 22),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: _reveal(0.1, _buildHeading()),
                        ),
                        const SizedBox(height: 20),
                        _reveal(
                          0.2,
                          SizedBox(
                            height: pagerHeight,
                            child: PageView.builder(
                              controller: _pageController,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _modes.length,
                              onPageChanged: (i) {
                                VibrationService.tap();
                                setState(() => _selectedMode = i);
                              },
                              itemBuilder: (context, i) => _buildPage(i),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _reveal(0.45, _buildBottomBar(mode)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Background

  Widget _buildBackground(_GameMode mode) {
    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(_bg, mode.color, _isDark ? 0.20 : 0.075)!,
              _bg,
              _bg,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  // Top bar with coin pill

  Widget _buildTopBar() {
    final mode = _modes[_selectedMode];

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [mode.color, mode.colorDeep],
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: mode.color.withValues(alpha: 0.25),
                blurRadius: 15,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.route_rounded, color: Colors.white, size: 25),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Arrow Maze',
                style: TextStyle(
                  fontSize: 21,
                  letterSpacing: -0.4,
                  color: _textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  mode.title,
                  key: ValueKey(mode.title),
                  style: TextStyle(
                    fontSize: 11,
                    color: mode.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Settings button
        _glassIconButton(icon: Icons.settings_rounded, onTap: _openSettings),

        const SizedBox(width: 9),

        // Coin pill
        _buildCoinPill(),
      ],
    );
  }

  // Premium coin balance pill
  Widget _buildCoinPill() {
    return GestureDetector(
      onTap: () {
        Get.to(() => const GameStoreScreen());
      },
      child: Container(
        height: 38,
        padding: const EdgeInsets.only(left: 7, right: 5),
        decoration: BoxDecoration(
          color: _isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gold coin icon
            Container(
              width: 25,
              height: 25,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFE58A),
                    Color(0xFFFFB52E),
                    Color(0xFFE88B16),
                  ],
                ),
              ),
              child: const Icon(
                Icons.monetization_on_rounded,
                color: Color(0xFF8B4B00),
                size: 19,
              ),
            ),

            const SizedBox(width: 6),

            // Coin count
            Text(
              '$_coinCount',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),

            // Add coins button
            const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _isDark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.white.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22, color: _textPrimary),
        ),
      ),
    );
  }

  // Heading

  Widget _buildHeading() {
    final mode = _modes[_selectedMode];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 28,
                height: 1.1,
                letterSpacing: -1.0,
                fontWeight: FontWeight.w800,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                'game mode',
                key: ValueKey(mode.title),
                style: TextStyle(
                  color: mode.color,
                  fontSize: 28,
                  height: 1.1,
                  letterSpacing: -1.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Swipe to explore. You can switch any time.',
          style: TextStyle(
            color: _textSecondary.withValues(alpha: 0.95),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // Mode pager

  Widget _buildPage(int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, _) {
        double page = _selectedMode.toDouble();

        if (_pageController.hasClients &&
            _pageController.position.haveDimensions) {
          page = _pageController.page ?? page;
        }

        final distance = (page - index).abs().clamp(0.0, 1.0).toDouble();

        final scale = 1.0 - 0.07 * distance;
        final opacity = 1.0 - 0.45 * distance;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
              child: GestureDetector(
                onTap: () => _selectMode(index),
                child: _modeCard(_modes[index], index == _selectedMode),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _modeCard(_GameMode mode, bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(_surface, mode.color, _isDark ? 0.30 : 0.08)!,
            _surface,
            Color.lerp(_surface, mode.colorDeep, _isDark ? 0.10 : 0.025)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -24,
            child: Transform.rotate(
              angle: -0.0,
              child: Icon(
                mode.icon,
                size: 190,
                color: mode.color.withValues(alpha: _isDark ? 0.10 : 0.07),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 90,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: _isDark ? 0.07 : 0.65),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [mode.color, mode.colorDeep],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: mode.color.withValues(
                              alpha: _isDark ? 0.3 : 0.24,
                            ),
                            blurRadius: 30,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(mode.icon, size: 32, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: mode.color.withValues(
                          alpha: _isDark ? 0.20 : 0.15,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: mode.color.withValues(
                            alpha: _isDark ? 0.10 : 0.15,
                          ),
                        ),
                      ),
                      child: Text(
                        mode.tagline,
                        style: TextStyle(
                          color: mode.color,
                          fontSize: 10.5,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.title,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 26,
                        letterSpacing: -0.7,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mode.subtitle,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final feature in mode.features)
                      _featureChip(feature, mode.color),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      height: 1,
                      color: _isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE9EAF2),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(mode.detailIcon, size: 18, color: mode.color),
                        const SizedBox(width: 8),
                        Text(
                          mode.detail,
                          style: TextStyle(
                            color: mode.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF0F1F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDark
              ? Colors.white.withValues(alpha: 0.03)
              : const Color(0xFFE5E7F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: _isDark
                  ? const Color(0xFFD8D9EE)
                  : const Color(0xFF44465E),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Bottom CTA

  Widget _buildBottomBar(_GameMode mode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _bg.withValues(alpha: 0),
            _bg.withValues(alpha: _isDark ? 1 : 0.97),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 62,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [mode.color, mode.colorDeep],
                ),
                boxShadow: [
                  BoxShadow(
                    color: mode.color.withValues(alpha: _isDark ? 0.30 : 0.22),
                    blurRadius: 15,
                    offset: const Offset(0, 3),
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
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Row(
                    key: ValueKey(_selectedMode),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(mode.ctaIcon, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        mode.cta,
                        style: const TextStyle(
                          fontSize: 17,
                          letterSpacing: -0.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 21),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_clock_rounded,
                size: 13,
                color: _textSecondary.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Progress is saved separately for each mode',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textSecondary.withValues(alpha: 0.8),
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Game mode model

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
