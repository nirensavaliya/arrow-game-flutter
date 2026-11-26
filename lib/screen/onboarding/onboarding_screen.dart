import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_font_size.dart';
import '../../controller/theme_controller.dart';
import '../../services/ads/interstitial_ad_service.dart';
import '../../storage/settings_storage.dart';
import '../game/game_intro_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final InterstitialAdService _interstitialAdService = InterstitialAdService();

  late final ThemeController _themeController;

  int _currentPage = 0;
  bool _isNavigating = false;

  final List<_OnboardingData> onboardingPages = [
    _OnboardingData(
      title: 'Think Before\nYou Escape.',
      subtitle:
          'Study every arrow, find the right direction, '
          'and clear the board with smart moves.',
      label: 'SMART PUZZLES',
      icon: Icons.grid_view_rounded,
      color: const Color(0xFF8175FF),
      badge: 'BRAIN POWER',
      secondaryIcon: Icons.psychology_rounded,
      featureTitle: 'Every move matters',
      featureDescription: 'Plan your path before tapping.',
      highlights: [
        'Unique puzzle layouts',
        'Strategic arrow movement',
        'Brain-training challenges',
      ],
      showGlow: true,
    ),
    _OnboardingData(
      title: 'Race Against\nThe Clock.',
      subtitle:
          'Beat the timer, make quick decisions, '
          'and prove your puzzle-solving speed.',
      label: 'TIME CHALLENGE',
      icon: Icons.timer_rounded,
      color: const Color(0xFFFFB34F),
      badge: 'SPEED MODE',
      secondaryIcon: Icons.bolt_rounded,
      featureTitle: 'Every second counts',
      featureDescription: 'Think fast and escape before time runs out.',
      highlights: [
        'Time-based challenges',
        'Fast decision making',
        'Beat your best performance',
      ],
    ),
    _OnboardingData(
      title: 'Master Every\nChallenge.',
      subtitle:
          'Unlock new levels, collect rewards, '
          'and become the ultimate arrow escape master.',
      label: 'UNLOCK & REWARD',
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFF35D68A),
      badge: 'LEVEL UP',
      secondaryIcon: Icons.workspace_premium_rounded,
      featureTitle: 'Your journey awaits',
      featureDescription: 'Complete levels and earn exciting rewards.',
      highlights: [
        'Unlock new challenges',
        'Earn coins and bonuses',
        'Track your progress',
      ],
    ),
  ];

  List<_OnboardingData> get _pages => onboardingPages;

  @override
  void initState() {
    super.initState();

    _themeController = Get.find<ThemeController>();

    // Preload while onboarding is displayed.
    _interstitialAdService.loadAd();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Finish onboarding
  // ---------------------------------------------------------------------------

  Future<void> _finishOnboarding() async {
    if (_isNavigating) return;

    setState(() => _isNavigating = true);

    try {
      await SettingsStorage.setOnboardingCompleted(true);
    } catch (e) {
      debugPrint('Onboarding storage error: $e');
    }

    if (!mounted) return;

    _interstitialAdService.show(onDone: _navigateToGame);
  }

  void _navigateToGame() {
    if (!mounted) return;

    Get.off(
      () => const GameIntroScreen(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 500),
    );
  }

  // ---------------------------------------------------------------------------
  // Page navigation
  // ---------------------------------------------------------------------------

  void _nextPage() {
    if (_isNavigating) return;

    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }
  double _fs(double size) => AppFontSize.s(context, size);
  // ---------------------------------------------------------------------------
  // Main UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = _themeController.isDark;

      final background = isDark
          ? const Color(0xFF07080F)
          : const Color(0xFFF4F5FA);

      final surface = isDark ? const Color(0xFF12141F) : Colors.white;

      final textColor = isDark
          ? const Color(0xFFF7F7FC)
          : const Color(0xFF14162A);

      final secondaryColor = isDark
          ? const Color(0xFF8E92AB)
          : const Color(0xFF6F7390);

      final inactiveColor = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : const Color(0xFFD9DCE8);

      final currentData = _pages[_currentPage];

      return Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 14),
            child: Column(
              children: [
                // Header
                _buildHeader(textColor, secondaryColor, surface, currentData),

                // // Top progress line
                // _buildTopProgress(
                //   inactiveColor,
                //   currentData.color,
                // ),
                const SizedBox(height: 12),
                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double page = _currentPage.toDouble();

                          if (_pageController.hasClients &&
                              _pageController.position.haveDimensions) {
                            page =
                                _pageController.page ?? _currentPage.toDouble();
                          }

                          final difference = (page - index).abs();
                          final scale = (1 - difference * 0.035).clamp(
                            0.94,
                            1.0,
                          );

                          return Transform.scale(scale: scale, child: child);
                        },
                        child: _buildOnboardingPage(
                          _pages[index],
                          textColor,
                          secondaryColor,
                          surface,
                          isDark,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 5),

                // Bottom progress
                _buildBottomProgress(
                  secondaryColor,
                  inactiveColor,
                  currentData.color,
                ),

                const SizedBox(height: 10),

                // Main CTA
                _buildContinueButton(currentData),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(
    Color textColor,
    Color secondaryColor,
    Color surface,
    _OnboardingData data,
  ) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: data.color.withValues(alpha: 0.20)),
          ),
          child: Icon(Icons.arrow_forward_rounded, color: data.color, size: 25),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Arrow Escape',
                style: TextStyle(
                  color: textColor,
                  fontSize: _fs(AppFontSize.title - 1),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              Text(
                'THINK  •  TRACE  •  ESCAPE',
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: _fs(AppFontSize.tiny - 0.5),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),

        GestureDetector(
          onTap: _isNavigating ? null : _finishOnboarding,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: secondaryColor.withValues(alpha: 0.13)),
            ),
            child: Text(
              'SKIP',
              style: TextStyle(
                color: secondaryColor,
                fontSize: _fs(AppFontSize.xs + 0.5),
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
  // ---------------------------------------------------------------------------
  // Onboarding content
  // ---------------------------------------------------------------------------

  Widget _buildOnboardingPage(
    _OnboardingData data,
    Color textColor,
    Color secondaryColor,
    Color surface,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationHeight = (constraints.maxHeight * 0.42).clamp(
          190.0,
          265.0,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium game illustration
            _buildGameIllustration(data, illustrationHeight, surface, isDark),

            const SizedBox(height: 10),

            // Main heading
            Text(
              data.title,
              style: TextStyle(
                color: textColor,
                fontSize: _fs(36),
                height: 1.10,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
              ),
            ),

            const SizedBox(height: 10),

            // Description
            Text(
              data.subtitle,
              style: TextStyle(
                color: secondaryColor,
                fontSize: _fs(AppFontSize.lg), // 14
                height: 1.65,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 10),

            // Feature information
            _buildFeatureCard(data, textColor, secondaryColor, surface),

            const SizedBox(height: 10),

            // Highlights
            _buildHighlights(data, textColor, secondaryColor),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Premium illustration
  // ---------------------------------------------------------------------------

  Widget _buildGameIllustration(
    _OnboardingData data,
    double height,
    Color surface,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(29),
        color: data.color.withValues(alpha: isDark ? 0.075 : 0.055),
        border: Border.all(color: data.color.withValues(alpha: 0.18)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background glow
          if (data.showGlow)
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    data.color.withValues(alpha: 0.24),
                    data.color.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

          // Decorative rings
          Container(
            width: 174,
            height: 174,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: data.color.withValues(alpha: 0.13)),
            ),
          ),

          Container(
            width: 135,
            height: 135,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.color.withValues(alpha: 0.09),
              border: Border.all(color: data.color.withValues(alpha: 0.24)),
              boxShadow: [
                BoxShadow(
                  color: data.color.withValues(alpha: 0.13),
                  blurRadius: 35,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),

          // Main icon
          Icon(
            data.icon,
            size: 78,
            color: data.color,
            shadows: [
              Shadow(color: data.color.withValues(alpha: 0.45), blurRadius: 25),
            ],
          ),

          // Secondary floating icon
          Positioned(
            top: 58,
            right: 38,
            child: _buildFloatingElement(
              data.secondaryIcon ?? Icons.auto_awesome_rounded,
              data.color,
            ),
          ),

          Positioned(
            bottom: 43,
            left: 35,
            child: _buildFloatingElement(Icons.bolt_rounded, data.color),
          ),

          // Small decorative dots
          Positioned(top: 85, left: 50, child: _buildDot(data.color)),

          Positioned(bottom: 72, right: 52, child: _buildDot(data.color)),

          // Badge
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: data.color.withValues(alpha: 0.22)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars_rounded, size: 14, color: data.color),
                  const SizedBox(width: 5),
                  Text(
                    data.badge ?? 'GAME FEATURE',
                    style: TextStyle(
                      color: data.color,
                      fontSize: _fs(AppFontSize.tiny - 0.5), // 9
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingElement(IconData icon, Color color) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.55),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10),
        ],
      ),
    );
  }
  // ---------------------------------------------------------------------------
  // Feature card
  // ---------------------------------------------------------------------------

  Widget _buildFeatureCard(
    _OnboardingData data,
    Color textColor,
    Color secondaryColor,
    Color surface,
  ) {
    if (data.featureTitle == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: data.color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              data.secondaryIcon ?? Icons.stars_rounded,
              color: data.color,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.featureTitle!,
                  style: TextStyle(
                    color: textColor,
                    fontSize: _fs(AppFontSize.lg),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.featureDescription ?? '',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: _fs(AppFontSize.xs + 0.5),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: data.color, size: 15),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Feature highlights
  // ---------------------------------------------------------------------------

  Widget _buildHighlights(
    _OnboardingData data,
    Color textColor,
    Color secondaryColor,
  ) {
    if (data.highlights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHAT YOU GET',
          style: TextStyle(
            color: secondaryColor,
            fontSize: _fs(AppFontSize.xs - 0.5),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 12),

        ...data.highlights.map(
          (highlight) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded, color: data.color, size: 13),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    highlight,
                    style: TextStyle(
                      color: textColor,
                      fontSize: _fs(12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom progress indicator
  // ---------------------------------------------------------------------------

  Widget _buildBottomProgress(
    Color secondaryColor,
    Color inactiveColor,
    Color activeColor,
  ) {
    return Row(
      children: [
        Text(
          '0${_currentPage + 1} / 0${_pages.length}',
          style: TextStyle(
            color: secondaryColor,
            fontSize: _fs(12),
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
        const Spacer(),
        ...List.generate(_pages.length, (index) {
          final selected = index == _currentPage;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: selected ? 23 : 6,
            height: 6,
            margin: const EdgeInsets.only(left: 5),
            decoration: BoxDecoration(
              color: selected ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }),
        const SizedBox(width: 10),
        Text(
          _currentPage == _pages.length - 1 ? 'READY' : 'NEXT',
          style: TextStyle(
            color: activeColor,
            fontSize: _fs(AppFontSize.xs - 0.5),
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Continue button
  // ---------------------------------------------------------------------------

  Widget _buildContinueButton(_OnboardingData data) {
    return SizedBox(
      width: double.infinity,
      height: 59,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: data.color.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isNavigating ? null : _nextPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: data.color,
            disabledBackgroundColor: data.color.withValues(alpha: 0.65),
            foregroundColor: const Color(0xFF080911),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: _isNavigating
              ? const SizedBox(
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Color(0xFF080911),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentPage == _pages.length - 1 ? "LET'S PLAY" : 'CONTINUE',
                      style: TextStyle(
                        fontSize: _fs(AppFontSize.lg), // 14
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Icon(Icons.arrow_forward_rounded, size: 21),
                  ],
                ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Onboarding Data Model
// -----------------------------------------------------------------------------

class _OnboardingData {
  final String title;
  final String subtitle;
  final String label;
  final IconData icon;
  final Color color;

  final String? badge;
  final IconData? secondaryIcon;
  final String? featureTitle;
  final String? featureDescription;
  final List<String> highlights;
  final bool showGlow;

  const _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.label,
    required this.icon,
    required this.color,
    this.badge,
    this.secondaryIcon,
    this.featureTitle,
    this.featureDescription,
    this.highlights = const [],
    this.showGlow = true,
  });
}
