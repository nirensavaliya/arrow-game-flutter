import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../animation/arrow_motion.dart';
import '../model/arrow_model.dart';
import '../modes/game_mode.dart';
import '../modes/game_mode_config.dart';
import '../screen/level/level_design.dart';
import '../services/game_storage.dart';
import '../services/vibration_service.dart';

class GameController extends GetxController {
  static const double boardAspect = 0.82;

  // Timed Challenge tuning.
  static const int _baseTimeSeconds = 15;
  static const int _timePerArrowMs = 1200;
  static const int _minTimeSeconds = 15;
  static const int _maxTimeSeconds = 400;

  // Extra time based on playable cells and level complexity.
  static const double _timePerCellSeconds = 0.10;
  static const double _timePerComplexitySeconds = 0.8;

  // Speed Run duration comes from GameModeConfig.
  int get speedRunDurationSeconds =>
      GameModeConfig.forMode(GameMode.speedRun).sessionDurationSeconds;

  final wrongClicks = 0.obs;

  final level = 1.obs;
  final moves = 0.obs;
  final lives = 3.obs;
  final arrows = <ArrowModel>[].obs;

  final isWon = false.obs;
  final isGameOver = false.obs;
  final isAnimating = false.obs;
  final isPaused = false.obs;

  final message = 'Tap an arrow to clear its path'.obs;

  final totalArrows = 0.obs;
  final levelTitle = ''.obs;
  final levelCategory = ''.obs;

  final selectedMode = GameMode.normal.obs;

  GameModeConfig get modeConfig => GameModeConfig.forMode(selectedMode.value);

  bool get timedMode => modeConfig.hasTimer;

  bool get isTimedChallenge => selectedMode.value == GameMode.timedChallenge;

  bool get isSpeedRun => selectedMode.value == GameMode.speedRun;

  final levelsCompleted = 0.obs;
  final timeLeft = 0.obs;
  final totalTime = 0.obs;

  Timer? _timer;

  int _rows = 6;
  int _cols = 5;

  int get gridRows => _rows;

  int get gridCols => _cols;

  Set<int> maskCells = {};

  final RxSet<int> visibleDotCells = <int>{}.obs;

  int _generation = 0;
  int _running = 0;

  // Changes the arrow layout on restart. The design stays the same.
  int _variant = 0;

  // Hint system: no free hints, they are earned by watching rewarded ads.
  static const int initialHints = 0;
  static const int hintsPerAd = 1;

  // Seconds given by the "Watch Ad & Continue" button after time is up.
  static const double adBonusSec = 0.5;

  final hintsRemaining = initialHints.obs;
  final Rxn<ArrowModel> hintArrow = Rxn<ArrowModel>();

  Timer? _hintTimer;

  // Coins
  final earnedCoins = 0.obs; // reward of the level just won (shown in dialog)
  final coinBalance = 0.obs; // total across all modes
  final comboCoins = 0.obs; // combo coins collected in the current attempt
  bool _coinEligible = true; // false when this level already paid in this mode
  bool _rewardPaid = false;

  static int comboCoinsFor(int streak) {
    if (streak >= 10) return 5;
    if (streak >= 7) return 4;
    if (streak >= 5) return 3;
    if (streak >= 4) return 2;
    return 0; // combo 2 and 3 give no coins
  }

  /// Coins paid for clearing a level for the first time.
  ///
  /// Starts at 5 coins and goes up by 2 every 5 levels:
  ///   levels 1-4   -> 5
  ///   levels 5-9   -> 7
  ///   levels 10-14 -> 9
  ///   levels 20-24 -> 13
  ///   levels 90+   -> 40 (cap)
  ///
  /// Combo coins are added on top of this (see comboCoinsFor).
  int _baseReward(int lvl) =>
      (5 + (lvl ~/ 5) * 2) // 5 base + 2 for every completed block of 5 levels
          .clamp(5, 40) // never below 5, never above 40
          .toInt(); // clamp returns num, so convert back to int

  /// Called by the screen when a combo streak finishes.
  /// Returns the coins granted (0 on a replayed level).
  int addComboCoins(int streak) {
    if (!_coinEligible || streak < 4) return 0;

    final coins = comboCoinsFor(streak);
    if (coins <= 0) return 0;

    if (_rewardPaid) {
      // Level already won (last arrow's streak arrives after the win).
      earnedCoins.value += coins;
      unawaited(GameStorage.addCoins(coins));
      coinBalance.value = GameStorage.totalCoins();
    } else {
      comboCoins.value += coins;
    }
    return coins;
  }

  void _payLevelReward() {
    if (!_coinEligible || _rewardPaid) {
      earnedCoins.value = 0;
      coinBalance.value = GameStorage.totalCoins();
      return;
    }

    _rewardPaid = true;

    final total = _baseReward(level.value) + comboCoins.value;
    earnedCoins.value = total;

    unawaited(
      GameStorage.claimLevelCoins(
        mode: selectedMode.value.name,
        level: level.value,
        coins: total,
      ),
    );

    coinBalance.value = GameStorage.totalCoins();
  }

  // Arrows currently playing the bump animation.
  final Set<int> _bumping = <int>{};

  @override
  void onInit() {
    super.onInit();
    coinBalance.value = GameStorage.totalCoins();
    _restoreProgress(GameMode.normal);
  }

  @override
  void onClose() {
    _hintTimer?.cancel();
    _stopTimer();
    super.onClose();
  }

