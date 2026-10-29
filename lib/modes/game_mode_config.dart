import 'game_mode.dart';

/// Stores the gameplay settings for each available game mode.
class GameModeConfig {
  /// Number of lives available when the game starts.
  final int startingLives;

  /// Whether the game mode uses a countdown timer.
  final bool hasTimer;

  /// Whether the mode uses a timer for the entire game session.
  final bool hasSessionTimer;

  /// Total session duration in seconds.
  final int sessionDurationSeconds;

  /// Maximum number of incorrect clicks allowed.
  final int maxWrongClicks;

  /// Seconds deducted when clicking a blocked arrow.
  final int blockedPenaltySeconds;

  const GameModeConfig({
    required this.startingLives,
    required this.hasTimer,
    this.hasSessionTimer = false,
    this.sessionDurationSeconds = 0,
    this.maxWrongClicks = 0,
    this.blockedPenaltySeconds = 0,
  });

  /// Default configurations for all supported game modes.
  static const Map<GameMode, GameModeConfig> configs = {
    // Normal Mode: Three lives, no timer.
    GameMode.normal: GameModeConfig(startingLives: 3, hasTimer: false),

    // Timed Challenge: A calculated timer for each level.
    GameMode.timedChallenge: GameModeConfig(
      startingLives: 3,
      hasTimer: true,
      hasSessionTimer: false,
      maxWrongClicks: 10,
      blockedPenaltySeconds: 2,
    ),

    // Speed Run: A fresh 60-second timer for every level.
    GameMode.speedRun: GameModeConfig(
      startingLives: 3,
      hasTimer: true,
      hasSessionTimer: false,
      sessionDurationSeconds: 120,
      maxWrongClicks: 10,
      blockedPenaltySeconds: 2,
    ),
  };

  /// Returns the configuration for the selected mode.
  static GameModeConfig forMode(GameMode mode) => configs[mode]!;
}
