import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/settings_storage.dart';

class ThemeController extends GetxController {
  final RxBool isDarkMode = false.obs;

  bool get isDark => isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    loadTheme();
  }

  void loadTheme() {
    final savedDarkMode = SettingsStorage.getDarkModeEnabled();

    isDarkMode.value = savedDarkMode;

    Get.changeThemeMode(savedDarkMode ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleTheme(bool value) async {
    isDarkMode.value = value;

    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);

    await SettingsStorage.setDarkModeEnabled(value);
  }

  Future<void> toggle() async {
    await toggleTheme(!isDarkMode.value);
  }
}
