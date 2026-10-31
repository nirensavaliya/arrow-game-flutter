import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../controller/game_controller.dart';
import '../../modes/game_mode.dart';
import '../../painter/animated_dot_grid.dart';
import '../../painter/grid_lines_painter.dart';
import '../../painter/arrow_Painter.dart';
import '../../services/game_storage.dart';
import '../../services/ads/interstitial_ad_service.dart';
import '../../services/ads/rewarded_ad_service.dart';
import '../../services/vibration_service.dart';
import '../level/level_design.dart';
import '../result/result_dialog.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // THEME
  // ---------------------------------------------------------------------------

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _textPrimary =>
      _isDark ? const Color(0xFFF0F0F2) : const Color(0xFF1B2233);

  Color get _textSecondary =>
      _isDark ? const Color(0xFFA0A6B5) : const Color(0xFF5B6478);

  Color get _blue => const Color(0xFF2F80FF);

  Color get _violet => const Color(0xFF7B61FF);

  Color get _red => const Color(0xFFFF4D5E);

  Color get _glass => _isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.white.withValues(alpha: 0.78);

  Color get _glassBorder => _isDark
      ? Colors.white.withValues(alpha: 0.10)
      : const Color(0xFF2F4A8A).withValues(alpha: 0.10);

  // ---------------------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------------------

  late final AnimationController _entranceController;
  late final Animation<double> _topAnim;
  late final Animation<double> _statusAnim;
  late final Animation<double> _boardAnim;
  late final Animation<double> _bottomAnim;

  late final AnimationController _shakeController;
  late final AnimationController _drawController;
  late final AnimationController _ambientController;
  late final RewardedAdService _rewardedAdService;
  late final InterstitialAdService _interstitialAdService;

  // Show an interstitial after every 3rd level (3, 6, 9, ...).
  static const int _adEveryLevels = 5;

  Worker? _livesWorker;
  int _prevLives = -1;

  Worker? _arrowsWorker;
  int _prevArrows = -1;

  late GameMode _mode;
  int? _requestedLevel;

  // Restart icon spin (each tap = one full counter-clockwise turn).
  double _restartTurns = 0;

  // Action pop + combo
  _ActionPop? _pop;
  int _popId = 0;

  // New combo banner (top) + coin burst (center)
  _ComboMsg? _comboMsg;
  _CoinBurstData? _coinBurst;
  int _fxId = 0;

  int _combo = 0;
  DateTime? _lastClear;
  DateTime? _pendingTapTime;
  static const Duration _comboWindow = Duration(milliseconds: 900);
  Timer? _comboTimer;
  DateTime? _milestoneUntil;
  static const Duration _milestoneTime = Duration(milliseconds: 900);

  // Zoom
  static const double _minZoom = 1.0;
  static const double _maxZoom = 3.0;

  final TransformationController _tc = TransformationController();
  late final AnimationController _zoomController;
  Animation<Matrix4>? _zoomAnim;
  Size _boardSize = Size.zero;

  // Grid toggle
  late bool _showGrid = GameStorage.loadShowGrid();

  Animation<double> _interval(
    double a,
    double b, [
    Curve c = Curves.easeOutCubic,
  ]) => CurvedAnimation(
    parent: _entranceController,
    curve: Interval(a, b, curve: c),
  );

  Widget _enter(
    Animation<double> a,
    Widget child, {
    double dy = 18,
    double scale = 1,
  }) {
    return AnimatedBuilder(
      animation: a,
      child: child,
      builder: (_, child) {
        final v = a.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - v) * dy),
            child: Transform.scale(
              scale: scale + (1 - scale) * v,
              child: child,
            ),
          ),
        );
      },
    );
  }

  void _readArguments() {
    final args = Get.arguments;

    String? modeName;
    int? requestedLevel;

    if (args is Map) {
      modeName = args['mode']?.toString();

      final value = args['level'];
      if (value is num && value.toInt() > 0) {
        requestedLevel = value.toInt();
      }
    }

    var mode = GameMode.normal;

    for (final candidate in GameMode.values) {
      if (candidate.name == modeName) {
        mode = candidate;
        break;
      }
    }

    _mode = mode;
    _requestedLevel = requestedLevel;
  }

  void _playEntrance() {
    if (mounted) {
      _entranceController.forward(from: 0);
      _drawController.forward(from: 0);
    }
  }

  // ---------------------------------------------------------------------------
  // ACTION POP / COMBO
  // ---------------------------------------------------------------------------

  void _showPop({
    required IconData icon,
    String? emoji,
    required Color color,
    required String big,
    String? label,
    bool compact = false,
  }) {
    setState(() {
      _pop = _ActionPop(
        id: ++_popId,
        icon: icon,
        emoji: emoji,
        color: color,
        big: big,
        label: label,
        compact: compact,
      );
    });
  }

  // Shows the combo now, or after the milestone toast has finished.
  void _showComboWhenFree() {
    final until = _milestoneUntil;
    final wait = until == null
        ? Duration.zero
        : until.difference(DateTime.now());

    if (wait <= Duration.zero) {
      _showComboPop(_combo);
      return;
    }

    _comboTimer?.cancel();
    _comboTimer = Timer(wait, () {
      if (!mounted) return;
      _showComboPop(_combo);
    });
  }

  void _resetCombo() {
    _comboTimer?.cancel();
    _comboTimer = null;
    _combo = 0;
    _lastClear = null;
    _pendingTapTime = null;
    _milestoneUntil = null;
  }

  void _registerClear(GameController c, int before, int after) {
    final now = _pendingTapTime ?? DateTime.now();
    _pendingTapTime = null;

    if (_lastClear == null || now.difference(_lastClear!) > _comboWindow) {
      _combo = 0;
    }

    _combo++;
    _lastClear = now;

    _comboTimer?.cancel();

    // Last arrow: the result dialog takes over.
    if (after <= 0) {
      final streak = _combo;
      _combo = 0;
      _lastClear = null;
      c.addComboCoins(streak); // pays into the level reward
      return;
    }

    // Milestones show immediately.
    final total = math.max(c.totalArrows.value, before);
    if (total > 0) {
      final doneBefore = (total - before) / total;
      final doneAfter = (total - after) / total;

      if (doneBefore < 0.5 && doneAfter >= 0.5) {
        _showPop(
          icon: Icons.flag_rounded,
          emoji: '🚩',
          color: const Color(0xFF1ED6C3),
          big: 'HALFWAY!',
          label: '50% CLEARED',
        );
        _milestoneUntil = DateTime.now().add(_milestoneTime);
      } else if (doneBefore < 0.8 && doneAfter >= 0.8) {
        _showPop(
          icon: Icons.rocket_launch_rounded,
          emoji: '🚀',
          color: _violet,
          big: 'ALMOST THERE!',
          label: '$after LEFT',
        );
        _milestoneUntil = DateTime.now().add(_milestoneTime);
      }
    }

    // Every clear restarts the wait. One message for the whole streak,
    // shown after the player stops clearing.
    _comboTimer = Timer(_comboWindow, () {
      if (!mounted || _combo < 1) return;
      _showComboWhenFree();
    });
  }

  void _showComboPop(int streak) {
    if (!mounted || streak < 1) return;

    final String emoji;
    final Color color;
    final String title;

    if (streak >= 10) {
      emoji = '🏆';
      color = const Color(0xFFFFB300);
      title = 'INCREDIBLE!';
    } else if (streak >= 7) {
      emoji = '🤩';
      color = const Color(0xFFFF4DA6);
      title = 'BRILLIANT!';
    } else if (streak >= 5) {
      emoji = '🔥';
      color = const Color(0xFFFF7A1A);
      title = 'AWESOME!';
    } else if (streak >= 4) {
      emoji = '⚡';
      color = _violet;
      title = 'EXCELLENT!';
    } else if (streak >= 3) {
      emoji = '👍';
      color = const Color(0xFF1ED6C3);
      title = 'GREAT!';
    } else if (streak >= 2) {
      emoji = '👍';
      color = const Color(0xFF1ED6C3);
      title = 'COOL!';
    } else {
      return;
    }

    final c = Get.find<GameController>();
    final coins = c.addComboCoins(streak); // 0 when the level is a replay

    setState(() {
      _comboMsg = _ComboMsg(
        id: ++_fxId,
        emoji: emoji,
        color: color,
        title: title,
        streak: streak,
      );
      _coinBurst = coins > 0 ? _CoinBurstData(id: ++_fxId, coins: coins) : null;
    });

    // Streak finished, start fresh.
    _combo = 0;
    _lastClear = null;
  }

  /// Compares the current arrow count with the last one seen. Called from the
  /// list worker, after every tap, and from the arrow layer, so a clear is
  /// caught however the controller removes the arrow. Deduped by _prevArrows.
  void _syncArrows(GameController c) {
    if (!mounted) return;

    final now = c.arrows.length;
    final prev = _prevArrows;
    _prevArrows = now;

    if (prev > 0 && now < prev) {
      _registerClear(c, prev, now);
    }
  }

  void _goNextLevel(GameController c) {
    // Level the player just finished.
    final finished = c.level.value;

    void proceed() {
      if (!mounted) return;
      _resetZoom();
      _resetCombo();
      _prevArrows = -1; // level load is not a clear
      setState(() {
        _pop = null;
        _comboMsg = null;
        _coinBurst = null;
      });
      c.nextLevel();
      _playEntrance();
    }
    // Ad after levels 3, 6, 9, 12, ... (never after level 1).
    if (finished % _adEveryLevels == 0) {
      _interstitialAdService.show(onDone: proceed);
    } else {
      proceed();
    }
  }

  void _restartLevel(GameController c) {
    VibrationService.tap();
    _resetZoom();
    _resetCombo();
    _prevArrows = -1; // level reload is not a clear
    if (mounted) {
      setState(() {
        _pop = null;
        _comboMsg = null;
        _coinBurst = null;
      });
    }
    c.restartLevel();
    _playEntrance();
  }

  void _handleBoardTap(
    GameController c,
    Offset position, {
    required bool won,
    required bool over,
  }) {
    if (won || over) return;

    final before = c.arrows.length;
    _pendingTapTime = DateTime.now();

    c.onBoardTap(position);

    if (c.arrows.length < before) {
      VibrationService.success();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _syncArrows(c));
  }

  void _onHint(GameController c) {
    if (c.isWon.value || c.isGameOver.value) return;

    // Has a hint: use it. No hints: show the rewarded ad straight away.
    if (c.hintsRemaining.value > 0) {
      c.showHint();
      _showPop(
        icon: Icons.lightbulb_rounded,
        color: const Color(0xFFFFB300),
        big: 'HINT',
        compact: true,
      );
    } else {
      _watchAdForHint(c);
    }
  }

  void _exit(GameController c) {
    VibrationService.tap();
    c.pauseTimer();

    Get.back();
  }

  // ---------------------------------------------------------------------------
  // ZOOM / GRID
  // ---------------------------------------------------------------------------

  void _onZoomTick() {
    final a = _zoomAnim;
    if (a != null) _tc.value = a.value;
  }

  void _animateTo(Matrix4 target) {
    _zoomController.stop();
    _zoomAnim = Matrix4Tween(begin: _tc.value, end: target).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeOutCubic),
    );
    _zoomController.forward(from: 0);
  }

  void _zoomBy(double factor) {
    if (_boardSize.isEmpty) return;
    VibrationService.tap();

    final current = _tc.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(_minZoom, _maxZoom).toDouble();

    if ((target - current).abs() < 0.001) return;

    // Back to 1x: just reset.
    if (target <= _minZoom + 0.001) {
      _animateTo(Matrix4.identity());
      return;
    }

    // Zoom around the centre of the visible area.
    final applied = target / current;
    final focal = _tc.toScene(
      Offset(_boardSize.width / 2, _boardSize.height / 2),
    );

    final m = _tc.value.clone()
      ..translate(focal.dx, focal.dy)
      ..scale(applied)
      ..translate(-focal.dx, -focal.dy);

    // Keep the board covering the viewport (no empty edges).
    final s = m.getMaxScaleOnAxis();
    final tx = m
        .getTranslation()
        .x
        .clamp(_boardSize.width * (1 - s), 0.0)
        .toDouble();
    final ty = m
        .getTranslation()
        .y
        .clamp(_boardSize.height * (1 - s), 0.0)
        .toDouble();
    m.setTranslationRaw(tx, ty, 0);

    _animateTo(m);
  }

  void _zoomIn() => _zoomBy(1.4);

  void _zoomOut() => _zoomBy(1 / 1.4);

  void _resetZoom() {
    _zoomController.stop();
    _tc.value = Matrix4.identity();
  }

  void _toggleGrid() {
    VibrationService.tap();
    final next = !_showGrid;
    setState(() => _showGrid = next);
    GameStorage.saveShowGrid(next);
  }

  void _watchRewardedAd(GameController c) {
    if (!mounted || !c.isGameOver.value || c.isWon.value) return;

    VibrationService.tap();

    _rewardedAdService.showAd(
      onRewardEarned: () {
        if (!mounted) return;
        c.continueAfterRewardedAd();
      },
      onUnavailable: () {
        if (!mounted) return;
        Get.snackbar(
          'Ad not ready',
          'Please try again in a moment.',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      },
      onClosedWithoutReward: () {},
    );
  }

  void _watchAdForHint(GameController c) {
    if (!mounted) return;

    // Pause the countdown during the ad, but only if the player hadn't paused it.
    final pausedByAd = c.timedMode && !c.isPaused.value;
    if (pausedByAd) c.pauseGame();

    void resumeIfNeeded() {
      if (pausedByAd && mounted) c.resumeGame();
    }

    VibrationService.tap();

    _rewardedAdService.showAd(
      onRewardEarned: () {
        if (!mounted) return;
        c.grantHintFromAd(); // +1 hint only
        resumeIfNeeded();
      },
      onUnavailable: () {
        resumeIfNeeded();
        if (!mounted) return;
        Get.snackbar(
          'Ad not ready',
          'Please try again in a moment.',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      },
      onClosedWithoutReward: resumeIfNeeded,
    );
  }

  void _watchAdForBonus(GameController c, double multiplier) {
    if (!mounted || !c.isWon.value || c.bonusClaimed.value) return;

    VibrationService.tap();

    _rewardedAdService.showAd(
      onRewardEarned: () {
        if (!mounted) return;
        c.claimBonusCoins(multiplier);
      },
      onUnavailable: () {
        if (!mounted) return;
        Get.snackbar(
          'Ad not ready',
          'Please try again in a moment.',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      },
      onClosedWithoutReward: () {},
    );
  }

  @override
  void initState() {
    super.initState();
    _rewardedAdService = RewardedAdService();
    _rewardedAdService.loadAd();
    _interstitialAdService = InterstitialAdService();
    _interstitialAdService.loadAd();
    _readArguments();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _topAnim = _interval(0.00, 0.50);
    _statusAnim = _interval(0.10, 0.60);
    _boardAnim = _interval(0.15, 0.85, Curves.easeOutCubic);
    _bottomAnim = _interval(0.40, 1.00);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    )..addListener(_onZoomTick);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final c = Get.find<GameController>();

      c.openLevel(mode: _mode, requestedLevel: _requestedLevel);

      // Detect cleared arrows from the list itself (the controller removes
      // arrows after their exit animation, not inside onBoardTap).
      _prevArrows = c.arrows.length;
      _arrowsWorker = ever(c.arrows, (_) => _syncArrows(c));

      _prevLives = c.lives.value;
      _livesWorker = ever<int>(c.lives, (v) {
        if (v < _prevLives) {
          VibrationService.wrongMove();
          _resetCombo();

          if (mounted) {
            _shakeController.forward(from: 0);
            _showPop(
              icon: Icons.heart_broken_rounded,
              emoji: '💔',
              color: _red,
              big: 'OOPS!',
              label: 'Wrong move',
              compact: true,
            );
          }
        }

        _prevLives = v;
      });

      if (mounted) _playEntrance();
    });
  }

  @override
  void dispose() {
    _comboTimer?.cancel();
    _livesWorker?.dispose();
    _arrowsWorker?.dispose();
    _shakeController.dispose();
    _drawController.dispose();
    _ambientController.dispose();
    _zoomController.dispose();
    _tc.dispose();
    _entranceController.dispose();
    _rewardedAdService.dispose();
    _interstitialAdService.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = Get.find<GameController>();

    return Scaffold(
      body: Stack(
        children: [
          // Premium ambient background
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _AmbientPainter(
                  listenable: _ambientController,
                  isDark: _isDark,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _enter(_topAnim, _topBar(c), dy: -14),

                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        children: [
                          const SizedBox(height: 4),
                          _enter(_statusAnim, _statusCard(c), dy: -10),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: _enter(
                                _boardAnim,
                                _boardCard(c),
                                dy: 20,
                                scale: 0.94,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _enter(_bottomAnim, _dock(c), dy: 20),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Centered action pop (combo / milestone / wrong / hint)
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: const Alignment(0, -0.1),
                child: _pop == null
                    ? const SizedBox.shrink()
                    : _ActionToast(
                        key: ValueKey(_pop!.id),
                        pop: _pop!,
                        onDone: () {
                          if (mounted && _pop != null) {
                            setState(() => _pop = null);
                          }
                        },
                      ),
              ),
            ),
          ),

          // NEW: combo banner at the top, below the top bar
          Positioned(
            top: 132,
            left: 0,
            right: 0,
            child: SafeArea(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _comboMsg == null
                      ? const SizedBox.shrink()
                      : _ComboBanner(
                          key: ValueKey(_comboMsg!.id),
                          msg: _comboMsg!,
                          onDone: () {
                            if (mounted && _comboMsg != null) {
                              setState(() => _comboMsg = null);
                            }
                          },
                        ),
                ),
              ),
            ),
          ),

          // NEW: coin animation in the center
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: const Alignment(0, 0.05),
                child: _coinBurst == null
                    ? const SizedBox.shrink()
                    : _CoinBurst(
                        key: ValueKey(_coinBurst!.id),
                        data: _coinBurst!,
                        onDone: () {
                          if (mounted && _coinBurst != null) {
                            setState(() => _coinBurst = null);
                          }
                        },
                      ),
              ),
            ),
          ),

          // Result dialog covers the whole screen.
          Obx(() {
            final won = c.isWon.value;
            final over = c.isGameOver.value;

            if (!won && !over) {
              return const SizedBox.shrink();
            }

            // Timer mode loses because time has expired.
            final timeUp = !won && c.timedMode && c.timeLeft.value <= 0;

            // Timer and speed modes end on the wrong-move limit, not on lives.
            final limitReached =
                !won && !timeUp && (c.timedMode || _mode == GameMode.speedRun);

            return Positioned.fill(
              child: ResultDialog(
                key: ValueKey('$won-$timeUp-$limitReached'),
                won: won,
                timeUp: timeUp,
                limitReached: limitReached,
                stars: c.resultStars,
                earnedCoins: c.earnedCoins.value,
                coinBalance: c.coinBalance.value,
                title: won
                    ? 'Level cleared!'
                    : timeUp
                    ? "Time's up!"
                    : limitReached
                    ? 'Limit reached'
                    : 'Out of lives',

                message: won
                    ? 'Nice work. Ready for the next one?'
                    : timeUp
                    ? 'The timer ran out before you finished. Try again!'
                    : limitReached
                    ? 'You made ${c.modeConfig.maxWrongClicks} wrong moves. Try again!'
                    : 'That was your last heart. Try again from the start.',

                primaryLabel: won ? 'Next level' : 'Try again',
                secondaryLabel: won ? 'Play again' : 'Start over',

                onPrimary: () {
                  if (won) {
                    _goNextLevel(c);
                  } else {
                    _restartLevel(c);
                  }
                },

                onSecondary: () => _restartLevel(c),
                onHome: () => Get.until((route) => route.isFirst),

                // Show the rewarded-ad button only after all hearts are lost.
                onWatchAd: !won ? () => _watchRewardedAd(c) : null,
                bonusClaimed: c.bonusClaimed.value,
                onWatchAdBonus: won ? (m) => _watchAdForBonus(c, m) : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOP BAR  ( <   LEVEL 3 / name / difficulty   ↻ ⏸ )
  // ---------------------------------------------------------------------------

  Widget _topBar(GameController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: SizedBox(
        height: 56,
        child: Row(
          spacing: 5,
          children: [
            // Back button
            _GlassIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              iconSize: 17,
              color: _blue,
              glass: _glass,
              border: _glassBorder,
              onTap: () => _exit(c),
            ),
            // Restart button
            _GlassIconButton(
              icon: Icons.refresh_rounded,
              color: _blue,
              glass: _glass,
              border: _glassBorder,
              turns: _restartTurns,
              onTap: () {
                setState(() => _restartTurns -= 1);
                _restartLevel(c);
              },
            ),

            // Level pill on the left
            Expanded(
              child: Align(alignment: Alignment.center, child: _levelPill(c)),
            ),

            // Coin balance pill
            Obx(() {
              final coins = c.coinBalance.value;

              return GestureDetector(
                onTap: () {
                  // Get.to(() => const GameStoreScreen());
                },
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: _glass,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _glassBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        coins >= 10000
                            ? '${(coins / 1000).toStringAsFixed(1)}k'
                            : '$coins',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [ui.FontFeature.tabularFigures()],
                        ),
                      ),

                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _levelPill(GameController c) {
    return Obx(() {
      final level = c.level.value;
      final designName = LevelDesigns.forLevel(level).name;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (r) =>
                LinearGradient(colors: [_blue, _violet]).createShader(r),
            child: _AnimatedCount(
              value: 'LEVEL $level',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              designName,
              key: ValueKey('$level-$designName'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // STATUS CARD  ( arrows + progress  |  timer or hearts )
  // ---------------------------------------------------------------------------

  Widget _statusCard(GameController c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _glassBorder),
      ),
      child: Row(
        spacing: 7,
        children: [
          Expanded(
            child: Obx(() {
              final left = c.arrows.length;
              final total = math.max(c.totalArrows.value, left);
              final progress = total > 0
                  ? ((total - left) / total).clamp(0.0, 1.0)
                  : 0.0;

              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'ARROWS',
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$left left',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
                                  ui.FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _GradientProgress(
                          value: progress,
                          track: _textSecondary.withValues(alpha: 0.16),
                          colors: [_blue, _violet],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
          Obx(() => c.timedMode ? _timerChip(c) : _heartsChip(c)),

          // Pause / Play — timer modes only
          Obx(() {
            if (!c.timedMode) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _GlassIconButton(
                icon: c.isPaused.value
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                color: _violet,
                glass: _glass,
                border: _glassBorder,
                onTap: c.togglePause,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _heartsChip(GameController c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < c.modeConfig.startingLives; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutBack,
              scale: i < c.lives.value ? 1.0 : 0.8,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 140),
                transitionBuilder: (ch, a) =>
                    ScaleTransition(scale: a, child: ch),
                child: Icon(
                  i < c.lives.value
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(i < c.lives.value),
                  color: i < c.lives.value
                      ? _red
                      : _textSecondary.withValues(alpha: 0.35),
                  size: 23,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _timerChip(GameController c) {
    final left = c.timeLeft.value;
    final urgent = left <= 10 && !c.isWon.value;
    final color = urgent ? _red : _blue;

    final minutes = (left ~/ 60).toString().padLeft(2, '0');
    final seconds = (left % 60).toString().padLeft(2, '0');

    return AnimatedScale(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      scale: urgent && left.isOdd ? 1.1 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, color: color, size: 18),
            const SizedBox(width: 5),
            Text(
              '$minutes:$seconds',
              style: TextStyle(
                color: color,
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                fontFeatures: const [ui.FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOARD
  // ---------------------------------------------------------------------------

  Widget _boardCard(GameController c) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = math.max(1, c.gridCols);
        final rows = math.max(1, c.gridRows);
        final aspect = (cols / rows).clamp(0.55, 1.45).toDouble();

        final availableWidth = math.max(0.0, constraints.maxWidth - 20);
        final availableHeight = math.max(0.0, constraints.maxHeight - 8);

        var width = availableWidth;
        var height = width / aspect;

        if (height > availableHeight) {
          height = availableHeight;
          width = height * aspect;
        }

        final radius = (math.min(width, height) * 0.055)
            .clamp(12.0, 22.0)
            .toDouble();

        return Center(
          child: AnimatedBuilder(
            animation: _shakeController,
            builder: (_, child) {
              final t = _shakeController.value;
              final dx = math.sin(t * math.pi * 6) * (1 - t) * 9;
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: _board(c),
            ),
          ),
        );
      },
    );
  }

  /// The zoom viewer and the stack are built once. Only the layers inside
  /// react to the game state (dots and arrows), each in its own Obx, so an
  /// arrow animation frame no longer rebuilds the whole board.
  Widget _board(GameController c) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = Size(constraints.maxWidth, constraints.maxHeight);
        _boardSize = boardSize;

        return InteractiveViewer(
          transformationController: _tc,
          minScale: _minZoom,
          maxScale: _maxZoom,
          panEnabled: true,
          scaleEnabled: true,
          constrained: true,
          clipBehavior: Clip.hardEdge,
          boundaryMargin: EdgeInsets.zero,
          child: SizedBox(
            width: boardSize.width,
            height: boardSize.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Grid lines layer (vertical + horizontal), fades in/out.
                // Plain widget: no Obx, driven by _showGrid via setState.
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _showGrid ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: GridLinesPainter(
                          cols: c.gridCols,
                          rows: c.gridRows,
                          isDark: _isDark,
                        ),
                      ),
                    ),
                  ),
                ),

                Obx(() {
                  final cells = c.visibleDotCells.toSet();

                  return AnimatedDotGrid(
                    cols: c.gridCols,
                    rows: c.gridRows,
                    visible: cells,
                    isDark: _isDark,
                    dotScale: 0.10,
                  );
                }),

                // Arrow layer: repaints on its own every animation frame.
                Obx(() {
                  final current = c.arrows.toList(growable: false);
                  final won = c.isWon.value;
                  final over = c.isGameOver.value;
                  final highlightedArrow = c.hintArrow.value;

                  // Safety net: catches clears even if the list worker misses.
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _syncArrows(c),
                  );

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      if (won ||
                          over ||
                          boardSize.width <= 0 ||
                          boardSize.height <= 0) {
                        return;
                      }

                      final position = details.localPosition;

                      _handleBoardTap(
                        c,
                        Offset(
                          position.dx / boardSize.width,
                          position.dy / boardSize.height,
                        ),
                        won: won,
                        over: over,
                      );
                    },
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: ArrowPainter(
                          arrows: current,
                          isDark: _isDark,
                          gridRows: c.gridRows,
                          gridCols: c.gridCols,
                          appearanceProgress: 1.0,
                          appearance: _drawController,
                          hintArrow: highlightedArrow,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DOCK  ( 💡  grid  +  - )
  // ---------------------------------------------------------------------------

  Widget _dock(GameController c) {
    return Obx(() {
      final remaining = c.hintsRemaining.value;

      return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: _glass,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DockButton(
              icon: Icons.lightbulb_rounded,
              color: const Color(0xFFFFB300),
              badge: remaining > 0 ? '$remaining' : 'AD',
              badgeColor: remaining > 0 ? _blue : _red,
              onTap: () => _onHint(c),
            ),
            const SizedBox(width: 8),
            _DockButton(
              icon: Icons.grid_4x4_rounded,
              color: _showGrid ? _blue : _textSecondary,
              active: _showGrid,
              onTap: _toggleGrid,
            ),
            const SizedBox(width: 8),
            _DockButton(
              icon: Icons.zoom_in_rounded,
              color: _blue,
              onTap: _zoomIn,
            ),
            const SizedBox(width: 8),
            _DockButton(
              icon: Icons.zoom_out_rounded,
              color: _blue,
              onTap: _zoomOut,
            ),
          ],
        ),
      );
    });
  }
}

// =============================================================================
// ACTION POP (center-screen combo / milestone toast)
// =============================================================================

class _ActionPop {
  final int id;
  final IconData icon;
  final String? emoji;
  final Color color;
  final String big;
  final String? label;
  final bool compact;

  const _ActionPop({
    required this.id,
    required this.icon,
    this.emoji,
    required this.color,
    required this.big,
    this.label,
    this.compact = false,
  });
}

class _ActionToast extends StatefulWidget {
  final _ActionPop pop;
  final VoidCallback onDone;

  const _ActionToast({super.key, required this.pop, required this.onDone});

  @override
  State<_ActionToast> createState() => _ActionToastState();
}

class _ActionToastState extends State<_ActionToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<double> _lift;
  late final Animation<double> _tilt;

  @override
  void initState() {
    super.initState();

    final ms = widget.pop.compact ? 800 : 1100;

    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    )..forward().whenComplete(widget.onDone);

    // Pop in with overshoot, hold, then shrink slightly while fading out.
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.3,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 35,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.9,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_c);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_c);

    _lift = Tween<double>(
      begin: 12,
      end: -46,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_c);

    _tilt = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.04), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.04, end: 0.0), weight: 70),
    ]).animate(_c);

    // Emoji pops in with a bounce, slightly after the badge appears.
    _emojiScale = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.08, 0.55, curve: Curves.elasticOut),
    );

    // Emoji slides up from below into the centre of the badge.
    _emojiSlide = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.05, 0.45, curve: Curves.easeOutBack),
      ),
    );
  }

  late final Animation<double> _emojiScale;
  late final Animation<double> _emojiSlide;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pop;
    final compact = p.compact;

    final iconBox = compact ? 40.0 : 64.0;
    final iconSize = compact ? 34.0 : 48.0;
    final bigSize = compact ? 22.0 : (p.big.length > 4 ? 30.0 : 58.0);

    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        return Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, _lift.value),
            child: Transform.rotate(
              angle: _tilt.value,
              child: Transform.scale(
                scale: _scale.value,
                child: compact
                    ? _compactBody(p, iconBox, iconSize, bigSize)
                    : _bigBody(p, iconBox, iconSize, bigSize),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _iconBadge(_ActionPop p, double box, double size) {
    // U+FE0F forces the coloured emoji form instead of a plain text glyph.
    final emoji = p.emoji == null
        ? null
        : '${p.emoji!.replaceAll('\uFE0F', '')}\uFE0F';

    return SizedBox(
      width: box,
      height: box,
      child: Center(
        child: emoji != null
            ? AnimatedBuilder(
                animation: _c,
                builder: (_, child) {
                  return Transform.translate(
                    offset: Offset(0, _emojiSlide.value),
                    child: Transform.scale(
                      scale: _emojiScale.value,
                      child: child,
                    ),
                  );
                },
                child: Text(
                  emoji,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: size,
                    height: 1.0,
                    decoration: TextDecoration.none,
                  ),
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                ),
              )
            // No emoji: use the pop's own colour, not the default white icon.
            : Icon(p.icon, size: size, color: p.color),
      ),
    );
  }

  TextStyle _outlined(double size, Color color) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
    color: color,
    height: 1.0,
    decoration: TextDecoration.none,
  );

  Widget _bigBody(_ActionPop p, double box, double iconSize, double bigSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconBadge(p, box, iconSize),
        const SizedBox(height: 6),
        Text(p.big, style: _outlined(bigSize, Colors.white)),
        if (p.label != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: p.color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              p.label!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _compactBody(
    _ActionPop p,
    double box,
    double iconSize,
    double bigSize,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 18, 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBadge(p, box, iconSize),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.big, style: _outlined(bigSize, Colors.white)),
              if (p.label != null)
                Text(
                  p.label!,
                  style: TextStyle(
                    color: p.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    decoration: TextDecoration.none,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// PREMIUM COMBO BANNER — OPEN ANIMATED DESIGN
class _ComboMsg {
  final int id;
  final String emoji;
  final Color color;
  final String title;
  final int streak;

  const _ComboMsg({
    required this.id,
    required this.emoji,
    required this.color,
    required this.title,
    required this.streak,
  });
}

class _ComboBanner extends StatefulWidget {
  final _ComboMsg msg;
  final VoidCallback onDone;

  const _ComboBanner({
    super.key,
    required this.msg,
    required this.onDone,
  });

  @override
  State<_ComboBanner> createState() => _ComboBannerState();
}

class _ComboBannerState extends State<_ComboBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  late final Animation<double> _opacity;
  late final Animation<double> _exitSlide;

  late final Animation<double> _iconScale;
  late final Animation<double> _iconRotation;
  late final Animation<double> _iconSlide;

  late final Animation<double> _titleSlide;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleScale;

  late final Animation<double> _subtitleSlide;
  late final Animation<double> _subtitleOpacity;

  late final Animation<double> _streakScale;
  late final Animation<double> _streakOpacity;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    // -----------------------------------------------------------------------
    // Overall visibility.
    // -----------------------------------------------------------------------

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1),
        weight: 78,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(
          CurveTween(curve: Curves.easeInCubic),
        ),
        weight: 12,
      ),
    ]).animate(_c);

    _exitSlide = Tween<double>(
      begin: 0,
      end: -12,
    ).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(
          0.88,
          1.0,
          curve: Curves.easeInCubic,
        ),
      ),
    );

    // -----------------------------------------------------------------------
    // Large emoji entrance.
    // -----------------------------------------------------------------------

    _iconScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.35,
          end: 1.15,
        ).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 75,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.15,
          end: 1.0,
        ).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 25,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.0, 0.25),
      ),
    );

    _iconRotation = Tween<double>(
      begin: -0.20,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(
          0.0,
          0.26,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _iconSlide = Tween<double>(
      begin: 18,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(
          0.0,
          0.24,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // -----------------------------------------------------------------------
    // Main title entrance.
    // -----------------------------------------------------------------------

    _titleSlide = Tween<double>(
      begin: 24,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(
          0.08,
          0.32,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _titleOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(
          0.08,
          0.22,
          curve: Curves.easeOut,
        ),
      ),
    );

    _titleScale = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(
          0.08,
          0.30,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // -----------------------------------------------------------------------
    // Subtitle entrance.
    // -----------------------------------------------------------------------

    _subtitleSlide = Tween<double>(
      begin: 10,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(
          0.17,
          0.36,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _subtitleOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(
          0.17,
          0.30,
          curve: Curves.easeOut,
        ),
      ),
    );

    // -----------------------------------------------------------------------
    // Combo count entrance.
    // -----------------------------------------------------------------------

    _streakScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.65,
          end: 1.12,
        ).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.12,
          end: 1,
        ).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 30,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(
          0.22,
          0.43,
        ),
      ),
    );

    _streakOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(
          0.22,
          0.34,
          curve: Curves.easeOut,
        ),
      ),
    );

    _c.forward().whenComplete(() {
      if (mounted) {
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.msg;
    final Color accent = m.color;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, _exitSlide.value),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // =========================================================
                  // LARGE ANIMATED EMOJI
                  // =========================================================

                  Transform.translate(
                    offset: Offset(0, _iconSlide.value),
                    child: Transform.rotate(
                      angle: _iconRotation.value,
                      child: Transform.scale(
                        scale: _iconScale.value,
                        child: Text(
                          m.emoji.replaceAll('\uFE0F', ''),
                          style: const TextStyle(
                            fontSize: 42,
                            height: 1.05,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // =========================================================
                  // TITLE + SUBTITLE
                  // =========================================================

                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main title
                        Opacity(
                          opacity: _titleOpacity.value.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(_titleSlide.value, 0),
                            child: Transform.scale(
                              alignment: Alignment.centerLeft,
                              scale: _titleScale.value,
                              child: Text(
                                m.title.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.15,
                                  height: 1.05,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 7),

                        // Supporting text
                        Opacity(
                          opacity: _subtitleOpacity.value.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(_subtitleSlide.value, 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  m.streak > 1
                                      ? 'COMBO STREAK'
                                      : 'PERFECT MOVE',
                                  style: TextStyle(
                                    color: accent.withValues(alpha: 0.80),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.7,
                                    height: 1.1,
                                    decoration: TextDecoration.none,
                                  ),
                                ),

                                if (m.streak > 1) ...[
                                  const SizedBox(width: 10),

                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.65),
                                      shape: BoxShape.circle,
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // Animated streak number
                                  Opacity(
                                    opacity: _streakOpacity.value.clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    child: Transform.scale(
                                      scale: _streakScale.value,
                                      child: Text(
                                        'x${m.streak}',
                                        style: TextStyle(
                                          color: accent,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.4,
                                          height: 1.0,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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

// COIN BURST (center)
// =============================================================================
class _CoinBurstData {
  final int id;
  final int coins;

  const _CoinBurstData({required this.id, required this.coins});
}

class _CoinBurst extends StatefulWidget {
  final _CoinBurstData data;
  final VoidCallback onDone;

  const _CoinBurst({super.key, required this.data, required this.onDone});

  @override
  State<_CoinBurst> createState() => _CoinBurstState();
}

class _CoinBurstState extends State<_CoinBurst>
    with SingleTickerProviderStateMixin {
  static const _gold = Color(0xFFFFC857);
  static const int _particles = 10;

  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _seg(double a, double b, Curve curve) =>
      curve.transform(((_c.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final t = _c.value;

          // Whole effect fades out at the end.
          final fade = t > 0.78 ? (1 - (t - 0.78) / 0.22) : 1.0;

          final mainScale = _seg(0.0, 0.40, Curves.elasticOut);
          final spin = _seg(0.0, 0.65, Curves.easeOutCubic) * math.pi * 4;
          final lift = -_seg(0.0, 1.0, Curves.easeOutCubic) * 26;
          final burst = _seg(0.12, 0.80, Curves.easeOutCubic);
          final textIn = _seg(0.20, 0.50, Curves.easeOutBack);

          return Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Soft golden glow
                Container(
                  width: 150 * mainScale,
                  height: 150 * mainScale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _gold.withValues(alpha: 0.45),
                        _gold.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),

                // Small coins flying outward
                for (var i = 0; i < _particles; i++)
                  Builder(
                    builder: (_) {
                      final angle = (i / _particles) * 2 * math.pi;
                      final dist = (70 + (i.isEven ? 30 : 0)) * burst;
                      final size = i.isEven ? 22.0 : 16.0;

                      return Transform.translate(
                        offset: Offset(
                          math.cos(angle) * dist,
                          math.sin(angle) * dist + lift,
                        ),
                        child: Opacity(
                          opacity: (1 - burst).clamp(0.0, 1.0),
                          child: Transform.rotate(
                            angle: angle + burst * math.pi,
                            child: Icon(
                              Icons.monetization_on_rounded,
                              color: _gold,
                              size: size,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // Main spinning coin
                Transform.translate(
                  offset: Offset(0, lift),
                  child: Transform.scale(
                    scale: mainScale,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateY(spin),
                      child: const Icon(
                        Icons.monetization_on_rounded,
                        color: _gold,
                        size: 88,
                        shadows: [
                          Shadow(color: Color(0x66FF9A00), blurRadius: 18),
                        ],
                      ),
                    ),
                  ),
                ),

                // +N text
                Transform.translate(
                  offset: Offset(0, 66 + lift),
                  child: Transform.scale(
                    scale: textIn,
                    child: Text(
                      '+${widget.data.coins}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        decoration: TextDecoration.none,
                        shadows: [
                          Shadow(color: Color(0xFFFF9A00), blurRadius: 12),
                          Shadow(color: Colors.black38, blurRadius: 4),
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
    );
  }
}

// =============================================================================
// AMBIENT BACKGROUND  (gradient + slowly drifting glow orbs)
// =============================================================================

class _AmbientPainter extends CustomPainter {
  final Animation<double> listenable;
  final bool isDark;

  _AmbientPainter({required this.listenable, required this.isDark})
    : super(repaint: listenable);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF12142B), Color(0xFF1A1D38)]
              : const [Color(0xFFF4F7FF), Color(0xFFE6ECFF)],
        ).createShader(rect),
    );

    final t = listenable.value * 2 * math.pi;
    final r = size.shortestSide;

    void orb(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    orb(
      Offset(
        size.width * (0.15 + 0.06 * math.sin(t)),
        size.height * (0.12 + 0.04 * math.cos(t)),
      ),
      r * 0.75,
      const Color(0xFF2F80FF).withValues(alpha: isDark ? 0.22 : 0.16),
    );
    orb(
      Offset(
        size.width * (0.90 + 0.05 * math.cos(t + 1)),
        size.height * (0.55 + 0.05 * math.sin(t + 2)),
      ),
      r * 0.8,
      const Color(0xFF7B61FF).withValues(alpha: isDark ? 0.20 : 0.14),
    );
    orb(
      Offset(
        size.width * (0.30 + 0.06 * math.sin(t + 3)),
        size.height * (0.95 + 0.03 * math.cos(t + 1)),
      ),
      r * 0.7,
      const Color(0xFF1ED6C3).withValues(alpha: isDark ? 0.14 : 0.10),
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter old) => old.isDark != isDark;
}

// =============================================================================
// GRADIENT PROGRESS BAR
// =============================================================================

class _GradientProgress extends StatelessWidget {
  final double value;
  final Color track;
  final List<Color> colors;

  const _GradientProgress({
    required this.value,
    required this.track,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Container(
          height: 9,
          decoration: BoxDecoration(
            color: track,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: v.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(colors: colors),
                  boxShadow: [
                    BoxShadow(
                      color: colors.last.withValues(alpha: 0.45),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// ANIMATED COUNT (level title)
// =============================================================================

class _AnimatedCount extends StatelessWidget {
  final String value;
  final TextStyle style;

  const _AnimatedCount({required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 130),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: anim, child: child),
      ),
      child: Text(value, key: ValueKey(value), style: style),
    );
  }
}

// GLASS ICON BUTTON (top bar)
class _GlassIconButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final Color color;
  final Color glass;
  final Color border;
  final double turns;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.color,
    required this.glass,
    required this.border,
    required this.onTap,
    this.iconSize = 24,
    this.turns = 0,
  });

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: widget.glass,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: widget.border),
          ),
          child: Center(
            child: AnimatedRotation(
              turns: widget.turns,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// DOCK BUTTON (hint / grid / zoom)
class _DockButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool active;
  final String? badge;
  final Color badgeColor;
  final VoidCallback onTap;

  const _DockButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.active = false,
    this.badge,
    this.badgeColor = const Color(0xFF2F80FF),
  });

  @override
  State<_DockButton> createState() => _DockButtonState();
}

class _DockButtonState extends State<_DockButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: widget.active
                        ? widget.color.withValues(alpha: 0.16)
                        : widget.color.withValues(alpha: 0.08),
                    border: Border.all(
                      color: widget.color.withValues(
                        alpha: widget.active ? 0.45 : 0.18,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Icon(widget.icon, size: 29, color: widget.color),
                  ),
                ),
              ),
              if (widget.badge != null)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.badgeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      widget.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
