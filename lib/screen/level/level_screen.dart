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

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bgTop =>
      _isDark ? const Color(0xFF101321) : const Color(0xFFF1F5FF);

  Color get _bgBottom =>
      _isDark ? const Color(0xFF090B12) : const Color(0xFFFAFBFF);

  Color get _surface => _isDark ? const Color(0xFF171B29) : Colors.white;

  Color get _locked =>
      _isDark ? const Color(0xFF111522) : const Color(0xFFF0F2F8);

  Color get _textPrimary =>
      _isDark ? const Color(0xFFF4F6FF) : const Color(0xFF172033);

  Color get _textSecondary =>
      _isDark ? const Color(0xFF969FB5) : const Color(0xFF7B8499);

  Color get _border =>
      _isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFE5EAF4);

  static const Color _blue = Color(0xFF6D67F8);
  static const Color _starGold = Color(0xFFFFBB38);
  static const Color _success = Color(0xFF32D6A0);

  late String _mode;
  late final AnimationController _intro;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();

    _mode = _readMode();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    final curve = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);

    _headerFade = Tween<double>(begin: 0, end: 1).animate(curve);

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(curve);

    // Starts immediately when the screen opens.
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
      backgroundColor: _bgBottom,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bgTop, _bgBottom],
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
                  color: _blue.withValues(alpha: _isDark ? 0.09 : 0.07),
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
                  child: SlideTransition(
                    position: _headerSlide,
                    child: _topBar(),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(child: _grid(unlocked)),
              ],
            ),
          ),
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
              'Choose your level',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 21,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _starGold.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _starGold.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 21, color: _starGold),
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

  // ───────────────────────── Grid ─────────────────────────

  Widget _grid(int unlocked) {
    return GridView.builder(
      scrollCacheExtent: ScrollCacheExtent.pixels(400),
      key: ValueKey('$_mode-$unlocked'),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 30),
      itemCount: LevelDesigns.totalLevels,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.98,
      ),
      itemBuilder: (context, index) {
        return _animatedLevelTile(
          index: index,
          child: _levelTile(index + 1, unlocked),
        );
      },
    );
  }

  // ───────────────────────── Level tile ─────────────────────────

  Widget _levelTile(int level, int unlocked) {
    final isUnlocked = level <= unlocked;
    final isCompleted = level < unlocked;
    final isCurrent = level == unlocked;
    final earnedStars = GameStorage.starsForLevel(_mode, level);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openLevel(level),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
          decoration: BoxDecoration(
            color: isUnlocked ? _surface : _locked,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCurrent
                  ? _blue.withValues(alpha: 0.75)
                  : isCompleted
                  ? _success.withValues(alpha: 0.27)
                  : _border,
              width: isCurrent ? 1.5 : 1.3,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: _blue.withValues(alpha: _isDark ? 0.12 : 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Text(
                        'CURRENT',
                        style: TextStyle(
                          color: _blue,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 1, height: 18),
                  Icon(
                    !isUnlocked
                        ? Icons.lock_rounded
                        : isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.play_circle_fill_rounded,
                    size: 19,
                    color: !isUnlocked
                        ? _textSecondary.withValues(alpha: 0.65)
                        : isCompleted
                        ? _success
                        : _blue,
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$level',
                      style: TextStyle(
                        color: isUnlocked
                            ? _textPrimary
                            : _textSecondary.withValues(alpha: 0.55),
                        fontSize: 39,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              if (isUnlocked)
                _stars(earnedStars)
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 12,
                      color: _textSecondary.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Locked',
                      style: TextStyle(
                        color: _textSecondary.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Icon(
            isEarned ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 13,
            color: isEarned
                ? _starGold
                : _textSecondary.withValues(alpha: 0.24),
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

    // Short stagger for the first rows.
    // No delayed futures and no replay on ordinary scrolling.
    final stagger = (widget.index % 9) * 12;

    if (stagger == 0) {
      _controller.forward();
    } else {
      // Animate using the controller's own timeline.
      _controller.value = 0;
      _startEntrance(stagger);
    }
  }

  void _startEntrance(int staggerMs) {
    // Delay is kept short and only applies during initial entry.
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
