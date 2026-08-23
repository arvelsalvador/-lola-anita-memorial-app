import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/controllers/display_controller.dart';
import 'package:nita/controllers/family_controller.dart';
import 'package:nita/models/family_model.dart';
import 'package:nita/views/family_page.dart' show showMemberDetailSheet;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

/// Fixed geometry for the canvas: card sizes, row heights, spacing.
/// Everything else is computed from these plus the member counts.
class _TreeLayout {
  static const double rootWidth = 220;
  static const double rootHeight = 96;
  static const double nodeWidth = 130;
  static const double nodeHeight = 92;
  static const double columnGap = 20;
  static const double rowGap = 90;
  static const double canvasPadding = 60;
}

/// One computed node: a member plus its resolved (x, y) position and
/// size, ready to paint/place on the canvas.
class _TreeNode {
  final FamilyMember member;
  final Rect rect;
  final bool isRoot;
  const _TreeNode(this.member, this.rect, {this.isRoot = false});
}

/// One connector line between two node centers (drawn as elbow: down from
/// parent, across, down into child — matching the org-chart look).
class _TreeEdge {
  final Offset from;
  final Offset to;
  const _TreeEdge(this.from, this.to);
}

class FamilyTreeCanvasPage extends StatefulWidget {
  const FamilyTreeCanvasPage({super.key});

  @override
  State<FamilyTreeCanvasPage> createState() => _FamilyTreeCanvasPageState();
}

class _FamilyTreeCanvasPageState extends State<FamilyTreeCanvasPage> {
  final TransformationController _transform = TransformationController();

  late final List<_TreeNode> _nodes;
  late final List<_TreeEdge> _edges;
  late final List<_TreeEdge> _siblingEdges;
  late final Size _canvasSize;

