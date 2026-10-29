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

bool _star(double x, double y, {int points = 5}) {
  final r = _distance(x, y);
  final a = _angle(x, y);
  final edge = 0.64 + 0.33 * math.cos(points * (a + math.pi / 2));

  return r <= edge;
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

  factory LevelDesign.shape(
    String name,
    String category,
    ShapeFn shape, {
    int preferredLongSide = 24,
    double extent = 1.3,
  }) {
    const samples = 180;
    final step = extent * 2 / samples;

    var minX = double.infinity;
    var maxX = -double.infinity;
    var minY = double.infinity;
    var maxY = -double.infinity;

    for (var row = 0; row < samples; row++) {
      final y = -extent + (row + 0.5) * step;

      for (var col = 0; col < samples; col++) {
        final x = -extent + (col + 0.5) * step;

        if (!shape(x, y)) continue;

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

    return LevelDesign._(
      name,
      category,
      preferredLongSide,
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
//   Levels 41-80   Expert          thin parts, many details, dense boards
//
// Difficulty only goes up. Three things rise together on every level:
//   1. the design itself (silhouettes are sorted simple -> complex),
//   2. the arrow count (smooth curve, no sudden jumps),
//   3. the board size and the interior holes (holes start at level 21 and
//      grow gradually denser and bigger).
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

  /// Board size follows the arrow count, so early levels are small and
  /// light, and the board only grows as the arrow count grows.
  static int longSideForLevel(int level, String name) {
    final l = level.clamp(1, totalLevels).toInt();

    // Tutorial: 5 columns wide (3 arrows + 2 gap columns).
    if (l == 1) return 5;

    final arrows = arrowCountForLevel(l);

    // Matches the controller's maximum arrow length (5 + level ~/ 4).
    final maxLen = (5 + l ~/ 4).clamp(5, 12).toInt();
    final avgLen = maxLen * 0.65;

    // About 0.75 * side^2 playable cells on an average silhouette.
    final cellsNeeded = arrows * avgLen;
    var side = math.sqrt(cellsNeeded / 0.75).round();

    // Detailed designs (levels 41+) need extra resolution.
    if (l >= 41) side += 2;

    return side.clamp(6, 66).toInt();
  }

  // Thin or delicate silhouettes keep their natural shape (no holes).
  static const Set<String> _noHoles = {
    'Ring',
    'Plus',
    'Chevron',
    'Bolt',
    'Flag',
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
  // Sorted from the simplest silhouette to the most complex one.
  static const List<(String, String)> _recipes = [
    // ---- Levels 2-6 (Easy): solid convex shapes ----
    ('Square', 'Shape'), // 2
    ('Circle', 'Shape'), // 3
    ('Triangle', 'Shape'), // 4
    ('Rhombus', 'Shape'), // 5
    ('Hexagon', 'Shape'), // 6
    // ---- Levels 7-10 (Easy+): rounder solid shapes ----
    ('Pentagon', 'Shape'), // 7
    ('Octagon', 'Shape'), // 8
    ('Heart', 'Shape'), // 9
    ('Droplet', 'Nature'), // 10
    // ---- Levels 11-15 (Normal): first concave shapes ----
    ('Star', 'Shape'), // 11
    ('Moon', 'Nature'), // 12
    ('Arrow Up', 'Shape'), // 13
    ('Home', 'Object'), // 14
    ('Tree', 'Nature'), // 15
    // ---- Levels 16-20 (Medium): icons with small details ----
    ('Mushroom', 'Nature'), // 16
    ('Fish', 'Animal'), // 17
    ('Bell', 'Object'), // 18
    ('Cup', 'Object'), // 19
    ('Crown', 'Object'), // 20
    // ---- Levels 21-25 (Medium-Hard) ----
    ('Shield', 'Object'), // 21
    ('Cat Face', 'Animal'), // 22
    ('Rocket', 'Object'), // 23
    ('Flag', 'Object'), // 24
    ('Plus', 'Shape'), // 25
    // ---- Levels 26-30 (Hard): animals with heads and limbs ----
    ('Duck', 'Animal'), // 26
    ('Penguin', 'Animal'), // 27
    ('Rabbit', 'Animal'), // 28
    ('Owl', 'Animal'), // 29
    ('Turtle', 'Animal'), // 30
    // ---- Levels 31-35 (Hard): larger animals and objects ----
    ('Whale', 'Animal'), // 31
    ('Dog', 'Animal'), // 32
    ('Butterfly', 'Animal'), // 33
    ('Flower', 'Nature'), // 34
    ('Sailboat', 'Object'), // 35
    // ---- Levels 36-40 (Very Hard): complex silhouettes ----
    ('Lighthouse', 'Object'), // 36
    ('Castle', 'Object'), // 37
    ('Hourglass', 'Object'), // 38
    ('Trophy', 'Object'), // 39
    ('Umbrella', 'Object'), // 40
    // ---- Levels 41-80 (Expert): thin parts, details, dense boards ----
    ('Cactus', 'Nature'), // 41
    ('Chevron', 'Shape'), // 42
    ('Bolt', 'Shape'), // 43
    ('Ring', 'Shape'), // 44
    ('Key', 'Object'), // 45
    ('Sun', 'Nature'), // 46
    ('Cog', 'Object'), // 47
    ('Planet', 'Nature'), // 48
    ('Paw Print', 'Animal'), // 49
    ('Train', 'Object'), // 50
    ('Dinosaur', 'Animal'), // 51
    ('Fox', 'Animal'), // 52
    ('Crab', 'Animal'), // 53
    ('Balloon', 'Object'), // 54
    ('Crystal', 'Shape'), // 55
    ('Skull', 'Object'), // 56
    ('Tulip', 'Nature'), // 57
    ('Rose', 'Nature'), // 58
    ('Temple', 'Object'), // 59
    ('Windmill', 'Object'), // 60
    ('Satellite', 'Object'), // 61
    ('Starburst', 'Pattern'), // 62
    ('Compass', 'Object'), // 63
    ('Eagle', 'Animal'), // 64
    ('Dragonfly', 'Animal'), // 65
    ('Peacock', 'Animal'), // 66
    ('Octopus', 'Animal'), // 67
    ('Infinity', 'Pattern'), // 68
    ('Spiral', 'Pattern'), // 69
    ('Pagoda', 'Object'), // 70
    ('Bridge', 'Object'), // 71
    ('Telescope', 'Object'), // 72
    ('Bicycle', 'Object'), // 73
    ('Palm Tree', 'Nature'), // 74
    ('Spider', 'Animal'), // 75
    ('Snowflake', 'Nature'), // 76
    ('Eiffel Tower', 'Object'), // 77
    ('Mandala', 'Pattern'), // 78
    ('Maze', 'Pattern'), // 79
    ('Galaxy', 'Nature'), // 80
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

    return LevelDesign.shape(
      name,
      category,
      _hardened(name, l, _shapeFor(name, l)),
      preferredLongSide: longSideForLevel(l, name),
    );
  }

  // ===========================================================================
  // EXTRA SHAPE HELPERS
  // ===========================================================================

  static bool _regular(
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

  static bool _petals(
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

  static bool _snow(double x, double y) {
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      final ex = math.cos(a) * 0.95;
      final ey = math.sin(a) * 0.95;

      if (_seg(x, y, 0, 0, ex, ey, 0.06)) return true;

      for (final t in [0.4, 0.7]) {
        final bx = ex * t;
        final by = ey * t;

        for (final s in [-1.0, 1.0]) {
          if (_seg(
            x,
            y,
            bx,
            by,
            bx + math.cos(a + s * 0.8) * 0.25,
            by + math.sin(a + s * 0.8) * 0.25,
            0.045,
          )) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static bool _mandala(double x, double y) {
    if (_petals(x, y, 8, 0.6, 0.22)) return true;
    if (_ell(x, y, 0, 0, 0.25, 0.25)) return true;
    if (_ring(x, y, 0.95, 0.85)) return true;

    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + math.pi / 8;
      if (_seg(x, y, 0, 0, math.cos(a) * 0.9, math.sin(a) * 0.9, 0.04)) {
        return true;
      }
    }
    return false;
  }

  static bool _cog(double x, double y) {
    final r = _distance(x, y);
    final a = _angle(x, y);
    final tooth = math.cos(8 * a) > 0.2 ? 0.95 : 0.72;
    return r <= tooth && r >= 0.28;
  }

  static bool _sun(double x, double y) {
    if (_distance(x, y) <= 0.45) return true;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      if (_seg(
        x,
        y,
        math.cos(a) * 0.4,
        math.sin(a) * 0.4,
        math.cos(a) * 0.95,
        math.sin(a) * 0.95,
        0.06,
      )) {
        return true;
      }
    }
    return false;
  }

  static bool _planet(double x, double y) {
    if (_ell(x, y, 0, 0, 0.55, 0.55)) return true;

    final c = math.cos(-0.45);
    final s = math.sin(-0.45);
    final xr = x * c - y * s;
    final yr = x * s + y * c;
    final e = (xr / 0.98) * (xr / 0.98) + (yr / 0.30) * (yr / 0.30);

    return e <= 1 && e >= 0.55;
  }

  static bool _peacock(double x, double y) {
    if (_ell(x, y, 0, 0.6, 0.15, 0.36)) return true;
    if (_ell(x, y, 0, 0.2, 0.3, 0.3)) return true;

    for (var i = 0; i < 7; i++) {
      final a = -math.pi + (i + 0.5) * math.pi / 7;
      if (_ell(x, y, math.cos(a) * 0.62, 0.15 + math.sin(a) * 0.62, 0.2, 0.2)) {
        return true;
      }
    }
    return false;
  }

  static bool _octopus(double x, double y) {
    if (_ell(x, y, 0, -0.35, 0.62, 0.55) &&
        !_ell(x.abs(), y, 0.25, -0.4, 0.08, 0.1)) {
      return true;
    }

    for (var i = 0; i < 6; i++) {
      final x0 = -0.5 + i * 0.2;
      final x1 = x0 + (i.isEven ? 0.1 : -0.1);
      if (_seg(x, y, x0, 0.05, x1, 0.9, 0.07)) return true;
    }
    return false;
  }

  static bool _pagoda(double x, double y) {
    for (var i = 0; i < 3; i++) {
      final t = -0.7 + i * 0.45;
      final w = 0.4 + 0.2 * i;

      if (_poly(x, y, [
            (-w - 0.1, t + 0.18),
            (-w + 0.15, t),
            (w - 0.15, t),
            (w + 0.1, t + 0.18),
          ]) ||
          _rect(x, y, -w + 0.15, t + 0.18, w - 0.15, t + 0.43)) {
        return true;
      }
    }

    return _rect(x, y, -0.9, 0.63, 0.9, 0.8) ||
        _seg(x, y, 0, -0.98, 0, -0.65, 0.035);
  }

  static bool _temple(double x, double y) {
    if (_poly(x, y, [(-0.95, -0.4), (0, -0.9), (0.95, -0.4)])) return true;
    if (_rect(x, y, -0.95, -0.4, 0.95, -0.25)) return true;

    for (var i = 0; i < 5; i++) {
      final cx = -0.72 + i * 0.36;
      if (_rect(x, y, cx - 0.07, -0.25, cx + 0.07, 0.65)) return true;
    }

    return _rect(x, y, -0.98, 0.65, 0.98, 0.78) ||
        _rect(x, y, -0.88, 0.78, 0.88, 0.9);
  }

  static bool _bridge(double x, double y) {
    final ax = x.abs();

    if (_rect(x, y, -0.98, 0.4, 0.98, 0.55)) return true;
    if (_rect(x, y, -0.6, -0.6, -0.5, 0.55)) return true;
    if (_rect(x, y, 0.5, -0.6, 0.6, 0.55)) return true;

    if (_seg(x, y, -0.98, 0.38, -0.55, -0.55, 0.035)) return true;
    if (_seg(x, y, 0.98, 0.38, 0.55, -0.55, 0.035)) return true;

    if (ax <= 0.55) {
      final k = ax / 0.55;
      final yc = -0.55 + 0.55 * (1 - k * k);

      if ((y - yc).abs() <= 0.04) return true;

      if (y > yc && y < 0.4) {
        final u = x / 0.11;
        if ((u - u.roundToDouble()).abs() * 0.11 < 0.02) return true;
      }
    }
    return false;
  }

  static bool _tower(double x, double y) {
    final body = _poly(x.abs(), y, [
      (0, -0.98),
      (0.08, -0.6),
      (0.2, -0.1),
      (0.45, 0.5),
      (0.8, 0.95),
      (0.55, 0.95),
      (0.35, 0.62),
      (0, 0.62),
    ]);

    return body ||
        _rect(x, y, -0.3, -0.1, 0.3, 0.0) ||
        _rect(x, y, -0.5, 0.5, 0.5, 0.62);
  }

  static bool _maze(double x, double y) {
    return (_rect(x, y, -0.95, -0.95, 0.95, 0.95) &&
            !_rect(x, y, -0.81, -0.81, 0.81, 0.81)) ||
        _rect(x, y, -0.81, -0.4, 0.3, -0.26) ||
        _rect(x, y, 0.3, -0.4, 0.44, 0.5) ||
        _rect(x, y, -0.5, 0.15, 0.44, 0.29) ||
        _rect(x, y, -0.5, 0.15, -0.36, 0.81);
  }

  // ===========================================================================
  // SHAPE LIBRARY — 79 silhouettes
  // ===========================================================================

  static ShapeFn _shapeFor(String name, int level) {
    return (double x, double y) {
      final ax = x.abs();
      final r = _distance(x, y);
      final angle = _angle(x, y);

      switch (name) {
        // ------------------------- Simple shapes -------------------------
        case 'Square':
          return _rect(x, y, -0.85, -0.85, 0.85, 0.85);

        case 'Triangle':
          return _poly(x, y, [(0, -0.9), (0.95, 0.8), (-0.95, 0.8)]);

        case 'Circle':
          return r <= 0.92;

        case 'Rhombus':
          return ax / 0.65 + y.abs() / 0.95 <= 1;

        case 'Plus':
          return _rect(x, y, -0.3, -0.9, 0.3, 0.9) ||
              _rect(x, y, -0.9, -0.3, 0.9, 0.3);

        case 'Heart':
          return _heart(x, y);

        case 'Star':
          return _star(x, y);

        case 'Pentagon':
          return _regular(x, y, 5, 0.98);

        case 'Ring':
          return _ring(x, y, 0.92, 0.5);

        // ------------------------- Simple icons --------------------------
        case 'Droplet':
          return _ell(x, y, 0, 0.25, 0.62, 0.62) ||
              _poly(x, y, [(0, -0.95), (-0.55, 0.1), (0.55, 0.1)]);

        case 'Moon':
          return _ell(x, y, 0, 0, 0.92, 0.92) &&
              !_ell(x, y, 0.38, -0.12, 0.72, 0.78);

        case 'Hexagon':
          return _regular(x, y, 6, 0.98, rot: 0);

        case 'Octagon':
          return _regular(x, y, 8, 0.98, rot: math.pi / 8);

        case 'Arrow Up':
          return _poly(x, y, [
            (0, -0.95),
            (0.7, -0.1),
            (0.28, -0.1),
            (0.28, 0.9),
            (-0.28, 0.9),
            (-0.28, -0.1),
            (-0.7, -0.1),
          ]);

        case 'Chevron':
          return _poly(x, y, [
            (-0.9, -0.8),
            (-0.35, -0.8),
            (0.9, 0),
            (-0.35, 0.8),
            (-0.9, 0.8),
            (0.35, 0),
          ]);

        case 'Bolt':
          return _poly(x, y, [
            (0.2, -0.95),
            (-0.65, 0.1),
            (-0.1, 0.1),
            (-0.25, 0.95),
            (0.65, -0.15),
            (0.1, -0.15),
          ]);

        case 'Flag':
          return _rect(x, y, -0.85, -0.95, -0.7, 0.95) ||
              _poly(x, y, [
                (-0.7, -0.9),
                (0.9, -0.9),
                (0.5, -0.45),
                (0.9, 0),
                (-0.7, 0),
              ]);

        case 'Tree':
          return _ell(x, y, 0, -0.3, 0.68, 0.62) ||
              _rect(x, y, -0.12, 0.1, 0.12, 0.92);

        case 'Mushroom':
          return (_ell(x, y, 0, -0.1, 0.92, 0.7) && y < 0.15) ||
              _rect(x, y, -0.28, 0.1, 0.28, 0.85);

        case 'Fish':
          return (_ell(x, y, -0.15, 0, 0.7, 0.45) ||
                  _poly(x, y, [(0.4, 0), (0.95, -0.45), (0.95, 0.45)])) &&
              !_ell(x, y, -0.5, -0.1, 0.07, 0.07);

        case 'Cat Face':
          return (_ell(x, y, 0, 0.2, 0.75, 0.65) ||
                  _poly(x, y, [(-0.75, -0.1), (-0.7, -0.85), (-0.15, -0.4)]) ||
                  _poly(x, y, [(0.75, -0.1), (0.7, -0.85), (0.15, -0.4)])) &&
              !_ell(ax, y, 0.3, 0.1, 0.08, 0.1);

        case 'Bell':
          return (_ell(x, y, 0, -0.1, 0.6, 0.65) && y < 0.4) ||
              _rect(x, y, -0.8, 0.35, 0.8, 0.55) ||
              _ell(x, y, 0, 0.7, 0.14, 0.14);

        case 'Cup':
          return _poly(x, y, [
                (-0.65, -0.5),
                (0.55, -0.5),
                (0.4, 0.7),
                (-0.5, 0.7),
              ]) ||
              (_ring(x - 0.58, y, 0.34, 0.2) && x > 0.5) ||
              _rect(x, y, -0.8, 0.7, 0.7, 0.88);

        case 'Home':
          return (_poly(x, y, [(-0.95, -0.05), (0, -0.9), (0.95, -0.05)]) ||
                  _rect(x, y, -0.7, -0.05, 0.7, 0.85) ||
                  _rect(x, y, 0.35, -0.8, 0.6, -0.3)) &&
              !_rect(x, y, -0.14, 0.4, 0.14, 0.85);

        // ------------------------- Medium designs ------------------------
        case 'Butterfly':
          return _poly(ax, y, [(0.05, -0.1), (0.95, -0.85), (0.9, -0.1)]) ||
              _ell(ax, y, 0.4, 0.45, 0.32, 0.4) ||
              _ell(ax, y, 0.45, -0.3, 0.4, 0.3) ||
              _rect(x, y, -0.06, -0.6, 0.06, 0.8);

        case 'Flower':
          return _petals(x, y + 0.3, 6, 0.4, 0.27) ||
              _ell(x, y, 0, -0.3, 0.22, 0.22) ||
              _rect(x, y, -0.06, -0.1, 0.06, 0.95) ||
              _ell(x, y, 0.27, 0.55, 0.25, 0.1);

        case 'Sailboat':
          return _poly(x, y, [
                (-0.9, 0.4),
                (0.9, 0.4),
                (0.55, 0.85),
                (-0.55, 0.85),
              ]) ||
              _rect(x, y, -0.04, -0.9, 0.04, 0.4) ||
              _poly(x, y, [(0.08, -0.85), (0.08, 0.3), (0.85, 0.3)]) ||
              _poly(x, y, [(-0.08, -0.5), (-0.08, 0.3), (-0.7, 0.3)]);

        case 'Rocket':
          return (_ell(x, y, 0, -0.1, 0.33, 0.75) ||
                  _poly(x, y, [(-0.3, 0.2), (-0.7, 0.8), (-0.3, 0.55)]) ||
                  _poly(x, y, [(0.3, 0.2), (0.7, 0.8), (0.3, 0.55)]) ||
                  _poly(x, y, [(-0.18, 0.6), (0, 0.98), (0.18, 0.6)])) &&
              !_ell(x, y, 0, -0.3, 0.12, 0.12);

        case 'Crown':
          return _poly(x, y, [
            (-0.9, 0.7),
            (-0.9, -0.5),
            (-0.45, 0),
            (0, -0.8),
            (0.45, 0),
            (0.9, -0.5),
            (0.9, 0.7),
          ]);

        case 'Shield':
          return _poly(x, y, [
                (-0.8, -0.85),
                (0.8, -0.85),
                (0.8, 0.1),
                (0, 0.95),
                (-0.8, 0.1),
              ]) &&
              !_rect(x, y, -0.07, -0.6, 0.07, 0.5);

        case 'Key':
          return _ring(x + 0.5, y, 0.42, 0.2) ||
              _rect(x, y, -0.1, -0.08, 0.92, 0.08) ||
              _rect(x, y, 0.6, 0.08, 0.74, 0.35) ||
              _rect(x, y, 0.78, 0.08, 0.92, 0.28);

        case 'Hourglass':
          return _poly(x, y, [
                (-0.75, -0.9),
                (0.75, -0.9),
                (0.1, 0),
                (0.75, 0.9),
                (-0.75, 0.9),
                (-0.1, 0),
              ]) ||
              _rect(x, y, -0.85, -0.98, 0.85, -0.85) ||
              _rect(x, y, -0.85, 0.85, 0.85, 0.98);

        case 'Trophy':
          return _poly(x, y, [
                (-0.6, -0.8),
                (0.6, -0.8),
                (0.4, 0.1),
                (-0.4, 0.1),
              ]) ||
              (_ring(x + 0.65, y + 0.45, 0.3, 0.17) && x < -0.55) ||
              (_ring(x - 0.65, y + 0.45, 0.3, 0.17) && x > 0.55) ||
              _rect(x, y, -0.1, 0.1, 0.1, 0.6) ||
              _rect(x, y, -0.5, 0.6, 0.5, 0.85);

        case 'Umbrella':
          return (_ell(x, y, 0, -0.1, 0.95, 0.7) && y < 0.15) ||
              _rect(x, y, -0.04, 0.1, 0.04, 0.7) ||
              (_ring(x + 0.16, y - 0.7, 0.16, 0.07) && y > 0.7);

        case 'Cactus':
          return _rect(x, y, -0.22, -0.8, 0.22, 0.9) ||
              _ell(x, y, 0, -0.8, 0.22, 0.12) ||
              _rect(x, y, -0.65, -0.3, -0.22, -0.1) ||
              _rect(x, y, -0.65, -0.6, -0.45, -0.1) ||
              _rect(x, y, 0.22, 0.0, 0.65, 0.2) ||
              _rect(x, y, 0.45, -0.35, 0.65, 0.2);

        case 'Penguin':
          return (_ell(x, y, 0, 0.05, 0.6, 0.85) ||
                  _ell(ax, y, 0.28, 0.88, 0.2, 0.08) ||
                  _poly(ax, y, [(0.5, -0.1), (0.9, 0.3), (0.55, 0.35)])) &&
              !_ell(ax, y, 0.2, -0.5, 0.06, 0.06);

        case 'Duck':
          return _ell(x, y, -0.1, 0.3, 0.7, 0.5) ||
              _ell(x, y, 0.35, -0.45, 0.32, 0.32) ||
              _poly(x, y, [(0.62, -0.45), (0.98, -0.35), (0.62, -0.25)]) ||
              _poly(x, y, [(-0.7, 0.15), (-0.98, -0.1), (-0.6, 0.4)]);

        case 'Rabbit':
          return _ell(ax, y, 0.22, -0.6, 0.12, 0.38) ||
              _ell(x, y, 0, 0.0, 0.45, 0.4) ||
              _ell(x, y, 0, 0.55, 0.55, 0.4) ||
              _ell(x, y, 0.5, 0.7, 0.14, 0.14);

        case 'Owl':
          return (_ell(x, y, 0, 0.1, 0.65, 0.85) ||
                  _poly(ax, y, [(0.2, -0.7), (0.55, -0.98), (0.62, -0.45)])) &&
              !(_ell(ax, y, 0.28, -0.2, 0.2, 0.2) &&
                  !_ell(ax, y, 0.28, -0.2, 0.08, 0.08));

        case 'Turtle':
          return (_ell(x, y, 0, 0.1, 0.8, 0.65) && y < 0.3) ||
              _ell(x, y, 0.78, 0.08, 0.2, 0.18) ||
              _rect(x, y, -0.55, 0.25, -0.35, 0.65) ||
              _rect(x, y, 0.3, 0.25, 0.5, 0.65) ||
              _rect(x, y, -0.8, 0.2, 0.8, 0.32);

        case 'Whale':
          return _ell(x, y, -0.1, 0.15, 0.8, 0.5) ||
              _poly(x, y, [
                (0.55, 0.1),
                (0.95, -0.4),
                (0.98, 0.0),
                (0.8, 0.25),
              ]) ||
              _seg(x, y, -0.55, -0.3, -0.55, -0.75, 0.04) ||
              _ell(x, y, -0.55, -0.8, 0.15, 0.08);

        case 'Dog':
          return (_ell(x, y, -0.1, 0.1, 0.7, 0.35) ||
                  _ell(x, y, 0.55, -0.3, 0.3, 0.27) ||
                  _seg(x, y, 0.3, 0.0, 0.5, -0.25, 0.15) ||
                  _rect(x, y, 0.7, -0.3, 0.98, -0.1) ||
                  _ell(x, y, 0.38, -0.5, 0.1, 0.18) ||
                  _rect(x, y, -0.6, 0.3, -0.46, 0.85) ||
                  _rect(x, y, -0.3, 0.3, -0.16, 0.85) ||
                  _rect(x, y, 0.15, 0.3, 0.29, 0.85) ||
                  _rect(x, y, 0.4, 0.3, 0.54, 0.85) ||
                  _seg(x, y, -0.75, 0.0, -0.97, -0.45, 0.06)) &&
              !_ell(x, y, 0.62, -0.38, 0.04, 0.04);

        case 'Lighthouse':
          return _poly(x, y, [
                (-0.4, -0.35),
                (0.4, -0.35),
                (0.6, 0.85),
                (-0.6, 0.85),
              ]) ||
              _rect(x, y, -0.5, -0.55, 0.5, -0.32) ||
              _poly(x, y, [(-0.6, -0.55), (0, -0.98), (0.6, -0.55)]) ||
              _rect(x, y, -0.8, 0.85, 0.8, 0.98) ||
              _seg(x, y, -0.5, -0.45, -0.98, -0.65, 0.05) ||
              _seg(x, y, 0.5, -0.45, 0.98, -0.65, 0.05);

        case 'Castle':
          return (_rect(x, y, -0.8, -0.3, 0.8, 0.9) ||
                  _rect(x, y, -0.95, -0.8, -0.5, 0.9) ||
                  _rect(x, y, 0.5, -0.8, 0.95, 0.9) ||
                  _poly(x, y, [(-1, -0.8), (-0.725, -1.0), (-0.45, -0.8)]) ||
                  _poly(x, y, [(0.45, -0.8), (0.725, -1.0), (1, -0.8)])) &&
              !(_rect(x, y, -0.15, 0.35, 0.15, 0.9) ||
                  _ell(x, y, 0, 0.35, 0.15, 0.15));

        // ------------------------- Detailed designs ----------------------
        case 'Windmill':
          {
            if (_poly(x, y, [
                  (-0.3, 0.92),
                  (0.3, 0.92),
                  (0.18, -0.2),
                  (-0.18, -0.2),
                ]) ||
                _ell(x, y, 0, -0.3, 0.15, 0.15)) {
              return true;
            }

            for (var i = 0; i < 4; i++) {
              final a = math.pi / 4 + i * math.pi / 2;
              if (_seg(
                x,
                y,
                0,
                -0.3,
                math.cos(a) * 0.7,
                -0.3 + math.sin(a) * 0.7,
                0.09,
              )) {
                return true;
              }
            }
            return false;
          }

        case 'Train':
          return (_rect(x, y, -0.9, -0.35, 0.25, 0.45) ||
                  _rect(x, y, -0.75, -0.7, -0.55, -0.35) ||
                  _ell(x, y, -0.2, -0.35, 0.12, 0.12) ||
                  _rect(x, y, 0.25, -0.65, 0.85, 0.45) ||
                  _rect(x, y, 0.2, -0.75, 0.9, -0.65) ||
                  _ell(x, y, -0.6, 0.55, 0.2, 0.2) ||
                  _ell(x, y, -0.1, 0.55, 0.2, 0.2) ||
                  _ell(x, y, 0.55, 0.55, 0.22, 0.22)) &&
              !_rect(x, y, 0.45, -0.5, 0.7, -0.2);

        case 'Bicycle':
          return _ring(x - 0.55, y - 0.3, 0.35, 0.25) ||
              _ring(x + 0.55, y - 0.3, 0.35, 0.25) ||
              _seg(x, y, -0.55, -0.3, -0.1, 0.3, 0.055) ||
              _seg(x, y, -0.1, 0.3, 0.55, -0.3, 0.055) ||
              _seg(x, y, -0.55, -0.3, 0.55, -0.3, 0.055) ||
              _seg(x, y, -0.1, 0.3, 0.0, 0.72, 0.055) ||
              _seg(x, y, -0.12, 0.72, 0.15, 0.72, 0.055) ||
              _seg(x, y, 0.45, -0.3, 0.55, -0.7, 0.055);

        case 'Eagle':
          return _poly(ax, y, [
            (0, -0.6),
            (0.12, -0.5),
            (0.2, -0.15),
            (0.98, -0.6),
            (0.85, -0.1),
            (0.98, 0.1),
            (0.55, 0.12),
            (0.4, 0.45),
            (0.18, 0.3),
            (0.12, 0.9),
            (0, 0.95),
          ]);

        case 'Dragonfly':
          return _ell(x, y, 0, 0.0, 0.1, 0.9) ||
              _ell(x, y, 0, -0.85, 0.14, 0.12) ||
              _ell(ax, y, 0.5, -0.4, 0.48, 0.14) ||
              _ell(ax, y, 0.45, -0.05, 0.42, 0.13);

        case 'Peacock':
          return _peacock(x, y);

        case 'Octopus':
          return _octopus(x, y);

        case 'Dinosaur':
          return (_ell(x, y, -0.1, 0.1, 0.65, 0.45) ||
                  _ell(x, y, 0.55, -0.35, 0.35, 0.28) ||
                  _seg(x, y, 0.3, 0.0, 0.55, -0.35, 0.2) ||
                  _rect(x, y, 0.6, -0.35, 0.95, -0.15) ||
                  _poly(x, y, [(-0.6, -0.1), (-0.98, 0.3), (-0.55, 0.3)]) ||
                  _rect(x, y, -0.3, 0.4, -0.1, 0.9) ||
                  _rect(x, y, 0.1, 0.4, 0.3, 0.9) ||
                  _seg(x, y, 0.45, 0.1, 0.6, 0.25, 0.05)) &&
              !_ell(x, y, 0.62, -0.42, 0.05, 0.05);

        case 'Snowflake':
          return _snow(x, y);

        case 'Mandala':
          return _mandala(x, y);

        case 'Cog':
          return _cog(x, y);

        case 'Sun':
          return _sun(x, y);

        case 'Planet':
          return _planet(x, y);

        case 'Spiral':
          {
            if (r > 0.95) return false;

            final p = r * 4.0 - angle / (2 * math.pi);
            final frac = p - p.floorToDouble();

            return r < 0.15 || frac < 0.5;
          }

        case 'Infinity':
          return _ring(x - 0.45, y, 0.5, 0.25) || _ring(x + 0.45, y, 0.5, 0.25);

        case 'Paw Print':
          return _ell(ax, y, 0.62, -0.1, 0.18, 0.26) ||
              _ell(ax, y, 0.24, -0.58, 0.2, 0.26) ||
              _ell(x, y, 0, 0.42, 0.5, 0.4) ||
              _ell(ax, y, 0.42, 0.35, 0.25, 0.3);

        case 'Temple':
          return _temple(x, y);

        case 'Bridge':
          return _bridge(x, y);

        case 'Telescope':
          return _seg(x, y, -0.8, 0.1, 0.55, -0.55, 0.14) ||
              _seg(x, y, 0.55, -0.55, 0.85, -0.7, 0.07) ||
              _seg(x, y, -0.12, -0.22, -0.45, 0.92, 0.055) ||
              _seg(x, y, -0.12, -0.22, 0.25, 0.92, 0.055) ||
              _seg(x, y, -0.12, -0.22, -0.1, 0.92, 0.055);

        case 'Maze':
          return _maze(x, y);

        // ------------------------- Expert designs ------------------------
        case 'Rose':
          return (_ell(x, y, 0, -0.5, 0.42, 0.42) &&
                  !_ell(x, y, 0, -0.6, 0.1, 0.2)) ||
              _ell(ax, y, 0.35, -0.4, 0.25, 0.3) ||
              _rect(x, y, -0.05, -0.2, 0.05, 0.95) ||
              _ell(x, y, -0.28, 0.35, 0.26, 0.11) ||
              _ell(x, y, 0.28, 0.6, 0.26, 0.11);

        case 'Tulip':
          return _poly(x, y, [
                (-0.5, -0.2),
                (-0.5, -0.8),
                (-0.2, -0.5),
                (0, -0.9),
                (0.2, -0.5),
                (0.5, -0.8),
                (0.5, -0.2),
                (0, 0.2),
              ]) ||
              _rect(x, y, -0.05, 0.1, 0.05, 0.95) ||
              _ell(x, y, -0.28, 0.6, 0.24, 0.1) ||
              _ell(x, y, 0.28, 0.45, 0.24, 0.1);

        case 'Fox':
          return _poly(x, y, [
                (-0.95, -0.85),
                (-0.45, -0.35),
                (0.45, -0.35),
                (0.95, -0.85),
                (0.8, 0.2),
                (0, 0.95),
                (-0.8, 0.2),
              ]) &&
              !_ell(ax, y, 0.35, -0.05, 0.08, 0.06);

        case 'Crab':
          return _ell(x, y, 0, 0.1, 0.55, 0.4) ||
              _ell(ax, y, 0.8, -0.45, 0.17, 0.2) ||
              _seg(ax, y, 0.45, -0.05, 0.75, -0.35, 0.06) ||
              _seg(ax, y, 0.5, 0.15, 0.9, 0.4, 0.05) ||
              _seg(ax, y, 0.4, 0.3, 0.8, 0.65, 0.05) ||
              _seg(ax, y, 0.25, 0.45, 0.5, 0.9, 0.05) ||
              _seg(ax, y, 0.2, -0.25, 0.25, -0.55, 0.04) ||
              _ell(ax, y, 0.25, -0.6, 0.06, 0.06);

        case 'Spider':
          return _ell(x, y, 0, 0.2, 0.3, 0.4) ||
              _ell(x, y, 0, -0.25, 0.2, 0.18) ||
              _seg(ax, y, 0.15, -0.3, 0.55, -0.75, 0.04) ||
              _seg(ax, y, 0.55, -0.75, 0.9, -0.2, 0.04) ||
              _seg(ax, y, 0.2, -0.15, 0.7, -0.2, 0.04) ||
              _seg(ax, y, 0.7, -0.2, 0.95, 0.2, 0.04) ||
              _seg(ax, y, 0.2, 0.0, 0.7, 0.2, 0.04) ||
              _seg(ax, y, 0.7, 0.2, 0.9, 0.7, 0.04) ||
              _seg(ax, y, 0.15, 0.3, 0.5, 0.6, 0.04) ||
              _seg(ax, y, 0.5, 0.6, 0.6, 0.95, 0.04);

        case 'Palm Tree':
          return _seg(x, y, -0.1, 0.95, 0.05, -0.2, 0.07) ||
              _seg(x, y, 0.05, -0.25, -0.85, -0.1, 0.07) ||
              _seg(x, y, 0.05, -0.25, -0.6, -0.6, 0.07) ||
              _seg(x, y, 0.05, -0.25, 0.05, -0.85, 0.07) ||
              _seg(x, y, 0.05, -0.25, 0.7, -0.6, 0.07) ||
              _seg(x, y, 0.05, -0.25, 0.9, -0.1, 0.07) ||
              _ell(x, y, -0.05, -0.15, 0.1, 0.1) ||
              _ell(x, y, 0.15, -0.12, 0.1, 0.1);

        case 'Skull':
          return (_ell(x, y, 0, -0.2, 0.75, 0.7) ||
                  _rect(x, y, -0.4, 0.3, 0.4, 0.85)) &&
              !_ell(ax, y, 0.3, -0.2, 0.17, 0.2) &&
              !_poly(x, y, [(0, 0.0), (-0.08, 0.15), (0.08, 0.15)]) &&
              !(y > 0.55 &&
                  y < 0.85 &&
                  ((x / 0.2) - (x / 0.2).roundToDouble()).abs() * 0.2 < 0.02);

        case 'Compass':
          return _ring(x, y, 0.95, 0.82) ||
              _poly(x, y, [(0, -0.88), (0.14, 0), (0, 0.88), (-0.14, 0)]) ||
              _poly(x, y, [(-0.88, 0), (0, 0.14), (0.88, 0), (0, -0.14)]);

        case 'Pagoda':
          return _pagoda(x, y);

        case 'Eiffel Tower':
          return _tower(x, y);

        case 'Balloon':
          return _ell(x, y, 0, -0.4, 0.65, 0.58) ||
              _poly(x, y, [
                (-0.6, -0.2),
                (0.6, -0.2),
                (0.2, 0.3),
                (-0.2, 0.3),
              ]) ||
              _seg(x, y, -0.2, 0.3, -0.2, 0.55, 0.03) ||
              _seg(x, y, 0.2, 0.3, 0.2, 0.55, 0.03) ||
              _rect(x, y, -0.28, 0.55, 0.28, 0.88);

        case 'Satellite':
          return _rect(x, y, -0.2, -0.2, 0.2, 0.2) ||
              _rect(x, y, -0.95, -0.3, -0.4, 0.3) ||
              _rect(x, y, 0.4, -0.3, 0.95, 0.3) ||
              _rect(x, y, -0.4, -0.04, -0.2, 0.04) ||
              _rect(x, y, 0.2, -0.04, 0.4, 0.04) ||
              _seg(x, y, 0, -0.2, 0, -0.6, 0.03) ||
              _ell(x, y, 0, -0.7, 0.15, 0.1);

        case 'Starburst':
          return _star(x, y, points: 12);

        case 'Crystal':
          return _poly(x, y, [
                (-0.2, 0.95),
                (-0.28, -0.2),
                (0, -0.98),
                (0.28, -0.2),
                (0.2, 0.95),
              ]) ||
              _poly(ax, y, [
                (0.15, 0.95),
                (0.3, 0.0),
                (0.55, -0.4),
                (0.8, 0.0),
                (0.85, 0.95),
              ]);

        case 'Galaxy':
          return r <= 0.95 &&
              (r < 0.2 || math.cos(2 * (angle - r * 3.5)) > 0.4);

        default:
          return r < 0.8;
      }
    };
  }
}
