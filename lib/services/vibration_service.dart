import 'package:flutter/services.dart';

import 'settings_storage.dart';

class VibrationService {
  VibrationService._();

  /// Checks whether vibration is enabled in Settings.
  static bool get isEnabled => SettingsStorage.getVibrationEnabled();

  /// Light feedback for normal taps.
  static Future<void> tap() async {
    if (!isEnabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Light impact for successful arrow movements.
  static Future<void> success() async {
    if (!isEnabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium impact for incorrect moves.
  static Future<void> wrongMove() async {
    if (!isEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Strong impact when a level is completed.
  static Future<void> levelComplete() async {
    if (!isEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Feedback when the player loses.
  static Future<void> gameOver() async {
    if (!isEnabled) return;
    await HapticFeedback.vibrate();
  }
}
