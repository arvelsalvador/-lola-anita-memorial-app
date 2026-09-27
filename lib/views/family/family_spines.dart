part of 'family_page.dart';

/// A short vertical line between two stacked group sections, so "Mga
/// Anak", "Mga Kapatid", "Mga Apo", etc. read as branches hanging off the
/// same root member instead of unconnected blocks. With [bead] set it
/// also carries a hollow junction bead mid-segment — the branch-origin
/// marker under the root card.
class _FamilyGroupConnector extends StatelessWidget {
  /// Segment height; defaults to the standard inter-section spacing.
  final double height;

  /// Whether to draw a hollow bead centered on the line mid-segment.
  final bool bead;

  const _FamilyGroupConnector({this.height = 22, this.bead = false});

  @override
  Widget build(BuildContext context) {
    if (bead) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _SpineBeadPainter()),
      );
    }
    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          width: 1.5,
          color: AppColors.gold.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

/// Paints one spine segment as a center line with a hollow junction bead
/// centered on it — cream fill with a gold ring, sized slightly larger
/// than the bus junction beads because it marks where the whole descent
/// begins.
class _SpineBeadPainter extends CustomPainter {
  static const _strokeWidth = 1.5;

  /// Slightly larger than the branch-point beads on the bus (4.5).
  static const _beadRadius = 5.5;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final center = Offset(cx, size.height / 2);

    canvas.drawLine(
      Offset(cx, 0),
      Offset(cx, size.height),
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.85)
        ..strokeWidth = _strokeWidth,
    );

    canvas.drawCircle(center, _beadRadius, Paint()..color = AppColors.cream);
    canvas.drawCircle(
      center,
      _beadRadius,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _SpineBeadPainter oldDelegate) => false;
}

/// One 1.5px gold line per column, laid out with the same equal-width
/// Expanded cell math as the member card rows, so every line sits
/// exactly under the card centers above and below it at any screen
/// width. Stretches to the available height. [count] limits how many
/// columns actually carry a line — used where the row below has fewer
/// cards than columns, so a line only ever lands on a real card.
class _SpineLines extends StatelessWidget {
  final int columns;

  /// Columns that actually draw a line; defaults to all of them.
  final int count;

  /// Hollow junction bead tangent to the segment's top edge.
  final bool beadTop;

  /// Hollow junction bead tangent to the segment's bottom edge.
  final bool beadBottom;

  const _SpineLines({
    required this.columns,
    int? count,
    this.beadTop = false,
    this.beadBottom = false,
  }) : count = count ?? columns;

  @override
  Widget build(BuildContext context) {
    if (beadTop || beadBottom) {
      return CustomPaint(
        size: Size.infinite,
        painter: _StraightSpinePainter(
          columns: columns,
          count: count,
          beadTop: beadTop,
          beadBottom: beadBottom,
        ),
      );
    }
    return Row(
      children: [
        for (var c = 0; c < columns; c++)
          Expanded(
            child: c < count
                ? Center(
                    child: Container(
                      width: 1.5,
                      height: double.infinity,
                      color: AppColors.gold.withValues(alpha: 0.85),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }
}

/// Paints the straight per-column descent lines with optional hollow
/// junction beads: [columns] equal-width cell centers, [count] of them
/// actually carrying a line, each optionally capped with a bead tangent
/// to the card edge at the top and/or bottom of the segment — the same
/// bead look as the branch connector's bus junctions.
class _StraightSpinePainter extends CustomPainter {
  final int columns;
  final int count;
  final bool beadTop;
  final bool beadBottom;

  _StraightSpinePainter({
    required this.columns,
    required this.count,
    required this.beadTop,
    required this.beadBottom,
  });

  static const _strokeWidth = 1.5;

  /// Same bead size as the branch connector's bus junctions.
  static const _beadRadius = 4.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.85)
      ..strokeWidth = _strokeWidth;

    final cellWidth = size.width / columns;
    for (var c = 0; c < count; c++) {
      final cx = (c + 0.5) * cellWidth;
      canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), paint);
      if (beadTop) {
        _paintBead(canvas, Offset(cx, _beadRadius));
      }
      if (beadBottom) {
        _paintBead(canvas, Offset(cx, size.height - _beadRadius));
      }
    }
  }

  /// Hollow junction bead: cream fill (the page ground, so the line
  /// reads as punched beneath it) with a gold ring matching the line
  /// weight.
  void _paintBead(Canvas canvas, Offset center) {
    canvas.drawCircle(center, _beadRadius, Paint()..color = AppColors.cream);
    canvas.drawCircle(
      center,
      _beadRadius,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _StraightSpinePainter oldDelegate) =>
      oldDelegate.columns != columns ||
      oldDelegate.count != count ||
      oldDelegate.beadTop != beadTop ||
      oldDelegate.beadBottom != beadBottom;
}

/// Paints vertical spine lines behind [child] — one per column at the
/// grid cell centers ([columns] = 1 gives the classic single center
/// line). Section headers wrap themselves in this so the descent
/// line(s) pass through the header's empty middle and land exactly on
/// the branch connector below instead of stopping short above it.
class _SpineBehind extends StatelessWidget {
  final Widget child;

  /// Number of column-centered lines to draw behind [child].
  final int columns;

  /// Lines actually drawn; defaults to all [columns].
  final int count;

  const _SpineBehind({required this.child, this.columns = 1, int? count})
    : count = count ?? columns;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Painted first so the header content sits on top; the spines
        // stretch to the full stack height, which [child] defines.
        Positioned.fill(
          child: _SpineLines(columns: columns, count: count),
        ),
        child,
      ],
    );
  }
}

