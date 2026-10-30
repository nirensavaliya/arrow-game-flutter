import 'dart:math' as math;

// =============================================================================
// LEVEL GRID
// =============================================================================

class LevelGrid {
  final int cols;
  final int rows;
  final Set<int> allowed;

  const LevelGrid(this.cols, this.rows, this.allowed);

  bool contains(int x, int y) =>
      x >= 0 &&
      x < cols &&
      y >= 0 &&
      y < rows &&
      allowed.contains(y * cols + x);

  int get cellCount => allowed.length;
}

// =============================================================================
// SHAPE HELPERS
// =============================================================================

typedef ShapeFn = bool Function(double x, double y);

// Must match GameController.boardAspect. Used to size a board from a design.
const double _boardAspect = 0.82;

bool _ell(double x, double y, double cx, double cy, double rx, double ry) {
  if (rx <= 0 || ry <= 0) return false;

  final dx = (x - cx) / rx;
  final dy = (y - cy) / ry;

  return dx * dx + dy * dy <= 1;
}

bool _rect(double x, double y, double x1, double y1, double x2, double y2) =>
    x >= math.min(x1, x2) &&
    x <= math.max(x1, x2) &&
    y >= math.min(y1, y2) &&
    y <= math.max(y1, y2);

bool _poly(double x, double y, List<(double, double)> points) {
  if (points.length < 3) return false;

  var inside = false;

  for (var i = 0, j = points.length - 1; i < points.length; j = i++) {
    final (xi, yi) = points[i];
    final (xj, yj) = points[j];

    if ((yi > y) != (yj > y)) {
      final crossX = (xj - xi) * (y - yi) / (yj - yi) + xi;
      if (x < crossX) inside = !inside;
    }
  }

  return inside;
}

bool _seg(
  double x,
  double y,
  double x1,
  double y1,
  double x2,
  double y2,
  double radius,
) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final len2 = dx * dx + dy * dy;

  final t = len2 == 0
      ? 0.0
      : (((x - x1) * dx + (y - y1) * dy) / len2).clamp(0.0, 1.0).toDouble();

  final px = x - x1 - dx * t;
  final py = y - y1 - dy * t;

  return px * px + py * py <= radius * radius;
}

bool _heart(double x, double y) {
  final hx = x * 1.25;
  final hy = -y * 1.25 + 0.20;

  final x2 = hx * hx;
  final y2 = hy * hy;
  final q = x2 + y2 - 1.0;

  return q * q * q - x2 * y2 * hy <= 0;
}

double _distance(double x, double y) => math.sqrt(x * x + y * y);

double _angle(double x, double y) => math.atan2(y, x);

String _repeat(String value, int count) =>
    count <= 0 ? '' : List.filled(count, value).join();

bool _ring(double x, double y, double outer, double inner) {
  final r = _distance(x, y);
  return r <= outer && r >= inner;
}

double _ab(double v) => v.abs();

double _frac(double v) => v - v.floorToDouble();

/// Rounded rectangle with corner radius [radius].
bool _rrect(
  double x,
  double y,
  double x1,
  double y1,
  double x2,
  double y2,
  double radius,
) {
  final l = math.min(x1, x2);
  final rt = math.max(x1, x2);
  final t = math.min(y1, y2);
  final b = math.max(y1, y2);

  if (x < l || x > rt || y < t || y > b) return false;

  final rad = math.min(radius, math.min((rt - l) / 2, (b - t) / 2));
  final cx = x.clamp(l + rad, rt - rad).toDouble();
  final cy = y.clamp(t + rad, b - rad).toDouble();

  final dx = x - cx;
  final dy = y - cy;

  return dx * dx + dy * dy <= rad * rad;
}

/// Regular polygon with [n] sides.
bool _regular(
  double x,
  double y,
  int n,
  double rad, {
  double rot = -math.pi / 2,
}) {
  return _poly(
    x,
    y,
    List.generate(n, (i) {
      final a = rot + i * 2 * math.pi / n;
      return (math.cos(a) * rad, math.sin(a) * rad);
    }),
  );
}

/// Star polygon with [n] points (outer and inner radius).
bool _starPoly(
  double x,
  double y,
  int n,
  double outer,
  double inner, {
  double rot = -math.pi / 2,
}) {
  final pts = <(double, double)>[];

  for (var i = 0; i < n * 2; i++) {
    final a = rot + i * math.pi / n;
    final rad = i.isEven ? outer : inner;
    pts.add((math.cos(a) * rad, math.sin(a) * rad));
  }

  return _poly(x, y, pts);
}

/// [count] circles placed around the centre.
bool _petals(
  double x,
  double y,
  int count,
  double dist,
  double radius, {
  double rot = -math.pi / 2,
}) {
  for (var i = 0; i < count; i++) {
    final a = rot + i * 2 * math.pi / count;
    if (_ell(x, y, math.cos(a) * dist, math.sin(a) * dist, radius, radius)) {
      return true;
    }
  }
  return false;
}

/// [count] thick lines going out from the centre (r0 to r1).
bool _rays(
  double x,
  double y,
  int count,
  double r0,
  double r1,
  double w, {
  double rot = 0,
}) {
  for (var i = 0; i < count; i++) {
    final a = rot + i * 2 * math.pi / count;
    if (_seg(
      x,
      y,
      math.cos(a) * r0,
      math.sin(a) * r0,
      math.cos(a) * r1,
      math.sin(a) * r1,
      w,
    )) {
      return true;
    }
  }
  return false;
}

/// Folds the plane into one of [n] mirrored sectors. Returns (u, v) where u
/// runs along the nearest axis and v is the distance from it (always >= 0).
(double, double) _fold(double x, double y, int n) {
  final r = _distance(x, y);
  final sector = 2 * math.pi / n;
  final d = ((_angle(x, y) + sector / 2) % sector) - sector / 2;

  return (r * math.cos(d), (r * math.sin(d)).abs());
}

bool _snow(double x, double y) {
  final (u, v) = _fold(x, y, 6);

  return _seg(u, v, 0, 0, 0.95, 0, 0.07) ||
      _seg(
        u,
        v,
        0.45,
        0,
        0.45 + math.cos(0.8) * 0.3,
        math.sin(0.8) * 0.3,
        0.055,
      ) ||
      _seg(
        u,
        v,
        0.72,
        0,
        0.72 + math.cos(0.8) * 0.2,
        math.sin(0.8) * 0.2,
        0.055,
      );
}

bool _cogShape(double x, double y) {
  final r = _distance(x, y);
  final tooth = math.cos(8 * _angle(x, y)) > 0.2 ? 0.95 : 0.72;

  return r <= tooth && r >= 0.28;
}

bool _planet(double x, double y) {
  if (_ell(x, y, 0, 0, 0.55, 0.55)) return true;

  final c = math.cos(-0.45);
  final s = math.sin(-0.45);
  final xr = x * c - y * s;
  final yr = x * s + y * c;
  final e = (xr / 0.98) * (xr / 0.98) + (yr / 0.30) * (yr / 0.30);

  return e <= 1 && e >= 0.55;
}

bool _octopus(double x, double y) {
  if (_ell(x, y, 0, -0.35, 0.64, 0.56) &&
      !_ell(x.abs(), y, 0.25, -0.4, 0.09, 0.11)) {
    return true;
  }

  for (var i = 0; i < 6; i++) {
    final x0 = -0.5 + i * 0.2;
    final x1 = x0 + (i.isEven ? 0.12 : -0.12);
    if (_seg(x, y, x0, 0.05, x1, 0.95, 0.08)) return true;
  }
  return false;
}

// =============================================================================
// LEVEL DESIGN
// =============================================================================

class LevelDesign {
  final String name;
  final String category;
  final int preferredLongSide;

  final ShapeFn _shape;
  final double _minX;
  final double _maxX;
  final double _minY;
  final double _maxY;
  final bool _crisp;

  const LevelDesign._(
    this.name,
    this.category,
    this.preferredLongSide,
    this._shape,
    this._minX,
    this._maxX,
    this._minY,
    this._maxY,
    this._crisp,
  );

