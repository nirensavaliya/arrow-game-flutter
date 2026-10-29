import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../model/arrow_model.dart';

class ArrowPainter extends CustomPainter {
  final List<ArrowModel> arrows;
  final bool isDark;
  final ArrowModel? hintArrow;

  /// Actual grid dimensions for the current level.
  final int gridRows;
  final int gridCols;

  /// 0.0 = starting appearance, 1.0 = full size.
  final double appearanceProgress;

  /// Optional draw-on entrance animation (0 -> 1).
  /// Each arrow grows from its tail to its head with a staggered start.
  /// When null, arrows are drawn fully.
  final Animation<double>? appearance;

  ArrowPainter({
    required this.arrows,
    this.isDark = false,
    this.hintArrow,
    this.gridRows = 10,
    this.gridCols = 10,
    this.appearanceProgress = 1.0,
    this.appearance,
  }) : super(repaint: appearance);

  // COLORS
  Color get _arrowColor =>
      isDark ? const Color(0xFFE4E8F5) : const Color(0xFF1B2233);

  Color get _hintColor => const Color(0xFF2F80FF);

  Color get _blockedColor => const Color(0xFFFF4D5E);

  /// Starts near the intended size so the appearance animation feels snappy.
  double _appearanceScale() {
    final progress = appearanceProgress.clamp(0.0, 1.0).toDouble();
    final eased = Curves.easeOutCubic.transform(progress);

    return 0.82 + (0.18 * eased);
  }

  // PAINT
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rows = gridRows > 0 ? gridRows : _estimateRows();
    final cols = gridCols > 0 ? gridCols : _estimateColumns();

    final cellWidth = size.width / math.max(1, cols);
    final cellHeight = size.height / math.max(1, rows);
    final cellSize = math.min(cellWidth, cellHeight);

    // Fixed proportions relative to the cell, on every board size.
    final scale = _appearanceScale();

    final strokeWidth = (cellSize * 0.11 * scale).clamp(1.0, 5.0).toDouble();

    final headLength = (cellSize * 0.45 * scale).clamp(3.0, 16.0).toDouble();
    final headHalfWidth = (cellSize * 0.24 * scale).clamp(1.8, 9.0).toDouble();

    // Large, round corners (about 0.4 of a cell).
    final cornerRadius = cellSize * 0.40 * scale;

    // Draw-on entrance progress (1.0 = finished / disabled).
    final draw = appearance?.value ?? 1.0;

