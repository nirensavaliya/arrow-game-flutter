import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../game/game_intro_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Same palette as GameIntroScreen
  static const Color _darkBg = Color(0xFF07080F);
  static const Color _darkTextPrimary = Color(0xFFF7F7FC);
  static const Color _darkTextSecondary = Color(0xFF8E92AB);

  static const Color _lightBg = Color(0xFFF4F5FA);
  static const Color _lightTextPrimary = Color(0xFF14162A);
  static const Color _lightTextSecondary = Color(0xFF6F7390);

  // Mode colors (Normal -> Timed -> Speed Run)
  static const List<Color> _colors = [
    Color(0xFF8175FF),
    Color(0xFFFFB34F),
    Color(0xFF35D68A),
  ];
  static const List<Color> _colorsDeep = [
    Color(0xFF4B3FD1),
    Color(0xFFD9681C),
    Color(0xFF0C7F52),
  ];

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _isDark ? _darkBg : _lightBg;
  Color get _textPrimary => _isDark ? _darkTextPrimary : _lightTextPrimary;
  Color get _textSecondary =>
      _isDark ? _darkTextSecondary : _lightTextSecondary;

  late final AnimationController _intro;
  late final AnimationController _ambient;
  late final AnimationController _load;

  late final Animation<double> _logoScale;
  late final Animation<Color?> _color;
  late final Animation<Color?> _colorDeep;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();

    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _load = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.0, 0.9, curve: Curves.elasticOut),
      ),
    );

    _color = _cycle(_colors);
    _colorDeep = _cycle(_colorsDeep);

    _load.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Get.off(
              () => const GameIntroScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 500),
        );
      }
    });
  }

  Animation<Color?> _cycle(List<Color> c) {
    return TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: c[0], end: c[1]),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: c[1], end: c[2]),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: c[2], end: c[0]),
        weight: 1,
      ),
    ]).animate(_load);
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _load.dispose();
    super.dispose();
  }

  // Same staggered reveal as the intro screen
  Widget _reveal(double start, Widget child) {
    final animation = CurvedAnimation(
      parent: _intro,
      curve: Interval(
        start,
        math.min(1.0, start + 0.55),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - animation.value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_ambient, _load]),
        builder: (context, _) {
          final color = _color.value ?? _colors[0];
          final deep = _colorDeep.value ?? _colorsDeep[0];

          return Stack(
            children: [
              Positioned.fill(child: _buildBackground(color, deep)),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _logoScale,
                      child: _reveal(0.0, _buildLogo(color, deep)),
                    ),
                    const SizedBox(height: 28),
                    _reveal(
                      0.18,
                      Text(
                        'Arrow Maze',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 32,
                          letterSpacing: -1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _reveal(
                      0.28,
                      Text(
                        'Think • Trace • Escape',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 44),
                    _reveal(0.42, _buildLoader(color, deep)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground(Color color, Color deep) {
    final drift = math.sin(_ambient.value * math.pi) * 22;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: MazePainter(
              color: (_isDark ? Colors.white : Colors.black)
                  .withValues(alpha: _isDark ? 0.03 : 0.035),
            ),
          ),
        ),
        Positioned(
          top: -150 + drift,
          right: -120,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: _isDark ? 0.28 : 0.16),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -140 - drift,
          left: -150,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  deep.withValues(alpha: _isDark ? 0.20 : 0.11),
                  deep.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(Color color, Color deep) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, deep],
        ),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: _isDark ? 0.42 : 0.34),
            blurRadius: 32,
            spreadRadius: -6,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: deep.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(33),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: MazePainter(
                  color: Colors.white.withValues(alpha: 0.10),
                  cell: 22,
                  seed: 4,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            const Icon(Icons.route_rounded, size: 58, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildLoader(Color color, Color deep) {
    final track = _isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    return SizedBox(
      width: 120,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            Container(height: 6, color: track),
            FractionallySizedBox(
              widthFactor: Curves.easeInOut.transform(_load.value),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, deep]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MazePainter extends CustomPainter {
  final Color color;
  final double cell;
  final int seed;

  const MazePainter({
    required this.color,
    this.cell = 36,
    this.seed = 11,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final rnd = math.Random(seed);

    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        if (rnd.nextBool()) {
          canvas.drawLine(Offset(x, y), Offset(x + cell, y), paint);
        } else {
          canvas.drawLine(Offset(x, y), Offset(x, y + cell), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MazePainter old) =>
      old.color != color || old.cell != cell || old.seed != seed;
}