  /// Builds a design from a shape function.
  ///
  /// When [targetCells] is given, the board size is NOT taken from
  /// [preferredLongSide]. It is calculated from the real silhouette: its
  /// filled area (holes included), its width and height. That way a thin or
  /// wide design gets a bigger board than a solid one, so every design ends up
  /// with about [targetCells] playable cells. The result is limited to
  /// [minSide]..[maxSide].
  factory LevelDesign.shape(
    String name,
    String category,
    ShapeFn shape, {
    int preferredLongSide = 24,
    double extent = 1.3,
    int? targetCells,
    int minSide = 6,
    int maxSide = 66,
  }) {
    const samples = 180;
    final step = extent * 2 / samples;

    var minX = double.infinity;
    var maxX = -double.infinity;
    var minY = double.infinity;
    var maxY = -double.infinity;
    var hits = 0;

    for (var row = 0; row < samples; row++) {
      final y = -extent + (row + 0.5) * step;

      for (var col = 0; col < samples; col++) {
        final x = -extent + (col + 0.5) * step;

        if (!shape(x, y)) continue;

        hits++;

        minX = math.min(minX, x);
        maxX = math.max(maxX, x);
        minY = math.min(minY, y);
        maxY = math.max(maxY, y);
      }
    }

    if (!minX.isFinite) {
      return LevelDesign._(
        name,
        category,
        1,
        (_, _) => false,
        0,
        1,
        0,
        1,
        true,
      );
    }

    var side = preferredLongSide;

    if (targetCells != null && hits > 0) {
      final w = maxX - minX + step;
      final h = maxY - minY + step;
      final area = hits * step * step;

      // The long side of the board follows the wider (or taller) edge of the
      // silhouette, the same way toGrid() picks its cell size.
      final longDim = (w / h >= _boardAspect) ? w : h;

      // 0.95: edge cells with partial coverage add a few extra cells.
      side = (longDim * math.sqrt(targetCells * 0.95 / area))
          .round()
          .clamp(minSide, maxSide)
          .toInt();
    }

    return LevelDesign._(
      name,
      category,
      side,
      shape,
      minX - step / 2,
      maxX + step / 2,
      minY - step / 2,
      maxY + step / 2,
      false,
    );
  }

  factory LevelDesign.rows(
    String name,
    String category,
    List<String> rows, {
    int? preferredLongSide,
  }) {
    var minX = 1 << 30;
    var maxX = -1;
    var minY = 1 << 30;
    var maxY = -1;

    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        if (rows[y][x] != '#') continue;

        minX = math.min(minX, x);
        maxX = math.max(maxX, x);
        minY = math.min(minY, y);
        maxY = math.max(maxY, y);
      }
    }

    if (maxX < 0) {
      return LevelDesign._(
        name,
        category,
        1,
        (_, _) => false,
        0,
        1,
        0,
        1,
        true,
      );
    }

    final width = maxX - minX + 1;
    final height = maxY - minY + 1;

    return LevelDesign._(
      name,
      category,
      preferredLongSide ?? math.max(width, height),
      (x, y) {
        final ix = x.floor();
        final iy = y.floor();

        return iy >= 0 &&
            iy < rows.length &&
            ix >= 0 &&
            ix < rows[iy].length &&
            rows[iy][ix] == '#';
      },
      minX.toDouble(),
      (maxX + 1).toDouble(),
      minY.toDouble(),
      (maxY + 1).toDouble(),
      true,
    );
  }

  factory LevelDesign.text(String name, List<String> lines, {int scale = 1}) {
    final s = math.max(1, scale);
    final source = lines.map((e) => e.toUpperCase()).toList();

    final width = source.fold<int>(
      0,
      (value, line) => math.max(value, line.length),
    );

    final result = <String>[];

    for (var i = 0; i < source.length; i++) {
      final line = source[i];
      final padding = (width - line.length) ~/ 2;

      for (var row = 0; row < 5; row++) {
        final buffer = StringBuffer(_repeat('.', padding * 4 * s));

        for (var j = 0; j < line.length; j++) {
          if (j > 0) buffer.write(_repeat('.', s));

          final glyph = _font[line[j]] ?? _font['?']!;

          buffer.write(
            glyph[row].split('').map((pixel) => _repeat(pixel, s)).join(),
          );
        }

        for (var repeat = 0; repeat < s; repeat++) {
          result.add(buffer.toString());
        }
      }

      if (i < source.length - 1) {
        for (var gap = 0; gap < s; gap++) {
          result.add('');
        }
      }
    }

    return LevelDesign.rows(name, 'Name', result);
  }

  LevelDesign mirrored() => LevelDesign._(
    name,
    category,
    preferredLongSide,
    (x, y) => _shape(-x, y),
    -_maxX,
    -_minX,
    _minY,
    _maxY,
    _crisp,
  );

  LevelDesign carved(ShapeFn hole) => LevelDesign._(
    name,
    category,
    preferredLongSide,
    (x, y) => _shape(x, y) && !hole(x, y),
    _minX,
    _maxX,
    _minY,
    _maxY,
    _crisp,
  );

  List<String> preview([int? longSide]) {
    final grid = toGrid(1, longSide: longSide);

    return List.generate(
      grid.rows,
      (y) => List.generate(
        grid.cols,
        (x) => grid.contains(x, y) ? '#' : '.',
      ).join(),
    );
  }

  // ===========================================================================
  // GRID GENERATION
  // ===========================================================================

  LevelGrid toGrid(double aspect, {int? longSide}) {
    final a = aspect.isFinite && aspect > 0 ? aspect : 1.0;
    final width = _maxX - _minX;
    final height = _maxY - _minY;

    if (width <= 0 || height <= 0) {
      return const LevelGrid(1, 1, <int>{});
    }

    final base = math.max(2, longSide ?? preferredLongSide);

    late final int cols;
    late final int rows;

    if (width / height >= a) {
      cols = base;
      rows = math.max(1, (cols / a).round());
    } else {
      rows = base;
      cols = math.max(1, (rows * a).round());
    }

    // Equal cell dimensions preserve the original silhouette proportions.
    final cell = math.max(width / cols, height / rows);
    final centerX = (_minX + _maxX) / 2;
    final centerY = (_minY + _maxY) / 2;

    final sampled = List<bool>.filled(cols * rows, false);

    const samplesPerAxis = 5;
    const totalSamples = samplesPerAxis * samplesPerAxis;
    const coverageThreshold = 0.30;
    final requiredHits = (totalSamples * coverageThreshold).ceil();

    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final left = centerX + (x - cols / 2) * cell;
        final top = centerY + (y - rows / 2) * cell;

        var hits = 0;
        final count = _crisp ? 1 : samplesPerAxis;

        for (var sy = 0; sy < count; sy++) {
          for (var sx = 0; sx < count; sx++) {
            final px = left + (sx + 0.5) / count * cell;
            final py = top + (sy + 0.5) / count * cell;

            if (_shape(px, py)) hits++;
          }
        }

        sampled[y * cols + x] = _crisp ? hits > 0 : hits >= requiredHits;
      }
    }

    bool at(int x, int y) =>
        x >= 0 && x < cols && y >= 0 && y < rows && sampled[y * cols + x];

    // Pixel-art and text designs must retain their exact block structure.
    if (_crisp) {
      final allowed = <int>{};

      for (var i = 0; i < sampled.length; i++) {
        if (sampled[i]) allowed.add(i);
      }

      return LevelGrid(cols, rows, allowed);
    }

    // Find connected components and remove isolated sampling noise.
    final visited = List<bool>.filled(cols * rows, false);
    final components = <List<int>>[];

    const directions = <(int, int)>[
      (0, -1),
      (1, 0),
      (0, 1),
      (-1, 0),
      (1, -1),
      (1, 1),
      (-1, 1),
      (-1, -1),
    ];

    for (var start = 0; start < sampled.length; start++) {
      if (!sampled[start] || visited[start]) continue;

      final component = <int>[];
      final queue = <int>[start];

      visited[start] = true;
      var head = 0;

      while (head < queue.length) {
        final current = queue[head++];
        component.add(current);

        final x = current % cols;
        final y = current ~/ cols;

        for (final direction in directions) {
          final nx = x + direction.$1;
          final ny = y + direction.$2;

          if (!at(nx, ny)) continue;

          final next = ny * cols + nx;

          if (visited[next]) continue;

          visited[next] = true;
          queue.add(next);
        }
      }

      components.add(component);
    }

    final allowed = <int>{};

    if (components.isNotEmpty) {
      final largestSize = components.fold<int>(
        0,
        (largest, component) => math.max(largest, component.length),
      );

      final minimumComponentSize = math.max(2, (largestSize * 0.025).ceil());

      for (final component in components) {
        if (component.length >= minimumComponentSize) {
          allowed.addAll(component);
        }
      }

      if (allowed.isEmpty) {
        final largest = components.reduce(
          (a, b) => a.length >= b.length ? a : b,
        );

        allowed.addAll(largest);
      }
    }

    return LevelGrid(cols, rows, allowed);
  }

  // ===========================================================================
  // PIXEL FONT
  // ===========================================================================

  static const Map<String, List<String>> _font = {
    'A': ['.#.', '#.#', '###', '#.#', '#.#'],
    'B': ['##.', '#.#', '##.', '#.#', '##.'],
    'C': ['.##', '#..', '#..', '#..', '.##'],
    'D': ['##.', '#.#', '#.#', '#.#', '##.'],
    'E': ['###', '#..', '##.', '#..', '###'],
    'F': ['###', '#..', '##.', '#..', '#..'],
    'G': ['.##', '#..', '#.#', '#.#', '.##'],
    'H': ['#.#', '#.#', '###', '#.#', '#.#'],
    'I': ['###', '.#.', '.#.', '.#.', '###'],
    'J': ['..#', '..#', '..#', '#.#', '.#.'],
    'K': ['#.#', '#.#', '##.', '#.#', '#.#'],
    'L': ['#..', '#..', '#..', '#..', '###'],
    'M': ['#.#', '###', '###', '#.#', '#.#'],
    'N': ['#.#', '###', '###', '###', '#.#'],
    'O': ['.#.', '#.#', '#.#', '#.#', '.#.'],
    'P': ['##.', '#.#', '##.', '#..', '#..'],
    'Q': ['.#.', '#.#', '#.#', '.##', '..#'],
    'R': ['##.', '#.#', '##.', '#.#', '#.#'],
    'S': ['.##', '#..', '.#.', '..#', '##.'],
    'T': ['###', '.#.', '.#.', '.#.', '.#.'],
    'U': ['#.#', '#.#', '#.#', '#.#', '###'],
    'V': ['#.#', '#.#', '#.#', '#.#', '.#.'],
    'W': ['#.#', '#.#', '###', '###', '#.#'],
    'X': ['#.#', '#.#', '.#.', '#.#', '#.#'],
    'Y': ['#.#', '#.#', '.#.', '.#.', '.#.'],
    'Z': ['###', '..#', '.#.', '#..', '###'],
    '0': ['###', '#.#', '#.#', '#.#', '###'],
    '1': ['.#.', '##.', '.#.', '.#.', '###'],
    '2': ['##.', '..#', '.#.', '#..', '###'],
    '3': ['##.', '..#', '.##', '..#', '##.'],
    '4': ['#.#', '#.#', '###', '..#', '..#'],
    '5': ['###', '#..', '##.', '..#', '##.'],
    '6': ['.##', '#..', '###', '#.#', '.#.'],
    '7': ['###', '..#', '.#.', '.#.', '.#.'],
    '8': ['.#.', '#.#', '.#.', '#.#', '.#.'],
    '9': ['.#.', '#.#', '.##', '..#', '##.'],
    '?': ['##.', '..#', '.#.', '...', '.#.'],
  };
}