/// Org-chart style branch connector that sits directly below a group's
/// section header and above its first row of member cards: a trunk
/// descends from top-center, fans out into a horizontal bus spanning the
/// first-to-last card centers, and drops a short vertical line onto the
/// top-center of each card. Every bus↔drop junction carries a hollow
/// cream bead with a gold ring; the outer beads cap the bus ends. With a
/// single card the bus is skipped and the beaded trunk runs straight
/// through to that card.
///
/// This is THE connector for every parent→children relationship in the
/// family tree — Mga Anak and Mga Kapatid render it through
/// their shared layout paths, and any new group added to
/// FamilyController.data.groups inherits it automatically via
/// [FamilyGroupSection]. A section that renders member cards must place
/// this widget as the first child of its card column; nothing else may
/// draw lines between a header and its cards. (The Mga Apo section draws
/// its own straight per-column descent lines instead — see _SpineLines.)
class _TreeBranchConnector extends StatelessWidget {
  final int cardCount;

  const _TreeBranchConnector({required this.cardCount});

  @override
  Widget build(BuildContext context) {
    if (cardCount <= 0) return const SizedBox.shrink();
    return SizedBox(
      height: 28,
      width: double.infinity,
      child: CustomPaint(painter: _TreeBranchPainter(cardCount: cardCount)),
    );
  }
}

/// Paints the trunk → bus → drops path. Card centers are derived purely
/// from geometry (equal-width cells), so no measuring of the actual
/// cards is needed.
class _TreeBranchPainter extends CustomPainter {
  final int cardCount;

  _TreeBranchPainter({required this.cardCount});

  static const _strokeWidth = 1.5;
  static const _busY = 12.0;

  /// Hollow junction beads sit centered ON every bus↔drop junction (and
  /// on the single-drop trunk), capping the bus ends and marking each
  /// branch point; the cream fill punches the lines out beneath the ring.
  static const _junctionRadius = 4.5;

  /// How far drops extend above the bus centerline so every junction is
  /// a physical overlap (≥1px past the bus's edge) rather than a touch.
  /// The junction beads hide the overlap, but it still guards against
  /// hairline anti-aliasing seams.
  static const _jointOverlap = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      // drawPath defaults to fill — these are strokes.
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final cx = size.width / 2;

    // Trunk, bus, and drops are stroked as ONE continuous path so no two
    // separately-rasterized lines ever merely touch; plus each joint is
    // made to physically overlap by [_jointOverlap] so anti-aliasing can
    // never open a hairline (dark-on-dark-background) gap at a junction.
    final path = Path();

    // Single card: no branching — one straight drop onto it, with its
    // junction bead at the top, where the spine from the header enters.
    if (cardCount == 1) {
      path.moveTo(cx, 0);
      path.lineTo(cx, size.height);
      canvas.drawPath(path, paint);
      _paintBead(canvas, Offset(cx, _junctionRadius));
      return;
    }

    final cellWidth = size.width / cardCount;
    final centers = [for (var i = 0; i < cardCount; i++) (i + 0.5) * cellWidth];

    // The trunk descends from the parent spine and turns onto the bus as
    // one connected stroke (the corner gets a proper miter join).
    path.moveTo(cx, 0);
    path.lineTo(cx, _busY);
    path.lineTo(centers.first, _busY);

    // Walk the bus left→right; each drop dips slightly ABOVE the bus
    // centerline before falling, so trunk/bus/drop overlap through every
    // junction instead of just meeting at an edge.
    for (var i = 0; i < centers.length; i++) {
      if (i == 0) {
        // Continue the trunk subpath into the first drop — one
        // continuous stroke, so the corner can never open a seam.
        path.lineTo(centers.first, _busY - _jointOverlap);
        path.lineTo(centers.first, size.height);
      } else {
        // Straight column: from just above the bus, down to the card.
        path.moveTo(centers[i], _busY - _jointOverlap);
        path.lineTo(centers[i], size.height);
      }
      if (i < centers.length - 1) {
        path.moveTo(centers[i], _busY);
        path.lineTo(centers[i + 1], _busY);
      }
    }
    canvas.drawPath(path, paint);

    // One hollow bead per branch point, each centered exactly ON the bus
    // line so every junction aligns on the same height; the outer beads
    // double as the bus's end caps.
    for (final c in centers) {
      _paintBead(canvas, Offset(c, _busY));
    }
  }

  /// Draws one hollow junction bead: cream fill (the page ground, so the
  /// lines read as punched beneath it) with a gold ring matching the
  /// line weight.
  void _paintBead(Canvas canvas, Offset center) {
    canvas.drawCircle(
      center,
      _junctionRadius,
      Paint()..color = AppColors.cream,
    );
    canvas.drawCircle(
      center,
      _junctionRadius,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _TreeBranchPainter oldDelegate) =>
      oldDelegate.cardCount != cardCount;
}