  @override
  void initState() {
    super.initState();
    _buildLayout();
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  /// Computes every node's fixed position once, up front. Root sits at
  /// top-center; the "children" group forms row 2, evenly spaced; each
  /// child's own grandchildren (matched via parentName) sit in row 3
  /// directly under that child. Grandchildren without a matching
  /// parentName are collected into one shared trailing branch.
  void _buildLayout() {
    final data = FamilyController.data;
    final childrenGroup = data.groups.firstWhere(
      (g) => g.labelKey == 'family_group_children',
      orElse: () => const FamilyGroup(
        labelKey: '',
        subtitleKey: '',
        count: 0,
        members: [],
      ),
    );
    final siblingsGroup = data.groups.firstWhere(
      (g) => g.labelKey == 'family_group_siblings',
      orElse: () => const FamilyGroup(
        labelKey: '',
        subtitleKey: '',
        count: 0,
        members: [],
      ),
    );
    final apoGroup = data.groups.firstWhere(
      (g) => g.labelKey == 'family_group_grandchildren',
      orElse: () => const FamilyGroup(
        labelKey: '',
        subtitleKey: '',
        count: 0,
        members: [],
      ),
    );

    final children = childrenGroup.members;
    final nodes = <_TreeNode>[];
    final edges = <_TreeEdge>[];
    final siblingPeerEdges = <_TreeEdge>[];

    // ── Row 1: root, centered ────────────────────────────────────────
    // Total canvas width is driven by row 2 (whichever is widest), so we
    // compute row 2 first, then center the root over it.
    final apoByParent = <String, List<FamilyMember>>{};
    final unlinkedApo = <FamilyMember>[];
    for (final apo in apoGroup.members) {
      if (apo.parentName != null &&
          children.any((c) => c.name == apo.parentName)) {
        apoByParent.putIfAbsent(apo.parentName!, () => []).add(apo);
      } else {
        unlinkedApo.add(apo);
      }
    }

    // Each child's column width is driven by however many of their own
    // grandchildren need to fit side by side under them.
    final childColumnWidths = <double>[];
    for (final child in children) {
      final apoCount = apoByParent[child.name]?.length ?? 0;
      final apoRowWidth = apoCount == 0
          ? _TreeLayout.nodeWidth
          : apoCount * _TreeLayout.nodeWidth +
                (apoCount - 1) * _TreeLayout.columnGap;
      childColumnWidths.add(
        apoRowWidth < _TreeLayout.nodeWidth
            ? _TreeLayout.nodeWidth
            : apoRowWidth,
      );
    }

    final row2TotalWidth =
        childColumnWidths.fold<double>(0, (a, b) => a + b) +
        (children.isEmpty ? 0 : (children.length - 1) * _TreeLayout.columnGap);
    final unlinkedWidth = unlinkedApo.isEmpty
        ? 0.0
        : unlinkedApo.length * _TreeLayout.nodeWidth +
              (unlinkedApo.length - 1) * _TreeLayout.columnGap;

    const rootRectPlaceholderWidth = _TreeLayout.rootWidth;
    final siblingsRowWidth = siblingsGroup.members.isEmpty
        ? 0.0
        : rootRectPlaceholderWidth +
              _TreeLayout.columnGap * 2 +
              siblingsGroup.members.length * _TreeLayout.nodeWidth +
              (siblingsGroup.members.length - 1) * _TreeLayout.columnGap;

    final canvasWidth =
        [
          row2TotalWidth,
          unlinkedWidth,
          _TreeLayout.rootWidth,
          siblingsRowWidth,
        ].reduce((a, b) => a > b ? a : b) +
        _TreeLayout.canvasPadding * 2;

    double cursorX = _TreeLayout.canvasPadding;
    final row1Y = _TreeLayout.canvasPadding;
    final row2Y = row1Y + _TreeLayout.rootHeight + _TreeLayout.rowGap;
    final row3Y = row2Y + _TreeLayout.nodeHeight + _TreeLayout.rowGap;

    final rootRect = Rect.fromLTWH(
      (canvasWidth - _TreeLayout.rootWidth) / 2,
      row1Y,
      _TreeLayout.rootWidth,
      _TreeLayout.rootHeight,
    );
    nodes.add(_TreeNode(data.rootMember, rootRect, isRoot: true));

    // Siblings sit beside the root at the SAME row (peers, not
    // descendants) — placed to the right of the root card, connected by
    // a horizontal peer line instead of a parent→child elbow.
    double siblingCursorX = rootRect.right + _TreeLayout.columnGap * 2;
    Offset? lastSiblingCenter;
    for (final sibling in siblingsGroup.members) {
      final siblingRect = Rect.fromLTWH(
        siblingCursorX,
        row1Y + (_TreeLayout.rootHeight - _TreeLayout.nodeHeight) / 2,
        _TreeLayout.nodeWidth,
        _TreeLayout.nodeHeight,
      );
      nodes.add(_TreeNode(sibling, siblingRect));
      siblingPeerEdges.add(
        _TreeEdge(
          lastSiblingCenter ?? Offset(rootRect.right, rootRect.center.dy),
          Offset(siblingRect.left, siblingRect.center.dy),
        ),
      );
      lastSiblingCenter = Offset(siblingRect.right, siblingRect.center.dy);
      siblingCursorX += _TreeLayout.nodeWidth + _TreeLayout.columnGap;
    }

    double maxY = row2Y + _TreeLayout.nodeHeight;

    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final colWidth = childColumnWidths[i];
      final childRect = Rect.fromLTWH(
        cursorX + (colWidth - _TreeLayout.nodeWidth) / 2,
        row2Y,
        _TreeLayout.nodeWidth,
        _TreeLayout.nodeHeight,
      );
      nodes.add(_TreeNode(child, childRect));
      edges.add(
        _TreeEdge(
          Offset(rootRect.center.dx, rootRect.bottom),
          Offset(childRect.center.dx, childRect.top),
        ),
      );

      final childApos = apoByParent[child.name] ?? const [];
      for (var j = 0; j < childApos.length; j++) {
        final apoRect = Rect.fromLTWH(
          cursorX + j * (_TreeLayout.nodeWidth + _TreeLayout.columnGap),
          row3Y,
          _TreeLayout.nodeWidth,
          _TreeLayout.nodeHeight,
        );
        nodes.add(_TreeNode(childApos[j], apoRect));
        edges.add(
          _TreeEdge(
            Offset(childRect.center.dx, childRect.bottom),
            Offset(apoRect.center.dx, apoRect.top),
          ),
        );
        maxY = row3Y + _TreeLayout.nodeHeight;
      }

      cursorX += colWidth + _TreeLayout.columnGap;
    }

    // ── Unlinked grandchildren: one shared trailing branch off the root ──
    if (unlinkedApo.isNotEmpty) {
      final unlinkedRowY = maxY + _TreeLayout.rowGap;
      final startX = (canvasWidth - unlinkedWidth) / 2;
      for (var j = 0; j < unlinkedApo.length; j++) {
        final apoRect = Rect.fromLTWH(
          startX + j * (_TreeLayout.nodeWidth + _TreeLayout.columnGap),
          unlinkedRowY,
          _TreeLayout.nodeWidth,
          _TreeLayout.nodeHeight,
        );
        nodes.add(_TreeNode(unlinkedApo[j], apoRect));
        edges.add(
          _TreeEdge(
            Offset(rootRect.center.dx, rootRect.bottom),
            Offset(apoRect.center.dx, apoRect.top),
          ),
        );
      }
      maxY = unlinkedRowY + _TreeLayout.nodeHeight;
    }

    _nodes = nodes;
    _edges = edges;
    _siblingEdges = siblingPeerEdges;
    _canvasSize = Size(canvasWidth, maxY + _TreeLayout.canvasPadding);
  }

