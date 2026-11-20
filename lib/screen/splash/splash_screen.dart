
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../services/force_update_service.dart';
import '../../widgets/force_update_dialog.dart';
import '../game/game_intro_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _darkVideoPath =
      'assets/videos/splash_video.mp4';

  static const String _lightVideoPath =
      'assets/videos/splash_video_light.mp4';

  static const Color _darkBackground = Color(0xFF0B1030);
  static const Color _lightBackground = Color(0xFFF4F5FA);

  static const Color _darkPrimaryText = Color(0xFFF7F7FC);
  static const Color _lightPrimaryText = Color(0xFF14162A);

  static const Color _darkSecondaryText = Color(0xFF8E92AB);
  static const Color _lightSecondaryText = Color(0xFF6F7390);

  late final VideoPlayerController _videoController;

  late final Future<bool> _updateCheckFuture;

  bool _isLightTheme = false;
  bool _isVideoReady = false;
  bool _navigationStarted = false;
  bool _videoFailed = false;
  bool _videoInitializationStarted = false;

  String get _videoPath =>
      _isLightTheme ? _lightVideoPath : _darkVideoPath;

  Color get _background =>
      _isLightTheme ? Colors.white : _darkBackground;

  Color get _primaryText =>
      _isLightTheme ? _lightPrimaryText : _darkPrimaryText;

  Color get _secondaryText =>
      _isLightTheme ? _lightSecondaryText : _darkSecondaryText;

  @override
  void initState() {
    super.initState();

    // Start force update check while the splash video plays.
    _updateCheckFuture =
        ForceUpdateService.instance.isUpdateRequired();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_videoInitializationStarted) return;

    _videoInitializationStarted = true;

    // Detect the current application theme.
    _isLightTheme =
        Theme.of(context).brightness == Brightness.light;

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset(_videoPath);

    try {
      await _videoController.initialize();

      if (!mounted) return;

      await _videoController.setLooping(false);
      await _videoController.setVolume(0);

      _videoController.addListener(_videoListener);

      setState(() {
        _isVideoReady = true;
      });

      await _videoController.play();
    } catch (e) {
      debugPrint('Splash video initialization failed: $e');

      if (!mounted) return;

      setState(() {
        _videoFailed = true;
      });

      // No timer-based navigation.
      // Navigation happens only after the video finishes.
    }
  }

  void _videoListener() {
    if (!_videoController.value.isInitialized ||
        _navigationStarted) {
      return;
    }

    final value = _videoController.value;

    if (value.hasError) {
      debugPrint(
        'Splash video error: ${value.errorDescription}',
      );
      return;
    }

    // Navigate only after the video finishes.
    if (value.position >= value.duration &&
        !value.isPlaying) {
      _checkForceUpdate();
    }
  }

  Future<void> _checkForceUpdate() async {
    if (_navigationStarted || !mounted) return;

    _navigationStarted = true;

    try {
      // Use the Remote Config check started during splash loading.
      final updateRequired = await _updateCheckFuture;

      if (!mounted) return;

      if (updateRequired) {
        ForceUpdateDialog.show();
        return;
      }

      Get.off(
            () => const GameIntroScreen(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 500),
      );
    } catch (e) {
      debugPrint('Force update check failed: $e');

      if (!mounted) return;

      // Allow the game to open if the update check fails.
      Get.off(
            () => const GameIntroScreen(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-screen animated splash video.
            // Full video centered without cropping.
            if (_isVideoReady)
              LayoutBuilder(
                builder: (context, constraints) {
                  final videoSize = _videoController.value.size;

                  final videoWidth = videoSize.width;
                  final videoHeight = videoSize.height;

                  final scale = math.min(
                    constraints.maxWidth / videoWidth,
                    constraints.maxHeight / videoHeight,
                  );

                  final displayWidth = videoWidth * scale;
                  final displayHeight = videoHeight * scale;

                  return Center(
                    child: SizedBox(
                      width: displayWidth,
                      height: displayHeight,
                      child: VideoPlayer(_videoController),
                    ),
                  );
                },
              )
            else
              ColoredBox(color: _background),

            // Subtle bottom gradient for branding.
            // Positioned(
            //   left: 0,
            //   right: 0,
            //   bottom: 0,
            //   height: 260,
            //   child: IgnorePointer(
            //     child: DecoratedBox(
            //       decoration: BoxDecoration(
            //         gradient: LinearGradient(
            //           begin: Alignment.topCenter,
            //           end: Alignment.bottomCenter,
            //           colors: [
            //             Colors.transparent,
            //             _background.withValues(alpha: 0.65),
            //             _background,
            //           ],
            //         ),
            //       ),
            //     ),
            //   ),
            // ),

            // // App branding and loading indicator.
            // Positioned(
            //   left: 24,
            //   right: 24,
            //   bottom: MediaQuery.of(context).padding.bottom + 55,
            //   child: Column(
            //     mainAxisSize: MainAxisSize.min,
            //     children: [
            //       Text(
            //         'Arrow Escape',
            //         textAlign: TextAlign.center,
            //         style: TextStyle(
            //           color: _primaryText,
            //           fontSize: 30,
            //           letterSpacing: -1.1,
            //           fontWeight: FontWeight.w900,
            //         ),
            //       ),
            //
            //       const SizedBox(height: 7),
            //
            //       Text(
            //         'Think • Trace • Escape',
            //         textAlign: TextAlign.center,
            //         style: TextStyle(
            //           color: _secondaryText,
            //           fontSize: 12,
            //           letterSpacing: 1.1,
            //           fontWeight: FontWeight.w600,
            //         ),
            //       ),
            //
            //       const SizedBox(height: 34),
            //
            //       // Video progress indicator.
            //       SizedBox(
            //         width: 125,
            //         child: ClipRRect(
            //           borderRadius: BorderRadius.circular(10),
            //           child: _videoFailed
            //               ? const LinearProgressIndicator(
            //                   minHeight: 4,
            //                   backgroundColor: Color(0x332FFFFFF),
            //                   valueColor: AlwaysStoppedAnimation(
            //                     Color(0xFF8175FF),
            //                   ),
            //                 )
            //               : ValueListenableBuilder<VideoPlayerValue>(
            //                   valueListenable: _videoController,
            //                   builder: (context, value, child) {
            //                     final progress =
            //                         value.duration.inMilliseconds > 0
            //                             ? (value.position.inMilliseconds /
            //                                     value.duration.inMilliseconds)
            //                                 .clamp(0.0, 1.0)
            //                             : 0.0;
            //
            //                     return LinearProgressIndicator(
            //                       value: progress,
            //                       minHeight: 4,
            //                       backgroundColor:
            //                           Colors.white.withValues(alpha: 0.12),
            //                       valueColor:
            //                           const AlwaysStoppedAnimation(
            //                         Color(0xFF35D6FF),
            //                       ),
            //                     );
            //                   },
            //                 ),
            //         ),
            //       ),
            //
            //       const SizedBox(height: 14),
            //
            //       Text(
            //         'PREPARING YOUR ESCAPE...',
            //         style: TextStyle(
            //           color: Colors.white.withValues(alpha: 0.55),
            //           fontSize: 9,
            //           letterSpacing: 2.0,
            //           fontWeight: FontWeight.w700,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
