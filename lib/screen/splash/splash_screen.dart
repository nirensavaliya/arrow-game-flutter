import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/theme_controller.dart';
import '../game/game_intro_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.65,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Get.off(
        () => const GameIntroScreen(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 500),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final bool isDark = themeController.isDarkMode.value;

    final screenBackground = isDark
        ? const Color(0xFF10111A)
        : const Color(0xFFF7F7FC);

    final cardBackground = isDark
        ? const Color(0xFF1B1E2C)
        : const Color(0xFFFCFCFF);

    final primaryText = isDark
        ? const Color(0xFFF3F3FC)
        : const Color(0xFF14162B);

    final secondaryText = isDark
        ? const Color(0xFFB0B1C5)
        : const Color(0xFF85869D);


    return Scaffold(
      backgroundColor: screenBackground,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.route_rounded,
                    size: 62,
                    color: Color(0xFF5B5BF0),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'ARROW MAZE',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Think smart. Find the way.',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryText,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 42),
                SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(10),
                    backgroundColor: const Color(
                      0xFF5B5BF0,
                    ).withValues(alpha: isDark ? 0.22 : 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF5B5BF0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