  /// Highlights a safe arrow for 3 seconds.
  void showHint() {
    if (isWon.value || isGameOver.value) return;

    if (hintsRemaining.value <= 0) {
      Get.snackbar(
        'No Hints Left',
        'You have used all your hints.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Cancel any previous hint.
    _hintTimer?.cancel();
    hintArrow.value = null;

    // Find an active arrow with a clear exit path.
    ArrowModel? candidate;

    for (var i = 0; i < arrows.length; i++) {
      final arrow = arrows[i];

      if (!arrow.isActive || arrow.isMoving || arrow.isBlocked) {
        continue;
      }

      if (_isPathBlocked(i)) {
        continue;
      }

      candidate = arrow;
      break;
    }

    if (candidate == null) {
      Get.snackbar(
        'No Hint Available',
        'Try again after the current animations finish.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Consume one hint and highlight the safe arrow.
    hintsRemaining.value--;
    hintArrow.value = candidate;

    VibrationService.success();

    // Remove the highlight automatically after 3 seconds.
    _hintTimer = Timer(const Duration(seconds: 3), () {
      if (!isClosed) {
        hintArrow.value = null;
      }
    });
  }

  // Clears the current arrow highlight.
  void clearHint() {
    _hintTimer?.cancel();
    _hintTimer = null;
    hintArrow.value = null;
  }

  /// Called after the player earns a rewarded ad. Gives only 1 hint.
  void grantHintFromAd() {
    hintsRemaining.value += hintsPerAd;
    message.value = 'You got $hintsPerAd hint!';
    VibrationService.success();
  }

  // Progress storage
  void _restoreProgress(GameMode mode) {
    _stopTimer();

    selectedMode.value = mode;

    final saved = GameStorage.loadProgress(mode.name);

    level.value = (saved?['level'] as num?)?.toInt() ?? 1;

    levelsCompleted.value = (saved?['levelsCompleted'] as num?)?.toInt() ?? 0;

    // Reset temporary state for the newly opened mode.
    wrongClicks.value = 0;
    moves.value = 0;
    lives.value = GameModeConfig.forMode(mode).startingLives;

    isWon.value = false;
    isGameOver.value = false;
    isAnimating.value = false;

    if (mode == GameMode.speedRun) {
      final duration = GameModeConfig.forMode(mode).sessionDurationSeconds;

      totalTime.value = duration;
      timeLeft.value = duration;
    } else {
      totalTime.value = 0;
      timeLeft.value = 0;
    }

    loadLevel(startNewSession: true);
  }

  Future<void> _saveProgress({bool completedLevel = false}) async {
    await GameStorage.saveProgress(
      level: completedLevel ? level.value + 1 : level.value,
      mode: selectedMode.value.name,
      levelsCompleted: levelsCompleted.value,
    );
  }

  Future<void> resetAllProgress() async {
    _stopTimer();

    // Invalidate animations currently running.
    _generation++;

    await Future.wait([
      GameStorage.clearProgress(GameMode.normal.name),
      GameStorage.clearProgress(GameMode.timedChallenge.name),
      GameStorage.clearProgress(GameMode.speedRun.name),
    ]);

    if (isClosed) return;

    // Reset the active mode and reload Level 1.
    _restoreProgress(selectedMode.value);
  }

  // Game mode and timer
  void startMode(GameMode mode) {
    // Restore this mode's own saved progress instead of resetting to Level 1.
    _restoreProgress(mode);
  }

  // Pause the countdown in Timed Challenge and Speed Run.
  void pauseGame() {
    if (!timedMode) return;
    if (isPaused.value || isWon.value || isGameOver.value) return;

    isPaused.value = true;
    _stopTimer();

    VibrationService.tap();
  }

  // Resume the countdown from the remaining time.
  void resumeGame() {
    if (!timedMode) return;
    if (!isPaused.value || isWon.value || isGameOver.value) return;

    isPaused.value = false;
    _startTimer();

    VibrationService.tap();
  }

  // Toggle between paused and running states.
  void togglePause() {
    if (isPaused.value) {
      resumeGame();
    } else {
      pauseGame();
    }
  }

  /// Stop the timer when leaving the game screen.
  void pauseTimer() {
    _stopTimer();
    isPaused.value = false;
  }

  int _timeForLevel(int lvl, int arrowCount) {
    final design = LevelDesigns.forLevel(lvl);
    final grid = design.toGrid(boardAspect);
    final cellCount = grid.allowed.length;

    var seconds = _baseTimeSeconds;

    seconds += (arrowCount * _timePerArrowMs / 1000).round();
    seconds += (cellCount * _timePerCellSeconds).round();

    final difficulty = LevelDesigns.difficultyForLevel(lvl);

    switch (difficulty) {
      case 'Tutorial':
        seconds += 5;
        break;
      case 'Very Easy':
        seconds += 2;
        break;
      case 'Easy':
        seconds += 3;
        break;
      case 'Easy+':
        seconds += 5;
        break;
      case 'Normal':
        seconds += 7;
        break;
      case 'Medium':
        seconds += 10;
        break;
      case 'Medium-Hard':
        seconds += 15;
        break;
      case 'Hard':
        seconds += 20;
        break;
      case 'Very Hard':
        seconds += 25;
        break;
      case 'Expert':
        seconds += 30;
        break;
    }

    seconds += (math.max(0, lvl - 1) * _timePerComplexitySeconds).round();

    return seconds.clamp(_minTimeSeconds, _maxTimeSeconds).toInt();
  }

  void _startTimer() {
    _stopTimer();

    if (!timedMode ||
        timeLeft.value <= 0 ||
        isGameOver.value ||
        isWon.value ||
        isPaused.value) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed || isGameOver.value || isWon.value || isPaused.value) {
        _stopTimer();
        return;
      }

      timeLeft.value = math.max(0, timeLeft.value - 1);

      if (timeLeft.value <= 0) {
        _timeUp();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _timeUp() {
    if (isGameOver.value) return;

    _stopTimer();

    timeLeft.value = 0;
    isWon.value = false;
    isGameOver.value = true;

    message.value = isSpeedRun
        ? 'Speed Run finished! Time is up.'
        : 'Time is up! Restart and try again.';

    VibrationService.gameOver();
  }

  // Five-star rating system.
  int get resultStars {
    if (!isWon.value) return 0;

    final total = totalTime.value;
    final ratio = total <= 0 ? 0.0 : timeLeft.value / total;

    if (isSpeedRun) {
      if (ratio >= 0.75) return 5;
      if (ratio >= 0.50) return 4;
      if (ratio >= 0.35) return 3;
      if (ratio >= 0.20) return 2;
      return 1;
    }

    if (isTimedChallenge) {
      if (wrongClicks.value == 0 && ratio >= 0.75) return 5;
      if (ratio >= 0.50 && wrongClicks.value <= 1) return 4;
      if (ratio >= 0.25 && wrongClicks.value <= 2) return 3;
      if (ratio > 0 && wrongClicks.value <= 4) return 2;
      return 1;
    }

    // Normal Mode rewards a clean clear and remaining lives.
    final mistakes = math.max(0, moves.value - totalArrows.value);

    if (lives.value >= modeConfig.startingLives && mistakes == 0) {
      return 5;
    }
    if (lives.value >= 2 && mistakes <= 1) return 4;
    if (lives.value >= 1 && mistakes <= 2) return 3;
    if (lives.value >= 1 && mistakes <= 4) return 2;

    return 1;
  }

  // Level loading
  //
  // [newLayout] = true (restart) builds a different arrow layout on the same
  // design. Any other load resets to the level's default layout.
  void loadLevel({bool startNewSession = false, bool newLayout = false}) {
    // Do not allow a finished Speed Run to be revived by loading
    // another level. Start a new run through startMode().
    if (isSpeedRun && isGameOver.value && !startNewSession && !newLayout) {
      return;
    }

    // Restart = new arrow layout. Any other load = default layout.
    _variant = newLayout ? _variant + 1 : 0;

    // Stop the previous level's timer before loading the next level.
    _stopTimer();
    clearHint();

    _generation++;
    _running = 0;
    _bumping.clear();

    moves.value = 0;
    lives.value = modeConfig.startingLives;

    // Timed Challenge resets wrong clicks each level.
    // Speed Run retains wrong clicks across levels.
    if (!isSpeedRun) {
      wrongClicks.value = 0;
    }

    isWon.value = false;
    isGameOver.value = false;
    isAnimating.value = false;
    isPaused.value = false;

    // Coins: only the first clear of this level in THIS mode pays.
    earnedCoins.value = 0;
    comboCoins.value = 0;
    _rewardPaid = false;
    _coinEligible = !GameStorage.isCoinLevelClaimed(
      selectedMode.value.name,
      level.value,
    );
    coinBalance.value = GameStorage.totalCoins();

    message.value = 'Tap an arrow to clear its path';

    visibleDotCells.clear();

    arrows.assignAll(_generateLevel(level.value));
    totalArrows.value = arrows.length;

    if (isSpeedRun) {
      final duration = modeConfig.sessionDurationSeconds;

      totalTime.value = duration;
      timeLeft.value = duration;
      _startTimer();
    } else if (isTimedChallenge) {
      totalTime.value = _timeForLevel(level.value, arrows.length);
      timeLeft.value = totalTime.value;
      _startTimer();
    } else {
      totalTime.value = 0;
      timeLeft.value = 0;
    }
  }

  void _startRun() {
    _running++;
    isAnimating.value = true;
  }

  void _endRun(int gen) {
    if (gen != _generation) return;

    _running = math.max(0, _running - 1);
    isAnimating.value = _running > 0;
  }

  bool _alive(int gen) => !isClosed && gen == _generation;

  int _indexOf(List<Offset> points) {
    return arrows.indexWhere((a) => identical(a.points, points));
  }

  // Dot reveal
  void _revealArrowDots(ArrowModel arrow) {
    if (_cols <= 0 || _rows <= 0) return;

    final cells = <int>{};

    for (final point in arrow.points) {
      final col = (point.dx * _cols - 0.5).round();
      final row = (point.dy * _rows - 0.5).round();

      if (col < 0 || col >= _cols || row < 0 || row >= _rows) {
        continue;
      }

      final cell = row * _cols + col;

      if (maskCells.contains(cell)) {
        cells.add(cell);
      }
    }

    visibleDotCells.addAll(cells);
  }

  void _revealArrowDotsProgress(ArrowModel arrow, double progress) {
    if (_cols <= 0 || _rows <= 0 || arrow.points.isEmpty) return;

    final normalizedProgress = progress.clamp(0.0, 1.0);
    final pointCount = arrow.points.length;

    final visibleCount = math.max(1, (pointCount * normalizedProgress).ceil());

    final cells = <int>{};

    for (var i = 0; i < visibleCount && i < pointCount; i++) {
      final point = arrow.points[i];

      final col = (point.dx * _cols - 0.5).round();
      final row = (point.dy * _rows - 0.5).round();

      if (col < 0 || col >= _cols || row < 0 || row >= _rows) {
        continue;
      }

      final cell = row * _cols + col;

      if (maskCells.contains(cell)) {
        cells.add(cell);
      }
    }

    visibleDotCells.addAll(cells);
  }

  // ===========================================================================
  // LEVEL GENERATION
  //
  //  * Arrow count follows the level curve but is never lower than what keeps
  //    every arrow short enough (cells / maxPathLength).
  //  * Several attempts are made; the one with the exact arrow count, the
  //    fewest uncovered cells and a free-arrow count nearest the target wins.
  //  * The winner is then tuned by reversing individual arrows until the
  //    number of arrows that are OPEN at the start (free to tap) falls inside
  //    the target range for the level AND its design:
  //
  //        open target = open count(level) * design factor
  //
  //    The open count falls smoothly as levels rise (level 23 = about 5 to 6
  //    open arrows). Thin or holey designs get more open arrows, because
  //    their exit rays are naturally less blocked.
  //
  //  * Every tuning step is checked, so the level always stays solvable.
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // OPEN ARROWS AT THE START (level wise + design wise)
  //
  // The number of arrows that are free to tap when the level begins comes from
  // two things:
  //
  //   1. A level table. It says how many open arrows a typical design gets on
  //      that level. Early levels start with more, later levels with fewer.
  //      Level 23 is 5.5, so a typical design opens 5 to 6 arrows there.
  //
  //   2. A design factor. Designs with a lot of exposed edge (thin parts,
  //      holes, slits) have more arrows that are naturally free, so they get
  //      more open arrows. Solid, compact designs get fewer.
  //
  //        open target = table(level) * design factor
  //
  // The range is floor(target)..ceil(target), so a target of 5.5 settles on
  // 5 or 6 open arrows. Every tuning step keeps the level solvable.
  // ---------------------------------------------------------------------------

  // (level, open arrows for a typical design). Values between key points are
  // interpolated, so the open count tapers with no jumps.
  static const List<(int, double)> _openCountKeys = [
    (6, 8.0),
    (10, 8.0),
    (15, 7.0),
    (20, 6.5),
    (23, 5.5),
    (30, 5.0),
    (40, 4.5),
    (50, 4.0),
    (65, 3.5),
    (80, 3.0),
  ];

  double _openCountForLevel(int lvl) {
    final l = lvl.clamp(6, LevelDesigns.totalLevels).toInt();

    for (var i = 1; i < _openCountKeys.length; i++) {
      final b = _openCountKeys[i];

      if (l <= b.$1) {
        final a = _openCountKeys[i - 1];
        final t = (l - a.$1) / (b.$1 - a.$1);

        return a.$2 + (b.$2 - a.$2) * t;
      }
    }

    return _openCountKeys.last.$2;
  }

  /// Share of playable cells that touch the outside of the design (the board
  /// border, a hole, a slit or a thin part). Thin and detailed designs score
  /// high, solid designs score low.
  double _edgeRatio(LevelGrid grid) {
    if (grid.cellCount == 0) return 0;

    var edge = 0;

    for (final id in grid.allowed) {
      final x = id % grid.cols;
      final y = id ~/ grid.cols;

      if (!grid.contains(x - 1, y) ||
          !grid.contains(x + 1, y) ||
          !grid.contains(x, y - 1) ||
          !grid.contains(x, y + 1)) {
        edge++;
      }
    }

    return edge / grid.cellCount;
  }

  /// Open-arrow multiplier for a design: 1.0 for an average silhouette,
  /// up to 1.5 for thin / holey ones, down to 0.8 for solid blocks.
  double _designOpenFactor(LevelGrid grid) {
    return (1.0 + (_edgeRatio(grid) - 0.30)).clamp(0.8, 1.5).toDouble();
  }

  /// Target range of arrows that are open (tappable) at the start.
  ///
  /// Based on the level (table), the arrow count of the level and the design
  /// (edge exposure of the silhouette).
  (int, int) _openRange(int lvl, LevelGrid grid, int arrowCount) {
    if (LevelDesigns.isTutorial(lvl)) {
      return (arrowCount, arrowCount);
    }

    // Levels 2-5: at most half the arrows are open at the start.
    if (lvl <= 5) {
      final c = math.max(1, arrowCount ~/ 2);
      return (math.max(1, c - 1), c);
    }

    final count = math.max(1, arrowCount);

    final target = _openCountForLevel(lvl) * _designOpenFactor(grid);

    var lo = math.max(1, target.floor());
    var hi = math.max(lo, target.ceil());

    // A whole-number target still gets a small window, so tuning can succeed.
    if (hi == lo && lo >= 4) {
      hi = lo + 1;
    }

    hi = math.min(hi, count);
    lo = math.min(lo, hi);

    return (lo, hi);
  }

  /// Longest allowed arrow, in cells. Shorter arrows = more arrows = harder.
  int _maxPathLength(int lvl) => (5 + lvl ~/ 4).clamp(5, 12).toInt();

  /// Number of arrows whose exit ray touches no other arrow (free at start).
  int _countFreeArrows(List<List<int>> paths, int cols, int rows) {
    return _analyze(paths, cols, rows).$1;
  }

  /// Maps every board cell to the index of the arrow that covers it.
  Map<int, int> _ownerMap(List<List<int>> paths) {
    final owner = <int, int>{};

    for (var i = 0; i < paths.length; i++) {
      for (final id in paths[i]) {
        owner[id] = i;
      }
    }

    return owner;
  }

  /// Arrows that sit on the exit ray of [path] (the arrows blocking it).
  Set<int> _blockersOf(
    List<int> path,
    int self,
    Map<int, int> owner,
    int cols,
    int rows,
  ) {
    final deps = <int>{};

    if (path.length < 2) return deps;

    final head = path.last;
    final prev = path[path.length - 2];

    final dr = head ~/ cols - prev ~/ cols;
    final dc = head % cols - prev % cols;

    var r = head ~/ cols + dr;
    var c = head % cols + dc;

    while (r >= 0 && r < rows && c >= 0 && c < cols) {
      final o = owner[r * cols + c];
      if (o != null && o != self) deps.add(o);
      r += dr;
      c += dc;
    }

    return deps;
  }

  /// Returns (free arrows at start, solvable, complexity) for a blocker graph.
  ///
  /// The level is solvable if arrows can be removed one by one, each time
  /// taking an arrow whose blockers are already gone.
  ///
  /// complexity = longest unlock chain * 100000 + total blockers * 2
  ///              - choices.
  ///
  /// A long chain means the player has only one or two safe arrows at every
  /// step. Many blockers means each safe arrow is hard to spot. "choices"
  /// grows when layers of the unlock order are wide (many safe arrows to pick
  /// from at once), so subtracting it favours narrow, sequential layouts.
  (int, bool, int) _evaluate(List<Set<int>> deps) {
    final n = deps.length;

    final waiting = List<int>.filled(n, 0);
    final depthOf = List<int>.filled(n, 0);
    final dependents = List.generate(n, (_) => <int>[]);

    var free = 0;
    var totalDeps = 0;
    final queue = <int>[];

    for (var i = 0; i < n; i++) {
      waiting[i] = deps[i].length;
      totalDeps += deps[i].length;

      for (final j in deps[i]) {
        dependents[j].add(i);
      }

      if (deps[i].isEmpty) {
        free++;
        queue.add(i);
      }
    }

    var cursor = 0;
    var maxDepth = 0;

    while (cursor < queue.length) {
      final done = queue[cursor++];

      for (final next in dependents[done]) {
        depthOf[next] = math.max(depthOf[next], depthOf[done] + 1);
        maxDepth = math.max(maxDepth, depthOf[next]);

        waiting[next]--;
        if (waiting[next] == 0) queue.add(next);
      }
    }

    final solvable = queue.length == n;

    // Width of each layer = how many safe arrows the player can pick from
    // at that stage. Narrow layers = more sequential play.
    var choices = 0;

    if (solvable) {
      final width = List<int>.filled(maxDepth + 1, 0);

      for (final i in queue) {
        width[depthOf[i]]++;
      }

      for (final w in width) {
        choices += w * (w + 1) ~/ 2;
      }
    }

    // Longest chain first, then more blockers, then fewer choices per step.
    return (free, solvable, maxDepth * 100000 + totalDeps * 2 - choices);
  }

  (int, bool, int) _analyze(List<List<int>> paths, int cols, int rows) {
    final owner = _ownerMap(paths);

    return _evaluate([
      for (var i = 0; i < paths.length; i++)
        _blockersOf(paths[i], i, owner, cols, rows),
    ]);
  }

  /// Reverses individual arrows (swapping head and tail).
  ///
  /// Reversing an arrow never changes which cells are covered, so only that
  /// arrow's own blockers change. That makes every trial cheap, which allows
  /// a much deeper search.
  ///
  /// Phase 1: bring the open-arrow count into [minOpen]..[maxOpen].
  /// Phase 2: keep it there while pushing complexity up. Sideways moves are
  /// allowed so the search can escape dead ends.
  ///
  /// Returns (paths, complexity, remaining open-count error).
  (List<List<int>>, int, int) _tuneOpenness({
    required List<List<int>> paths,
    required int cols,
    required int rows,
    required int minOpen,
    required int maxOpen,
    required math.Random rng,
  }) {
    final n = paths.length;
    if (n < 2) return (paths, 0, 0);

    final lo = math.min(minOpen, n);
    final hi = math.min(maxOpen, n);

    int errorOf(int free) {
      if (free < lo) return lo - free;
      if (free > hi) return free - hi;
      return 0;
    }

    final owner = _ownerMap(paths);
    final work = [for (final p in paths) List<int>.from(p)];
    final deps = [
      for (var i = 0; i < n; i++) _blockersOf(work[i], i, owner, cols, rows),
    ];

    final start = _evaluate(deps);
    if (!start.$2) return (paths, 0, 1 << 20);

    (int, bool, int) flip(int i) {
      work[i] = work[i].reversed.toList();
      deps[i] = _blockersOf(work[i], i, owner, cols, rows);
      return _evaluate(deps);
    }

    void undo(int i) {
      work[i] = work[i].reversed.toList();
      deps[i] = _blockersOf(work[i], i, owner, cols, rows);
    }

    var error = errorOf(start.$1);
    var complexity = start.$3;

    // Phase 1: reach the open-arrow range.
    var budget = 6000;
    var improved = true;

    while (error > 0 && improved && budget > 0) {
      improved = false;

      final order = List<int>.generate(n, (i) => i)..shuffle(rng);

      for (final i in order) {
        if (error == 0 || budget <= 0) break;
        budget--;

        final r = flip(i);
        final e = errorOf(r.$1);

        if (r.$2 && e < error) {
          error = e;
          complexity = r.$3;
          improved = true;
        } else {
          undo(i);
        }
      }
    }

    // Phase 2: make the interior harder without opening more arrows.
    var budget2 = 15000;
    var stale = 0;

    while (budget2 > 0 && stale < 4) {
      var gained = false;

      final order = List<int>.generate(n, (i) => i)..shuffle(rng);

      for (final i in order) {
        if (budget2 <= 0) break;
        budget2--;

        final r = flip(i);
        final e = errorOf(r.$1);

        final valid = r.$2 && e <= error;
        final better = valid && (e < error || r.$3 > complexity);
        final sideways = valid && e == error && r.$3 == complexity;

        if (better) {
          error = e;
          complexity = r.$3;
          gained = true;
        } else if (sideways && rng.nextDouble() < 0.3) {
          // Keep the flip: same difficulty, different layout.
        } else {
          undo(i);
        }
      }

      stale = gained ? 0 : stale + 1;
    }

    return (work, complexity, error);
  }

  List<ArrowModel> _generateLevel(int lvl) {
    final design = LevelDesigns.forLevel(lvl);
    final grid = design.toGrid(boardAspect);

    final cols = grid.cols;
    final rows = grid.rows;
    final allowed = grid.allowed;

    levelTitle.value = design.name;
    levelCategory.value = design.category;
    maskCells = allowed;

    _cols = cols;
    _rows = rows;

    if (allowed.isEmpty) return const [];

    List<List<int>>? paths;

    // Level 1: exactly three simple arrows that fill the block.
    if (LevelDesigns.isTutorial(lvl)) {
      paths = _tutorialPaths(cols, rows, allowed);
    }

    paths ??= _bestPaths(lvl, grid);

    return [
      for (final p in paths)
        ArrowModel(
          points: [
            for (final id in p)
              Offset((id % cols + 0.5) / cols, (id ~/ cols + 0.5) / rows),
          ],
        ),
    ];
  }

  /// Splits a full rectangle into three bands. Each band is one snake arrow
  /// whose head ends on the board edge, so all three arrows can always exit.
  List<List<int>>? _tutorialPaths(int cols, int rows, Set<int> allowed) {
    if (cols < 2 || rows < 3 || allowed.length != cols * rows) {
      return null;
    }

    final base = rows ~/ 3;
    final extra = rows % 3;

    final paths = <List<int>>[];
    var row = 0;

    for (var band = 0; band < 3; band++) {
      final height = base + (band < extra ? 1 : 0);
      final path = <int>[];

      for (var k = 0; k < height; k++) {
        final leftToRight = (k % 2 == 0) == (band % 2 == 0);

        for (var i = 0; i < cols; i++) {
          final col = leftToRight ? i : cols - 1 - i;
          path.add((row + k) * cols + col);
        }
      }

      paths.add(path);
      row += height;
    }

    return paths;
  }

  List<List<int>> _bestPaths(int lvl, LevelGrid grid) {
    final allowed = grid.allowed;
    final cells = allowed.length;
    final maxLen = _maxPathLength(lvl);

    var target = LevelDesigns.safeArrowCount(lvl, grid, cellsPerArrow: 2);

    // Keep arrows short enough that the board stays busy.
    if (!LevelDesigns.isTutorial(lvl)) {
      target = math.max(target, (cells / maxLen).ceil());
    }

    target = target
        .clamp(1, math.max(1, math.min(LevelDesigns.maxArrows, cells ~/ 2)))
        .toInt();

    // Open arrows at the start depend on the level, the design and the
    // final arrow count.
    final (minOpen, maxOpen) = _openRange(lvl, grid, target);
    final openMid = (minOpen + maxOpen) / 2;

    // Multiplies every picked arrow length; calibrated below so the arrow
    // count lands on the level's target.
    var lengthScale = 1.0;

    final candidates = <(double, List<List<int>>, math.Random)>[];

    for (var attempt = 0; attempt < 12; attempt++) {
      // _variant changes on every restart, so the same design gets a
      // different arrow layout.
      final seed = lvl * 7919 + 13 + attempt * 104729 + _variant * 1299709;
      final rng = math.Random(seed);

      final paths = _buildPaths(
        cols: grid.cols,
        rows: grid.rows,
        allowed: allowed,
        lengthScale: lengthScale,
        maxLen: maxLen,
        rng: rng,
      );

      var covered = 0;
      for (final p in paths) {
        covered += p.length;
      }

      final uncovered = cells - covered;
      final countError = (paths.length - target).abs();
      final free = _countFreeArrows(paths, grid.cols, grid.rows);

      // Uncovered cells hurt the shape the most, so weight them higher.
      // Free arrows only need to be near the target; tuning finishes the job.
      final score =
          countError + uncovered * 3.0 + (free - openMid).abs() * 0.25;

      candidates.add((score, paths, math.Random(seed + 1)));

      if (uncovered == 0 && countError <= math.max(1, target ~/ 20)) {
        break;
      }

      // Calibrate: too many arrows -> longer paths, too few -> shorter.
      if (paths.isNotEmpty) {
        lengthScale = (lengthScale * paths.length / target).clamp(0.5, 2.0);
      }
    }

    candidates.removeWhere((c) => c.$2.isEmpty);
    if (candidates.isEmpty) return const [];

    candidates.sort((a, b) => a.$1.compareTo(b.$1));

    // Tune the best layouts and keep whichever is hardest.
    var bestPaths = candidates.first.$2;
    var bestError = 1 << 30;
    var bestComplexity = -1;

    for (final c in candidates.take(4)) {
      if (c.$1 > candidates.first.$1 + 4) continue;

      final r = _tuneOpenness(
        paths: c.$2,
        cols: grid.cols,
        rows: grid.rows,
        minOpen: minOpen,
        maxOpen: maxOpen,
        rng: c.$3,
      );

      if (r.$3 < bestError || (r.$3 == bestError && r.$2 > bestComplexity)) {
        bestPaths = r.$1;
        bestError = r.$3;
        bestComplexity = r.$2;
      }
    }

    return bestPaths;
  }

  List<List<int>> _buildPaths({
    required int cols,
    required int rows,
    required Set<int> allowed,
    required double lengthScale,
    required int maxLen,
    required math.Random rng,
  }) {
    const dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)];

    final occ = <int>{};
    final paths = <List<int>>[];
    final rays = <Set<int>>[];

    Set<int> rayCells(int head, (int, int) d) {
      final out = <int>{};

      var r = head ~/ cols + d.$1;
      var c = head % cols + d.$2;

      while (r >= 0 && r < rows && c >= 0 && c < cols) {
        out.add(r * cols + c);
        r += d.$1;
        c += d.$2;
      }

      return out;
    }

    bool rayClear(int head, (int, int) d, Set<int> occupied, Set<int> seen) {
      var r = head ~/ cols + d.$1;
      var c = head % cols + d.$2;

      while (r >= 0 && r < rows && c >= 0 && c < cols) {
        final id = r * cols + c;

        if (occupied.contains(id) || seen.contains(id)) {
          return false;
        }

        r += d.$1;
        c += d.$2;
      }

      return true;
    }

    int freeNeighbours(int id, Set<int> seen) {
      final r = id ~/ cols;
      final c = id % cols;
      var count = 0;

      for (final d in dirs) {
        final nr = r + d.$1;
        final nc = c + d.$2;

        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) {
          continue;
        }

        final nid = nr * cols + nc;

        if (allowed.contains(nid) &&
            !occ.contains(nid) &&
            !seen.contains(nid)) {
          count++;
        }
      }

      return count;
    }

    double cx = 0;
    double cy = 0;

    for (final id in allowed) {
      cx += id % cols;
      cy += id ~/ cols;
    }

    cx /= allowed.length;
    cy /= allowed.length;

    final dist = {
      for (final id in allowed)
        id:
            math.sqrt(
              math.pow(id % cols - cx, 2) + math.pow(id ~/ cols - cy, 2),
            ) +
            rng.nextDouble() * 1.5,
    };

    final starts = allowed.toList()
      ..sort((a, b) => dist[a]!.compareTo(dist[b]!));

    // Pass 1: snake-shaped arrows. Lengths follow a fixed mix:
    //   short  (2 .. ~25% of max)   10%
    //   medium (up to ~60% of max)  55%
    //   long   (up to max)          35%
    final shortMax = math.max(2, (maxLen * 0.25).round());
    final mediumMax = math.max(shortMax + 1, (maxLen * 0.60).round());
    final longMin = math.min(mediumMax + 1, maxLen);

    int pickLength() {
      final roll = rng.nextDouble();

      int lo;
      int hi;

      if (roll < 0.10) {
        lo = 2;
        hi = shortMax;
      } else if (roll < 0.65) {
        lo = shortMax + 1;
        hi = mediumMax;
      } else {
        lo = longMin;
        hi = maxLen;
      }

      final base = lo + rng.nextInt(math.max(1, hi - lo + 1));

      return (base * lengthScale).round().clamp(2, maxLen).toInt();
    }

    for (final s in starts) {
      if (occ.contains(s)) continue;

      for (var attempt = 0; attempt < 14; attempt++) {
        final path = <int>[s];
        final seen = <int>{s};
        final target = pickLength();

        var bestLen = 0;
        var bestDepth = -1;
        (int, int) bestDir = (0, 0);

        while (path.length < target) {
          final r = path.last ~/ cols;
          final c = path.last % cols;

          final opts = <(int, int)>[];

          for (final d in dirs) {
            final nr = r + d.$1;
            final nc = c + d.$2;

            if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) {
              continue;
            }

            final id = nr * cols + nc;

            if (!allowed.contains(id)) continue;
            if (occ.contains(id) || seen.contains(id)) continue;

            opts.add(d);
          }

          if (opts.isEmpty) break;

          late (int, int) d;

          if (rng.nextDouble() < 0.75) {
            var minN = 99;
            var best = <(int, int)>[];

            for (final o in opts) {
              final id = (r + o.$1) * cols + (c + o.$2);
              final n = freeNeighbours(id, seen);

              if (n < minN) {
                minN = n;
                best = [o];
              } else if (n == minN) {
                best.add(o);
              }
            }

            d = best[rng.nextInt(best.length)];
          } else {
            d = opts[rng.nextInt(opts.length)];
          }

          final nid = (r + d.$1) * cols + (c + d.$2);

          path.add(nid);
          seen.add(nid);

          // Prefer heads whose exit ray runs deep across the board.
          if (rayClear(nid, d, occ, seen)) {
            final depth = rayCells(nid, d).length;

            if (depth >= bestDepth) {
              bestDepth = depth;
              bestLen = path.length;
              bestDir = d;
            }
          }
        }

        if (bestLen >= 2) {
          final used = path.sublist(0, bestLen);

          occ.addAll(used);
          paths.add(used);
          rays.add(rayCells(used.last, bestDir));

          break;
        }
      }
    }

    // Attach leftover cells to neighbouring arrow tails.
    void absorbLeftovers() {
      var absorbed = true;

      while (absorbed) {
        absorbed = false;

        for (final cell in starts) {
          if (occ.contains(cell)) continue;

          final r = cell ~/ cols;
          final c = cell % cols;

          for (var i = 0; i < paths.length; i++) {
            if (paths[i].length >= maxLen + 4) continue;

            final tail = paths[i].first;

            final adjacent =
                (tail ~/ cols - r).abs() + (tail % cols - c).abs() == 1;

            if (!adjacent) continue;
            if (rays[i].contains(cell)) continue;

            var ok = true;

            for (var j = i + 1; j < paths.length; j++) {
              if (rays[j].contains(cell)) {
                ok = false;
                break;
              }
            }

            if (!ok) continue;

            paths[i].insert(0, cell);
            occ.add(cell);
            absorbed = true;
            break;
          }
        }
      }
    }

    // Pass 2: absorb leftovers.
    absorbLeftovers();

    // Pass 3: turn remaining uncovered cells into new arrows.
    for (final s in starts) {
      if (occ.contains(s)) continue;

      final path = <int>[s];
      final seen = <int>{s};

      var bestLen = 0;
      var bestDepth = -1;
      (int, int) bestDir = (0, 0);

      while (path.length < maxLen) {
        final r = path.last ~/ cols;
        final c = path.last % cols;

        int? next;
        (int, int)? nextDir;
        var minN = 99;

        for (final d in dirs) {
          final nr = r + d.$1;
          final nc = c + d.$2;

          if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) {
            continue;
          }

          final id = nr * cols + nc;

          if (!allowed.contains(id)) continue;
          if (occ.contains(id) || seen.contains(id)) continue;

          final n = freeNeighbours(id, seen);

          if (n < minN) {
            minN = n;
            next = id;
            nextDir = d;
          }
        }

        if (next == null || nextDir == null) break;

        path.add(next);
        seen.add(next);

        if (rayClear(next, nextDir, occ, seen)) {
          final depth = rayCells(next, nextDir).length;

          if (depth >= bestDepth) {
            bestDepth = depth;
            bestLen = path.length;
            bestDir = nextDir;
          }
        }
      }

      if (bestLen >= 2) {
        final used = path.sublist(0, bestLen);

        occ.addAll(used);
        paths.add(used);
        rays.add(rayCells(used.last, bestDir));
      }
    }

    // Final absorb for anything left next to the new arrows.
    absorbLeftovers();

    return paths;
  }

