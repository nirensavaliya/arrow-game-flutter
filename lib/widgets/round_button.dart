import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';
import '../controller/theme_controller.dart';

class RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;
  final double? size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final double radius;

  const RoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.dark = false,
    this.size,
    this.iconSize = 21,
    this.backgroundColor,
    this.iconColor,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode.value;

      final buttonBackground =
          backgroundColor ??
          (dark
              ? (isDark ? const Color(0xFF30354B) : AppColors.textPrimary)
              : (isDark ? const Color(0xFF1B1E2C) : AppColors.surface));

      final buttonIconColor =
          iconColor ??
          (dark
              ? AppColors.iconOnPrimary
              : (isDark ? const Color(0xFFF2F3FF) : AppColors.iconPrimary));

      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: buttonBackground,
            borderRadius: BorderRadius.circular(radius),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: iconSize, color: buttonIconColor),
        ),
      );
    });
  }
}
