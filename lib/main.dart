import 'dart:ui';

import 'package:arrow/constants/app_colors.dart';
import 'package:arrow/controller/game_controller.dart';
import 'package:arrow/controller/theme_controller.dart';
import 'package:arrow/screen/splash/splash_screen.dart';
import 'package:arrow/services/ads/ad_config.dart';
import 'package:arrow/services/analytics_service.dart';
import 'package:arrow/services/ads/app_open_ad_service.dart';
import 'package:arrow/services/remote_config_service.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'firebase_options.dart';

/// Remembers the last real system bar insets.
///
/// While a full-screen ad (AdActivity) is open, Android reports
/// padding.top = 0 (status bar hidden). When the ad closes it goes back
/// to the real value. That change makes every SafeArea / MediaQuery.padding
/// based layout jump up and down. We ignore the temporary 0 and keep the
/// last real value so the layout stays stable.
class StableInsets {
  static double top = 0;
  static double bottom = 0;
  static double left = 0;
  static double right = 0;

  static void update(EdgeInsets padding) {
    if (padding.top > 0) top = padding.top;
    if (padding.bottom > 0) bottom = padding.bottom;
    if (padding.left > 0) left = padding.left;
    if (padding.right > 0) right = padding.right;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Crashlytics
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize Firebase Analytics
  await AnalyticsService.instance.setAnalyticsEnabled(!kDebugMode);

  // Initialize Firebase Remote Config
  // Must run before GameController is created.
  try {
    await RemoteConfigService.instance.initialize();
    AdConfig.printAdConfiguration();
  } catch (e, stack) {
    debugPrint('Remote Config initialization error: $e');

    await FirebaseCrashlytics.instance.recordError(
      e,
      stack,
      reason: 'Remote Config initialization failed',
    );
  }

  // Initialize Google Mobile Ads
  if (RemoteConfigService.instance.adsEnabled) {
    await MobileAds.instance.initialize();
  }
  AppOpenAdService.instance.start();
  // Initialize GetStorage
  await GetStorage.init();

  // Initialize GetX controllers
  Get.put(GameController(), permanent: true);

  final themeController = Get.put(ThemeController(), permanent: true);

  // Load saved theme
  themeController.loadTheme();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

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

        // Keeps system insets constant so screens don't jump
        // when a full-screen ad opens/closes.
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          StableInsets.update(mq.padding);

          final stablePadding = EdgeInsets.fromLTRB(
            StableInsets.left,
            StableInsets.top,
            StableInsets.right,
            StableInsets.bottom,
          );

          return MediaQuery(
            data: mq.copyWith(
              padding: stablePadding,
              viewPadding: stablePadding,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },

        home: const SplashScreen(),
      );
    });
  }
}