  /// Opens a requested level while respecting mode-specific unlock progress.
  void openLevel({required GameMode mode, int? requestedLevel}) {
    // Restore this mode's independent saved progress.
    if (selectedMode.value != mode) {
      _restoreProgress(mode);
    }

    if (requestedLevel == null) return;

    final unlocked = GameStorage.unlockedLevel(mode.name);

    level.value = requestedLevel.clamp(1, unlocked).toInt();

    loadLevel(startNewSession: true);
  }

  // Input
  void onBoardTap(Offset position) {
    if (isWon.value || isGameOver.value) return;

    // Allow arrow taps while paused.
    // Resume the timer only when a valid arrow is selected.
    final wasPaused = isPaused.value;

    Offset scalePoint(Offset point) {
      return Offset(point.dx * boardAspect, point.dy);
    }

    final tap = scalePoint(position);

    var selectedIndex = -1;
    var closestDistance = double.infinity;

    for (var i = 0; i < arrows.length; i++) {
      final arrow = arrows[i];

      if (!arrow.isActive || arrow.isMoving || arrow.isBlocked) {
        continue;
      }

      for (var j = 0; j < arrow.points.length - 1; j++) {
        final distance = _pointToSegmentDistance(
          tap,
          scalePoint(arrow.points[j]),
          scalePoint(arrow.points[j + 1]),
        );

        if (distance < closestDistance) {
          closestDistance = distance;
          selectedIndex = i;
        }
      }
    }

    if (selectedIndex == -1 || closestDistance > 0.6 / _rows) {
      return;
    }

    // A valid arrow was clicked: resume the timer from remaining time.
    if (wasPaused) {
      resumeGame();
    }

    moves.value++;
    clearHint();

    if (_isPathBlocked(selectedIndex)) {
      _animateBlocked(selectedIndex);
    } else {
      VibrationService.tap();
      _animateArrowOut(selectedIndex);
    }
  }

