import 'package:arrow/constants/app_colors.dart';
import 'package:arrow/controller/game_controller.dart';
import 'package:arrow/controller/theme_controller.dart';
import 'package:arrow/screen/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await MobileAds.instance.initialize();
  await GetStorage.init();

  Get.put(GameController(), permanent: true);

  final themeController = Get.put(ThemeController(), permanent: true);

  // Load the saved theme before showing the app.
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
