import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/theme_controller.dart';

class CustomizationScreen extends StatefulWidget {
  const CustomizationScreen({super.key});

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFF8175FF);
  static const Color _accentDeep = Color(0xFF4B3FD1);

  static const Color _darkBg = Color(0xFF07080F);
  static const Color _darkSurface = Color(0xFF12141F);
  static const Color _darkText = Color(0xFFF7F7FC);
  static const Color _darkMuted = Color(0xFF8E92AB);

  static const Color _lightBg = Color(0xFFF4F5FA);
  static const Color _lightSurface = Colors.white;
  static const Color _lightText = Color(0xFF14162A);
  static const Color _lightMuted = Color(0xFF6F7390);

  String _selectedArrowTheme = 'Ocean';
  String _selectedBoardTheme = 'Classic';

  final Set<String> _ownedArrowThemes = {'Ocean'};
  final Set<String> _ownedBoardThemes = {'Classic'};

  late final AnimationController _previewController;

  @override
  void initState() {
    super.initState();

    _previewController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _previewController.dispose();
    super.dispose();
  }

  bool _isDark(ThemeController controller) => controller.isDarkMode.value;

  Color get _coinColor => const Color(0xFFFFB52E);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final dark = _isDark(themeController);

      final bg = dark ? _darkBg : _lightBg;
      final surface = dark ? _darkSurface : _lightSurface;
      final ink = dark ? _darkText : _lightText;
      final muted = dark ? _darkMuted : _lightMuted;

      return Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _CustomizationBackgroundPainter(
                  color: Colors.black.withValues(alpha: 0),
                ),
              ),
            ),
            Positioned(
              top: -130,
              right: -130,
              child: _glow(_accent, 340, dark ? 0.20 : 0.10),
            ),
            Positioned(
              bottom: 100,
              left: -170,
              child: _glow(_accentDeep, 340, dark ? 0.14 : 0.07),
            ),
            Column(
              children: [
                _buildAppBar(context, ink, muted),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFeaturedPreview(),
                        const SizedBox(height: 15),
                        _buildSectionHeader(
                          'Arrow Themes',
                          'Customize your arrows',
                          Icons.near_me_rounded,
                          ink,
                          muted,
                        ),
                        const SizedBox(height: 10),
                        _buildArrowThemes(dark, surface, ink, muted),
                        const SizedBox(height: 15),
                        _buildSectionHeader(
                          'Board Themes',
                          'Give your maze a new look',
                          Icons.grid_view_rounded,
                          ink,
                          muted,
                        ),
                        const SizedBox(height: 10),
                        _buildBoardThemes(dark, surface, ink, muted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _glow(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  // APP BAR

  Widget _buildAppBar(BuildContext context, Color ink, Color muted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: ink.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: ink.withValues(alpha: 0.07)),
              ),
              child: Icon(Icons.arrow_back_rounded, color: ink, size: 21),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customization',
                  style: TextStyle(
                    color: ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Make Arrow Escape yours',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.palette_rounded, color: _accent, size: 21),
          ),
        ],
      ),
    );
  }

  // FEATURED PREVIEW

  Widget _buildFeaturedPreview() {
    return Container(
      height: 175,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8175FF), Color(0xFF5543CF), Color(0xFF30218C)],
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _CustomizationBackgroundPainter(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              right: -20,
              bottom: -45,
              child: Icon(
                Icons.palette_rounded,
                size: 190,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(19),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'STYLE COLLECTION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Text(
                          'EXPLORE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'A fresh look\nfor every escape.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.15,
                      letterSpacing: -0.7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Arrows, colors and boards.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SECTION HEADER

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    IconData icon,
    Color ink,
    Color muted,
  ) {
    return Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: _accent, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ARROW THEMES

  Widget _buildArrowThemes(bool dark, Color surface, Color ink, Color muted) {
    final themes = [
      _ArrowThemeData(
        name: 'Ocean',
        subtitle: 'Electric blue',
        color: const Color(0xFF36B9FF),
        deep: const Color(0xFF1265D8),
        price: 0,
        anim: _ArrowAnimStyle.ripple,
      ),
      _ArrowThemeData(
        name: 'Flame',
        subtitle: 'Golden orange',
        color: const Color(0xFFFFB347),
        deep: const Color(0xFFD96A19),
        price: 250,
        anim: _ArrowAnimStyle.sparks,
      ),
      _ArrowThemeData(
        name: 'Mystic',
        subtitle: 'Royal purple',
        color: const Color(0xFFC05AFF),
        deep: const Color(0xFF752BC9),
        price: 400,
        anim: _ArrowAnimStyle.orbit,
      ),
      _ArrowThemeData(
        name: 'Emerald',
        subtitle: 'Neon green',
        color: const Color(0xFF35D68A),
        deep: const Color(0xFF087F54),
        price: 600,
        anim: _ArrowAnimStyle.comet,
      ),
      _ArrowThemeData(
        name: 'Frost',
        subtitle: 'Freezing ice',
        color: const Color(0xFF9BE8FF),
        deep: const Color(0xFF2A7FB0),
        price: 700,
        anim: _ArrowAnimStyle.freeze,
      ),
      _ArrowThemeData(
        name: 'Thunder',
        subtitle: 'Lightning strike',
        color: const Color(0xFFFFE23D),
        deep: const Color(0xFF8A5A00),
        price: 800,
        anim: _ArrowAnimStyle.thunder,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: themes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.91,
      ),
      itemBuilder: (context, index) {
        return _buildArrowThemeCard(themes[index], surface, ink, muted, dark);
      },
    );
  }

  // ARROW THEME CARD
  Widget _buildArrowThemeCard(
    _ArrowThemeData theme,
    Color surface,
    Color ink,
    Color muted,
    bool dark,
  ) {
    final owned = _ownedArrowThemes.contains(theme.name);
    final selected = _selectedArrowTheme == theme.name;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: selected
              ? theme.color.withValues(alpha: 0.85)
              : ink.withValues(alpha: dark ? 0.09 : 0.07),
          width: selected ? 1.3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.color.withValues(
              alpha: selected ? (dark ? 0.20 : 0.13) : (dark ? 0.07 : 0.035),
            ),
            blurRadius: selected ? 22 : 13,
            spreadRadius: selected ? 1 : 0,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(9, 9, 9, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme.deep, const Color(0xFF111323)],
                  ),
                  borderRadius: BorderRadius.circular(17),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CustomizationBackgroundPainter(
                          color: Colors.white.withValues(alpha: 0.075),
                          cell: 22,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ArrowPreviewPainter(
                          color: theme.color,
                          style: theme.anim,
                          animation: _previewController,
                        ),
                      ),
                    ),

                    // Selected indicator.
                    if (selected)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),

                    // Price.
                    if (!owned)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _priceBadge(theme.price),
                      ),

                    // Equipped label.
                    if (selected)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: const Text(
                            'ACTIVE STYLE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          theme.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.color.withValues(alpha: 0.55),
                              blurRadius: 7,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    theme.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _themeActionButton(
                    owned: owned,
                    selected: selected,
                    color: theme.color,
                    price: theme.price,
                    onTap: () {
                      if (owned) {
                        setState(() {
                          _selectedArrowTheme = theme.name;
                        });
                      } else {
                        _showPurchaseInfo(theme.name, theme.price);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BOARD THEME CARD
  Widget _buildBoardThemeCard(
    _BoardThemeData theme,
    Color surface,
    Color ink,
    Color muted,
    bool dark,
  ) {
    final owned = _ownedBoardThemes.contains(theme.name);
    final selected = _selectedBoardTheme == theme.name;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: selected
              ? _accent.withValues(alpha: 0.85)
              : ink.withValues(alpha: dark ? 0.09 : 0.07),
          width: selected ? 1.7 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.line.withValues(
              alpha: selected ? (dark ? 0.20 : 0.12) : (dark ? 0.07 : 0.035),
            ),
            blurRadius: selected ? 22 : 13,
            spreadRadius: selected ? 1 : 0,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(9, 9, 9, 8),
                decoration: BoxDecoration(
                  color: theme.background,
                  borderRadius: BorderRadius.circular(17),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CustomizationBackgroundPainter(
                          color: theme.line.withValues(alpha: 0.55),
                          cell: 23,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BoardThemePainter(
                          lineColor: theme.line,
                          showStars: theme.stars,
                        ),
                      ),
                    ),

                    // Selected indicator.
                    if (selected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),

                    // Price.
                    if (!owned)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _priceBadge(theme.price),
                      ),

                    // Board preview label.
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          theme.stars ? 'COSMIC BOARD' : 'BOARD STYLE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          theme.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.line,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    theme.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _themeActionButton(
                    owned: owned,
                    selected: selected,
                    color: _accent,
                    price: theme.price,
                    onTap: () {
                      if (owned) {
                        setState(() {
                          _selectedBoardTheme = theme.name;
                        });
                      } else {
                        _showPurchaseInfo(theme.name, theme.price);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // REFINED ACTION BUTTON
  Widget _themeActionButton({
    required bool owned,
    required bool selected,
    required Color color,
    required int price,
    required VoidCallback onTap,
  }) {
    final isEquipped = owned && selected;

    final background = isEquipped
        ? color.withValues(alpha: 0.14)
        : owned
        ? color.withValues(alpha: 0.09)
        : _accent;

    final foreground = owned ? color : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: 35,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEquipped
                    ? color.withValues(alpha: 0.48)
                    : owned
                    ? color.withValues(alpha: 0.18)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isEquipped) ...[
                  Icon(Icons.check_circle_rounded, color: foreground, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    'EQUIPPED',
                    style: TextStyle(
                      color: foreground,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.65,
                    ),
                  ),
                ] else if (owned) ...[
                  Icon(Icons.check_rounded, color: foreground, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    'EQUIP',
                    style: TextStyle(
                      color: foreground,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.lock_open_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'UNLOCK THEME',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // BOARD THEMES
  Widget _buildBoardThemes(bool dark, Color surface, Color ink, Color muted) {
    final themes = [
      // FREE
      _BoardThemeData(
        name: 'Classic',
        subtitle: 'Minimal grid',
        background: const Color(0xFF101827),
        line: const Color(0xFF34445C),
        price: 0,
      ),

      // EXISTING THEMES
      _BoardThemeData(
        name: 'Royal',
        subtitle: 'Purple maze',
        background: const Color(0xFF3826A8),
        line: const Color(0xFF7055E8),
        price: 200,
      ),
      _BoardThemeData(
        name: 'Forest',
        subtitle: 'Green world',
        background: const Color(0xFF123D32),
        line: const Color(0xFF278C68),
        price: 350,
      ),
      _BoardThemeData(
        name: 'Galaxy',
        subtitle: 'Cosmic space',
        background: const Color(0xFF101B38),
        line: const Color(0xFF5364A0),
        stars: true,
        price: 500,
      ),

      // NEW THEMES
      _BoardThemeData(
        name: 'Cyber',
        subtitle: 'Neon technology',
        background: const Color(0xFF071E26),
        line: const Color(0xFF00D9C5),
        price: 600,
      ),
      _BoardThemeData(
        name: 'Sunset',
        subtitle: 'Warm orange world',
        background: const Color(0xFF351B2C),
        line: const Color(0xFFFF895D),
        price: 650,
      ),
      _BoardThemeData(
        name: 'Crimson',
        subtitle: 'Red challenge',
        background: const Color(0xFF2B101B),
        line: const Color(0xFFE74768),
        price: 700,
      ),
      _BoardThemeData(
        name: 'Arctic',
        subtitle: 'Frozen maze',
        background: const Color(0xFF102B43),
        line: const Color(0xFF8CE5FF),
        price: 750,
      ),
      _BoardThemeData(
        name: 'Void',
        subtitle: 'Deep dark space',
        background: const Color(0xFF090A16),
        line: const Color(0xFF8175FF),
        stars: true,
        price: 850,
      ),
      _BoardThemeData(
        name: 'Golden',
        subtitle: 'Luxury gold',
        background: const Color(0xFF302414),
        line: const Color(0xFFFFC857),
        price: 900,
      ),
      _BoardThemeData(
        name: 'Ocean',
        subtitle: 'Deep blue water',
        background: const Color(0xFF092B49),
        line: const Color(0xFF36B9FF),
        price: 1000,
      ),
      _BoardThemeData(
        name: 'Toxic',
        subtitle: 'Radioactive green',
        background: const Color(0xFF17230D),
        line: const Color(0xFFB5F542),
        price: 1200,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: themes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
        childAspectRatio: 0.91,
      ),
      itemBuilder: (context, index) {
        return _buildBoardThemeCard(themes[index], surface, ink, muted, dark);
      },
    );
  }

  // COIN PRICE BADGE

  Widget _priceBadge(int price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF171522).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on_rounded, color: _coinColor, size: 13),
          const SizedBox(width: 4),
          Text(
            '$price',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // PURCHASE INFO

  void _showPurchaseInfo(String name, int price) {
    Get.snackbar(
      'Unlock $name',
      'This theme costs $price coins. Connect your coin purchase system here.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1B1E2C),
      colorText: Colors.white,
      borderRadius: 16,
      margin: const EdgeInsets.all(14),
      duration: const Duration(seconds: 2),
    );
  }
}

// --------------------------------------------------
// ARROW ANIMATION STYLES
// --------------------------------------------------

enum _ArrowAnimStyle { ripple, sparks, orbit, comet, freeze, thunder }

// --------------------------------------------------
// ARROW MODEL
// --------------------------------------------------

class _ArrowThemeData {
  final String name;
  final String subtitle;
  final Color color;
  final Color deep;
  final int price;
  final _ArrowAnimStyle anim;

  const _ArrowThemeData({
    required this.name,
    required this.subtitle,
    required this.color,
    required this.deep,
    required this.price,
    required this.anim,
  });
}

// --------------------------------------------------
// BOARD MODEL
// --------------------------------------------------

class _BoardThemeData {
  final String name;
  final String subtitle;
  final Color background;
  final Color line;
  final bool stars;
  final int price;

  const _BoardThemeData({
    required this.name,
    required this.subtitle,
    required this.background,
    required this.line,
    required this.price,
    this.stars = false,
  });
}

// --------------------------------------------------
// BACKGROUND GRID PAINTER
// --------------------------------------------------

class _CustomizationBackgroundPainter extends CustomPainter {
  final Color color;
  final double cell;

  const _CustomizationBackgroundPainter({required this.color, this.cell = 36});

  @override
  void paint(Canvas canvas, Size size) {
    if (color.alpha == 0 || size.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final random = math.Random(11);

    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        if (random.nextBool()) {
          canvas.drawLine(Offset(x, y), Offset(x + cell, y), paint);
        } else {
          canvas.drawLine(Offset(x, y), Offset(x, y + cell), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CustomizationBackgroundPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.cell != cell;
  }
}

// --------------------------------------------------
// REFINED ARROW PREVIEW PAINTER
// --------------------------------------------------

class _ArrowPreviewPainter extends CustomPainter {
  final Color color;
  final _ArrowAnimStyle style;
  final Animation<double> animation;

  _ArrowPreviewPainter({
    required this.color,
    required this.style,
    required this.animation,
  }) : super(repaint: animation);

  static const int _thunderFlashes = 3;

  static const double _awayAngle = math.pi / 2;

  double _clamp(double value) => value.clamp(0.0, 1.0).toDouble();

  double _smooth(double value) {
    return Curves.easeInOutCubic.transform(_clamp(value));
  }

  double _sine(double value) {
    return 0.5 + 0.5 * math.sin(value * math.pi * 2);
  }

  double _thunderIntensity(double t) {
    final scaled = t * _thunderFlashes;
    final local = scaled - scaled.floor();

    if (local > 0.40) return 0;

    final fade = 1 - local / 0.40;

    final flicker = ((local * 65).floor() % 3 == 0) ? 1.0 : 0.48;

    return _clamp(fade * flicker);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final t = animation.value;

    final cell = size.shortestSide / 5;
    final strokeWidth = cell * 0.24;
    final headLength = cell * 0.95;
    final headHalfWidth = cell * 0.52;
    final cornerRadius = cell * 0.85;

    // Arrow geometry

    final points = <Offset>[
      Offset(size.width * 0.28, size.height * 0.66),
      Offset(size.width * 0.28, size.height * 0.30),
      Offset(size.width * 0.78, size.height * 0.30),
    ];

    const direction = Offset(1, 0);

    final tip = points.last;
    final tail = points.first;

    final body = <Offset>[
      points[0],
      points[1],
      tip - direction * (headLength * 0.55),
    ];

    final incoming = body[1] - body[0];
    final outgoing = body[2] - body[1];

    final inLen = incoming.distance;
    final outLen = outgoing.distance;

    final radius = math.min(cornerRadius, math.min(inLen, outLen) * 0.5);

    final entry = body[1] - incoming / inLen * radius;
    final exit = body[1] + outgoing / outLen * radius;

    final path = Path()
      ..moveTo(body.first.dx, body.first.dy)
      ..lineTo(entry.dx, entry.dy)
      ..quadraticBezierTo(body[1].dx, body[1].dy, exit.dx, exit.dy)
      ..lineTo(body[2].dx, body[2].dy);

    // Draw arrow body glow.

    _drawGlowPath(
      canvas,
      path,
      strokeWidth * 2.8,
      color.withValues(alpha: 0.18),
      13,
    );

    _drawGlowPath(
      canvas,
      path,
      strokeWidth * 1.7,
      color.withValues(alpha: 0.40),
      6,
    );

    // Arrow body.

    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(path, bodyPaint);

    // Inner highlight.

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.22
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawPath(path, highlight);

    // Static arrowhead.

    final perpendicular = Offset(-direction.dy, direction.dx);

    final base = tip - direction * headLength;

    final left = base + perpendicular * headHalfWidth;
    final right = base - perpendicular * headHalfWidth;

    final headPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    final headGlow = Paint()
      ..color = color.withValues(alpha: 0.50)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9)
      ..isAntiAlias = true;

    canvas.drawPath(headPath, headGlow);

    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(headPath, headPaint);

    // Tail cap.

    final flash = _tailFlash(t);

    final capColor = Color.lerp(color, Colors.white, 0.75 * flash)!;

    final capPaint = Paint()
      ..color = capColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(tail, strokeWidth * 0.5, capPaint);

    // Theme-specific animations.

    canvas.save();

    switch (style) {
      case _ArrowAnimStyle.ripple:
        _paintRipple(canvas, tail, cell, strokeWidth, t);
        break;

      case _ArrowAnimStyle.sparks:
        _paintSparks(canvas, tail, cell, t);
        break;

      case _ArrowAnimStyle.orbit:
        _paintOrbit(canvas, tail, cell, t);
        break;

      case _ArrowAnimStyle.comet:
        _paintComet(canvas, path, tail, cell, strokeWidth, t);
        break;

      case _ArrowAnimStyle.freeze:
        _paintFreeze(canvas, tail, cell, t);
        break;

      case _ArrowAnimStyle.thunder:
        _paintThunder(canvas, tail, cell, t);
        break;
    }

    canvas.restore();
  }

  void _drawGlowPath(
    Canvas canvas,
    Path path,
    double width,
    Color glowColor,
    double blur,
  ) {
    final paint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur)
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  double _tailFlash(double t) {
    switch (style) {
      case _ArrowAnimStyle.freeze:
        final grow = _smooth(t / 0.45);
        final fade = t > 0.82 ? 1 - _clamp((t - 0.82) / 0.18) : 1.0;
        return grow * fade;

      case _ArrowAnimStyle.thunder:
        return _thunderIntensity(t);

      case _ArrowAnimStyle.comet:
        final p = _clamp((t - 0.60) / 0.25);
        return math.sin(p * math.pi);

      case _ArrowAnimStyle.sparks:
        return 0.35 + 0.35 * _sine(t * 3);

      case _ArrowAnimStyle.ripple:
      case _ArrowAnimStyle.orbit:
        return 0;
    }
  }

  // OCEAN: Smooth expanding ripple rings.

  void _paintRipple(
    Canvas canvas,
    Offset tail,
    double cell,
    double strokeWidth,
    double t,
  ) {
    const count = 3;

    for (var i = 0; i < count; i++) {
      final phase = (t + i / count) % 1.0;
      final eased = _smooth(phase);

      final radius = cell * (0.30 + 1.55 * eased);

      final opacity = 0.65 * (1 - eased);

      final glow = Paint()
        ..color = color.withValues(alpha: opacity * 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      final ring = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, strokeWidth * 0.65 * (1 - eased))
        ..isAntiAlias = true;

      canvas.drawCircle(tail, radius, glow);
      canvas.drawCircle(tail, radius, ring);
    }
  }

  // FLAME: Natural flying sparks.

  void _paintSparks(Canvas canvas, Offset tail, double cell, double t) {
    const count = 12;

    for (var i = 0; i < count; i++) {
      final phase = (t * 1.15 + i * 0.137) % 1.0;

      final eased = _smooth(phase);

      final spread = -1.0 + i * (2.0 / (count - 1));

      final angle = _awayAngle + spread + math.sin(t * math.pi * 4 + i) * 0.15;

      final speed = 0.75 + 0.25 * ((i % 4) / 3);

      final distance = cell * (0.20 + 1.55 * eased * speed);

      final position =
          tail + Offset(math.cos(angle), math.sin(angle)) * distance;

      final opacity = 1 - phase;

      final sparkColor = Color.lerp(color, Colors.white, 0.65 * opacity)!;

      final glow = Paint()
        ..color = sparkColor.withValues(alpha: opacity * 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final core = Paint()
        ..color = sparkColor.withValues(alpha: opacity)
        ..isAntiAlias = true;

      final radius = 0.7 + 2.0 * opacity;

      canvas.drawCircle(position, radius * 2, glow);
      canvas.drawCircle(position, radius, core);
    }

    // Small warm aura.

    final aura = Paint()
      ..color = color.withValues(alpha: 0.12 + 0.08 * _sine(t))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(tail, cell * 0.65, aura);
  }

  // MYSTIC: Orbiting particles and breathing aura.

  void _paintOrbit(Canvas canvas, Offset tail, double cell, double t) {
    final breathe = _sine(t);

    final aura = Paint()
      ..color = color.withValues(alpha: 0.12 + 0.15 * breathe)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9)
      ..isAntiAlias = true;

    canvas.drawCircle(tail, cell * (0.65 + 0.30 * breathe), aura);

    // Inner aura.

    final innerAura = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(tail, cell * 0.35, innerAura);

    const count = 4;

    for (var i = 0; i < count; i++) {
      final angle = t * math.pi * 2 + i * math.pi * 2 / count;

      final radius = cell * (0.60 + 0.10 * math.sin(angle * 2));

      final position = tail + Offset(math.cos(angle), math.sin(angle)) * radius;

      final dotGlow = Paint()
        ..color = color.withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      final dot = Paint()..color = Color.lerp(color, Colors.white, 0.75)!;

      canvas.drawCircle(position, 5, dotGlow);
      canvas.drawCircle(position, 2.0, dot);
    }
  }

  // EMERALD: Smooth comet travelling along arrow path.

  void _paintComet(
    Canvas canvas,
    Path path,
    Offset tail,
    double cell,
    double strokeWidth,
    double t,
  ) {
    final metrics = path.computeMetrics().toList();

    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final total = metric.length;

    if (total <= 0) return;

    // Comet travels from head towards tail.

    final sweep = _clamp(t / 0.62);

    if (t < 0.62) {
      final progress = Curves.easeInOutCubic.transform(sweep);

      final headDistance = progress * total;

      final trailLength = math.max(total * 0.28, strokeWidth * 4);

      final start = math.max(0.0, headDistance - trailLength);

      final end = math.min(total, headDistance);

      if (end > start) {
        final trail = metric.extractPath(start, end);

        // Wide glow.

        _drawGlowPath(
          canvas,
          trail,
          strokeWidth * 2.2,
          color.withValues(alpha: 0.32),
          9,
        );

        // Bright comet core.

        final cometPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              color.withValues(alpha: 0.0),
              color.withValues(alpha: 0.45),
              Colors.white,
            ],
          ).createShader(Rect.fromLTWH(0, 0, total, sizeHeightFallback(trail)))
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.85
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true;

        // A solid bright sweep avoids shader orientation issues
        // on bent paths.
        final brightPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.65
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true;

        canvas.drawPath(trail, cometPaint);
        canvas.drawPath(trail, brightPaint);

        // Moving head glow.

        final tangent = metric.getTangentForOffset(headDistance);

        if (tangent != null) {
          final glow = Paint()
            ..color = color.withValues(alpha: 0.65)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

          canvas.drawCircle(tangent.position, strokeWidth * 0.9, glow);

          final core = Paint()
            ..color = Colors.white
            ..isAntiAlias = true;

          canvas.drawCircle(tangent.position, strokeWidth * 0.30, core);
        }
      }
    }

    // Tail burst.

    final burst = _clamp((t - 0.62) / 0.23);

    if (burst > 0 && burst < 1) {
      final eased = _smooth(burst);

      final radius = cell * (0.30 + 1.20 * eased);

      final ring = Paint()
        ..color = color.withValues(alpha: 0.75 * (1 - eased))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * (0.85 * (1 - eased))
        ..isAntiAlias = true;

      final glow = Paint()
        ..color = color.withValues(alpha: 0.25 * (1 - eased))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      canvas.drawCircle(tail, radius, glow);
      canvas.drawCircle(tail, radius, ring);
    }
  }

  // Helper for comet shader bounds.

  double sizeHeightFallback(Path path) {
    return path.computeMetrics().fold<double>(
      1,
      (value, metric) => math.max(value, metric.length),
    );
  }

  // FROST: Growing crystals and drifting snow.

  void _paintFreeze(Canvas canvas, Offset center, double cell, double t) {
    final grow = _smooth(t / 0.45);

    final fade = t > 0.82 ? 1 - _clamp((t - 0.82) / 0.18) : 1.0;

    final strength = grow * fade;

    // Cold aura.

    final aura = Paint()
      ..color = const Color(0xFFBFF3FF).withValues(alpha: 0.22 * strength)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(center, cell * (0.7 + 0.45 * grow), aura);

    // Inner crystal glow.

    final inner = Paint()
      ..color = Colors.white.withValues(alpha: 0.15 * strength)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(center, cell * 0.4, inner);

    const spikes = 6;

    final innerRadius = cell * 0.28;
    final outerRadius = cell * (0.45 + 0.85 * grow);

    final shimmer = 0.85 + 0.15 * _sine(t * 4);

    final crystalPaint = Paint()
      ..color = Colors.white.withValues(alpha: strength * shimmer)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final branchPaint = Paint()
      ..color = color.withValues(alpha: 0.85 * strength)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (var i = 0; i < spikes; i++) {
      final angle = i * math.pi / 3 + math.pi / 6;

      final direction = Offset(math.cos(angle), math.sin(angle));

      final perpendicular = Offset(-direction.dy, direction.dx);

      final start = center + direction * innerRadius;
      final end = center + direction * outerRadius;

      canvas.drawLine(start, end, crystalPaint);

      final branchPoint = Offset.lerp(start, end, 0.65)!;

      final branchLength = cell * 0.25 * grow;

      canvas.drawLine(
        branchPoint,
        branchPoint + (direction + perpendicular) * branchLength,
        branchPaint,
      );

      canvas.drawLine(
        branchPoint,
        branchPoint + (direction - perpendicular) * branchLength,
        branchPaint,
      );

      final tipPaint = Paint()
        ..color = Colors.white.withValues(alpha: strength);

      canvas.drawCircle(end, 1.7, tipPaint);
    }

    // Snow particles.

    const flakes = 10;

    for (var i = 0; i < flakes; i++) {
      final p = (t * 0.85 + i * 0.137) % 1.0;

      final x = center.dx + math.sin((p * 2 + i * 0.25) * math.pi) * cell * 1.0;

      final y = center.dy - cell * 0.9 + p * cell * 2.2;

      final opacity = math.sin(p * math.pi);

      final snowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9 * opacity * strength)
        ..isAntiAlias = true;

      canvas.drawCircle(Offset(x, y), 1.0 + (i % 3) * 0.35, snowPaint);
    }
  }

  // THUNDER: Stable lightning bolts with animated flashes.

  void _paintThunder(Canvas canvas, Offset tail, double cell, double t) {
    final zap = _thunderIntensity(t);

    if (zap <= 0.01) return;

    final flashIndex = (t * _thunderFlashes).floor();

    // Deterministic random seed per flash.
    // This prevents lightning geometry from changing randomly
    // on every repaint.

    final rnd = math.Random(flashIndex * 7919 + 13);

    // Flash aura.

    final aura = Paint()
      ..color = color.withValues(alpha: 0.28 * zap)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(tail, cell * 1.15, aura);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.85 * zap)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
      ..isAntiAlias = true;

    final corePaint = Paint()
      ..color = Color.lerp(color, Colors.white, 0.9)!.withValues(alpha: zap)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    const spread = [-0.95, 0.0, 0.95];

    for (var b = 0; b < spread.length; b++) {
      final angle = _awayAngle + spread[b] + (rnd.nextDouble() - 0.5) * 0.25;

      final length = cell * (1.2 + rnd.nextDouble() * 0.5);

      final points = _boltPoints(tail, angle, length, 6, cell * 0.25, rnd);

      final bolt = _pathFromPoints(points);

      canvas.drawPath(bolt, glowPaint);
      canvas.drawPath(bolt, corePaint);

      // Branching lightning.

      final branchIndex = 3;

      final forkSide = rnd.nextBool() ? 1.0 : -1.0;

      final fork = _boltPoints(
        points[branchIndex],
        angle + forkSide * 0.75,
        length * 0.38,
        3,
        cell * 0.14,
        rnd,
      );

      final forkPath = _pathFromPoints(fork);

      canvas.drawPath(forkPath, glowPaint);
      canvas.drawPath(forkPath, corePaint);
    }
  }

  List<Offset> _boltPoints(
    Offset start,
    double angle,
    double length,
    int segments,
    double jitter,
    math.Random rnd,
  ) {
    final direction = Offset(math.cos(angle), math.sin(angle));

    final perpendicular = Offset(-direction.dy, direction.dx);

    final step = length / segments;

    final points = <Offset>[start];

    for (var i = 1; i <= segments; i++) {
      final offset = i == segments ? 0.0 : (rnd.nextDouble() * 2 - 1) * jitter;

      points.add(start + direction * (step * i) + perpendicular * offset);
    }

    return points;
  }

  Path _pathFromPoints(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _ArrowPreviewPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.style != style ||
        oldDelegate.animation != animation;
  }
}

// --------------------------------------------------
// BOARD PREVIEW PAINTER
// --------------------------------------------------

class _BoardThemePainter extends CustomPainter {
  final Color lineColor;
  final bool showStars;

  const _BoardThemePainter({required this.lineColor, this.showStars = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (!showStars) return;

    final paint = Paint()..color = Colors.white.withValues(alpha: 0.8);

    for (final point in [
      Offset(size.width * 0.18, size.height * 0.22),
      Offset(size.width * 0.72, size.height * 0.35),
      Offset(size.width * 0.45, size.height * 0.75),
      Offset(size.width * 0.85, size.height * 0.82),
      Offset(size.width * 0.30, size.height * 0.55),
    ]) {
      canvas.drawCircle(point, 1.3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardThemePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.showStars != showStars;
  }
}
