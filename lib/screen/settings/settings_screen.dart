import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/game_controller.dart';
import '../../controller/theme_controller.dart';
import '../../modes/game_mode.dart';
import '../../storage/game_storage.dart';
import '../../storage/settings_storage.dart';
import '../../services/vibration_service.dart';
import '../../widgets/app_switch.dart';
import '../../widgets/round_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _accent = Color(0xFF8175FF);
  static const Color _accentDeep = Color(0xFF4B3FD1);
  static const Color _red = Color(0xFFFF4D5E);

  static const Color _darkBg = Color(0xFF07080F);
  static const Color _darkSurface = Color(0xFF12141F);
  static const Color _darkTextPrimary = Color(0xFFF7F7FC);
  static const Color _darkTextSecondary = Color(0xFF8E92AB);

  static const Color _lightBg = Color(0xFFF4F5FA);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightTextPrimary = Color(0xFF14162A);
  static const Color _lightTextSecondary = Color(0xFF6F7390);

  bool _soundEnabled = true;
  bool _systemTapSoundEnabled = true;
  bool _vibrationEnabled = true;
  bool _darkModeEnabled = false;
  String _defaultMode = 'Normal Mode';

  late final AnimationController _ambient;

  ThemeController get _themeController => Get.find<ThemeController>();

  bool get _isDark => _themeController.isDarkMode.value;

  Color get _ink => _isDark ? _darkTextPrimary : _lightTextPrimary;

  Color get _muted => _isDark ? _darkTextSecondary : _lightTextSecondary;

  Color get _background => _isDark ? _darkBg : _lightBg;

  Color get _surface => _isDark ? _darkSurface : _lightSurface;

  Color get _dividerColor => _isDark
      ? Colors.white.withValues(alpha: 0.07)
      : Colors.black.withValues(alpha: 0.065);

  Color get _cardBorder => _isDark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.black.withValues(alpha: 0.055);

  Color get _dialogOptionColor =>
      _isDark ? const Color(0xFF1B1E2C) : const Color(0xFFF3F4FA);

  List<BoxShadow> get _cardShadow => [
    BoxShadow(
      color: _isDark
          ? Colors.black.withValues(alpha: 0.25)
          : const Color(0xFF8175FF).withValues(alpha: 0.055),
      blurRadius: 24,
      offset: const Offset(0, 9),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _loadSettings();

    _ambient = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(seconds: 7),
    );
  }

  void _loadSettings() {
    _soundEnabled = SettingsStorage.getSoundEnabled();
    _systemTapSoundEnabled = SettingsStorage.getSystemTapSoundEnabled();
    _vibrationEnabled = SettingsStorage.getVibrationEnabled();
    _darkModeEnabled = SettingsStorage.getDarkModeEnabled();
    _defaultMode = SettingsStorage.getDefaultGameMode();
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: _background,
        body: Stack(
          children: [
            Positioned.fill(child: _buildBackground()),

            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                    child: _buildAppBar(),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 26, 18, 35),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // GAMEPLAY
                          _sectionTitle(
                            'Gameplay',
                            Icons.sports_esports_rounded,
                          ),
                          const SizedBox(height: 13),

                          _buildSettingsCard([
                            _buildSwitchTile(
                              icon: Icons.volume_up_rounded,
                              iconColor: _accent,
                              title: 'Sound Effects',
                              subtitle: 'Sounds during gameplay',
                              value: _soundEnabled,
                              onChanged: (value) async {
                                setState(() => _soundEnabled = value);
                                await SettingsStorage.setSoundEnabled(value);
                              },
                            ),

                            _buildDivider(),

                            // SYSTEM TAP SOUND
                            _buildSwitchTile(
                              icon: Icons.touch_app_rounded,
                              iconColor: const Color(0xFFFFB34F),
                              title: 'System Tap Sound',
                              subtitle: 'Native click sound when tapping',
                              value: _systemTapSoundEnabled,
                              onChanged: (value) async {
                                setState(() {
                                  _systemTapSoundEnabled = value;
                                });

                                await SettingsStorage.setSystemTapSoundEnabled(
                                  value,
                                );
                              },
                            ),

                            _buildDivider(),

                            _buildSwitchTile(
                              icon: Icons.vibration_rounded,
                              iconColor: const Color(0xFF35D68A),
                              title: 'Vibration',
                              subtitle: 'Haptic feedback on moves',
                              value: _vibrationEnabled,
                              onChanged: (value) async {
                                setState(() => _vibrationEnabled = value);
                                await SettingsStorage.setVibrationEnabled(
                                  value,
                                );
                              },
                            ),

                            _buildDivider(),

                            _buildActionTile(
                              icon: Icons.timer_rounded,
                              iconColor: const Color(0xFFFFB34F),
                              title: 'Default Game Mode',
                              subtitle: _defaultMode,
                              onTap: _showGameModeDialog,
                            ),
                          ]),

                          const SizedBox(height: 28),

                          // PREFERENCES
                          _sectionTitle('Preferences', Icons.tune_rounded),
                          const SizedBox(height: 13),

                          _buildSettingsCard([
                            _buildSwitchTile(
                              icon: Icons.dark_mode_rounded,
                              iconColor: const Color(0xFF6D9FFF),
                              title: 'Dark Mode',
                              subtitle: 'Use a darker appearance',
                              value: _darkModeEnabled,
                              onChanged: (value) async {
                                setState(() => _darkModeEnabled = value);
                                await _themeController.toggleTheme(value);
                              },
                            ),

                            _buildDivider(),

                            _buildActionTile(
                              icon: Icons.restart_alt_rounded,
                              iconColor: _red,
                              title: 'Reset Progress',
                              subtitle: 'Restart your level progress',
                              onTap: _confirmReset,
                              danger: true,
                            ),
                          ]),

                          const SizedBox(height: 28),

                          // ABOUT
                          _sectionTitle('About', Icons.info_outline_rounded),
                          const SizedBox(height: 13),

                          _buildSettingsCard([
                            _buildActionTile(
                              icon: Icons.shield_outlined,
                              iconColor: _accent,
                              title: 'Privacy Policy',
                              subtitle: 'How your data is handled',
                              onTap: () {
                                _showSnackbar(
                                  'Privacy Policy',
                                  'Connect your privacy policy URL here.',
                                );
                              },
                            ),

                            _buildDivider(),

                            _buildActionTile(
                              icon: Icons.info_outline_rounded,
                              iconColor: const Color(0xFF6D9FFF),
                              title: 'App Version',
                              subtitle: 'Version 1.0.0',
                              showArrow: false,
                              onTap: () {},
                            ),
                          ]),

                          const SizedBox(height: 30),

                          // FOOTER
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 43,
                                  height: 43,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [_accent, _accentDeep],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _accent.withValues(alpha: 0.25),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.route_rounded,
                                    color: Colors.white,
                                    size: 23,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'ARROW MAZE',
                                  style: TextStyle(
                                    color: _ink,
                                    fontSize: 12,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Think • Trace • Escape',
                                  style: TextStyle(
                                    color: _muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  'Version 1.0.0',
                                  style: TextStyle(
                                    color: _muted.withValues(alpha: 0.7),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // --------------------------------------------------
  // BACKGROUND - MATCH INTRO SCREEN
  // --------------------------------------------------

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _SettingsMazePainter(
              color: (_isDark ? Colors.white : Colors.black).withValues(
                alpha: _isDark ? 0.03 : 0.035,
              ),
            ),
          ),
        ),

        Positioned(
          top: -150,
          right: -120,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _accent.withValues(alpha: _isDark ? 0.24 : 0.13),
                  _accent.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _accentDeep.withValues(alpha: _isDark ? 0.16 : 0.08),
                  _accentDeep.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // APP BAR
  // --------------------------------------------------

  Widget _buildAppBar() {
    return Row(
      children: [
        RoundButton(
          icon: Icons.arrow_back_rounded,
          size: 44,
          iconSize: 21,
          radius: 15,
          onTap: () {
            SettingsStorage.playSystemTapSound();
            VibrationService.tap();
            Get.back();
          },
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: _ink,
                  fontSize: 23,
                  letterSpacing: -0.7,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Customize your game experience',
                style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // SECTION TITLE
  // --------------------------------------------------

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: _isDark ? 0.16 : 0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: _accent, size: 17),
          ),

          const SizedBox(width: 10),

          Text(
            title,
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              letterSpacing: -0.3,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // SETTINGS CARD
  // --------------------------------------------------

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _cardBorder),
        boxShadow: _cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 76, right: 18),
      child: Divider(height: 1, thickness: 1, color: _dividerColor),
    );
  }

  // --------------------------------------------------
  // SWITCH TILE
  // --------------------------------------------------

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        children: [
          _buildIconBox(icon, iconColor),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          AppSwitch(
            value: value,
            onChanged: (newValue) async {
              await SettingsStorage.playSystemTapSound();
              VibrationService.tap();
              onChanged(newValue);
            },
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // ACTION TILE
  // --------------------------------------------------

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showArrow = true,
    bool danger = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await SettingsStorage.playSystemTapSound();
          VibrationService.tap();
          onTap();
        },
        splashColor: iconColor.withValues(alpha: 0.08),
        highlightColor: iconColor.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Row(
            children: [
              _buildIconBox(icon, iconColor),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: danger ? _red : _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              if (showArrow)
                Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    color: _isDark
                        ? Colors.white.withValues(alpha: 0.055)
                        : const Color(0xFFF2F3F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: _muted,
                    size: 19,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // ICON BOX
  // --------------------------------------------------

  Widget _buildIconBox(IconData icon, Color color) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: _isDark ? 0.23 : 0.13),
            color.withValues(alpha: _isDark ? 0.10 : 0.055),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }

  // --------------------------------------------------
  // DEFAULT GAME MODE DIALOG
  // --------------------------------------------------

  void _showGameModeDialog() {
    final modes = ['Normal Mode', 'Timed Challenge', 'Speed Run'];

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
            side: BorderSide(color: _cardBorder),
          ),
          title: Text(
            'Default Game Mode',
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
              fontSize: 19,
              letterSpacing: -0.4,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: modes.map((mode) {
              final selected = _defaultMode == mode;

              final Color modeColor = mode == 'Normal Mode'
                  ? _accent
                  : mode == 'Timed Challenge'
                  ? const Color(0xFFFFB34F)
                  : const Color(0xFF35D68A);

              final IconData modeIcon = mode == 'Normal Mode'
                  ? Icons.explore_rounded
                  : mode == 'Timed Challenge'
                  ? Icons.timer_rounded
                  : Icons.bolt_rounded;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(17),
                  onTap: () async {
                    SettingsStorage.playSystemTapSound();
                    VibrationService.tap();

                    await SettingsStorage.setDefaultGameMode(mode);

                    if (!mounted || !dialogContext.mounted) return;

                    setState(() => _defaultMode = mode);

                    Navigator.pop(dialogContext);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? modeColor.withValues(alpha: _isDark ? 0.16 : 0.09)
                          : _dialogOptionColor,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: selected
                            ? modeColor.withValues(alpha: 0.55)
                            : _dividerColor,
                        width: selected ? 1.3 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 37,
                          height: 37,
                          decoration: BoxDecoration(
                            color: modeColor.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(modeIcon, color: modeColor, size: 20),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            mode,
                            style: TextStyle(
                              color: selected ? modeColor : _ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        if (selected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: modeColor,
                            size: 21,
                          )
                        else
                          Icon(
                            Icons.circle_outlined,
                            color: _muted.withValues(alpha: 0.4),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // --------------------------------------------------
  // RESET PROGRESS
  // --------------------------------------------------

  void _confirmReset() {
    Get.dialog<void>(
      AlertDialog(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(27),
          side: BorderSide(color: _cardBorder),
        ),
        icon: Container(
          width: 57,
          height: 57,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _red.withValues(alpha: _isDark ? 0.18 : 0.10),
          ),
          child: const Icon(Icons.restart_alt_rounded, color: _red, size: 29),
        ),
        title: Text(
          'Reset Progress?',
          style: TextStyle(
            color: _ink,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        content: Text(
          'This will reset all game modes to Level 1. '
          'Your sound, vibration, and other settings will remain unchanged.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, height: 1.5, fontSize: 13),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () {
              SettingsStorage.playSystemTapSound();
              Get.back();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
            ),
          ),

          ElevatedButton(
            onPressed: () async {
              SettingsStorage.playSystemTapSound();
              Get.back();

              try {
                if (Get.isRegistered<GameController>()) {
                  await Get.find<GameController>().resetAllProgress();
                } else {
                  await Future.wait([
                    GameStorage.clearProgress(GameMode.normal.name),
                    GameStorage.clearProgress(GameMode.timedChallenge.name),
                    GameStorage.clearProgress(GameMode.speedRun.name),
                  ]);
                }

                _showSnackbar(
                  'Progress Reset',
                  'All game modes have been reset to Level 1.',
                );
              } catch (e) {
                _showSnackbar(
                  'Reset Failed',
                  'Could not reset progress. Please try again.',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Reset',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // SNACKBAR
  // --------------------------------------------------

  void _showSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _surface,
      colorText: _ink,
      borderRadius: 18,
      borderColor: _cardBorder,
      borderWidth: 1,
      margin: const EdgeInsets.all(16),
    );
  }
}

// --------------------------------------------------
// MAZE BACKGROUND PAINTER
// --------------------------------------------------

class _SettingsMazePainter extends CustomPainter {
  final Color color;

  const _SettingsMazePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double cell = 36;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final rnd = math.Random(11);

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
  bool shouldRepaint(covariant _SettingsMazePainter old) {
    return old.color != color;
  }
}
