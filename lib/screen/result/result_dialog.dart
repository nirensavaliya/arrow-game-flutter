import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../services/vibration_service.dart';

class ResultDialog extends StatefulWidget {
  final bool won;

  /// True when the player lost because the timer ran out (timer mode).
  final bool timeUp;

  /// True when the player lost by hitting the wrong-move limit.
  final bool limitReached;

  final int stars;
  final String title;
  final String message;
  final String? timeText;

  /// Coins earned by completing this level for the first time.
  final int earnedCoins;

  /// Current shared coin balance.
  final int coinBalance;

  final bool newBest;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final VoidCallback onHome;
  final VoidCallback? onWatchAd;
  final String primaryLabel;
  final String secondaryLabel;

  const ResultDialog({
    super.key,
    required this.won,
    required this.stars,
    required this.onPrimary,
    required this.onSecondary,
    required this.onHome,
    this.timeUp = false,
    this.limitReached = false,
    this.title = '',
    this.message = '',
    this.timeText,
    this.newBest = false,
    this.primaryLabel = '',
    this.secondaryLabel = '',
    this.onWatchAd,
    this.earnedCoins = 0,
    this.coinBalance = 0,
  });

  @override
  State<ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<ResultDialog>
    with TickerProviderStateMixin {
  // Same palette as GameScreen.
  static const _blue = Color(0xFF2F80FF);
  static const _violet = Color(0xFF7B61FF);
  static const _red = Color(0xFFFF4D5E);
  static const _amber = Color(0xFFFFB300);
  static const _orange = Color(0xFFFF7A00);
  static const _mint = Color(0xFF1ED6C3);
  static const _maxStars = 5;

  static const _confettiClockSeconds = 3600;

  late final AnimationController _c;
  late final AnimationController _confetti;
  late final List<_Particle> _particles;
  late final List<_Shot> _shots;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  bool get _isTimeUp => widget.timeUp && !widget.won;

  bool get _isLimit => widget.limitReached && !widget.won && !widget.timeUp;

  Color get _textSecondary =>
      _isDark ? const Color(0xFFA0A6B5) : const Color(0xFF5B6478);

  Color get _glass => _isDark
      ? const Color(0xFF1A1D38).withValues(alpha: 0.82)
      : Colors.white.withValues(alpha: 0.88);

  Color get _glassBorder => _isDark
      ? Colors.white.withValues(alpha: 0.12)
      : const Color(0xFF2F4A8A).withValues(alpha: 0.12);

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _confettiClockSeconds),
    );

    final rnd = math.Random();

    const colors = [
      _blue,
      _violet,
      _mint,
      _amber,
      _orange,
      _red,
      Color(0xFFFF8AD8),
      Color(0xFF4ADE80),
      Color(0xFF22D3EE),
      Color(0xFFFFE066),
      Color(0xFFC084FC),
      Color(0xFFFF6B9D),
    ];

    double pickSize() {
      final r = rnd.nextDouble();

      if (r < 0.40) return 5 + rnd.nextDouble() * 3;
      if (r < 0.78) return 9 + rnd.nextDouble() * 4;

      return 14 + rnd.nextDouble() * 6;
    }

    _particles = List.generate(90, (_) {
      return _Particle(
        xFrac: rnd.nextDouble(),
        phase: rnd.nextDouble(),
        sway: 1 + rnd.nextDouble() * 2,
        size: pickSize(),
        spin: 2 + rnd.nextDouble() * 6,
        color: colors[rnd.nextInt(colors.length)],
      );
    });

    _shots = List.generate(130, (_) {
      final cannon = rnd.nextInt(3);

      final double ox;
      final double angle;

      if (cannon == 0) {
        ox = 0.08;
        angle = -math.pi / 2 + 0.10 + rnd.nextDouble() * 0.55;
      } else if (cannon == 1) {
        ox = 0.50;
        angle = -math.pi / 2 + (rnd.nextDouble() - 0.5) * 0.9;
      } else {
        ox = 0.92;
        angle = -math.pi / 2 - 0.10 - rnd.nextDouble() * 0.55;
      }

      return _Shot(
        ox: ox,
        angle: angle,
        speed: 900 + rnd.nextDouble() * 800,
        delay: rnd.nextDouble() * 0.3,
        size: pickSize(),
        spin: 2 + rnd.nextDouble() * 6,
        color: colors[rnd.nextInt(colors.length)],
      );
    });

    if (widget.won) {
      VibrationService.levelComplete();

      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          _confetti.repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Animation<double> _iv(double a, double b, Curve curve) {
    return CurvedAnimation(
      parent: _c,
      curve: Interval(a, b, curve: curve),
    );
  }

  @override
  Widget build(BuildContext context) {
    final won = widget.won;
    final timeUp = _isTimeUp;
    final limit = _isLimit;

    final backdrop = _iv(0.0, 0.3, Curves.easeOut);
    final card = _iv(0.0, 0.55, Curves.easeOutBack);

    final title = widget.title.isNotEmpty
        ? widget.title
        : (won
              ? 'Level cleared!'
              : (timeUp
                    ? "Time's up!"
                    : (limit ? 'Limit reached' : 'Out of lives')));

    final message = widget.message.isNotEmpty
        ? widget.message
        : (won
              ? 'Nice work. Ready for the next one?'
              : (timeUp
                    ? 'The timer ran out before you finished. Give it another go!'
                    : (limit
                          ? 'Too many wrong moves. Give it another go!'
                          : 'That was your last heart. Try again from the start.')));

    final primary = widget.primaryLabel.isNotEmpty
        ? widget.primaryLabel
        : (won ? 'Next level' : 'Try again');

    final secondary = widget.secondaryLabel.isNotEmpty
        ? widget.secondaryLabel
        : (won ? 'Play again' : 'Start over');

    return Stack(
      children: [
        // Blurred dim backdrop.
        Positioned.fill(
          child: FadeTransition(
            opacity: backdrop,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: ColoredBox(
                color:
                    (_isDark
                            ? const Color(0xFF0B0D20)
                            : const Color(0xFF1B2233))
                        .withValues(alpha: 0.55),
              ),
            ),
          ),
        ),

        Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, child) {
              final t = card.value;

              return Opacity(
                opacity: backdrop.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * 30),
                  child: Transform.scale(scale: 0.88 + 0.12 * t, child: child),
                ),
              );
            },
            child: _card(title, message, primary, secondary),
          ),
        ),

        if (won)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (_, _) => CustomPaint(
                  painter: _ConfettiPainter(
                    _particles,
                    _shots,
                    _confetti.value * _confettiClockSeconds,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _card(String title, String message, String primary, String secondary) {
    final won = widget.won;
    final timeUp = _isTimeUp;
    final limit = _isLimit;

    final accent = won
        ? [_blue, _violet]
        : (timeUp
              ? [_amber, _orange]
              : (limit ? [_orange, _red] : [_red, const Color(0xFFFF8A5B)]));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
          decoration: BoxDecoration(
            color: _glass,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _glassBorder),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 80,
                  child: won
                      ? _stars()
                      : (timeUp
                            ? _timeUpIcon()
                            : (limit
                                  ? _timeUpIcon(icon: Icons.block_rounded)
                                  : _brokenHeart())),
                ),

                const SizedBox(height: 12),

                ShaderMask(
                  shaderCallback: (r) =>
                      LinearGradient(colors: accent).createShader(r),
                  child: Text(
                    title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 14.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                if (won && widget.timeText != null) ...[
                  const SizedBox(height: 14),
                  _chip(widget.timeText!, Icons.schedule_rounded, _blue),
                ],

                if (won && widget.newBest) ...[
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _iv(0.6, 0.9, Curves.easeOut),
                    child: _chip(
                      'New best time!',
                      Icons.emoji_events_rounded,
                      _mint,
                    ),
                  ),
                ],

                // Coin reward appears only when this completion earned coins.
                if (won && widget.earnedCoins > 0) ...[
                  const SizedBox(height: 14),
                  _coinReward(),
                ],

                const SizedBox(height: 20),

                Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: _GradientButton(
                        label: primary,
                        icon: won
                            ? Icons.play_arrow_rounded
                            : Icons.refresh_rounded,
                        colors: accent,
                        onTap: widget.onPrimary,
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: _GlassButton(
                        label: '',
                        icon: Icons.home_rounded,
                        color: _violet,
                        onTap: widget.onHome,
                      ),
                    ),
                  ],
                ),

                if (!won && widget.onWatchAd != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: _GradientButton(
                      label: 'Watch Ad & Continue',
                      icon: Icons.play_circle_rounded,
                      colors: const [_mint, _blue],
                      onTap: widget.onWatchAd!,
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else
                  const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Animated reward panel.
  Widget _coinReward() {
    final animation = _iv(0.55, 1.0, Curves.easeOutBack);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final scale = animation.value.clamp(0.0, 1.2);
        final opacity = animation.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _amber.withValues(alpha: _isDark ? 0.20 : 0.16),
              _orange.withValues(alpha: _isDark ? 0.12 : 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE082), Color(0xFFFFA000)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _amber.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.monetization_on_rounded,
                color: Color(0xFF6D3900),
                size: 30,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LEVEL REWARD',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: _orange,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '+${widget.earnedCoins} coins',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _isDark ? Colors.white : const Color(0xFF252B3B),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'BALANCE',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      size: 16,
                      color: _amber,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${widget.coinBalance}',
                      style: TextStyle(
                        color: _isDark ? Colors.white : const Color(0xFF252B3B),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stars() {
    const sizes = [32.0, 42.0, 54.0, 42.0, 32.0];
    const lift = [0.0, 8.0, 14.0, 8.0, 0.0];
    const tilt = [-0.30, -0.15, 0.0, 0.15, 0.30];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(_maxStars, (i) {
        final start = 0.20 + i * 0.09;
        final a = _iv(start, start + 0.40, Curves.elasticOut);
        final filled = i < widget.stars;
        final size = sizes[i];

        return Padding(
          padding: EdgeInsets.only(bottom: lift[i], left: 2, right: 2),
          child: AnimatedBuilder(
            animation: a,
            builder: (_, _) => Transform.scale(
              scale: a.value.clamp(0.0, 1.4),
              child: Transform.rotate(
                angle: tilt[i],
                child: filled
                    ? ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFD54F), _amber],
                        ).createShader(r),
                        child: Icon(
                          Icons.star_rounded,
                          size: size,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.star_rounded,
                        size: size,
                        color: _textSecondary.withValues(alpha: 0.28),
                      ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _brokenHeart() {
    final a = _iv(0.1, 0.6, Curves.elasticOut);

    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final t = a.value;
          final rot = math.sin(_c.value * math.pi * 8) * 0.15 * (1 - _c.value);

          return Transform.rotate(
            angle: rot,
            child: Transform.scale(
              scale: t.clamp(0.0, 1.4),
              child: const Text('💔', style: TextStyle(fontSize: 64)),
            ),
          );
        },
      ),
    );
  }

  Widget _timeUpIcon({IconData icon = Icons.timer_off_rounded}) {
    final a = _iv(0.1, 0.6, Curves.elasticOut);

    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final rot = math.sin(_c.value * math.pi * 8) * 0.15 * (1 - _c.value);

          return Transform.rotate(
            angle: rot,
            child: Transform.scale(
              scale: a.value.clamp(0.0, 1.3),
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFD54F), _orange],
                ).createShader(r),
                child: Icon(icon, size: 68, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

class _GradientButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) {
      setState(() => _down = v);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.colors),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.colors.last.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 26),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GlassButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) {
      setState(() => _down = v);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 24),
              if (widget.label.isNotEmpty) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confetti: firecracker burst from the bottom, then continuous falling ribbons
// ---------------------------------------------------------------------------

class _Particle {
  final double xFrac, phase, sway, size, spin;
  final Color color;

  const _Particle({
    required this.xFrac,
    required this.phase,
    required this.sway,
    required this.size,
    required this.spin,
    required this.color,
  });
}

class _Shot {
  final double ox, angle, speed, delay, size, spin;
  final Color color;

  const _Shot({
    required this.ox,
    required this.angle,
    required this.speed,
    required this.delay,
    required this.size,
    required this.spin,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final List<_Shot> shots;
  final double elapsed;

  static const _burstLife = 2.8;
  static const _gravity = 1300.0;
  static const _fallStart = 1.3;
  static const _fallCycle = 4.0;

  _ConfettiPainter(this.particles, this.shots, this.elapsed);

  @override
  void paint(Canvas canvas, Size size) {
    // Firecracker burst.
    if (elapsed < _burstLife + 0.4) {
      for (final p in shots) {
        final s = elapsed - p.delay;

        if (s <= 0 || s >= _burstLife) continue;

        final x = size.width * p.ox + math.cos(p.angle) * p.speed * s;

        final y =
            size.height +
            10 +
            math.sin(p.angle) * p.speed * s +
            0.5 * _gravity * s * s;

        final life = s / _burstLife;
        final opacity = life < 0.7 ? 1.0 : (1 - life) / 0.3;

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(p.angle + math.pi / 2 + s * (p.spin - 5) * 1.2);
        canvas.scale(
          1,
          math.cos(s * p.spin * 0.5 * math.pi * 2).abs().clamp(0.15, 1.0),
        );

        _drawRibbon(canvas, p.color, p.size, opacity);
        canvas.restore();
      }
    }

    // Continuous falling ribbons.
    final f = elapsed - _fallStart;

    if (f > 0) {
      for (final p in particles) {
        final delay = p.phase * _fallCycle;

        if (f < delay) continue;

        final lt = ((f - delay) / _fallCycle) % 1.0;

        final x =
            size.width * p.xFrac + math.sin(lt * math.pi * 2 * p.sway) * 24;

        final y = -20 + lt * (size.height + 40);

        final opacity = lt < 0.1
            ? lt / 0.1
            : (lt > 0.85 ? (1 - lt) / 0.15 : 1.0);

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(math.sin(lt * math.pi * 2 * p.sway) * 0.8);
        canvas.scale(
          1,
          math.cos(lt * p.spin * math.pi * 2).abs().clamp(0.15, 1.0),
        );

        _drawRibbon(canvas, p.color, p.size, opacity);
        canvas.restore();
      }
    }
  }

  void _drawRibbon(Canvas canvas, Color color, double size, double opacity) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: size * 0.55,
          height: size * 2.2,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = color.withValues(alpha: opacity.clamp(0.0, 1.0)),
    );
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) {
    return old.elapsed != elapsed;
  }
}