// =============================================================================
// LEVEL DESIGNS — 80 LEVELS, SMOOTH DIFFICULTY CURVE
//
//   Level 1        Tutorial        exactly 3 separate vertical arrows (heads up)
//                                  (NOT a 3x3 board)
//   Levels  2- 6   Easy            solid convex shapes, small board
//   Levels  7-10   Easy+           rounder shapes, still solid
//   Levels 11-15   Normal          first concave shapes
//   Levels 16-20   Medium          icons with small details
//   Levels 21-25   Medium-Hard     bigger icons, first interior holes
//   Levels 26-30   Hard            animals with limbs / heads
//   Levels 31-35   Hard            larger animals and objects
//   Levels 36-40   Very Hard       complex silhouettes
//   Levels 41-80   Expert          thin parts first, then denser, fuller
//                                  silhouettes as the arrow count peaks
//
// Difficulty only goes up. Three things are tied together on every level:
//   1. the arrow count (smooth curve, no sudden jumps),
//   2. the arrow size (longest allowed arrow grows with the level),
//   3. the design size: the board is sized from the real silhouette (its
//      area, width and height, holes included), so every design ends up with
//      the number of playable cells that its arrow count and arrow size need.
//      Thin or wide designs get a bigger board, solid designs a smaller one.
//
// Expert designs are ordered from thin to solid. Thin silhouettes sit where
// the arrow count is still moderate, and the fullest silhouettes sit at the
// end, where the arrow count peaks and the board needs the most cells.
// =============================================================================

class LevelDesigns {
  static const int totalLevels = 80;

  // Global difficulty multiplier for the arrow count (1.25 = 25% harder).
  static const double difficultyBoost = 1.25;

  static const int minArrows = 3;
  static const int maxArrows = 363; // 290 * 1.25, rounded
  static const int tutorialArrows = 3;

  // Interior holes begin once the player is in the Medium-Hard tier.
  static const int _holesFromLevel = 21;

  // Board limits (long side, in cells).
  static const int _minSide = 6;
  static const int _maxSide = 66;

  // Average arrow length as a share of the longest allowed arrow. Follows the
  // controller's 10% short / 55% medium / 35% long mix.
  static const double _avgLengthShare = 0.62;

  // Small extra room so the generator can fit every arrow, and a little more
  // for Expert levels, whose thin parts waste some cells.
  static const double _slack = 1.05;
  static const double _expertSlack = 1.08;

  static bool isTutorial(int level) => level == 1;

  /// Difficulty tier. The names match the ones used by the game controller.
  static String difficultyForLevel(int level) {
    final l = level.clamp(1, totalLevels).toInt();

    if (l == 1) return 'Tutorial';
    if (l <= 6) return 'Easy';
    if (l <= 10) return 'Easy+';
    if (l <= 15) return 'Normal';
    if (l <= 20) return 'Medium';
    if (l <= 25) return 'Medium-Hard';
    if (l <= 35) return 'Hard';
    if (l <= 40) return 'Very Hard';

    return 'Expert';
  }

  // (level, arrow count) key points. Values between them are interpolated,
  // so the arrow count rises evenly with no jumps.
  static const List<(int, int)> _arrowKeys = [
    (1, 3),
    (2, 8),
    (6, 14),
    (10, 22),
    (15, 32),
    (20, 45),
    (25, 60),
    (30, 80),
    (35, 102),
    (40, 125),
    (50, 165),
    (60, 207),
    (70, 248),
    (80, 290),
  ];

  static int arrowCountForLevel(int level) {
    final l = level.clamp(1, totalLevels).toInt();

    if (l == 1) return tutorialArrows;

    for (var i = 1; i < _arrowKeys.length; i++) {
      final b = _arrowKeys[i];

      if (l <= b.$1) {
        final a = _arrowKeys[i - 1];
        final t = (l - a.$1) / (b.$1 - a.$1);
        final value = (a.$2 + (b.$2 - a.$2) * t) * difficultyBoost;

        return value.round().clamp(minArrows, maxArrows).toInt();
      }
    }

    return maxArrows;
  }

  static int safeArrowCount(
    int level,
    LevelGrid grid, {
    int cellsPerArrow = 3,
  }) {
    if (isTutorial(level)) return tutorialArrows;

    final byLevel = arrowCountForLevel(level);
    final byGrid = grid.cellCount ~/ math.max(1, cellsPerArrow);

    return math
        .min(byLevel, math.max(minArrows, byGrid))
        .clamp(1, maxArrows)
        .toInt();
  }

  /// Longest allowed arrow, in cells. Same formula as the controller's
  /// maximum arrow length (5 + level ~/ 4, from 5 to 12).
  static int maxArrowLength(int level) {
    final l = level.clamp(1, totalLevels).toInt();
    return (5 + l ~/ 4).clamp(5, 12).toInt();
  }

  /// Playable cells a level needs: arrow count * average arrow length, plus
  /// a little slack. Together with the real silhouette this decides how big
  /// the board is.
  static int targetCellsForLevel(int level) {
    final l = level.clamp(1, totalLevels).toInt();

    final arrows = arrowCountForLevel(l);
    final avgLength = maxArrowLength(l) * _avgLengthShare;

    final slack = l >= 41 ? _expertSlack : _slack;

    return math.max(arrows * 2, (arrows * avgLength * slack).round());
  }

  /// Rough board size that does not know the silhouette. Kept as a fallback;
  /// [forLevel] sizes the board from the real design instead.
  static int longSideForLevel(int level, String name) {
    final l = level.clamp(1, totalLevels).toInt();

    // Tutorial: 5 columns wide (3 arrows + 2 gap columns).
    if (l == 1) return 5;

    final cellsNeeded = targetCellsForLevel(l);

    // About 0.75 * side^2 playable cells on an average silhouette.
    final side = math.sqrt(cellsNeeded / 0.75).round();

    return side.clamp(_minSide, _maxSide).toInt();
  }

