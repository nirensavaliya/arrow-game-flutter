import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'level_design.dart';
import '../game/game_screen.dart';
import '../../services/game_storage.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen>
    with SingleTickerProviderStateMixin {
  // ───────────────────────── Theme ─────────────────────────

  bool get _isDark =>
      Theme.of(context).brightness == Brightness.dark;

  Color get _bgTop =>
      _isDark ? const Color(0xFF101321) : const Color(0xFFF1F5FF);

  Color get _bgBottom =>
      _isDark ? const Color(0xFF090B12) : const Color(0xFFFAFBFF);

  Color get _surface =>
      _isDark ? const Color(0xFF171B29) : Colors.white;

  Color get _locked =>
      _isDark ? const Color(0xFF111522) : const Color(0xFFF0F2F8);

  Color get _textPrimary =>
      _isDark ? const Color(0xFFF4F6FF) : const Color(0xFF172033);

  Color get _textSecondary =>
      _isDark ? const Color(0xFF969FB5) : const Color(0xFF7B8499);

  Color get _border =>
      _isDark
          ? Colors.white.withValues(alpha: 0.07)
          : const Color(0xFFE5EAF4);

  static const Color _blue = Color(0xFF6D67F8);
  static const Color _starGold = Color(0xFFFFBB38);
  static const Color _success = Color(0xFF32D6A0);

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
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  // ───────────────────────── Lifecycle ─────────────────────────

  @override
  void initState() {
    super.initState();

    _mode = _readMode();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    final curve = CurvedAnimation(
      parent: _intro,
      curve: Curves.easeOutCubic,
    );

    _headerFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(curve);

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(curve);

    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  // ───────────────────────── Game mode ─────────────────────────

  String _readMode() {
    final args = Get.arguments;

    if (args is Map && args['mode'] is String) {
      final requestedMode = args['mode'] as String;

      const supportedModes = {
        'normal',
        'timedChallenge',
        'speedRun',
      };

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

    for (var level = 1;
    level <= LevelDesigns.totalLevels;
    level++) {
      total += GameStorage.starsForLevel(_mode, level);
    }

    return total;
  }

  // ───────────────────────── Segment helpers ─────────────────────────

  int _segmentStart(int segmentNumber) {
    return ((segmentNumber - 1) * _levelsPerSegment) + 1;
  }

  int _segmentEnd(int segmentNumber) {
    return (segmentNumber * _levelsPerSegment)
        .clamp(1, LevelDesigns.totalLevels);
  }

  int _segmentLevelCount(int segmentNumber) {
    final start = _segmentStart(segmentNumber);
    final end = _segmentEnd(segmentNumber);

    if (start > LevelDesigns.totalLevels) {
      return 0;
    }

    return end - start + 1;
  }

  bool _isSegmentUnlocked(
      int segmentNumber,
      int unlocked,
      ) {
    return _segmentStart(segmentNumber) <= unlocked;
  }

  bool _isSegmentCompleted(
      int segmentNumber,
      int unlocked,
      ) {
    return unlocked > _segmentEnd(segmentNumber);
  }

  int _completedLevelsInSegment(
      int segmentNumber,
      int unlocked,
      ) {
    final start = _segmentStart(segmentNumber);
    final end = _segmentEnd(segmentNumber);

    if (start > LevelDesigns.totalLevels) {
      return 0;
    }

    return (unlocked - start)
        .clamp(0, end - start + 1);
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
        icon: Icon(
          Icons.lock_rounded,
          color: _textSecondary,
        ),
      );

      return;
    }

    HapticFeedback.selectionClick();

    await Get.to(
          () => const GameScreen(),
      arguments: {
        'level': level,
        'mode': _mode,
      },
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
      backgroundColor: _bgBottom,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _bgTop,
                    _bgBottom,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: -100,
            right: -95,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _blue.withValues(
                    alpha: _isDark ? 0.09 : 0.07,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                FadeTransition(
                  opacity: _headerFade,
                  child: _topBar(),
                ),
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
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 12),
                      ),
                      _segmentList(unlocked),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ───────────────────────── Header ─────────────────────────

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Row(
        children: [
          _backButton(),
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'Level Journey',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
              ),
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
      color: _surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          HapticFeedback.selectionClick();
          Get.back();
        },
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _border),
          ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _starGold.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _starGold.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 21,
            color: _starGold,
          ),
          const SizedBox(width: 5),
          Text(
            '$_totalStars',
            style: const TextStyle(
              color: _starGold,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Journey summary ─────────────────────────

  Widget _journeySummary(int unlocked) {
    final total = LevelDesigns.totalLevels;
    final completed = (unlocked - 1).clamp(0, total);
    final progress = completed / total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: _isDark ? 0.08 : 0.025,
              ),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: _blue,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your adventure',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$completed of $total levels completed',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: _border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  _blue,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _summaryChip(
                  Icons.flag_rounded,
                  '${_segments.where((segment) => _isSegmentCompleted(segment.number, unlocked)).length}/${_segments.length} Segments',
                  _blue,
                ),

                const SizedBox(width: 8),

                _summaryChip(
                  Icons.star_rounded,
                  '$_totalStars Stars',
                  _starGold,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(
      IconData icon,
      String label,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 10,
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
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 30),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final segment = _segments[index];

            final levelCount = _segmentLevelCount(segment.number);

            if (levelCount == 0) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _segmentCard(
                segment: segment,
                unlocked: unlocked,
              ),
            );
          },
          childCount: _segments.length,
        ),
      ),
    );
  }

  // ───────────────────────── Segment card ─────────────────────────

  Widget _segmentCard({
    required _LevelSegment segment,
    required int unlocked,
  }) {
    final start = _segmentStart(segment.number);
    final end = _segmentEnd(segment.number);

    final isUnlocked = _isSegmentUnlocked(
      segment.number,
      unlocked,
    );

    final isCompleted = _isSegmentCompleted(
      segment.number,
      unlocked,
    );

    final completedLevels = _completedLevelsInSegment(
      segment.number,
      unlocked,
    );

    final totalLevels = _segmentLevelCount(segment.number);

    final progress = totalLevels == 0
        ? 0.0
        : (completedLevels / totalLevels).clamp(0.0, 1.0);

    final stars = _starsInSegment(segment.number);
    final accent = segment.color;

    const success = Color(0xFF25BE83);
    const gold = Color(0xFFFFB94D);

    final foreground = _textPrimary;

    final muted = _isDark
        ? const Color(0xFF9BA6B8)
        : const Color(0xFF8993A5);

    // Premium glass-inspired surface.
    final glassGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: _isDark
          ? [
        const Color(0xFF222B3A).withValues(alpha: 0.98),
        const Color(0xFF171D29).withValues(alpha: 0.99),
        const Color(0xFF141923),
      ]
          : [
        Colors.white,
        const Color(0xFFFCFDFF),
        const Color(0xFFF5F8FF),
      ],
      stops: const [0.0, 0.55, 1.0],
    );

    final borderColor = isCompleted
        ? success.withValues(alpha: 0.36)
        : isUnlocked
        ? accent.withValues(alpha: _isDark ? 0.30 : 0.20)
        : (_isDark
        ? Colors.white.withValues(alpha: 0.09)
        : const Color(0xFFE7EBF3));

    final trackColor = _isDark
        ? Colors.white.withValues(alpha: 0.075)
        : const Color(0xFFEBEFF6);

    final iconColor = isCompleted
        ? success
        : isUnlocked
        ? accent
        : muted;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: glassGradient,
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          // Soft colored ambient shadow.
          BoxShadow(
            color: accent.withValues(
              alpha: isUnlocked
                  ? (_isDark ? 0.055 : 0.035)
                  : 0.012,
            ),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),

          // Natural depth.
          BoxShadow(
            color: Colors.black.withValues(
              alpha: _isDark ? 0.16 : 0.035,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Top glass reflection.
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: IgnorePointer(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(
                        alpha: _isDark ? 0.15 : 0.95,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Accent strip.
              Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  height: 3,
                  width: isCompleted
                      ? 84
                      : isUnlocked
                      ? 62
                      : 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCompleted
                          ? [
                        success,
                        success.withValues(alpha: 0.55),
                      ]
                          : [
                        accent,
                        accent.withValues(alpha: 0.55),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                ),
              ),

              // Stage header.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  15,
                  15,
                  15,
                  14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Glass-inspired stage emblem.
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            iconColor.withValues(alpha: 0.15),
                            iconColor.withValues(alpha: 0.055),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: iconColor.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Icon(
                        isUnlocked
                            ? Icons.route_rounded
                            : Icons.lock_outline_rounded,
                        size: 22,
                        color: iconColor,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Title and stage range.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            segment.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.45,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'STAGE ${segment.number.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.9,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                ),
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: muted.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  '$start–$end',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Progress percentage or completion badge.
                    if (isCompleted)
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: success.withValues(alpha: 0.11),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: success.withValues(alpha: 0.20),
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: success,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              color: isUnlocked ? accent : muted,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PROGRESS',
                            style: TextStyle(
                              color: muted,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Refined progress bar.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 4,
                    child: LinearProgressIndicator(
                      value: isUnlocked ? progress : 0,
                      backgroundColor: trackColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? success : accent,
                      ),
                    ),
                  ),
                ),
              ),

              // Level selection.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  14,
                  12,
                  12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUnlocked)
                      _buildSegmentLevels(
                        segment: segment,
                        unlocked: unlocked,
                      )
                    else
                      _lockedSegmentMessage(
                        segment,
                        start,
                      ),

                    const SizedBox(height: 12),

                    // Footer separator and statistics.
                    Container(
                      padding: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: _isDark
                                ? Colors.white.withValues(alpha: 0.075)
                                : const Color(0xFFE9EDF4),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            size: 18,
                            color: muted,
                          ),
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
                            color: gold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$stars',
                            style: TextStyle(
                              color: foreground,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'STARS',
                            style: TextStyle(
                              color: muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
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
      padding: const EdgeInsets.fromLTRB(1, 2, 1, 3),
      itemCount: count,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final level = start + index;

        return _animatedLevelTile(
          index: level - 1,
          child: _levelTile(
            level,
            unlocked,
            segmentColor: segment.color,
          ),
        );
      },
    );
  }

  // ───────────────────────── Locked segment ─────────────────────────

  Widget _lockedSegmentMessage(
      _LevelSegment segment,
      int start,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: _locked,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: _textSecondary,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete Segment ${segment.number - 1}',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Levels $start–${_segmentEnd(segment.number)} unlock next.',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

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

  Widget _levelTile(
      int level,
      int unlocked, {
        required Color segmentColor,
      }) {
    final isUnlocked = level <= unlocked;
    final isCompleted = level < unlocked;
    final isCurrent = level == unlocked;

    final earnedStars = GameStorage.starsForLevel(
      _mode,
      level,
    );

    final accent = isCurrent ? _blue : segmentColor;

    final background = !isUnlocked
        ? _locked
        : isCurrent
        ? (_isDark
        ? const Color(0xFF19263B)
        : const Color(0xFFF0F5FF))
        : _surface;

    final borderColor = isCurrent
        ? _blue.withValues(alpha: 0.65)
        : isCompleted
        ? _success.withValues(alpha: 0.24)
        : _border.withValues(alpha: _isDark ? 0.75 : 0.85);

    final muted = _textSecondary.withValues(
      alpha: isUnlocked ? 0.8 : 0.5,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => _openLevel(level),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(9, 9, 9, 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: borderColor,
              width: isCurrent ? 1.4 : 0,
            ),
            boxShadow: [
              if (isCurrent)
                BoxShadow(
                  color: _blue.withValues(
                    alpha: _isDark ? 0.15 : 0.09,
                  ),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
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
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CURRENT',
                          style: TextStyle(
                            color: _blue,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.45,
                          ),
                        ),
                      )
                          : Text(
                        'LEVEL',
                        style: TextStyle(
                          color: muted.withValues(alpha: 0.75),
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  if (isCompleted)
                    Icon(
                      Icons.check_circle_rounded,
                      color: _success,
                      size: 17,
                    )
                  else if (isCurrent)
                    Container(
                      width: 23,
                      height: 23,
                      decoration: BoxDecoration(
                        color: _blue.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: _blue,
                        size: 17,
                      ),
                    )
                  else if (!isUnlocked)
                      Icon(
                        Icons.lock_rounded,
                        size: 15,
                        color: muted,
                      )
                    else
                      Icon(
                        Icons.circle_outlined,
                        size: 15,
                        color: accent.withValues(alpha: 0.7),
                      ),
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
                            ? _textSecondary.withValues(alpha: 0.48)
                            : isCurrent
                            ? _blue
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
                    ? Center(
                  child: _stars(earnedStars),
                )
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
                      'LOCKED',
                      style: TextStyle(
                        color: muted,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
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

  Widget _stars(int earned) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isEarned = index < earned;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.5),
          child: Icon(
            isEarned
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            size: 14,
            color: isEarned
                ? _starGold
                : _textSecondary.withValues(alpha: 0.24),
          ),
        );
      }),
    );
  }

  // ───────────────────────── Animated tile ─────────────────────────

  Widget _animatedLevelTile({
    required int index,
    required Widget child,
  }) {
    return _StaggeredLevelEntry(
      key: ValueKey('$_mode-level-$index'),
      index: index,
      child: child,
    );
  }
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
  State<_StaggeredLevelEntry> createState() =>
      _StaggeredLevelEntryState();
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

    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(curve);

    _scale = Tween<double>(
      begin: 0.97,
      end: 1,
    ).animate(curve);

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
    Future<void>.delayed(
      Duration(milliseconds: staggerMs),
          () {
        if (mounted && !_controller.isAnimating) {
          _controller.forward();
        }
      },
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