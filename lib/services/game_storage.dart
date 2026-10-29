import 'package:get_storage/get_storage.dart';

class GameStorage {
  static final GetStorage _storage = GetStorage();

  static String _progressKey(String mode) => 'arrow_game_progress_$mode';

  // ---------------------------------------------------------------------------
  // Load progress
  // ---------------------------------------------------------------------------

  static Map<String, dynamic>? loadProgress(String mode) {
    final data = _storage.read(_progressKey(mode));

    if (data == null || data is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(data);
  }

  // ---------------------------------------------------------------------------
  // Level stars — saved independently for each game mode
  // ---------------------------------------------------------------------------

  /// Returns the saved star ratings for all levels in a mode.
  /// Keys are level numbers stored as strings.
  static Map<String, int> loadLevelStars(String mode) {
    final rawStars = loadProgress(mode)?['levelStars'];

    if (rawStars is! Map) {
      return <String, int>{};
    }

    final result = <String, int>{};

    for (final entry in rawStars.entries) {
      final value = entry.value;

      if (value is num) {
        result[entry.key.toString()] = value.toInt().clamp(0, 5).toInt();
      }
    }

    return result;
  }

  /// Returns the saved stars for a particular level, or zero if unplayed.
  static int starsForLevel(String mode, int level) {
    if (level < 1) return 0;
    return loadLevelStars(mode)[level.toString()] ?? 0;
  }

  /// Saves a level's best rating. A lower replay score never replaces
  /// a previously earned higher score.
  static Future<void> saveLevelStars({
    required String mode,
    required int level,
    required int stars,
  }) async {
    if (level < 1) return;

    final old =
        loadProgress(mode) ??
        <String, dynamic>{'level': 1, 'levelsCompleted': 0};

    final savedStars = loadLevelStars(mode);
    final key = level.toString();
    final previousStars = savedStars[key] ?? 0;
    final bestStars = stars.clamp(0, 5).toInt();

    savedStars[key] = bestStars > previousStars ? bestStars : previousStars;

    await _storage.write(_progressKey(mode), {
      ...old,
      'levelStars': savedStars,
    });
  }

  // ---------------------------------------------------------------------------
  // Unlocked levels — independent for each mode
  // ---------------------------------------------------------------------------

  /// Returns the highest level the player can access in this mode.
  /// Level 1 is always unlocked.
  static int unlockedLevel(String mode) {
    final data = loadProgress(mode);

    final savedLevel = data?['level'];
    final completed = data?['levelsCompleted'];

    final level = savedLevel is num ? savedLevel.toInt() : 1;
    final levelsCompleted = completed is num ? completed.toInt() : 0;

    return [1, level, levelsCompleted + 1].reduce((a, b) => a > b ? a : b);
  }

  static bool isLevelUnlocked(String mode, int level) {
    return level >= 1 && level <= unlockedLevel(mode);
  }

  // ---------------------------------------------------------------------------
  // Save progress — preserve stars and never mix game modes
  // ---------------------------------------------------------------------------

  /// [level] is the level to resume from.
  /// When completing a level, GameController passes the next level here.
  /// Completion count and resume level never move backwards.
  static Future<void> saveProgress({
    required int level,
    required String mode,
    required int levelsCompleted,
  }) async {
    final old = loadProgress(mode);

    final oldLevelValue = old?['level'];
    final oldCompletedValue = old?['levelsCompleted'];

    final previousLevel = oldLevelValue is num ? oldLevelValue.toInt() : 1;

    final previousCompleted = oldCompletedValue is num
        ? oldCompletedValue.toInt()
        : 0;

    final requestedResumeLevel = level < 1 ? 1 : level;

    final safeCompleted = levelsCompleted
        .clamp(0, requestedResumeLevel - 1)
        .toInt();

    final highestCompleted = [
      previousCompleted,
      safeCompleted,
    ].reduce((a, b) => a > b ? a : b);

    final highestLevel = [
      1,
      previousLevel,
      requestedResumeLevel,
      highestCompleted + 1,
    ].reduce((a, b) => a > b ? a : b);

    // Preserve ratings when progress is saved.
    final oldStars = old?['levelStars'];
    final savedStars = oldStars is Map
        ? Map<String, dynamic>.from(oldStars)
        : <String, dynamic>{};

    await _storage.write(_progressKey(mode), {
      'level': highestLevel,
      'levelsCompleted': highestCompleted,
      'levelStars': savedStars,
    });
  }

  // ---------------------------------------------------------------------------
  // Clear progress
  // ---------------------------------------------------------------------------

  static Future<void> clearProgress(String mode) async {
    await _storage.remove(_progressKey(mode));
  }

  static Future<void> clearAllProgress(Iterable<String> modes) async {
    await Future.wait(modes.map(clearProgress));
  }

  // ---------------------------------------------------------------------------
  // Grid lines setting: one value for the entire game (all modes)
  // ---------------------------------------------------------------------------

  static const String _showGridKey = 'arrow_game_show_grid_lines';

  static bool loadShowGrid() {
    final value = _storage.read(_showGridKey);
    return value is bool ? value : false; // default: lines hidden
  }

  static Future<void> saveShowGrid(bool value) async {
    await _storage.write(_showGridKey, value);
  }
  // ---------------------------------------------------------------------------
  // Coins: one shared total, first-clear tracking per mode
  // ---------------------------------------------------------------------------

  static const String _coinsKey = 'arrow_game_total_coins';

  static String _coinLevelsKey(String mode) => 'arrow_game_coin_levels_$mode';

  /// Total coins across ALL modes.
  static int totalCoins() {
    final v = _storage.read(_coinsKey);
    return v is num ? v.toInt() : 0;
  }

  static Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    await _storage.write(_coinsKey, totalCoins() + amount);
  }

  /// True if this level already paid its reward in this mode.
  static bool isCoinLevelClaimed(String mode, int level) {
    final raw = _storage.read(_coinLevelsKey(mode));
    return raw is List && raw.any((e) => e is num && e.toInt() == level);
  }

  /// Marks the level as paid for this mode and adds the coins to the total.
  static Future<void> claimLevelCoins({
    required String mode,
    required int level,
    required int coins,
  }) async {
    final raw = _storage.read(_coinLevelsKey(mode));
    final claimed = raw is List
        ? raw.whereType<num>().map((e) => e.toInt()).toSet()
        : <int>{};

    claimed.add(level);

    final w1 = _storage.write(_coinLevelsKey(mode), claimed.toList());
    final w2 = addCoins(coins);
    await Future.wait([w1, w2]);
  }
}