  // Thin or delicate silhouettes keep their natural shape (no holes).
  static const Set<String> _noHoles = {
    'Ring',
    'Plus',
    'Chevron',
    'Bolt',
    'Key',
    'Umbrella',
    'Cactus',
    'Sailboat',
    'Windmill',
    'Bicycle',
    'Eagle',
    'Dragonfly',
    'Peacock',
    'Octopus',
    'Snowflake',
    'Mandala',
    'Cog',
    'Planet',
    'Spiral',
    'Infinity',
    'Bridge',
    'Telescope',
    'Maze',
    'Rose',
    'Tulip',
    'Crab',
    'Spider',
    'Palm Tree',
    'Skull',
    'Compass',
    'Pagoda',
    'Eiffel Tower',
    'Satellite',
    'Starburst',
    'Galaxy',
    'Temple',
    'Hourglass',
    'Trophy',
    'Paw Print',
  };

  // 79 designs: level 2 = index 0 ... level 80 = index 78.
  // Levels 2-40 go from the simplest silhouette to complex ones. Levels 41-80
  // go from the thinnest silhouettes to the fullest ones, so the board can
  // hold the growing arrow count.
  static const List<(String, String)> _recipes = [
    // ---- Levels 2-6 (Easy): solid convex shapes ----
    ('Rounded Square', 'Shape'), // 2
    ('Circle', 'Shape'), // 3
    ('Triangle', 'Shape'), // 4
    ('Diamond', 'Shape'), // 5
    ('Hexagon', 'Shape'), // 6
    // ---- Levels 7-10 (Easy+): rounder solid shapes ----
    ('Pentagon', 'Shape'), // 7
    ('Octagon', 'Shape'), // 8
    ('Heart', 'Shape'), // 9
    ('Droplet', 'Nature'), // 10
    // ---- Levels 11-15 (Normal): first concave shapes ----
    ('Star', 'Shape'), // 11
    ('Crescent', 'Nature'), // 12
    ('Arrow Up', 'Shape'), // 13
    ('House', 'Object'), // 14
    ('Pine Tree', 'Nature'), // 15
    // ---- Levels 16-20 (Medium): icons with small details ----
    ('Mushroom', 'Nature'), // 16
    ('Fish', 'Animal'), // 17
    ('Bell', 'Object'), // 18
    ('Coffee Cup', 'Object'), // 19
    ('Crown', 'Object'), // 20
    // ---- Levels 21-25 (Medium-Hard) ----
    ('Shield', 'Object'), // 21
    ('Cat Face', 'Animal'), // 22
    ('Rocket', 'Object'), // 23
    ('Apple', 'Nature'), // 24
    ('Plus', 'Shape'), // 25
    // ---- Levels 26-30 (Hard): animals with heads and limbs ----
    ('Duck', 'Animal'), // 26
    ('Penguin', 'Animal'), // 27
    ('Rabbit', 'Animal'), // 28
    ('Owl', 'Animal'), // 29
    ('Turtle', 'Animal'), // 30
    // ---- Levels 31-35 (Hard): larger animals and objects ----
    ('Whale', 'Animal'), // 31
    ('Elephant', 'Animal'), // 32
    ('Butterfly', 'Animal'), // 33
    ('Flower', 'Nature'), // 34
    ('Sailboat', 'Object'), // 35
    // ---- Levels 36-40 (Very Hard): complex silhouettes ----
    ('Lighthouse', 'Object'), // 36
    ('Castle', 'Object'), // 37
    ('Hourglass', 'Object'), // 38
    ('Trophy', 'Object'), // 39
    ('Umbrella', 'Object'), // 40
    // ---- Levels 41-50 (Expert): the thinnest silhouettes ----
    ('Snowflake', 'Nature'), // 41
    ('Spider', 'Animal'), // 42
    ('Palm Tree', 'Nature'), // 43
    ('Bridge', 'Object'), // 44
    ('Telescope', 'Object'), // 45
    ('Bicycle', 'Object'), // 46
    ('Windmill', 'Object'), // 47
    ('Dragonfly', 'Animal'), // 48
    ('Key', 'Object'), // 49
    ('Eiffel Tower', 'Object'), // 50
    // ---- Levels 51-60 (Expert): thin parts with more body ----
    ('Compass', 'Object'), // 51
    ('Crab', 'Animal'), // 52
    ('Maze', 'Pattern'), // 53
    ('Bolt', 'Shape'), // 54
    ('Tulip', 'Nature'), // 55
    ('Rose', 'Nature'), // 56
    ('Eagle', 'Animal'), // 57
    ('Satellite', 'Object'), // 58
    ('Spiral', 'Pattern'), // 59
    ('Galaxy', 'Nature'), // 60
    // ---- Levels 61-70 (Expert): fuller silhouettes ----
    ('Cactus', 'Nature'), // 61
    ('Sun', 'Nature'), // 62
    ('Planet', 'Nature'), // 63
    ('Dinosaur', 'Animal'), // 64
    ('Infinity', 'Pattern'), // 65
    ('Chevron', 'Shape'), // 66
    ('Crystal', 'Shape'), // 67
    ('Balloon', 'Object'), // 68
    ('Peacock', 'Animal'), // 69
    ('Octopus', 'Animal'), // 70
    // ---- Levels 71-80 (Expert): the fullest silhouettes, peak arrows ----
    ('Mandala', 'Pattern'), // 71
    ('Ring', 'Shape'), // 72
    ('Paw Print', 'Animal'), // 73
    ('Fox', 'Animal'), // 74
    ('Starburst', 'Pattern'), // 75
    ('Pagoda', 'Object'), // 76
    ('Cog', 'Object'), // 77
    ('Skull', 'Object'), // 78
    ('Temple', 'Object'), // 79
    ('Train', 'Object'), // 80
  ];

  static int _recipeIndex(int level) =>
      (level - 2).clamp(0, _recipes.length - 1).toInt();

  /// Carves a repeating pattern of holes into the silhouette. Holes start at
  /// [_holesFromLevel] and grow denser and larger step by step.
  static ShapeFn _hardened(String name, int level, ShapeFn base) {
    if (level < _holesFromLevel || _noHoles.contains(name)) return base;

    final p = ((level - _holesFromLevel) / (totalLevels - _holesFromLevel))
        .clamp(0.0, 1.0)
        .toDouble();

    final spacing = 0.62 - 0.34 * p;
    final size = spacing * (0.10 + 0.10 * p);

    final offsetX = (level * 0.37) % spacing;
    final offsetY = (level * 0.53) % spacing;
    final half = spacing / 2;

    final pattern = level % 5;

    return (double x, double y) {
      if (!base(x, y)) return false;

      final rowIndex = ((y - offsetY) / spacing).floor();
      final stagger = (pattern == 1 || pattern == 4) && rowIndex.isOdd
          ? half
          : 0.0;

      final dx = ((x - offsetX - stagger) % spacing) - half;
      final dy = ((y - offsetY) % spacing) - half;

      switch (pattern) {
        case 0:
        case 1:
          return dx * dx + dy * dy > size * size;

        case 2:
          return !(dx.abs() <= size && dy.abs() <= size);

        case 3:
          {
            final arm = size * 0.45;
            final plus =
                (dx.abs() <= size && dy.abs() <= arm) ||
                (dy.abs() <= size && dx.abs() <= arm);

            return !plus;
          }

        default:
          return dx.abs() + dy.abs() > size * 1.25;
      }
    };
  }

  static LevelDesign forLevel(int level) {
    final l = level.clamp(1, totalLevels).toInt();

    // Tutorial: THREE separate vertical arrows, side by side. Each column is
    // 2 cells tall and the columns are separated by an empty column, so the
    // cells can never merge into one long arrow -> exactly 3 arrows, each one
    // lying vertically (head on the top cell). Crisp pixel design: it is never
    // resampled into a bigger board.
    if (l == 1) {
      return LevelDesign.rows('Tutorial Block', 'Tutorial', const [
        '#.#.#',
        '#.#.#',
      ], preferredLongSide: 5);
    }

    final recipe = _recipes[_recipeIndex(l)];
    final name = recipe.$1;
    final category = recipe.$2;

    // The board is sized from the real silhouette (holes included) so it
    // holds the cells that this level's arrow count and arrow size need.
    return LevelDesign.shape(
      name,
      category,
      _hardened(name, l, _shapeFor(name, l)),
      preferredLongSide: longSideForLevel(l, name),
      targetCells: targetCellsForLevel(l),
      minSide: _minSide,
      maxSide: _maxSide,
    );
  }

