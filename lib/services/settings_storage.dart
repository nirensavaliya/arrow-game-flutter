import 'package:get_storage/get_storage.dart';

class SettingsStorage {
  static final GetStorage _storage = GetStorage();

  static const String _soundKey = 'settings_sound_enabled';
  static const String _vibrationKey = 'settings_vibration_enabled';
  static const String _darkModeKey = 'settings_dark_mode_enabled';
  static const String _defaultModeKey = 'settings_default_game_mode';

  // Sound Effects
  static bool getSoundEnabled() {
    return _storage.read<bool>(_soundKey) ?? true;
  }

  static Future<void> setSoundEnabled(bool value) async {
    await _storage.write(_soundKey, value);
  }

  // Vibration
  static bool getVibrationEnabled() {
    return _storage.read<bool>(_vibrationKey) ?? true;
  }

  static Future<void> setVibrationEnabled(bool value) async {
    await _storage.write(_vibrationKey, value);
  }

  // Dark Mode
  static bool getDarkModeEnabled() {
    return _storage.read<bool>(_darkModeKey) ?? false;
  }

  static Future<void> setDarkModeEnabled(bool value) async {
    await _storage.write(_darkModeKey, value);
  }

  // Default Game Mode
  static String getDefaultGameMode() {
    return _storage.read<String>(_defaultModeKey) ?? 'Normal Mode';
  }

  static Future<void> setDefaultGameMode(String value) async {
    await _storage.write(_defaultModeKey, value);
  }

  // Reset only settings; game progress remains untouched.
  static Future<void> resetSettings() async {
    await Future.wait([
      _storage.remove(_soundKey),
      _storage.remove(_vibrationKey),
      _storage.remove(_darkModeKey),
      _storage.remove(_defaultModeKey),
    ]);
  }
}
