import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/theme_controller.dart';

class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final double scale;

  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = const Color(0xFF5B5BF0),
    this.inactiveColor = const Color(0xFFE5E7F0),
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode.value;

      final trackColor = value
          ? activeColor
          : isDark
          ? const Color(0xFF383C50)
          : inactiveColor;

      return Transform.scale(
        scale: scale,
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOutCubic,
            width: 48,
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(30),

              boxShadow: [
                if (value)
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFFF2F3FF) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.18 : 0.08,
                      ),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