  // ===========================================================================
  // SHAPE LIBRARY — 79 silhouettes
  //
  // Every shape lives in a -1..1 box (y grows downward). Helper values:
  //   ax = |x| (mirror left/right), ay = |y|, r = distance from the centre.
  // ===========================================================================

  static ShapeFn _shapeFor(String name, int level) {
    return (double x, double y) {
      final ax = x.abs();
      final ay = y.abs();
      final r = _distance(x, y);
      final angle = _angle(x, y);

      switch (name) {
        // ------------------------- Easy: solid shapes --------------------
        case 'Rounded Square':
          return _rrect(x, y, -0.88, -0.88, 0.88, 0.88, 0.3);

        case 'Circle':
          return r <= 0.92;

        case 'Triangle':
          return _poly(x, y, [(0, -0.95), (0.95, 0.7), (-0.95, 0.7)]);

        case 'Diamond':
          return ax / 0.72 + ay / 0.95 <= 1;

        case 'Hexagon':
          return _regular(x, y, 6, 0.98, rot: 0);

        case 'Pentagon':
          return _regular(x, y, 5, 0.98);

        case 'Octagon':
          return _regular(x, y, 8, 0.98, rot: math.pi / 8);

        case 'Heart':
          return _heart(x, y);

        case 'Droplet':
          return _ell(x, y, 0, 0.3, 0.6, 0.6) ||
              _poly(x, y, [(0, -0.95), (0.526, 0.012), (-0.526, 0.012)]);

        // ------------------------- Normal: first concave shapes ----------
        case 'Star':
          return _starPoly(x, y, 5, 0.98, 0.42);

        case 'Crescent':
          return _ell(x, y, -0.1, 0, 0.9, 0.9) &&
              !_ell(x, y, 0.3, -0.1, 0.75, 0.78);

        case 'Arrow Up':
          return _poly(x, y, [
            (0, -0.95),
            (0.75, -0.05),
            (0.3, -0.05),
            (0.3, 0.92),
            (-0.3, 0.92),
            (-0.3, -0.05),
            (-0.75, -0.05),
          ]);

        case 'House':
          return (_poly(x, y, [(-0.98, -0.05), (0, -0.92), (0.98, -0.05)]) ||
                  _rect(x, y, -0.72, -0.05, 0.72, 0.9) ||
                  _rect(x, y, 0.38, -0.8, 0.6, -0.3)) &&
              !_rrect(x, y, -0.17, 0.35, 0.17, 0.95, 0.08);

        case 'Pine Tree':
          return _poly(x, y, [(0, -0.95), (0.5, -0.3), (-0.5, -0.3)]) ||
              _poly(x, y, [(0, -0.6), (0.7, 0.15), (-0.7, 0.15)]) ||
              _poly(x, y, [(0, -0.25), (0.92, 0.65), (-0.92, 0.65)]) ||
              _rect(x, y, -0.15, 0.6, 0.15, 0.95);

        // ------------------------- Medium: icons with details ------------
        case 'Mushroom':
          return ((_ell(x, y, 0, 0.05, 0.95, 0.78) && y < 0.05) ||
                  _rrect(x, y, -0.3, 0.0, 0.3, 0.92, 0.1)) &&
              !_ell(x, y, -0.4, -0.25, 0.14, 0.14) &&
              !_ell(x, y, 0.35, -0.3, 0.12, 0.12) &&
              !_ell(x, y, 0.02, -0.45, 0.08, 0.08);

        case 'Fish':
          return (_ell(x, y, -0.15, 0, 0.72, 0.48) ||
                  _poly(x, y, [(0.4, 0), (0.98, -0.45), (0.98, 0.45)]) ||
                  _poly(x, y, [(-0.35, -0.42), (0, -0.8), (0.2, -0.4)])) &&
              !_ell(x, y, -0.5, -0.08, 0.07, 0.07);

        case 'Bell':
          return (_ell(x, y, 0, -0.2, 0.5, 0.55) && y < 0.1) ||
              _poly(x, y, [
                (-0.5, -0.2),
                (0.5, -0.2),
                (0.78, 0.45),
                (-0.78, 0.45),
              ]) ||
              _rrect(x, y, -0.88, 0.4, 0.88, 0.56, 0.07) ||
              _ell(x, y, 0, 0.72, 0.16, 0.16) ||
              _ell(x, y, 0, -0.82, 0.1, 0.1);

        case 'Coffee Cup':
          return _poly(x, y, [
                (-0.7, -0.45),
                (0.5, -0.45),
                (0.38, 0.65),
                (-0.58, 0.65),
              ]) ||
              (_ring(x - 0.62, y, 0.36, 0.2) && x > 0.45) ||
              _rrect(x, y, -0.95, 0.65, 0.75, 0.88, 0.1);

        case 'Crown':
          return (_poly(x, y, [
                    (-0.9, 0.7),
                    (-0.9, -0.4),
                    (-0.45, 0.05),
                    (0, -0.65),
                    (0.45, 0.05),
                    (0.9, -0.4),
                    (0.9, 0.7),
                  ]) ||
                  _ell(x, y, -0.9, -0.5, 0.11, 0.11) ||
                  _ell(x, y, 0, -0.75, 0.11, 0.11) ||
                  _ell(x, y, 0.9, -0.5, 0.11, 0.11)) &&
              !_ell(x, y, 0, 0.35, 0.1, 0.1) &&
              !_ell(ax, y, 0.5, 0.35, 0.08, 0.08);

        // ------------------------- Medium-Hard ---------------------------
        case 'Shield':
          return _poly(x, y, [
                (-0.8, -0.85),
                (0.8, -0.85),
                (0.8, 0.05),
                (0.55, 0.5),
                (0, 0.95),
                (-0.55, 0.5),
                (-0.8, 0.05),
              ]) &&
              !_starPoly(x, y + 0.1, 5, 0.4, 0.17);

        case 'Cat Face':
          return (_ell(x, y, 0, 0.2, 0.78, 0.65) ||
                  _poly(ax, y, [(0.8, 0.0), (0.78, -0.88), (0.2, -0.42)])) &&
              !_ell(ax, y, 0.3, 0.1, 0.09, 0.12) &&
              !_poly(x, y, [(-0.08, 0.3), (0.08, 0.3), (0, 0.4)]);

        case 'Rocket':
          return (_ell(x, y, 0, -0.08, 0.34, 0.8) ||
                  _poly(ax, y, [(0.28, 0.25), (0.72, 0.85), (0.28, 0.6)]) ||
                  _poly(x, y, [(-0.17, 0.6), (0, 0.98), (0.17, 0.6)])) &&
              !_ell(x, y, 0, -0.25, 0.14, 0.14);

        case 'Apple':
          return _ell(ax, y, 0.3, 0.12, 0.58, 0.66) ||
              _rect(x, y, -0.07, -0.95, 0.07, -0.4) ||
              _poly(x, y, [
                (0.07, -0.78),
                (0.5, -0.98),
                (0.56, -0.7),
                (0.1, -0.55),
              ]);

        case 'Plus':
          return _rrect(x, y, -0.3, -0.92, 0.3, 0.92, 0.08) ||
              _rrect(x, y, -0.92, -0.3, 0.92, 0.3, 0.08);

        // ------------------------- Hard: animals -------------------------
        case 'Duck':
          return (_ell(x, y, -0.1, 0.3, 0.72, 0.5) ||
                  _ell(x, y, 0.38, -0.42, 0.3, 0.3) ||
                  _seg(x, y, 0.38, -0.25, 0.25, 0.15, 0.2) ||
                  _poly(x, y, [(0.64, -0.5), (1.0, -0.38), (0.64, -0.28)]) ||
                  _poly(x, y, [(-0.7, 0.15), (-1.0, -0.15), (-0.55, 0.4)])) &&
              !_ell(x, y, 0.45, -0.5, 0.05, 0.05);

        case 'Penguin':
          return (_ell(x, y, 0, 0.05, 0.62, 0.9) ||
                  _ell(ax, y, 0.3, 0.93, 0.24, 0.07) ||
                  _poly(ax, y, [(0.5, -0.1), (0.95, 0.35), (0.55, 0.42)])) &&
              !_ell(ax, y, 0.2, -0.5, 0.06, 0.06);

        case 'Rabbit':
          return (_ell(ax, y, 0.22, -0.62, 0.13, 0.36) ||
                  _ell(x, y, 0, 0.0, 0.42, 0.38) ||
                  _ell(x, y, 0, 0.6, 0.62, 0.38) ||
                  _ell(x, y, 0.6, 0.78, 0.14, 0.14)) &&
              !_ell(ax, y, 0.16, -0.05, 0.05, 0.07);

        case 'Owl':
          return (_ell(x, y, 0, 0.1, 0.68, 0.85) ||
                  _poly(ax, y, [(0.2, -0.7), (0.58, -0.98), (0.64, -0.45)])) &&
              !(_ell(ax, y, 0.28, -0.2, 0.22, 0.22) &&
                  !_ell(ax, y, 0.28, -0.2, 0.09, 0.09)) &&
              !_poly(x, y, [(-0.08, -0.02), (0.08, -0.02), (0, 0.14)]);

        case 'Turtle':
          return (_ell(x, y, 0, 0.2, 0.8, 0.65) && y < 0.3) ||
              _ell(x, y, 0.88, 0.1, 0.2, 0.18) ||
              _rrect(x, y, -0.6, 0.25, -0.32, 0.7, 0.06) ||
              _rrect(x, y, 0.3, 0.25, 0.58, 0.7, 0.06) ||
              _rect(x, y, -0.8, 0.2, 0.8, 0.34) ||
              _poly(x, y, [(-0.8, 0.25), (-1.0, 0.4), (-0.78, 0.38)]);

        // ------------------------- Hard: larger animals / objects --------
        case 'Whale':
          return (_ell(x, y, -0.1, 0.15, 0.82, 0.52) ||
                  _poly(x, y, [
                    (0.55, 0.1),
                    (0.8, -0.05),
                    (0.98, -0.5),
                    (1.0, -0.05),
                    (0.85, 0.2),
                    (0.6, 0.3),
                  ]) ||
                  _seg(x, y, -0.45, -0.3, -0.45, -0.62, 0.05) ||
                  _ell(x, y, -0.45, -0.7, 0.16, 0.07)) &&
              !_ell(x, y, -0.62, 0.05, 0.05, 0.05);

        case 'Elephant':
          return (_ell(x, y, -0.1, 0.05, 0.62, 0.45) ||
                  _ell(x, y, 0.52, -0.05, 0.32, 0.36) ||
                  _seg(x, y, 0.65, 0.12, 0.8, 0.7, 0.1) ||
                  _seg(x, y, 0.8, 0.7, 0.95, 0.8, 0.09) ||
                  _rrect(x, y, -0.62, 0.3, -0.42, 0.92, 0.05) ||
                  _rrect(x, y, -0.34, 0.3, -0.14, 0.92, 0.05) ||
                  _rrect(x, y, 0.0, 0.3, 0.2, 0.92, 0.05) ||
                  _rrect(x, y, 0.28, 0.3, 0.48, 0.92, 0.05) ||
                  _seg(x, y, -0.7, 0.0, -0.92, 0.4, 0.05)) &&
              !_ell(x, y, 0.6, -0.12, 0.04, 0.04);

        case 'Butterfly':
          return (_ell(ax, y, 0.5, -0.4, 0.48, 0.4) ||
                  _ell(ax, y, 0.38, 0.42, 0.34, 0.4) ||
                  _rrect(x, y, -0.07, -0.5, 0.07, 0.85, 0.07) ||
                  _ell(x, y, 0, -0.55, 0.1, 0.1) ||
                  _seg(ax, y, 0.05, -0.55, 0.3, -0.92, 0.04)) &&
              !_ell(ax, y, 0.55, -0.4, 0.12, 0.12);

        case 'Flower':
          return _petals(x, y + 0.3, 6, 0.38, 0.28) ||
              _ell(x, y, 0, -0.3, 0.2, 0.2) ||
              _rrect(x, y, -0.07, -0.1, 0.07, 0.95, 0.03) ||
              _ell(x, y, 0.3, 0.55, 0.28, 0.1) ||
              _ell(x, y, -0.3, 0.35, 0.28, 0.1);

        case 'Sailboat':
          return _poly(x, y, [
                (-0.92, 0.4),
                (0.92, 0.4),
                (0.6, 0.88),
                (-0.6, 0.88),
              ]) ||
              _rect(x, y, -0.05, -0.92, 0.05, 0.4) ||
              _poly(x, y, [(0.1, -0.88), (0.1, 0.3), (0.88, 0.3)]) ||
              _poly(x, y, [(-0.1, -0.55), (-0.1, 0.3), (-0.72, 0.3)]);

        // ------------------------- Very Hard: complex silhouettes --------
        case 'Lighthouse':
          return (_poly(x, y, [
                    (-0.38, -0.35),
                    (0.38, -0.35),
                    (0.58, 0.85),
                    (-0.58, 0.85),
                  ]) ||
                  _rrect(x, y, -0.5, -0.58, 0.5, -0.32, 0.05) ||
                  _poly(x, y, [(-0.58, -0.58), (0, -0.98), (0.58, -0.58)]) ||
                  _rect(x, y, -0.82, 0.85, 0.82, 0.98) ||
                  _poly(ax, y, [(0.5, -0.5), (0.98, -0.72), (0.98, -0.38)])) &&
              !_rect(x, y, -0.14, -0.5, 0.14, -0.4) &&
              !_rect(x, y, -0.12, 0.05, 0.12, 0.25);

        case 'Castle':
          return (_rect(x, y, -0.8, -0.15, 0.8, 0.9) ||
                  _rect(x, y, -0.95, -0.8, -0.5, 0.9) ||
                  _rect(x, y, 0.5, -0.8, 0.95, 0.9) ||
                  _poly(ax, y, [(0.45, -0.8), (0.725, -1.0), (1.0, -0.8)]) ||
                  _rect(x, y, -0.1, -0.3, 0.1, -0.15) ||
                  _rect(ax, y, 0.2, -0.3, 0.4, -0.15)) &&
              !(_rect(x, y, -0.15, 0.35, 0.15, 0.95) ||
                  _ell(x, y, 0, 0.35, 0.15, 0.15)) &&
              !_rect(ax, y, 0.66, -0.5, 0.78, -0.3);

        case 'Hourglass':
          return _poly(x, y, [
                (-0.75, -0.88),
                (0.75, -0.88),
                (0.12, 0),
                (0.75, 0.88),
                (-0.75, 0.88),
                (-0.12, 0),
              ]) ||
              _rrect(x, y, -0.9, -0.98, 0.9, -0.84, 0.05) ||
              _rrect(x, y, -0.9, 0.84, 0.9, 0.98, 0.05);

        case 'Trophy':
          return _poly(x, y, [
                (-0.62, -0.85),
                (0.62, -0.85),
                (0.45, 0.05),
                (0.2, 0.2),
                (-0.2, 0.2),
                (-0.45, 0.05),
              ]) ||
              (_ring(ax - 0.7, y + 0.45, 0.3, 0.17) && ax > 0.55) ||
              _rect(x, y, -0.1, 0.2, 0.1, 0.65) ||
              _rrect(x, y, -0.5, 0.65, 0.5, 0.9, 0.05);

        case 'Umbrella':
          return (_ell(x, y, 0, -0.1, 0.98, 0.75) && y < 0.1) ||
              _ell(x, y, 0, 0.1, 0.33, 0.12) ||
              _ell(ax, y, 0.66, 0.1, 0.32, 0.12) ||
              _rect(x, y, -0.05, 0.1, 0.05, 0.7) ||
              (_ring(x + 0.16, y - 0.7, 0.16, 0.07) && y > 0.7);

        // ------------------------- Expert: thin silhouettes --------------
        case 'Snowflake':
          return _snow(x, y);

        case 'Spider':
          return _ell(x, y, 0, 0.25, 0.32, 0.42) ||
              _ell(x, y, 0, -0.22, 0.22, 0.2) ||
              _seg(ax, y, 0.15, -0.28, 0.58, -0.8, 0.05) ||
              _seg(ax, y, 0.58, -0.8, 0.92, -0.45, 0.05) ||
              _seg(ax, y, 0.2, -0.12, 0.75, -0.35, 0.05) ||
              _seg(ax, y, 0.75, -0.35, 0.98, 0.0, 0.05) ||
              _seg(ax, y, 0.2, 0.05, 0.75, 0.2, 0.05) ||
              _seg(ax, y, 0.75, 0.2, 0.95, 0.65, 0.05) ||
              _seg(ax, y, 0.15, 0.3, 0.55, 0.65, 0.05) ||
              _seg(ax, y, 0.55, 0.65, 0.7, 0.98, 0.05);

        case 'Palm Tree':
          return _seg(x, y, -0.15, 0.95, -0.05, 0.4, 0.09) ||
              _seg(x, y, -0.05, 0.4, 0.05, -0.2, 0.08) ||
              _seg(x, y, 0.05, -0.25, -0.9, -0.05, 0.07) ||
              _seg(x, y, 0.05, -0.25, -0.65, -0.68, 0.07) ||
              _seg(x, y, 0.05, -0.25, 0.05, -0.92, 0.07) ||
              _seg(x, y, 0.05, -0.25, 0.75, -0.68, 0.07) ||
              _seg(x, y, 0.05, -0.25, 0.95, -0.05, 0.07) ||
              _ell(x, y, -0.05, -0.15, 0.1, 0.1) ||
              _ell(x, y, 0.15, -0.12, 0.1, 0.1);

        case 'Bridge':
          return _rect(x, y, -0.98, 0.35, 0.98, 0.5) ||
              _rect(x, y, -0.62, -0.6, -0.5, 0.5) ||
              _rect(x, y, 0.5, -0.6, 0.62, 0.5) ||
              _seg(ax, y, 0.98, 0.35, 0.56, -0.55, 0.04) ||
              (ax <= 0.56 &&
                  _ab(y - (0.05 - 0.6 * ax * ax / 0.3136)) <= 0.045) ||
              _rect(x, y, -0.04, 0.04, 0.04, 0.35) ||
              _rect(ax, y, 0.11, 0.0, 0.19, 0.35) ||
              _rect(ax, y, 0.26, -0.13, 0.34, 0.35) ||
              _rect(ax, y, 0.42, -0.35, 0.5, 0.35);

        case 'Telescope':
          return _seg(x, y, -0.75, 0.15, 0.45, -0.5, 0.16) ||
              _seg(x, y, 0.45, -0.5, 0.8, -0.68, 0.09) ||
              _seg(x, y, -0.1, -0.1, -0.45, 0.95, 0.06) ||
              _seg(x, y, -0.1, -0.1, 0.0, 0.95, 0.06) ||
              _seg(x, y, -0.1, -0.1, 0.35, 0.95, 0.06);

        case 'Bicycle':
          return _ring(x - 0.55, y - 0.3, 0.38, 0.27) ||
              _ring(x + 0.55, y - 0.3, 0.38, 0.27) ||
              _seg(x, y, -0.55, 0.3, -0.12, 0.3, 0.055) ||
              _seg(x, y, -0.55, 0.3, -0.3, -0.25, 0.055) ||
              _seg(x, y, -0.12, 0.3, -0.3, -0.25, 0.055) ||
              _seg(x, y, -0.3, -0.25, 0.35, -0.2, 0.055) ||
              _seg(x, y, -0.12, 0.3, 0.35, -0.2, 0.055) ||
              _seg(x, y, 0.35, -0.2, 0.55, 0.3, 0.055) ||
              _seg(x, y, 0.35, -0.2, 0.3, -0.45, 0.055) ||
              _seg(x, y, 0.3, -0.45, 0.48, -0.5, 0.055) ||
              _seg(x, y, -0.45, -0.3, -0.15, -0.3, 0.06);

        case 'Windmill':
          return (_poly(x, y, [
                    (-0.3, 0.95),
                    (0.3, 0.95),
                    (0.17, -0.2),
                    (-0.17, -0.2),
                  ]) ||
                  _ell(x, y, 0, -0.3, 0.14, 0.14) ||
                  _rays(x, y + 0.3, 4, 0.0, 0.82, 0.1, rot: math.pi / 4)) &&
              !_rrect(x, y, -0.08, 0.6, 0.08, 0.95, 0.04);

        case 'Dragonfly':
          return _ell(x, y, 0, 0.0, 0.11, 0.92) ||
              _ell(x, y, 0, -0.88, 0.15, 0.13) ||
              _ell(ax, y, 0.52, -0.45, 0.46, 0.13) ||
              _ell(ax, y, 0.46, -0.12, 0.4, 0.12);

        case 'Key':
          return _ring(x + 0.55, y, 0.4, 0.2) ||
              _rect(x, y, -0.18, -0.09, 0.95, 0.09) ||
              _rect(x, y, 0.62, 0.09, 0.76, 0.38) ||
              _rect(x, y, 0.8, 0.09, 0.94, 0.3);

        case 'Eiffel Tower':
          return (_poly(ax, y, [
                    (0, -0.98),
                    (0.07, -0.6),
                    (0.18, -0.15),
                    (0.4, 0.45),
                    (0.8, 0.95),
                    (0.5, 0.95),
                    (0.32, 0.65),
                    (0, 0.65),
                  ]) ||
                  _rect(x, y, -0.3, -0.15, 0.3, -0.05) ||
                  _rect(x, y, -0.5, 0.4, 0.5, 0.52)) &&
              !_ell(x, y, 0, 0.95, 0.28, 0.3);

        // ------------------------- Expert: thin parts with more body -----
        case 'Compass':
          return _ring(x, y, 0.95, 0.8) ||
              _poly(x, y, [(0, -0.88), (0.16, 0), (0, 0.88), (-0.16, 0)]) ||
              _poly(x, y, [(-0.88, 0), (0, 0.16), (0.88, 0), (0, -0.16)]);

        case 'Crab':
          return (_ell(x, y, 0, 0.15, 0.58, 0.4) ||
                  _seg(ax, y, 0.45, 0.0, 0.75, -0.4, 0.07) ||
                  _ell(ax, y, 0.8, -0.55, 0.2, 0.22) ||
                  _seg(ax, y, 0.45, 0.25, 0.9, 0.5, 0.05) ||
                  _seg(ax, y, 0.4, 0.38, 0.8, 0.75, 0.05) ||
                  _seg(ax, y, 0.25, 0.5, 0.5, 0.95, 0.05) ||
                  _seg(ax, y, 0.2, -0.2, 0.25, -0.55, 0.05) ||
                  _ell(ax, y, 0.25, -0.6, 0.07, 0.07)) &&
              !_poly(ax, y, [(0.8, -0.55), (0.72, -0.9), (0.9, -0.9)]);

        case 'Maze':
          return (_rect(x, y, -0.95, -0.95, 0.95, 0.95) &&
                  !_rect(x, y, -0.8, -0.8, 0.8, 0.8)) ||
              _rect(x, y, -0.8, -0.45, 0.3, -0.28) ||
              _rect(x, y, 0.3, -0.45, 0.47, 0.5) ||
              _rect(x, y, -0.5, 0.15, 0.47, 0.32) ||
              _rect(x, y, -0.5, 0.15, -0.33, 0.8);

        case 'Bolt':
          return _poly(x, y, [
            (0.25, -0.98),
            (-0.62, 0.12),
            (-0.08, 0.12),
            (-0.28, 0.98),
            (0.65, -0.18),
            (0.1, -0.18),
          ]);

        case 'Tulip':
          return _poly(x, y, [
                (-0.52, -0.2),
                (-0.52, -0.82),
                (-0.2, -0.5),
                (0, -0.92),
                (0.2, -0.5),
                (0.52, -0.82),
                (0.52, -0.2),
                (0, 0.2),
              ]) ||
              _rect(x, y, -0.07, 0.1, 0.07, 0.95) ||
              _ell(x, y, -0.28, 0.6, 0.25, 0.11) ||
              _ell(x, y, 0.28, 0.45, 0.25, 0.11);

        case 'Rose':
          return (_ell(x, y, 0, -0.5, 0.45, 0.42) ||
                  _ell(ax, y, 0.38, -0.4, 0.25, 0.3) ||
                  _rect(x, y, -0.06, -0.2, 0.06, 0.95) ||
                  _ell(x, y, -0.28, 0.35, 0.26, 0.11) ||
                  _ell(x, y, 0.28, 0.6, 0.26, 0.11)) &&
              !_ring(x, y + 0.5, 0.26, 0.17);

        case 'Eagle':
          return _poly(ax, y, [
            (0, -0.7),
            (0.1, -0.62),
            (0.16, -0.3),
            (0.98, -0.65),
            (0.92, -0.2),
            (0.98, 0.05),
            (0.6, 0.08),
            (0.45, 0.4),
            (0.2, 0.25),
            (0.14, 0.9),
            (0, 0.95),
          ]);

        case 'Satellite':
          return (_rrect(x, y, -0.22, -0.22, 0.22, 0.22, 0.04) ||
                  _rect(x, y, -0.98, -0.32, -0.42, 0.32) ||
                  _rect(x, y, 0.42, -0.32, 0.98, 0.32) ||
                  _rect(ax, y, 0.22, -0.05, 0.42, 0.05) ||
                  _seg(x, y, 0, -0.2, 0, -0.62, 0.04) ||
                  _ell(x, y, 0, -0.72, 0.16, 0.11)) &&
              !_rect(ax, y, 0.68, -0.3, 0.72, 0.3);

        case 'Spiral':
          return r <= 0.95 &&
              (r < 0.15 || _frac(r * 3.5 - angle / (2 * math.pi)) < 0.55);

        case 'Galaxy':
          return r <= 0.95 &&
              (r < 0.18 || math.cos(2 * (angle - r * 3.5)) > 0.35);

        // ------------------------- Expert: fuller silhouettes ------------
        case 'Cactus':
          return _rrect(x, y, -0.24, -0.85, 0.24, 0.82, 0.24) ||
              _rrect(x, y, -0.7, -0.35, -0.2, -0.12, 0.1) ||
              _rrect(x, y, -0.7, -0.68, -0.48, -0.12, 0.1) ||
              _rrect(x, y, 0.2, 0.05, 0.7, 0.28, 0.1) ||
              _rrect(x, y, 0.48, -0.32, 0.7, 0.28, 0.1) ||
              _poly(x, y, [
                (-0.5, 0.78),
                (0.5, 0.78),
                (0.4, 0.98),
                (-0.4, 0.98),
              ]);

        case 'Sun':
          return r <= 0.45 || _rays(x, y, 12, 0.4, 0.95, 0.07);

        case 'Planet':
          return _planet(x, y);

        case 'Dinosaur':
          return (_ell(x, y, -0.1, 0.15, 0.62, 0.42) ||
                  _seg(x, y, 0.35, 0.0, 0.6, -0.4, 0.17) ||
                  _ell(x, y, 0.68, -0.5, 0.27, 0.2) ||
                  _poly(x, y, [(-0.62, 0.0), (-1.0, 0.45), (-0.5, 0.38)]) ||
                  _rrect(x, y, -0.42, 0.45, -0.16, 0.92, 0.06) ||
                  _rrect(x, y, 0.05, 0.45, 0.31, 0.92, 0.06) ||
                  _poly(x, y, [(-0.5, -0.18), (-0.38, -0.5), (-0.24, -0.22)]) ||
                  _poly(x, y, [(-0.2, -0.22), (-0.08, -0.52), (0.06, -0.2)])) &&
              !_ell(x, y, 0.75, -0.55, 0.05, 0.05);

        case 'Infinity':
          return _ring(x - 0.45, y, 0.52, 0.26) ||
              _ring(x + 0.45, y, 0.52, 0.26);

        case 'Chevron':
          return _poly(x, y, [
            (-0.9, -0.85),
            (-0.3, -0.85),
            (0.9, 0),
            (-0.3, 0.85),
            (-0.9, 0.85),
            (0.3, 0),
          ]);

        case 'Crystal':
          return _poly(x, y, [
                (-0.22, 0.95),
                (-0.3, -0.2),
                (0, -0.98),
                (0.3, -0.2),
                (0.22, 0.95),
              ]) ||
              _poly(ax, y, [
                (0.2, 0.95),
                (0.34, 0.05),
                (0.62, -0.45),
                (0.9, 0.05),
                (0.95, 0.95),
              ]);

        case 'Balloon':
          return _ell(x, y, 0, -0.4, 0.66, 0.58) ||
              _poly(x, y, [
                (-0.6, -0.2),
                (0.6, -0.2),
                (0.2, 0.3),
                (-0.2, 0.3),
              ]) ||
              _seg(x, y, -0.2, 0.3, -0.2, 0.55, 0.035) ||
              _seg(x, y, 0.2, 0.3, 0.2, 0.55, 0.035) ||
              _rrect(x, y, -0.28, 0.55, 0.28, 0.88, 0.05);

        case 'Peacock':
          return ((_ell(x, y, 0, 0.3, 0.95, 0.95) && y < 0.3) ||
                  _ell(x, y, 0, 0.62, 0.22, 0.36)) &&
              !_ell(x, y, 0, -0.3, 0.08, 0.1) &&
              !_ell(ax, y, 0.3, -0.22, 0.08, 0.1) &&
              !_ell(ax, y, 0.52, 0.0, 0.08, 0.1);

        case 'Octopus':
          return _octopus(x, y);

        // ------------------------- Expert: the fullest silhouettes -------
        case 'Mandala':
          return _petals(x, y, 8, 0.6, 0.22) ||
              _ell(x, y, 0, 0, 0.25, 0.25) ||
              _ring(x, y, 0.95, 0.84) ||
              _rays(x, y, 8, 0.0, 0.9, 0.045, rot: math.pi / 8);

        case 'Ring':
          return _ring(x, y, 0.92, 0.5);

        case 'Paw Print':
          return _ell(ax, y, 0.65, -0.1, 0.18, 0.26) ||
              _ell(ax, y, 0.26, -0.58, 0.2, 0.26) ||
              _ell(x, y, 0, 0.42, 0.5, 0.4) ||
              _ell(ax, y, 0.42, 0.35, 0.25, 0.3);

        case 'Fox':
          return (_poly(x, y, [
                    (-0.8, -0.25),
                    (0.8, -0.25),
                    (0.92, 0.1),
                    (0, 0.95),
                    (-0.92, 0.1),
                  ]) ||
                  _poly(ax, y, [(0.95, -0.95), (0.3, -0.3), (0.9, 0.0)])) &&
              !_ell(ax, y, 0.35, -0.02, 0.09, 0.06);

        case 'Starburst':
          return _starPoly(x, y, 12, 0.98, 0.58);

        case 'Pagoda':
          return _poly(ax, y, [
                (0, -0.7),
                (0.25, -0.7),
                (0.5, -0.52),
                (0, -0.52),
              ]) ||
              _rect(x, y, -0.25, -0.52, 0.25, -0.27) ||
              _poly(ax, y, [
                (0, -0.25),
                (0.45, -0.25),
                (0.7, -0.07),
                (0, -0.07),
              ]) ||
              _rect(x, y, -0.45, -0.07, 0.45, 0.18) ||
              _poly(ax, y, [(0, 0.2), (0.65, 0.2), (0.9, 0.38), (0, 0.38)]) ||
              _rect(x, y, -0.65, 0.38, 0.65, 0.63) ||
              _rect(x, y, -0.92, 0.63, 0.92, 0.82) ||
              _seg(x, y, 0, -0.98, 0, -0.7, 0.045);

        case 'Cog':
          return _cogShape(x, y);

        case 'Skull':
          return (_ell(x, y, 0, -0.15, 0.78, 0.72) ||
                  _rrect(x, y, -0.42, 0.3, 0.42, 0.92, 0.08)) &&
              !_ell(ax, y, 0.3, -0.15, 0.18, 0.2) &&
              !_poly(x, y, [(0, 0.05), (-0.09, 0.2), (0.09, 0.2)]) &&
              !(y > 0.62 && (_ab(x) < 0.03 || _ab(ax - 0.2) < 0.03));

        case 'Temple':
          return _poly(x, y, [(-0.98, -0.4), (0, -0.92), (0.98, -0.4)]) ||
              _rect(x, y, -0.98, -0.4, 0.98, -0.25) ||
              _rect(x, y, -0.79, -0.25, -0.65, 0.65) ||
              _rect(x, y, -0.43, -0.25, -0.29, 0.65) ||
              _rect(x, y, -0.07, -0.25, 0.07, 0.65) ||
              _rect(x, y, 0.29, -0.25, 0.43, 0.65) ||
              _rect(x, y, 0.65, -0.25, 0.79, 0.65) ||
              _rect(x, y, -0.98, 0.65, 0.98, 0.78) ||
              _rect(x, y, -0.88, 0.78, 0.88, 0.92);

        case 'Train':
          return (_rrect(x, y, -0.9, -0.3, 0.2, 0.45, 0.1) ||
                  _rect(x, y, -0.8, -0.7, -0.55, -0.3) ||
                  _rect(x, y, -0.88, -0.78, -0.47, -0.68) ||
                  _ell(x, y, -0.1, -0.32, 0.12, 0.12) ||
                  _rect(x, y, 0.2, -0.65, 0.88, 0.45) ||
                  _rect(x, y, 0.15, -0.78, 0.93, -0.65) ||
                  _poly(x, y, [(-0.9, 0.45), (-1.0, 0.72), (-0.8, 0.72)]) ||
                  _ell(x, y, -0.6, 0.55, 0.22, 0.22) ||
                  _ell(x, y, -0.15, 0.55, 0.22, 0.22) ||
                  _ell(x, y, 0.55, 0.55, 0.25, 0.25)) &&
              !_rect(x, y, 0.42, -0.5, 0.7, -0.2);

        default:
          return r < 0.8;
      }
    };
  }
}
