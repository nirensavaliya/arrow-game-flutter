import 'package:flutter/animation.dart';

/// Shared animation timings and easing curves for Arrow Maze.
///
/// Keep these method names compatible with GameController so existing
/// animation and game logic continues to work.
class ArrowMotion {
  ArrowMotion._();

  /// Approximate frame interval used by the existing animation loop.
  static const Duration frameDelay = Duration(milliseconds: 16);

  // ------------------------------------------------------------
  // ESCAPE ANIMATION
  // ------------------------------------------------------------

  /// Total frames for an arrow to leave the board.
  static const int escapeFrames = 36;

  /// Smoothly accelerates an arrow as it escapes.
  static double escape(int frame) {
    final progress = (frame / escapeFrames).clamp(0.0, 1.0);
    return Curves.easeInCubic.transform(progress);
  }

  // ------------------------------------------------------------
  // BLOCKED ARROW BUMP ANIMATION
  // ------------------------------------------------------------

  /// Frames for the arrow to move forward before hitting the obstacle.
  static const int bumpForwardFrames = 12;

  /// Frames for the arrow to return to its original position.
  static const int bumpBackFrames = 16;

  /// Moves the blocked arrow forward smoothly, then slows near the obstacle.
  static double bumpForward(int frame) {
    final progress = (frame / bumpForwardFrames).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(progress);
  }

  /// Returns the blocked arrow smoothly to its original position.
  static double bumpBack(int frame) {
    final progress = (frame / bumpBackFrames).clamp(0.0, 1.0);
    return 1.0 - Curves.easeInOutCubic.transform(progress);
  }
}
