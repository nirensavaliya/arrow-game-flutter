import 'dart:ui';

import 'package:arrow/constants/app_colors.dart';
import 'package:arrow/controller/game_controller.dart';
import 'package:arrow/controller/theme_controller.dart';
import 'package:arrow/screen/splash/splash_screen.dart';
import 'package:arrow/services/analytics_service.dart';
import 'package:arrow/services/remote_config_service.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Crashlytics
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize Firebase Analytics
  await AnalyticsService.instance.setAnalyticsEnabled(true);

  // Initialize Firebase Remote Config (defaults + settings + fetch).
  // Must run before GameController is created.
  try {
    await RemoteConfigService.instance.initialize();
  } catch (e) {
    debugPrint('Remote Config initialization error: $e');
  }

  // Initialize Google Mobile Ads
  await MobileAds.instance.initialize();

  // Initialize GetStorage
  await GetStorage.init();

  // Initialize GetX controllers
  Get.put(GameController(), permanent: true);

  final themeController = Get.put(ThemeController(), permanent: true);

  // Load saved theme
  themeController.loadTheme();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeController = Get.find<ThemeController>();

      return GetMaterialApp(
        title: "Arrow Escape",
        debugShowCheckedModeBanner: false,

        themeMode: themeController.isDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,

        theme: ThemeData(
          brightness: Brightness.light,
          fontFamily: 'Outfit',
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
            surface: AppColors.surface,
          ),
          useMaterial3: true,
        ),

        darkTheme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'Outfit',
          scaffoldBackgroundColor: const Color(0xFF10121D),
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.dark,
            surface: const Color(0xFF1B1E2C),
          ),
          useMaterial3: true,
        ),

        home: const SplashScreen(),
      );
    });
  }
}