  // Blocked arrow animation
  Future<void> _animateBlocked(int index) async {
    if (index < 0 || index >= arrows.length) return;
    if (isWon.value || isGameOver.value) return;

    final originalArrow = arrows[index];

    if (!originalArrow.isActive ||
        originalArrow.isMoving ||
        originalArrow.isBlocked) {
      return;
    }

    final gen = _generation;
    final points = originalArrow.points;
    final end = points.last;
    final key = identityHashCode(points);

    arrows[index] = originalArrow.copyWith(isBlocked: true);
    _bumping.add(key);
    _startRun();

    try {
      Offset? previous;

      for (var i = points.length - 2; i >= 0; i--) {
        if ((end - points[i]).distance > 0.0001) {
          previous = points[i];
          break;
        }
      }

      if (previous == null) {
        final i = _indexOf(points);
        if (i != -1) {
          arrows[i] = arrows[i].copyWith(isBlocked: false);
        }
        return;
      }

      final dir = end - previous;
      final unit = dir / dir.distance;
      final horizontal = unit.dx.abs() > unit.dy.abs();

      final hit = _rayHitDistance(end, unit, index);
      final gap = 0.35 * (horizontal ? 1 / _cols : 1 / _rows);
      final travel = math.max(0.0, hit - gap);

      bool step(double progress) {
        if (!_alive(gen)) return false;

        final i = _indexOf(points);
        if (i == -1) return false;

        if (!arrows[i].isBlocked) return false;

        arrows[i] = arrows[i].copyWith(
          isBlocked: true,
          bumpTravel: travel,
          bumpProgress: progress,
        );

        return true;
      }

      for (var f = 1; f <= ArrowMotion.bumpForwardFrames; f++) {
        await Future.delayed(ArrowMotion.frameDelay);

        if (!step(ArrowMotion.bumpForward(f))) return;
      }

      if (!_alive(gen)) return;

      // Count the blocked click and apply the configured time penalty.
      if (isTimedChallenge || isSpeedRun) {
        if (!isGameOver.value && !isWon.value) {
          VibrationService.wrongMove();

          wrongClicks.value++;

          final penalty = modeConfig.blockedPenaltySeconds;

          if (penalty > 0) {
            timeLeft.value = math.max(0, timeLeft.value - penalty);
          }

          // Time expiration takes priority over the wrong-click limit.
          if (timeLeft.value <= 0) {
            _timeUp();
          } else if (wrongClicks.value >= modeConfig.maxWrongClicks) {
            isGameOver.value = true;
            message.value =
                '${modeConfig.maxWrongClicks} wrong clicks! Game over.';

            _stopTimer();
          } else {
            message.value =
                'Wrong clicks: ${wrongClicks.value}/'
                '${modeConfig.maxWrongClicks}';
          }
        }
      } else {
        // Normal Mode retains its original lives system.
        lives.value--;
        VibrationService.wrongMove();

        if (lives.value <= 0) {
          isGameOver.value = true;
          message.value = 'Game over! Restart and try again.';
          _stopTimer();
          VibrationService.gameOver();
        } else {
          message.value = 'Blocked! Try another arrow.';
        }
      }

      for (var f = 1; f <= ArrowMotion.bumpBackFrames; f++) {
        await Future.delayed(ArrowMotion.frameDelay);

        if (!step(ArrowMotion.bumpBack(f))) return;
      }

      if (!_alive(gen)) return;

      final i = _indexOf(points);

      if (i != -1) {
        arrows[i] = arrows[i].copyWith(
          isBlocked: true,
          bumpTravel: 0,
          bumpProgress: 0,
        );
      }
    } finally {
      _bumping.remove(key);

      if (_alive(gen)) {
        final i = _indexOf(points);

        if (i != -1 && arrows[i].isBlocked && !arrows[i].isMoving) {
          arrows[i] = arrows[i].copyWith(bumpTravel: 0, bumpProgress: 0);
        }
      }

      _endRun(gen);

      if (_alive(gen)) _autoReleaseRed();
    }
  }