  void _zoomBy(double factor, {Offset? focalPoint}) {
    final matrix = _transform.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    final targetScale = (currentScale * factor).clamp(0.4, 2.5);
    final adjust = targetScale / currentScale;

    // Zoom around a specific screen point (defaults to the viewport
    // center) instead of the canvas's (0,0) corner — otherwise the zoom
    // effect happens far outside whatever you're actually looking at.
    final renderBox = context.findRenderObject() as RenderBox?;
    final viewportCenter =
        focalPoint ??
        (renderBox != null
            ? Offset(renderBox.size.width / 2, renderBox.size.height / 2)
            : Offset.zero);

    final scenePoint = _transform.toScene(viewportCenter);
    final result = matrix.clone()
      ..translate(scenePoint.dx, scenePoint.dy)
      ..scale(adjust)
      ..translate(-scenePoint.dx, -scenePoint.dy);

    _transform.value = result;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.warmDark,
        title: Text(
          lang.t('family_name'),
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            color: AppColors.warmDark,
          ),
        ),
      ),
      body: Stack(
        children: [
          Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent &&
                  HardwareKeyboard.instance.isControlPressed) {
                final zoomIn = event.scrollDelta.dy < 0;
                _zoomBy(zoomIn ? 1.1 : 0.9, focalPoint: event.localPosition);
              }
            },
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.4,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(200),
              child: SizedBox(
                width: _canvasSize.width,
                height: _canvasSize.height,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: _canvasSize,
                      painter: _TreeEdgePainter(_edges),
                    ),
                    CustomPaint(
                      size: _canvasSize,
                      painter: _SiblingEdgePainter(_siblingEdges),
                    ),
                    for (final node in _nodes)
                      Positioned(
                        left: node.rect.left,
                        top: node.rect.top,
                        width: node.rect.width,
                        height: node.rect.height,
                        child: _TreeNodeCard(
                          member: node.member,
                          isRoot: node.isRoot,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 70,
            child: _HintBanner(text: lang.t('family_tree_tap_hint')),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _ZoomControls(
              onZoomOut: () => _zoomBy(0.8),
              onZoomIn: () => _zoomBy(1.25),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws sibling peer-lines as a dashed horizontal stroke, visually
/// distinct from the solid parent→child elbow connectors.
class _SiblingEdgePainter extends CustomPainter {
  final List<_TreeEdge> edges;
  const _SiblingEdgePainter(this.edges);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.rose.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const dashWidth = 5.0;
    const dashGap = 4.0;

    for (final edge in edges) {
      final total = (edge.to - edge.from).distance;
      final direction = (edge.to - edge.from) / total;
      var covered = 0.0;
      while (covered < total) {
        final start = edge.from + direction * covered;
        final end =
            edge.from + direction * (covered + dashWidth).clamp(0, total);
        canvas.drawLine(start, end, paint);
        covered += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SiblingEdgePainter oldDelegate) => false;
}

/// Draws every parent→child elbow connector: down from the parent's
/// bottom-center, across at the midpoint height, down into the child's
/// top-center.
class _TreeEdgePainter extends CustomPainter {
  final List<_TreeEdge> edges;
  const _TreeEdgePainter(this.edges);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (final edge in edges) {
      final midY = (edge.from.dy + edge.to.dy) / 2;
      final path = Path()
        ..moveTo(edge.from.dx, edge.from.dy)
        ..lineTo(edge.from.dx, midY)
        ..lineTo(edge.to.dx, midY)
        ..lineTo(edge.to.dx, edge.to.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TreeEdgePainter oldDelegate) => false;
}

/// One card on the canvas: circular photo (or initials), name, and a
/// small generation label. Root gets a larger, bolder treatment; every
/// card opens the existing member-detail sheet on tap.
class _TreeNodeCard extends StatelessWidget {
  final FamilyMember member;
  final bool isRoot;

  const _TreeNodeCard({required this.member, this.isRoot = false});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final initials = DisplayController.initialsOf(member.name);
    final avatarSize = isRoot ? 56.0 : 44.0;

    return GestureDetector(
      onTap: () => showMemberDetailSheet(context, member),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isRoot ? 16 : 10,
          vertical: isRoot ? 14 : 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isRoot ? 20 : 16),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: isRoot ? 0.5 : 0.25),
            width: isRoot ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFF4EC),
              ),
              child: member.photoPath == null
                  ? Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: isRoot ? 18 : 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.roseDeep,
                        ),
                      ),
                    )
                  : ClipOval(
                      child: Image.asset(
                        member.photoPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: isRoot ? 18 : 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.roseDeep,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              member.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: isRoot ? 15 : 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            if (member.spouseName != null)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  '+ ${member.spouseName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                    color: AppColors.warmMid,
                  ),
                ),
              ),
            if (isRoot)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0DD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    lang.t(member.roleKey),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.roseDeep,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HintBanner extends StatelessWidget {
  final String text;
  const _HintBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0DD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 15, color: AppColors.roseDeep),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 11.5,
                color: AppColors.roseDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  const _ZoomControls({required this.onZoomOut, required this.onZoomIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded),
            color: AppColors.warmDark,
            onPressed: onZoomOut,
          ),
          const Expanded(child: SizedBox()),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            color: AppColors.warmDark,
            onPressed: onZoomIn,
          ),
        ],
      ),
    );
  }
}
