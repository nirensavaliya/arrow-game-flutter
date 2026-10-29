import 'package:flutter/material.dart';

class AppColors {
  // APP BACKGROUND
  static const Color background = Color(0xFFF5F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF0F3FA);
  static const Color surfaceDark = Color(0xFFE7ECF5);

  // PRIMARY COLORS
  static const Color primary = Color(0xFF5865F2);
  static const Color primaryDark = Color(0xFF414BC4);
  static const Color primaryLight = Color(0xFF8B93FF);

  // TEXT COLORS
  static const Color textPrimary = Color(0xFF1E2433);
  static const Color textSecondary = Color(0xFF737D91);
  static const Color textMuted = Color(0xFFA3ACBD);
  static const Color textWhite = Color(0xFFFFFFFF);

  // ARROW GAME BOARD
  static const Color boardBackground = Color(0xFFFFFFFF);
  static const Color boardBorder = Color(0xFFE4E9F3);
  static const Color gridDot = Color(0xFFDCE2EF);
  static const Color arrowLine = Color(0xFF252D43);
  static const Color arrowHead = Color(0xFF252D43);
  static const Color blockedArrow = Color(0xFFFF5B6E);
  static const Color selectedArrow = Color(0xFF5865F2);
  static const Color completedArrow = Color(0xFF24B47E);

  // ARROW COLORS
  static const Color arrowBlue = Color(0xFF4F7CFF);
  static const Color arrowPurple = Color(0xFF9B6DFF);
  static const Color arrowGreen = Color(0xFF2DBD85);
  static const Color arrowOrange = Color(0xFFFFA447);
  static const Color arrowPink = Color(0xFFFF6FAE);
  static const Color arrowCyan = Color(0xFF28B9D4);
  static const Color arrowYellow = Color(0xFFF2C94C);
  static const Color arrowRed = Color(0xFFFF647C);

  static const List<Color> arrowPalette = [
    arrowBlue,
    arrowPurple,
    arrowGreen,
    arrowOrange,
    arrowPink,
    arrowCyan,
    arrowYellow,
    arrowRed,
  ];

  // GAME MODES
  static const Color normalMode = Color(0xFF4F7CFF);
  static const Color speedRunMode = Color(0xFFFF9F43);
  static const Color timerChallengeMode = Color(0xFF9B6DFF);

  // LEVELS & PROGRESS
  static const Color levelCompleted = Color(0xFF24B47E);
  static const Color levelCurrent = Color(0xFF5865F2);
  static const Color levelLocked = Color(0xFFE2E7F0);
  static const Color progressTrack = Color(0xFFE8ECF5);
  static const Color progressFill = Color(0xFF5865F2);

  // STATUS COLORS
  static const Color success = Color(0xFF24B47E);
  static const Color warning = Color(0xFFFFA447);
  static const Color error = Color(0xFFFF5B6E);
  static const Color info = Color(0xFF4F7CFF);

  // BUTTONS & BORDERS
  static const Color buttonPrimary = Color(0xFF5865F2);
  static const Color buttonSecondary = Color(0xFFF0F3FA);
  static const Color buttonDisabled = Color(0xFFDCE2EF);
  static const Color border = Color(0xFFE4E9F3);
  static const Color divider = Color(0xFFEDF0F6);

  // OVERLAYS & SHADOWS
  static const Color overlay = Color(0x66000000);
  static const Color shadow = Color(0x140F172A);

  // ICON COLORS
  static const Color iconPrimary = Color(0xFF30394D);
  static const Color iconSecondary = Color(0xFF8791A5);
  static const Color iconOnPrimary = Color(0xFFFFFFFF);
}