  // Auto release of blocked arrows
  void _autoReleaseRed() {
    if (isClosed || isWon.value || isGameOver.value) return;

    final candidates = <List<Offset>>[
      for (final a in arrows)
        if (a.isBlocked &&
            !a.isMoving &&
            !_bumping.contains(identityHashCode(a.points)))
          a.points,
    ];

    for (final pts in candidates) {
      final i = _indexOf(pts);
      if (i == -1) continue;

      final a = arrows[i];

      if (!a.isBlocked || a.isMoving) continue;
      if (_isPathBlocked(i)) continue;

      arrows[i] = a.copyWith(isBlocked: false, bumpTravel: 0, bumpProgress: 0);

      unawaited(_animateArrowOut(i));
    }
  }

  double _rayHitDistance(Offset origin, Offset unit, int ignoreIndex) {
    const eps = 1e-6;

    final horizontal = unit.dx.abs() > unit.dy.abs();
    final sign = horizontal ? unit.dx.sign : unit.dy.sign;

    var best = double.infinity;

    for (var i = 0; i < arrows.length; i++) {
      if (i == ignoreIndex || arrows[i].isMoving) continue;

      final pts = arrows[i].points;

      for (var j = 0; j < pts.length - 1; j++) {
        final a = pts[j];
        final b = pts[j + 1];

        final o = horizontal ? origin.dy : origin.dx;
        final lo = horizontal ? math.min(a.dy, b.dy) : math.min(a.dx, b.dx);
        final hi = horizontal ? math.max(a.dy, b.dy) : math.max(a.dx, b.dx);

        if (o < lo - eps || o > hi + eps) continue;

        for (final p in [a, b]) {
          final d = (horizontal ? p.dx - origin.dx : p.dy - origin.dy) * sign;

          if (d > eps && d < best) best = d;
        }
      }
    }

    return best.isFinite ? best : 0.0;
  }

