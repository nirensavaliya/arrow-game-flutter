import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/game_controller.dart';
import '../../controller/theme_controller.dart';
import '../../modes/game_mode.dart';
import '../../services/game_storage.dart';
import '../../services/settings_storage.dart';
import '../../services/vibration_service.dart';
import '../../widgets/app_switch.dart';
import '../../widgets/round_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _accent = Color(0xFF5B5BF0);
  static const Color _accentDeep = Color(0xFF7C5CFA);
  static const Color _red = Color(0xFFD94F83);

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _darkModeEnabled = false;
  String _defaultMode = 'Normal Mode';

  ThemeController get _themeController => Get.find<ThemeController>();

  bool get _isDark => _themeController.isDarkMode.value;

  Color get _ink => _isDark ? const Color(0xFFF5F5FF) : const Color(0xFF17182B);

  Color get _muted =>
      _isDark ? const Color(0xFF9B9DB8) : const Color(0xFF6F7289);

  // Same as intro screen background
  Color get _background =>
      _isDark ? const Color(0xFF0A0B14) : const Color(0xFFF6F7FC);

  // Same as intro screen surface
  Color get _surface => _isDark ? const Color(0xFF14162A) : Colors.white;

  Color get _dividerColor =>
      _isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEDEEF5);

  Color get _dialogOptionColor =>
      _isDark ? const Color(0xFF1B1E36) : const Color(0xFFF0F1F8);

  Color get _cardBorder => _isDark
      ? Colors.white.withValues(alpha: 0.07)
      : const Color(0xFF5B5BF0).withValues(alpha: 0.06);

  List<BoxShadow> get _cardShadow => _isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF5B5BF0).withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _soundEnabled = SettingsStorage.getSoundEnabled();
    _vibrationEnabled = SettingsStorage.getVibrationEnabled();
    _darkModeEnabled = SettingsStorage.getDarkModeEnabled();
    _defaultMode = SettingsStorage.getDefaultGameMode();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: _background,
        body: Stack(
          children: [
            // Soft ambient glow behind the header
            Positioned(
              top: -120,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accent.withValues(alpha: _isDark ? 0.28 : 0.16),
                      _accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppBar(),
                    const SizedBox(height: 22),

                    _sectionTitle('Gameplay'),
                    const SizedBox(height: 12),

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
                      _buildSwitchTile(
                        icon: Icons.vibration_rounded,
                        iconColor: const Color(0xFF219B68),
                        title: 'Vibration',
                        subtitle: 'Haptic feedback on moves',
                        value: _vibrationEnabled,
                        onChanged: (value) async {
                          setState(() => _vibrationEnabled = value);
                          await SettingsStorage.setVibrationEnabled(value);
                        },
                      ),
                      _buildDivider(),
                      _buildActionTile(
                        icon: Icons.timer_rounded,
                        iconColor: const Color(0xFFE99A32),
                        title: 'Default Game Mode',
                        subtitle: _defaultMode,
                        onTap: _showGameModeDialog,
                      ),
                    ]),

                    const SizedBox(height: 26),

                    _sectionTitle('Preferences'),
                    const SizedBox(height: 12),

                    _buildSettingsCard([
                      _buildSwitchTile(
                        icon: Icons.dark_mode_rounded,
                        iconColor: const Color(0xFF3978D4),
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

                    const SizedBox(height: 26),

                    _sectionTitle('About'),
                    const SizedBox(height: 12),

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
                        iconColor: const Color(0xFF3978D4),
                        title: 'App Version',
                        subtitle: 'Version 1.0.0',
                        showArrow: false,
                        onTap: () {},
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAppBar() {
    return Row(
      spacing: 8,
      children: [
        RoundButton(
          icon: Icons.arrow_back_rounded,
          size: 46,
          iconSize: 23,
          radius: 15,
          onTap: () {
            VibrationService.tap();
            Get.back();
          },
        ),
        Expanded(
          child: Text(
            'Settings',
            style: TextStyle(
              color: _ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_accent, _accentDeep],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: _ink,
              fontSize: 15,
              letterSpacing: -0.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _cardBorder),
        boxShadow: _cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 78, right: 18),
      child: Divider(height: 1, thickness: 1, color: _dividerColor),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          _buildIconBox(icon, iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: _muted, fontSize: 12)),
              ],
            ),
          ),
          AppSwitch(
            value: value,
            onChanged: (newValue) {
              VibrationService.tap();
              onChanged(newValue);
            },
          ),
        ],
      ),
    );
  }

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
        onTap: onTap,
        splashColor: iconColor.withValues(alpha: 0.08),
        highlightColor: iconColor.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              _buildIconBox(icon, iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: danger ? _red : _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (showArrow)
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF3F4FA),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: _isDark
                        ? const Color(0xFF8D93AD)
                        : const Color(0xFF9A9CB4),
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox(IconData icon, Color color) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: _isDark ? 0.28 : 0.18),
            color.withValues(alpha: _isDark ? 0.12 : 0.07),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  void _showGameModeDialog() {
    final modes = ['Normal Mode', 'Timed Challenge', 'Speed Run'];

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: _cardBorder),
              ),
              title: Text(
                'Default Game Mode',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  letterSpacing: -0.3,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: modes.map((mode) {
                  final selected = _defaultMode == mode;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        VibrationService.tap();

                        await SettingsStorage.setDefaultGameMode(mode);

                        if (!mounted || !dialogContext.mounted) return;

                        setState(() => _defaultMode = mode);
                        Navigator.pop(dialogContext);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          gradient: selected
                              ? LinearGradient(
                                  colors: [
                                    _accent.withValues(
                                      alpha: _isDark ? 0.30 : 0.14,
                                    ),
                                    _accentDeep.withValues(
                                      alpha: _isDark ? 0.18 : 0.06,
                                    ),
                                  ],
                                )
                              : null,
                          color: selected ? null : _dialogOptionColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? _accent.withValues(alpha: 0.6)
                                : _dividerColor,
                            width: selected ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                mode,
                                style: TextStyle(
                                  color: selected
                                      ? (_isDark
                                            ? const Color(0xFFB5B2FF)
                                            : _accent)
                                      : _ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: _accent,
                                size: 22,
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
      },
    );
  }

  void _confirmReset() {
    Get.dialog<void>(
      AlertDialog(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: _cardBorder),
        ),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _red.withValues(alpha: _isDark ? 0.2 : 0.12),
          ),
          child: const Icon(Icons.restart_alt_rounded, color: _red, size: 28),
        ),
        title: Text(
          'Reset Progress?',
          style: TextStyle(
            color: _ink,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
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
            onPressed: () => Get.back(),
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
