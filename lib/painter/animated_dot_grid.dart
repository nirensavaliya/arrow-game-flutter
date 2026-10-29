import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// =============================================================================
// ANIMATED DOT GRID  (dots appear / fade as arrows are cleared)
// =============================================================================

// Shorter than before so dots keep up with the faster arrow exit.
const _enterMs = 150.0;
const _exitMs = 90.0;

class _DotAnim {
  final double startMs;
  final bool exiting;

  const _DotAnim(this.startMs, {required this.exiting});

  double endMs() => startMs + (exiting ? _exitMs : _enterMs);
}

class AnimatedDotGrid extends StatefulWidget {
  final int cols;
  final int rows;
  final Set<int> visible;
  final bool isDark;
  final int? originCell;
  final double dotScale;
  final bool animateInitial;

  const AnimatedDotGrid({
    super.key,
    required this.cols,
    required this.rows,
    required this.visible,
    this.isDark = false,
    this.originCell,
    this.dotScale = 0.13,
    this.animateInitial = false,
  });

  @override
  State<AnimatedDotGrid> createState() => _AnimatedDotGridState();
}

class _AnimatedDotGridState extends State<AnimatedDotGrid>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  final Stopwatch _stopwatch = Stopwatch()..start();
  final ValueNotifier<double> _clock = ValueNotifier<double>(0);
  final Map<int, _DotAnim> _anims = {};

  Set<int> _previous = {};
  bool _reduceMotion = false;
  bool _initialized = false;
  int _revision = 0;

  double get _nowMs => _stopwatch.elapsedMicroseconds / 1000.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _previous = widget.animateInitial ? <int>{} : Set<int>.of(widget.visible);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (!_initialized) {
      _initialized = true;
      _sync();
    } else if (_reduceMotion) {
      _anims.clear();
      _ticker.stop();
      _clock.value = _nowMs;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedDotGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.cols != widget.cols || oldWidget.rows != widget.rows) {
      _anims.clear();
      _ticker.stop();
      _previous = widget.animateInitial ? <int>{} : Set<int>.of(widget.visible);
      _revision++;
    }

    _sync();
  }

  void _sync() {
    final added = widget.visible.difference(_previous);
    final removed = _previous.difference(widget.visible);

    _previous = Set<int>.of(widget.visible);

    if (added.isEmpty && removed.isEmpty) return;

    _revision++;

    if (_reduceMotion) {
      _anims.clear();
      _ticker.stop();
      _clock.value = _nowMs;
      return;
    }

    final now = _nowMs;

    _schedule(added, now, exiting: false);
    _schedule(removed, now, exiting: true);

    _clock.value = now;

    if (_anims.isNotEmpty && !_ticker.isActive) {
      _ticker.start();
    }
  }

  void _schedule(Set<int> cells, double now, {required bool exiting}) {
    if (cells.isEmpty || widget.cols <= 0 || widget.rows <= 0) return;

    final cols = widget.cols;
    final rows = widget.rows;

    double originX;
    double originY;

    final origin = widget.originCell;

    if (origin != null && origin >= 0 && origin < cols * rows) {
      originX = (origin % cols) + 0.5;
      originY = (origin ~/ cols) + 0.5;
    } else {
      var sx = 0.0;
      var sy = 0.0;

      for (final cell in cells) {
        sx += (cell % cols) + 0.5;
        sy += (cell ~/ cols) + 0.5;
      }

      originX = sx / cells.length;
      originY = sy / cells.length;
    }

    final distances = <int, double>{};
    var maxDistance = 0.0;

    for (final cell in cells) {
      if (cell < 0 || cell >= cols * rows) continue;

      final dx = (cell % cols) + 0.5 - originX;
      final dy = (cell ~/ cols) + 0.5 - originY;
      final distance = math.sqrt(dx * dx + dy * dy);

      distances[cell] = distance;
      maxDistance = math.max(maxDistance, distance);
    }

    // Tighter stagger: the ripple still reads, but it no longer lags behind.
    final maxStagger = exiting ? 28.0 : 55.0;
    final perCell = exiting ? 2.0 : 4.0;
    final stagger = math.min(maxStagger, perCell * math.sqrt(cells.length));

    for (final entry in distances.entries) {
      final normalized = maxDistance > 0 ? entry.value / maxDistance : 0.0;

      _anims[entry.key] = _DotAnim(
        now + stagger * normalized,
        exiting: exiting,
      );
    }
  }

  void _onTick(Duration elapsed) {
    final now = _nowMs;

    _anims.removeWhere((_, anim) => now >= anim.endMs());
    _clock.value = now;

    if (_anims.isEmpty) {
      _ticker.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _DotPainter(
          cols: widget.cols,
          rows: widget.rows,
          visible: widget.visible,
          anims: _anims,
          clock: _clock,
          isDark: widget.isDark,
          dotScale: widget.dotScale,
          revision: _revision,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    _stopwatch.stop();
    super.dispose();
  }
}

class _DotPainter extends CustomPainter {
  final int cols;
  final int rows;
  final Set<int> visible;
  final Map<int, _DotAnim> anims;
  final ValueNotifier<double> clock;
  final bool isDark;
  final double dotScale;
  final int revision;

  _DotPainter({
    required this.cols,
    required this.rows,
    required this.visible,
    required this.anims,
    required this.clock,
    required this.isDark,
    required this.dotScale,
    required this.revision,
  }) : super(repaint: clock);

  @override
  void paint(Canvas canvas, Size size) {
    if (cols <= 0 || rows <= 0 || size.isEmpty) return;

    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;
    final radius = math.min(cellWidth, cellHeight) * dotScale;
    final now = clock.value;

    final color = isDark ? const Color(0xFF929CFF) : const Color(0xFF7186E8);

    final glowColor = isDark
        ? const Color(0xFF7965FF)
        : const Color(0xFF9AABFF);

    Offset centerOf(int cell) => Offset(
      ((cell % cols) + 0.5) * cellWidth,
      ((cell ~/ cols) + 0.5) * cellHeight,
    );

    final settledPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.88 : 0.82)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: isDark ? 0.12 : 0.09)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final settled = <Offset>[];

    for (final cell in visible) {
      if (cell < 0 || cell >= cols * rows) continue;

      final anim = anims[cell];

      if (anim == null || anim.exiting) {
        settled.add(centerOf(cell));
      }
    }

    for (final point in settled) {
      canvas.drawCircle(point, radius * 1.8, glowPaint);
    }

    if (settled.isNotEmpty) {
      final pointsPaint = Paint()
        ..color = settledPaint.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = radius * 2
        ..isAntiAlias = true;

      canvas.drawPoints(ui.PointMode.points, settled, pointsPaint);
    }

    final dotPaint = Paint()..isAntiAlias = true;

    for (final entry in anims.entries) {
      final cell = entry.key;
      final anim = entry.value;

      if (anim.exiting || !visible.contains(cell)) continue;
      if (cell < 0 || cell >= cols * rows || now < anim.startMs) {
        continue;
      }

      final t = ((now - anim.startMs) / _enterMs).clamp(0.0, 1.0);
      final eased = Curves.easeOutBack.transform(t);
      final scale = (0.45 + eased * 0.55).clamp(0.2, 1.12);

      final alpha = Curves.easeOutCubic.transform(t);

      final center = centerOf(cell);

      dotPaint.color = glowColor.withValues(
        alpha: alpha * (isDark ? 0.24 : 0.16),
      );

      canvas.drawCircle(center, radius * scale * 2.1, dotPaint);

      dotPaint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(center, radius * scale, dotPaint);
    }

    for (final entry in anims.entries) {
      final cell = entry.key;
      final anim = entry.value;

      if (!anim.exiting || visible.contains(cell)) continue;
      if (cell < 0 || cell >= cols * rows) continue;

      final raw = ((now - anim.startMs) / _exitMs).clamp(0.0, 1.0);
      final eased = Curves.easeInCubic.transform(raw);
      final scale = 1.0 - eased * 0.72;
      final alpha = 1.0 - eased;

      final center = centerOf(cell);

      dotPaint.color = glowColor.withValues(
        alpha: alpha * (isDark ? 0.18 : 0.12),
      );
      canvas.drawCircle(center, radius * scale * 1.8, dotPaint);

      dotPaint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(center, radius * scale, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotPainter oldDelegate) {
    return oldDelegate.cols != cols ||
        oldDelegate.rows != rows ||
        oldDelegate.isDark != isDark ||
        oldDelegate.dotScale != dotScale ||
        oldDelegate.revision != revision ||
        oldDelegate.visible != visible;
  }
}
