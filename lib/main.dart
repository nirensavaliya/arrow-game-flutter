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
/// Prevents layout jumps when full-screen ads open and close.
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

/// Application entry point.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --------------------------------------------------
  // 1. Enable immersive sticky full-screen mode
  // --------------------------------------------------

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

   SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
  );

  // --------------------------------------------------
  // 2. Initialize Firebase
  // --------------------------------------------------

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --------------------------------------------------
  // 3. Initialize Crashlytics
  // --------------------------------------------------

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);

    return true;
  };

  // --------------------------------------------------
  // 4. Initialize Firebase Analytics
  // --------------------------------------------------

  await AnalyticsService.instance.setAnalyticsEnabled(!kDebugMode);

  // --------------------------------------------------
  // 5. Initialize Remote Config
  // --------------------------------------------------

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

  // --------------------------------------------------
  // 6. Initialize Google Mobile Ads
  // --------------------------------------------------

  if (RemoteConfigService.instance.adsEnabled) {
    await MobileAds.instance.initialize();
  }

  // --------------------------------------------------
  // 7. Start App Open Ads
  // --------------------------------------------------

  AppOpenAdService.instance.start();

  // --------------------------------------------------
  // 8. Initialize GetStorage
  // --------------------------------------------------

  await GetStorage.init();

  // --------------------------------------------------
  // 9. Initialize GetX controllers
  // --------------------------------------------------

  Get.put(GameController(), permanent: true);

  final themeController = Get.put(ThemeController(), permanent: true);

  // Load saved theme
  themeController.loadTheme();

  // --------------------------------------------------
  // 10. Start application
  // --------------------------------------------------

  runApp(const MyApp());
}

// ======================================================
// MAIN APPLICATION
// ======================================================

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _enableImmersiveMode();
  }

  /// Enables immersive mode.
  ///
  /// Reapplies immersive mode when returning from:
  /// - Full-screen advertisements
  /// - External applications
  /// - System UI interruptions
  Future<void> _enableImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enableImmersiveMode();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeController = Get.find<ThemeController>();

      return GetMaterialApp(
        title: 'Arrow Escape',
        debugShowCheckedModeBanner: false,

        // ------------------------------------------------
        // THEME MODE
        // ------------------------------------------------
        themeMode: themeController.isDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,

        // ------------------------------------------------
        // LIGHT THEME
        // ------------------------------------------------
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

        // ------------------------------------------------
        // DARK THEME
        // ------------------------------------------------
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

        // ------------------------------------------------
        // STABLE SYSTEM INSETS
        // ------------------------------------------------
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

        // ------------------------------------------------
        // INITIAL SCREEN
        // ------------------------------------------------
        home: const SplashScreen(),
      );
    });
  }
}