    for (var index = 0; index < arrows.length; index++) {
      final arrow = arrows[index];

      if (!arrow.isActive || arrow.points.length < 2) continue;

      var points = arrow.points
          .map((point) => Offset(point.dx * size.width, point.dy * size.height))
          .toList(growable: false);

      final direction = _headDirection(points);
      if (direction == null) continue;

      final pathLength = _length(points);
      var shift = 0.0;

      if (arrow.isMoving) {
        final progress = _smoothProgress(arrow.progress);

        // Extend movement far enough for the arrow to leave the board.
        shift = progress * (pathLength + size.longestSide * 1.2);
      } else if (arrow.bumpProgress > 0 && arrow.bumpTravel > 0) {
        final horizontal = direction.dx.abs() > direction.dy.abs();
        final progress = _bumpProgress(arrow.bumpProgress);

        shift =
            arrow.bumpTravel *
                progress *
                (horizontal ? size.width : size.height);
      }

      if (shift > 0) {
        final extended = <Offset>[...points, points.last + direction * shift];

        points = _slice(extended, shift, shift + pathLength);

        if (points.length < 2) continue;
      }

      // ---- Draw-on entrance: each arrow grows from tail to head ----
      var headProgress = 1.0;

      if (draw < 1.0 && !arrow.isMoving) {
        // Deterministic pseudo-random stagger per arrow (no flicker).
        final n = math.max(1, arrows.length);
        final delay = (((index * 37) % n) / n) * 0.45;

        final local = ((draw - delay) / 0.55).clamp(0.0, 1.0).toDouble();
        if (local <= 0) continue;

        final eased = Curves.easeOutCubic.transform(local);
        points = _slice(points, 0, pathLength * eased);
        if (points.length < 2) continue;

        // Head pops in only at the very end of the stroke.
        headProgress = ((local - 0.82) / 0.18).clamp(0.0, 1.0).toDouble();
        headProgress = Curves.easeOutBack.transform(headProgress);
      }

      final isHint = identical(arrow, hintArrow);

      final isClearing = arrow.isMoving && !arrow.isBlocked;

      // Fade out during the last part of the exit so it "clears" smoothly.
      final fade = isClearing
          ? (1.0 - ((arrow.progress - 0.55) / 0.45).clamp(0.0, 1.0)).toDouble()
          : 1.0;

      final baseColor = arrow.isBlocked
          ? _blockedColor
          : (isClearing || isHint ? _hintColor : _arrowColor);

      _drawArrow(
        canvas,
        points,
        color: baseColor.withValues(alpha: fade),
        strokeWidth: strokeWidth,
        // same width in every state
        headLength: headLength,
        headHalfWidth: headHalfWidth,
        cornerRadius: cornerRadius,
        headProgress: headProgress,
        glow: false,
      );
    }
  }

  // GRID DIMENSION FALLBACKS
  int _estimateColumns() {
    var columns = 1;

    for (final arrow in arrows) {
      for (final point in arrow.points) {
        if (point.dx > 0) {
          columns = math.max(columns, (1.0 / point.dx).round());
        }
      }
    }

    return columns.clamp(1, 200);
  }

  int _estimateRows() {
    var rows = 1;

    for (final arrow in arrows) {
      for (final point in arrow.points) {
        if (point.dy > 0) {
          rows = math.max(rows, (1.0 / point.dy).round());
        }
      }
    }

    return rows.clamp(1, 200);
  }

  // ARROW DRAWING
  void _drawArrow(
      Canvas canvas,
      List<Offset> points, {
        required Color color,
        required double strokeWidth,
        required double headLength,
        required double headHalfWidth,
        required double cornerRadius,
        double headProgress = 1.0,
        bool glow = false,
      }) {
    if (points.length < 2) return;

    final direction = _headDirection(points);
    if (direction == null) return;

    final tip = points.last;
    final showHead = headProgress > 0.001;

    // Leave enough room for a clean, connected arrowhead.
    // While the stroke is still growing (no head yet) keep the full body.
    final body = showHead ? _trimEnd(points, headLength * 0.55) : points;
    if (body.length < 2) return;

    final path = _buildSmoothPath(body, cornerRadius);

    // Soft glow behind the hinted arrow.
    if (glow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 1.5);

      canvas.drawPath(path, glowPaint);
    }

    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(path, bodyPaint);

    if (!showHead) return;

    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(
      _createArrowHead(
        tip,
        direction,
        headLength * headProgress,
        headHalfWidth * headProgress,
      ),
      headPaint,
    );
  }

  Path _createArrowHead(
      Offset tip,
      Offset direction,
      double headLength,
      double headHalfWidth,
      ) {
    final perpendicular = Offset(-direction.dy, direction.dx);
    final base = tip - direction * headLength;

    final left = base + perpendicular * headHalfWidth;
    final right = base - perpendicular * headHalfWidth;

    return Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
  }

  // SMOOTH PATHS
  Path _buildSmoothPath(List<Offset> points, double cornerRadius) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);

    if (points.length == 2) {
      path.lineTo(points.last.dx, points.last.dy);
      return path;
    }

    for (var i = 1; i < points.length - 1; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final next = points[i + 1];

      final incoming = current - previous;
      final outgoing = next - current;

      final incomingLength = incoming.distance;
      final outgoingLength = outgoing.distance;

      if (incomingLength < 0.001 || outgoingLength < 0.001) {
        path.lineTo(current.dx, current.dy);
        continue;
      }

      // Limited by half of the shorter neighbouring segment.
      final radius = math.min(
        cornerRadius,
        math.min(incomingLength, outgoingLength) * 0.5,
      );

      final entry = current - incoming / incomingLength * radius;
      final exit = current + outgoing / outgoingLength * radius;

      path.lineTo(entry.dx, entry.dy);
      path.quadraticBezierTo(current.dx, current.dy, exit.dx, exit.dy);
    }

    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  // ANIMATION HELPERS

  /// Fast response with a smooth finish.
  double _smoothProgress(double progress) {
    final t = progress.clamp(0.0, 1.0).toDouble();

    // Ease out quadratic.
    return 1.0 - (1.0 - t) * (1.0 - t);
  }

  /// Quick, controlled bump with a gentle settle.
  double _bumpProgress(double progress) {
    final t = progress.clamp(0.0, 1.0).toDouble();

    return Curves.easeOutCubic.transform(t);
  }

  List<Offset> _trimEnd(List<Offset> points, double amount) {
    final result = List<Offset>.from(points);
    var remaining = amount;

    while (result.length >= 2 && remaining > 0) {
      final a = result[result.length - 2];
      final b = result.last;
      final segment = (b - a).distance;

      if (segment < 0.0001) {
        result.removeLast();
        continue;
      }

      if (segment > remaining) {
        result[result.length - 1] = Offset.lerp(
          a,
          b,
          1.0 - remaining / segment,
        )!;
        remaining = 0;
      } else {
        remaining -= segment;
        result.removeLast();
      }
    }

    return result.length >= 2 ? result : <Offset>[points.first, points.first];
  }

  /// Head direction = direction of the last non-zero segment, which is the
  /// same direction the controller uses for the exit ray.
  Offset? _headDirection(List<Offset> points) {
    for (var i = points.length - 1; i > 0; i--) {
      final delta = points[i] - points[i - 1];
      final distance = delta.distance;

      if (distance > 0.0001) return delta / distance;
    }

    return null;
  }

  double _length(List<Offset> points) {
    var total = 0.0;

    for (var i = 0; i < points.length - 1; i++) {
      total += (points[i + 1] - points[i]).distance;
    }

    return total;
  }

  List<Offset> _slice(List<Offset> points, double from, double to) {
    final result = <Offset>[];
    var accumulated = 0.0;

    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];

      final segmentLength = (b - a).distance;
      if (segmentLength < 0.0001) continue;

      final start = accumulated;
      final end = accumulated + segmentLength;

      if (end > from && start < to) {
        final t0 = ((from - start) / segmentLength).clamp(0.0, 1.0).toDouble();
        final t1 = ((to - start) / segmentLength).clamp(0.0, 1.0).toDouble();

        final startPoint = Offset.lerp(a, b, t0)!;
        final endPoint = Offset.lerp(a, b, t1)!;

        if (result.isEmpty) {
          result.add(startPoint);
        } else if ((result.last - startPoint).distance > 0.01) {
          result.add(startPoint);
        }

        result.add(endPoint);
      }

      accumulated = end;

      if (accumulated >= to) break;
    }

    return result;
  }

  // REPAINT
  @override
  bool shouldRepaint(covariant ArrowPainter oldDelegate) {
    return oldDelegate.arrows != arrows ||
        oldDelegate.isDark != isDark ||
        oldDelegate.hintArrow != hintArrow ||
        oldDelegate.gridRows != gridRows ||
        oldDelegate.gridCols != gridCols ||
        oldDelegate.appearanceProgress != appearanceProgress ||
        oldDelegate.appearance != appearance;
  }
}