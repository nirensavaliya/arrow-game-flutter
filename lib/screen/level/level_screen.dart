import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'level_design.dart';
import '../game/game_screen.dart';
import '../../storage/game_storage.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen>
    with TickerProviderStateMixin {
  // ───────────────────────── Theme (matches intro screen) ─────────────────

  static const Color _darkBg = Color(0xFF07080F);
  static const Color _darkSurface = Color(0xFF12141F);
  static const Color _darkTextPrimary = Color(0xFFF7F7FC);
  static const Color _darkTextSecondary = Color(0xFF8E92AB);

  static const Color _lightBg = Color(0xFFF4F5FA);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightTextPrimary = Color(0xFF14162A);
  static const Color _lightTextSecondary = Color(0xFF6F7390);

  static const Color _starGold = Color(0xFFFFBB38);

  // Completed state uses the current mode color (no separate green).
  Color get _success => _modeColor;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bg => _isDark ? _darkBg : _lightBg;

  Color get _surface => _isDark ? _darkSurface : _lightSurface;

  Color get _textPrimary => _isDark ? _darkTextPrimary : _lightTextPrimary;

  Color get _textSecondary =>
      _isDark ? _darkTextSecondary : _lightTextSecondary;

  Color get _hairline => _isDark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.black.withValues(alpha: 0.07);

  Color get _locked =>
      _isDark ? const Color(0xFF0E1019) : const Color(0xFFEDEFF6);

  // ───────────────────────── Mode look (same colors as intro) ─────────────

  Color get _modeColor {
    switch (_mode) {
      case 'timedChallenge':
        return const Color(0xFFFFB34F);
      case 'speedRun':
        return const Color(0xFF35D68A);
      default:
        return const Color(0xFF8175FF);
    }
  }

  Color get _modeDeep {
    switch (_mode) {
      case 'timedChallenge':
        return const Color(0xFFD9681C);
      case 'speedRun':
        return const Color(0xFF0C7F52);
      default:
        return const Color(0xFF4B3FD1);
    }
  }

  IconData get _modeIcon {
    switch (_mode) {
      case 'timedChallenge':
        return Icons.timer_rounded;
      case 'speedRun':
        return Icons.bolt_rounded;
      default:
        return Icons.explore_rounded;
    }
  }

  String get _modeName {
    switch (_mode) {
      case 'timedChallenge':
        return 'Timed Challenge';
      case 'speedRun':
        return 'Speed Run';
      default:
        return 'Normal Mode';
    }
  }

  // ───────────────────────── Segments ─────────────────────────

  // 80 levels = 8 segments.
  // Keep these boundaries stable so saved level progress
  // continues to match the same segments.

  static const int _levelsPerSegment = 10;

  static const List<_LevelSegment> _segments = [
    _LevelSegment(
      number: 1,
      title: 'First Steps',
      subtitle: 'Discover the path',
      icon: Icons.explore_rounded,
      color: Color(0xFF32D6A0),
    ),
    _LevelSegment(
      number: 2,
      title: 'Quick Escape',
      subtitle: 'Find your rhythm',
      icon: Icons.bolt_rounded,
      color: Color(0xFF48B8FF),
    ),
    _LevelSegment(
      number: 3,
      title: 'Mind Bender',
      subtitle: 'Think beyond the obvious',
      icon: Icons.psychology_rounded,
      color: Color(0xFF6D67F8),
    ),
    _LevelSegment(
      number: 4,
      title: 'Twisted Paths',
      subtitle: 'Every move matters',
      icon: Icons.route_rounded,
      color: Color(0xFFFFB547),
    ),
    _LevelSegment(
      number: 5,
      title: 'Deadly Crossroads',
      subtitle: 'Choose your escape wisely',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFF795B),
    ),
    _LevelSegment(
      number: 6,
      title: 'Shadow Labyrinth',
      subtitle: 'Outsmart the maze',
      icon: Icons.nightlight_round,
      color: Color(0xFFB17AFF),
    ),
    _LevelSegment(
      number: 7,
      title: 'Precision Trials',
      subtitle: 'Prove your mastery',
      icon: Icons.gps_fixed_rounded,
      color: Color(0xFFFFC857),
    ),
    _LevelSegment(
      number: 8,
      title: 'The Final Escape',
      subtitle: 'Conquer every challenge',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFFF6FAE),
    ),
  ];

  late String _mode;

  late final AnimationController _intro;
  late final AnimationController _ambient;
  late final Animation<double> _headerFade;

  // ───────────────────────── Lifecycle ─────────────────────────

  @override
  void initState() {
    super.initState();

    _mode = _readMode();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    final curve = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);

    _headerFade = Tween<double>(begin: 0, end: 1).animate(curve);

    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  // ───────────────────────── Game mode ─────────────────────────

  String _readMode() {
    final args = Get.arguments;

    if (args is Map && args['mode'] is String) {
      final requestedMode = args['mode'] as String;

      const supportedModes = {'normal', 'timedChallenge', 'speedRun'};

      if (supportedModes.contains(requestedMode)) {
        return requestedMode;
      }
    }

    return 'normal';
  }

  int get _unlockedLevel {
    return GameStorage.unlockedLevel(
      _mode,
    ).clamp(1, LevelDesigns.totalLevels).toInt();
  }

  int get _totalStars {
    var total = 0;

    for (var level = 1; level <= LevelDesigns.totalLevels; level++) {
      total += GameStorage.starsForLevel(_mode, level);
    }

    return total;
  }

  // ───────────────────────── Segment helpers ─────────────────────────

  int _segmentStart(int segmentNumber) {
    return ((segmentNumber - 1) * _levelsPerSegment) + 1;
  }

  int _segmentEnd(int segmentNumber) {
    return (segmentNumber * _levelsPerSegment).clamp(
      1,
      LevelDesigns.totalLevels,
    );
  }

  int _segmentLevelCount(int segmentNumber) {
    final start = _segmentStart(segmentNumber);
    final end = _segmentEnd(segmentNumber);

    if (start > LevelDesigns.totalLevels) {
      return 0;
    }

    return end - start + 1;
  }

  bool _isSegmentUnlocked(int segmentNumber, int unlocked) {
    return _segmentStart(segmentNumber) <= unlocked;
  }

  bool _isSegmentCompleted(int segmentNumber, int unlocked) {
    return unlocked > _segmentEnd(segmentNumber);
  }

  int _completedLevelsInSegment(int segmentNumber, int unlocked) {
    final start = _segmentStart(segmentNumber);
    final end = _segmentEnd(segmentNumber);

    if (start > LevelDesigns.totalLevels) {
      return 0;
    }

    return (unlocked - start).clamp(0, end - start + 1);
  }

  int _starsInSegment(int segmentNumber) {
    final start = _segmentStart(segmentNumber);
    final end = _segmentEnd(segmentNumber);

    if (start > LevelDesigns.totalLevels) {
      return 0;
    }

    var stars = 0;

    for (var level = start; level <= end; level++) {
      stars += GameStorage.starsForLevel(_mode, level);
    }

    return stars;
  }

  // ───────────────────────── Open level ─────────────────────────

  Future<void> _openLevel(int level) async {
    if (level > LevelDesigns.totalLevels ||
        !GameStorage.isLevelUnlocked(_mode, level)) {
      HapticFeedback.heavyImpact();

      Get.snackbar(
        'Level locked',
        'Complete the previous levels to unlock this level.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: _surface,
        colorText: _textPrimary,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        icon: Icon(Icons.lock_rounded, color: _textSecondary),
      );

      return;
    }

    HapticFeedback.selectionClick();

    await Get.to(
      () => const GameScreen(),
      arguments: {'level': level, 'mode': _mode},
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 350),
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final unlocked = _unlockedLevel;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                FadeTransition(opacity: _headerFade, child: _topBar()),
                const SizedBox(height: 12),
                Expanded(
                  child: CustomScrollView(
                    key: PageStorageKey<String>('levels-scroll-$_mode'),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _headerFade,
                          child: _journeySummary(unlocked),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 18)),
                      _segmentList(unlocked),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Background ─────────────────────────

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, _) {
        final drift = math.sin(_ambient.value * math.pi) * 22;

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _MazePainter(
                  color: (_isDark ? Colors.white : Colors.black).withValues(
                    alpha: _isDark ? 0.03 : 0.035,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -150 + drift,
              right: -120,
              child: IgnorePointer(
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _modeColor.withValues(alpha: _isDark ? 0.26 : 0.15),
                        _modeColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150 - drift,
              left: -150,
              child: IgnorePointer(
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _modeDeep.withValues(alpha: _isDark ? 0.18 : 0.10),
                        _modeDeep.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ───────────────────────── Header ─────────────────────────

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          _backButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Level Journey',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(_modeIcon, size: 12, color: _modeColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _modeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _starCounter(),
        ],
      ),
    );
  }

  Widget _backButton() {
    return Material(
      color: _surface.withValues(alpha: _isDark ? 0.75 : 0.95),
      shape: CircleBorder(side: BorderSide(color: _hairline)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          Get.back();
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: _textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _starCounter() {
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
          const Icon(
            Icons.star_rounded,
            color: CupertinoColors.systemYellow,
            size: 26,
          ),
          const SizedBox(width: 8),
          Text(
            '$_totalStars',
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

  // ───────────────────────── Journey summary (hero card) ─────────────────

  Widget _journeySummary(int unlocked) {
    final total = LevelDesigns.totalLevels;
    final completed = (unlocked - 1).clamp(0, total);
    final progress = total == 0 ? 0.0 : completed / total;

    final completedSegments = _segments
        .where((segment) => _isSegmentCompleted(segment.number, unlocked))
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_modeColor, _modeDeep],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.40),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: _modeColor.withValues(alpha: _isDark ? 0.38 : 0.30),
              blurRadius: 30,
              offset: const Offset(0, 14),
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
                    seed: 6,
                  ),
                ),
              ),
              Positioned(
                right: -26,
                bottom: -30,
                child: Icon(
                  _modeIcon,
                  size: 170,
                  color: Colors.white.withValues(alpha: 0.13),
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
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0),
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
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.32),
                            ),
                          ),
                          child: const Icon(
                            Icons.route_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your adventure',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  letterSpacing: -0.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$completed of $total levels completed',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.86),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            letterSpacing: -1.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                color: Colors.black.withValues(alpha: 0.22),
                              ),
                              FractionallySizedBox(
                                widthFactor: value.clamp(0.0, 1.0),
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _summaryChip(
                          Icons.flag_rounded,
                          '$completedSegments/${_segments.length} segments',
                        ),
                        _summaryChip(Icons.star_rounded, '$_totalStars stars'),
                        _summaryChip(
                          Icons.play_arrow_rounded,
                          'Level $unlocked',
                        ),
                      ],
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

  Widget _summaryChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Segment list ─────────────────────────

  Widget _segmentList(int unlocked) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final segment = _segments[index];

          final levelCount = _segmentLevelCount(segment.number);

          if (levelCount == 0) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _segmentCard(segment: segment, unlocked: unlocked),
          );
        }, childCount: _segments.length),
      ),
    );
  }

  // ───────────────────────── Segment card ─────────────────────────

  Widget _segmentCard({required _LevelSegment segment, required int unlocked}) {
    final start = _segmentStart(segment.number);
    final end = _segmentEnd(segment.number);

    final isUnlocked = _isSegmentUnlocked(segment.number, unlocked);
    final isCompleted = _isSegmentCompleted(segment.number, unlocked);

    final completedLevels = _completedLevelsInSegment(segment.number, unlocked);

    final totalLevels = _segmentLevelCount(segment.number);

    final progress = totalLevels == 0
        ? 0.0
        : (completedLevels / totalLevels).clamp(0.0, 1.0);

    final stars = _starsInSegment(segment.number);
    // Mode-wise color (purple / orange / green), not the segment's own color.
    final accent = _modeColor;

    final muted = _isDark ? const Color(0xFF9BA6B8) : const Color(0xFF8993A5);

    final borderColor = isCompleted
        ? _success.withValues(alpha: 0.45)
        : isUnlocked
        ? accent.withValues(alpha: _isDark ? 0.45 : 0.35)
        : _hairline;

    final iconColor = isCompleted
        ? _success
        : isUnlocked
        ? accent
        : muted;

    final statusLabel = isCompleted
        ? 'Completed'
        : isUnlocked
        ? 'In progress'
        : 'Locked';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Color.lerp(
          _surface,
          accent,
          isUnlocked ? (_isDark ? 0.07 : 0.035) : 0,
        ),
        border: Border.all(color: borderColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(
              alpha: isUnlocked ? (_isDark ? 0.12 : 0.09) : 0.02,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Faint maze texture in the card corner.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _MazePainter(
                  color: accent.withValues(alpha: isUnlocked ? 0.05 : 0.02),
                  cell: 30,
                  seed: segment.number + 2,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        gradient: isUnlocked
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  iconColor,
                                  Color.lerp(iconColor, Colors.black, 0.28)!,
                                ],
                              )
                            : null,
                        color: isUnlocked
                            ? null
                            : muted.withValues(alpha: 0.14),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: isUnlocked ? 0.28 : 0.06,
                          ),
                        ),
                        boxShadow: isUnlocked
                            ? [
                                BoxShadow(
                                  color: iconColor.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isUnlocked ? segment.icon : Icons.lock_rounded,
                        size: 25,
                        color: isUnlocked ? Colors.white : muted,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            segment.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            segment.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCompleted)
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _success.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _success.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 19,
                          color: _success,
                        ),
                      )
                    else
                      Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          color: isUnlocked ? accent : muted,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // Progress bar + labels
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: isUnlocked ? progress : 0,
                  ),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Container(
                            height: 6,
                            color: _isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.07),
                          ),
                          FractionallySizedBox(
                            widthFactor: value.clamp(0.0, 1.0),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isCompleted
                                      ? [_success, _success]
                                      : [
                                          accent,
                                          Color.lerp(
                                            accent,
                                            Colors.black,
                                            0.25,
                                          )!,
                                        ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(
                          alpha: _isDark ? 0.16 : 0.11,
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Levels $start–$end',
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Level selection
                if (isUnlocked)
                  _buildSegmentLevels(segment: segment, unlocked: unlocked)
                else
                  _lockedSegmentMessage(segment, start),

                const SizedBox(height: 12),

                // Footer
                Container(
                  padding: const EdgeInsets.only(top: 11),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: _hairline)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.layers_outlined, size: 17, color: muted),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '$completedLevels/$totalLevels completed',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: _starGold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$stars',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'stars',
                        style: TextStyle(
                          color: muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
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
    );
  }

  // ───────────────────────── Segment levels ─────────────────────────

  Widget _buildSegmentLevels({
    required _LevelSegment segment,
    required int unlocked,
  }) {
    final start = _segmentStart(segment.number);
    final end = _segmentEnd(segment.number);
    final count = end - start + 1;

    return GridView.builder(
      key: ValueKey('segment-${segment.number}-$_mode-$unlocked'),
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: count,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final level = start + index;

        return _animatedLevelTile(
          index: level - 1,
          child: _levelTile(level, unlocked, segmentColor: segment.color),
        );
      },
    );
  }

  // ───────────────────────── Locked segment ─────────────────────────

  Widget _lockedSegmentMessage(_LevelSegment segment, int start) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: _locked,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _textSecondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: _textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete Segment ${segment.number - 1}',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Levels $start–${_segmentEnd(segment.number)} unlock next.',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_rounded,
            size: 17,
            color: _textSecondary.withValues(alpha: 0.65),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Level tile ─────────────────────────

  Widget _levelTile(int level, int unlocked, {required Color segmentColor}) {
    final isUnlocked = level <= unlocked;
    final isCompleted = level < unlocked;
    final isCurrent = level == unlocked;

    final earnedStars = GameStorage.starsForLevel(_mode, level);

    final muted = _textSecondary.withValues(alpha: isUnlocked ? 0.8 : 0.5);

    final BoxDecoration decoration;

    if (isCurrent) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_modeColor, _modeDeep],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.45),
          width: 1.3,
        ),
      );
    } else if (isCompleted) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _surface,
        border: Border.all(
          color: _success.withValues(alpha: _isDark ? 0.30 : 0.28),
        ),
      );
    } else {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _locked,
        border: Border.all(color: _hairline),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openLevel(level),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(9, 9, 9, 8),
          decoration: decoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top status row
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: isCurrent
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Text(
                                'Current',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            )
                          : Text(
                              'Level',
                              style: TextStyle(
                                color: muted.withValues(alpha: 0.8),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (isCompleted)
                    Icon(Icons.check_circle_rounded, color: _success, size: 17)
                  else if (isCurrent)
                    Container(
                      width: 23,
                      height: 23,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: _modeDeep,
                        size: 17,
                      ),
                    )
                  else
                    Icon(Icons.lock_rounded, size: 15, color: muted),
                ],
              ),

              // Large level number
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$level',
                      style: TextStyle(
                        color: !isUnlocked
                            ? _textSecondary.withValues(alpha: 0.45)
                            : isCurrent
                            ? Colors.white
                            : _textPrimary,
                        fontSize: 35,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.8,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom rating / status
              SizedBox(
                height: 17,
                child: isUnlocked
                    ? Center(child: _stars(earnedStars, onGradient: isCurrent))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 11,
                            color: muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Locked',
                            style: TextStyle(
                              color: muted,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
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

  // ───────────────────────── Stars ─────────────────────────

  Widget _stars(int earned, {bool onGradient = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isEarned = index < earned;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.5),
          child: Icon(
            isEarned ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 14,
            color: isEarned
                ? (onGradient ? Colors.white : _starGold)
                : (onGradient
                      ? Colors.white.withValues(alpha: 0.38)
                      : _textSecondary.withValues(alpha: 0.26)),
          ),
        );
      }),
    );
  }

  // ───────────────────────── Animated tile ─────────────────────────

  Widget _animatedLevelTile({required int index, required Widget child}) {
    return _StaggeredLevelEntry(
      key: ValueKey('$_mode-level-$index'),
      index: index,
      child: child,
    );
  }
}

// ───────────────────────── Maze texture painter ─────────────────────────

class _MazePainter extends CustomPainter {
  final Color color;
  final double cell;
  final int seed;

  const _MazePainter({required this.color, this.cell = 36, this.seed = 11});

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

// ───────────────────────── Segment model ─────────────────────────

class _LevelSegment {
  final int number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _LevelSegment({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

// ───────────────────────── One-time tile entrance ─────────────────────────

class _StaggeredLevelEntry extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredLevelEntry({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<_StaggeredLevelEntry> createState() => _StaggeredLevelEntryState();
}

class _StaggeredLevelEntryState extends State<_StaggeredLevelEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);

    _scale = Tween<double>(begin: 0.97, end: 1).animate(curve);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(curve);

    final stagger = (widget.index % 9) * 12;

    if (stagger == 0) {
      _controller.forward();
    } else {
      _startEntrance(stagger);
    }
  }

  void _startEntrance(int staggerMs) {
    Future<void>.delayed(Duration(milliseconds: staggerMs), () {
      if (mounted && !_controller.isAnimating) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: ScaleTransition(
            scale: _scale,
            alignment: Alignment.center,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