  // Arrow escape animation
  Future<void> _animateArrowOut(int index) async {
    if (index < 0 || index >= arrows.length) return;
    if (isWon.value || isGameOver.value) return;

    final originalArrow = arrows[index];

    if (!originalArrow.isActive ||
        originalArrow.isMoving ||
        originalArrow.isBlocked) {
      return;
    }

    final gen = _generation;
    final points = originalArrow.points;

    arrows[index] = originalArrow.copyWith(isMoving: true, progress: 0);

    _startRun();

    _autoReleaseRed();

    try {
      for (var frame = 1; frame <= ArrowMotion.escapeFrames; frame++) {
        await Future.delayed(ArrowMotion.frameDelay);

        if (!_alive(gen) || isGameOver.value) return;

        final currentIndex = _indexOf(points);
        if (currentIndex == -1) return;

        final progress = ArrowMotion.escape(frame);

        _revealArrowDotsProgress(originalArrow, progress);

        arrows[currentIndex] = arrows[currentIndex].copyWith(
          isMoving: true,
          progress: progress,
        );
      }

      if (!_alive(gen) || isGameOver.value) return;

      final finalIndex = _indexOf(points);
      if (finalIndex == -1) return;

      _revealArrowDots(originalArrow);

      arrows.removeAt(finalIndex);

      if (!_alive(gen) || isGameOver.value) return;

      if (arrows.isEmpty) {
        _stopTimer();

        visibleDotCells.addAll(maskCells);

        isWon.value = true;
        _payLevelReward();

        // Update completion statistics without counting replays twice.
        levelsCompleted.value = math.max(levelsCompleted.value, level.value);

        // Save this level's best star rating for the active mode.
        unawaited(
          GameStorage.saveLevelStars(
            mode: selectedMode.value.name,
            level: level.value,
            stars: resultStars,
          ),
        );

        unawaited(_saveProgress(completedLevel: true));

        VibrationService.levelComplete();
        message.value = 'Level complete!';
      } else {
        final left = arrows.where((arrow) => !arrow.isMoving).length;
        message.value = 'Great! $left arrows remaining.';
        _autoReleaseRed();
      }
    } finally {
      _endRun(gen);
    }
  }

