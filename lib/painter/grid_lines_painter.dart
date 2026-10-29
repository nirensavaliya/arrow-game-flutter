import 'package:flutter/material.dart';

/// Draws vertical + horizontal grid lines for the game board.
class GridLinesPainter extends CustomPainter {
  final int cols;
  final int rows;
  final bool isDark;

  const GridLinesPainter({
    required this.cols,
    required this.rows,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (cols <= 0 || rows <= 0 || size.isEmpty) return;

    final cellW = size.width / cols;
    final cellH = size.height / rows;

    final paint = Paint()
      ..color = (isDark ? const Color(0xFF929CFF) : const Color(0xFF7186E8))
          .withValues(alpha: isDark ? 0.22 : 0.26)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    // Vertical lines through the dot centres.
    for (var i = 0; i < cols; i++) {
      final x = (i + 0.5) * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines through the dot centres.
    for (var j = 0; j < rows; j++) {
      final y = (j + 0.5) * cellH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridLinesPainter old) =>
      old.cols != cols || old.rows != rows || old.isDark != isDark;
}