  // Geometry helpers
  bool _isPathBlocked(int index) {
    final points = arrows[index].points;
    if (points.length < 2) return true;

    final end = points.last;

    Offset? previous;

    for (var i = points.length - 2; i >= 0; i--) {
      if ((end - points[i]).distance > 0.0001) {
        previous = points[i];
        break;
      }
    }

    if (previous == null) return true;

    final direction = end - previous;
    final length = direction.distance;

    if (length == 0) return true;

    final unit = Offset(direction.dx / length, direction.dy / length);
    final exitPoint = end + unit * 2.0;

    for (var i = 0; i < arrows.length; i++) {
      if (i == index || arrows[i].isMoving) continue;

      for (var j = 0; j < arrows[i].points.length - 1; j++) {
        if (_segmentsIntersect(
          end,
          exitPoint,
          arrows[i].points[j],
          arrows[i].points[j + 1],
        )) {
          return true;
        }
      }
    }

    return false;
  }

  double _pointToSegmentDistance(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;

    final lengthSquared = ab.dx * ab.dx + ab.dy * ab.dy;

    if (lengthSquared == 0) return (p - a).distance;

    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / lengthSquared).clamp(0.0, 1.0);

    final nearest = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);

    return (p - nearest).distance;
  }

  bool _segmentsIntersect(Offset a, Offset b, Offset c, Offset d) {
    const epsilon = 1e-9;

    double cross(Offset p, Offset q, Offset r) {
      return (q.dx - p.dx) * (r.dy - p.dy) - (q.dy - p.dy) * (r.dx - p.dx);
    }

    bool onSegment(Offset p, Offset q, Offset r) {
      return q.dx >= math.min(p.dx, r.dx) - epsilon &&
          q.dx <= math.max(p.dx, r.dx) + epsilon &&
          q.dy >= math.min(p.dy, r.dy) - epsilon &&
          q.dy <= math.max(p.dy, r.dy) + epsilon;
    }

    final o1 = cross(a, b, c);
    final o2 = cross(a, b, d);
    final o3 = cross(c, d, a);
    final o4 = cross(c, d, b);

    if (((o1 > epsilon && o2 < -epsilon) || (o1 < -epsilon && o2 > epsilon)) &&
        ((o3 > epsilon && o4 < -epsilon) || (o3 < -epsilon && o4 > epsilon))) {
      return true;
    }

    if (o1.abs() <= epsilon && onSegment(a, c, b)) return true;
    if (o2.abs() <= epsilon && onSegment(a, d, b)) return true;
    if (o3.abs() <= epsilon && onSegment(c, a, d)) return true;
    if (o4.abs() <= epsilon && onSegment(c, b, d)) return true;

    return false;
  }

  // Level controls
  void restartLevel() {
    if (isSpeedRun) {
      // Preserve the level where the player lost.
      _stopTimer();

      isGameOver.value = false;
      isWon.value = false;
      isAnimating.value = false;

      // Start the retry with a fresh wrong-click count.
      wrongClicks.value = 0;

      // Same design, new arrow layout.
      loadLevel(newLayout: true);
      return;
    }

    // Normal and Timed Challenge: same design, new arrow layout.
    loadLevel(newLayout: true);
  }

  void nextLevel() {
    if (!isWon.value) return;

    if (isGameOver.value || (isSpeedRun && timeLeft.value <= 0)) {
      return;
    }

    level.value++;
    loadLevel();

    // Persist this mode's current level.
    unawaited(_saveProgress());
  }

  /// Continue the current level after the player earns a rewarded ad.
  /// Works in every mode:
  ///  - Normal: restores 2 hearts.
  ///  - Timed Challenge / Speed Run, time up: adds [adBonusSeconds].
  ///  - Timed Challenge / Speed Run, wrong-click limit: resets wrong clicks.
  void continueAfterRewardedAd() {
    // Only revive a game that has actually ended.
    if (!isGameOver.value || isWon.value) return;

    _stopTimer();
    _generation++; // cancel any animation still running

    _running = 0;
    _bumping.clear();

    // Arrows may be stuck mid-animation (blocked or moving). Reset them
    // so the player can tap them again.
    for (var i = 0; i < arrows.length; i++) {
      final a = arrows[i];
      if (a.isBlocked || a.isMoving) {
        arrows[i] = a.copyWith(
          isBlocked: false,
          isMoving: false,
          progress: 0,
          bumpTravel: 0,
          bumpProgress: 0,
        );
      }
    }

    isGameOver.value = false;
    isWon.value = false;
    isAnimating.value = false;
    isPaused.value = false;

    if (timedMode) {
      final wasTimeUp = timeLeft.value <= 0;

      // Fresh wrong-click allowance in both cases.
      wrongClicks.value = 0;

      if (wasTimeUp) {
        // Half of the full timer (at least 1 second).
        final bonus = math.max(1, (totalTime.value * adBonusSec).round());

        timeLeft.value = bonus;
        message.value = 'Continue playing! +$bonus seconds.';
      } else {
        message.value = 'Continue playing! Wrong clicks reset.';
      }

      _startTimer();
    } else {
      lives.value = 2;
      message.value = 'Continue playing! 2 hearts restored.';
    }

    // Keep the current board; do not call loadLevel().
    VibrationService.success();
  }
}
