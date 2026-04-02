import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/models/portals.dart';
import 'package:ludo_game/utils/board_coordinates.dart';

// ==============================
// LUDO BOARD PAINTER
// A CustomPainter that draws the entire static Ludo board.
//
// Drawing order (painter's algorithm — back to front):
//   1. White background fill.
//   2. Four colored player base rectangles.
//   3. Home pawn slots (ghost circles in each base).
//   4. Center square outline.
//   5. Center colored triangles (4 win zones).
//   6. Home-stretch colored arms (the 5-cell colored lanes).
//   7. Safe-zone star markers.
//   8. Path grid lines.
//
// The board is always square. All sizes derive from:
//   cellSize = size.width / 15
// so it scales to any canvas width automatically.
// ADJUSTABLE: Change board grid resolution by changing the divisor (currently 15).
// ==============================

class LudoBoardPainter extends CustomPainter {
  final List<Portals> portals;
  final String portalState;

  LudoBoardPainter({this.portals = const [], this.portalState = ''});

  @override
  void paint(Canvas canvas, Size size) {
    // Derive cell size from canvas width. The board is 15×15 cells.
    // Change board grid column/row count here (currently 15).
    final double cellSize = size.width / 15;

    final Paint fillPaint = Paint()..style = PaintingStyle.fill;

    // ─── 1. BACKGROUND ───
    // Fill entire canvas white so transparent cells don't show the screen background.
    fillPaint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fillPaint);

    // Stroke paint used throughout for cell outlines and borders.
    // Change board outline color and thickness here.
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 1;

    // ─── 2. PLAYER BASES ───
    // Each base occupies a 6×6 cell area in one of the four corners.
    // ADJUSTABLE: Corner positions are multiples of 9 * cellSize (board width - 6 cells).

    // Top-left: Green
    _drawBase(canvas, 0, 0, Colors.green, cellSize, fillPaint, strokePaint);

    // Top-right: Yellow
    _drawBase(
      canvas,
      9 * cellSize,
      0,
      Colors.yellow,
      cellSize,
      fillPaint,
      strokePaint,
    );

    // Bottom-left: Red
    _drawBase(
      canvas,
      0,
      9 * cellSize,
      Colors.red,
      cellSize,
      fillPaint,
      strokePaint,
    );

    // Bottom-right: Blue
    _drawBase(
      canvas,
      9 * cellSize,
      9 * cellSize,
      Colors.blue,
      cellSize,
      fillPaint,
      strokePaint,
    );

    // ─── 3. HOME PAWN SLOTS ───
    // Ghost circles drawn inside each base to show where pawns rest.
    _drawHomePawnSlots(canvas, size);

    // ─── 4 & 5. CENTER AREA ───
    // Draws the center square outline and the 4 colored win triangles inside it.
    _drawCenter(canvas, cellSize, fillPaint, strokePaint);
    _drawCenterTriangles(canvas, size, strokePaint);

    // ─── 6. HOME-STRETCH COLORED ARMS ───
    // The 5-cell colored lanes leading inward from each side to the center.
    _drawHomeStretches(canvas, cellSize, fillPaint);

    // ─── 7. SAFE-ZONE STAR MARKERS ───
    // Colored star icons on the 8 safe-zone cells.
    _drawSafeZones(canvas, cellSize, fillPaint);

    // ─── 8. PATH GRID LINES ───
    // Outlines the individual path cells, skipping base and center regions.
    _drawPathGride(canvas, cellSize, strokePaint);

    // ─── 9. PORTALS ───
    _drawPortals(canvas, cellSize);
  }

  // ==============================
  // SAFE ZONES
  // ==============================

  /// Draws colored star icons on the 8 safe-zone cells of the main path.
  ///
  /// Safe-zone index mapping (based on BoardCoordinates.mainPath):
  ///   Index  0 → Green Start  (1,6)
  ///   Index  8 → Green Star   (2,8)
  ///   Index 13 → Yellow Start (8,1)
  ///   Index 21 → Yellow Star  (6,2)
  ///   Index 26 → Blue Start   (13,8)
  ///   Index 34 → Blue Star    (12,6)
  ///   Index 39 → Red Start    (6,13)
  ///   Index 47 → Red Star     (8,12)
  void _drawSafeZones(Canvas canvas, double cellSize, Paint fill) {
    final Map<Color, List<Offset>> safeZoneOffsets = {
      Colors.green: [
        const Offset(1, 6), // index 0  — Green Start
        const Offset(2, 8), // index 8  — Green Star
      ],
      Colors.yellow.shade700: [
        const Offset(8, 1), // index 13 — Yellow Start
        const Offset(6, 2), // index 21 — Yellow Star
      ],
      Colors.blue: [
        const Offset(13, 8), // index 26 — Blue Start
        const Offset(12, 6), // index 34 — Blue Star
      ],
      Colors.red: [
        const Offset(6, 13), // index 39 — Red Start
        const Offset(8, 12), // index 47 — Red Star
      ],
    };

    safeZoneOffsets.forEach((color, offsets) {
      fill.color = color;
      for (var offset in offsets) {
        _drawStar(
          canvas,
          offset.dx * cellSize + (cellSize / 2), // center X of the cell
          offset.dy * cellSize + (cellSize / 2), // center Y of the cell
          //  Change star radius relative to cell here (currently cellSize * 0.35).
          cellSize * 0.35,
          fill,
        );
      }
    });
  }

  // ==============================
  // STAR SHAPE HELPER
  // ==============================

  /// Draws a 6-pointed star polygon centered at ([cx], [cy]) with outer [radius].
  ///
  /// Algorithm:
  ///   - Alternates between outer and inner radius at each of 12 vertex positions.
  ///   - Inner radius = radius / 2 (giving a classic star proportion).
  ///   - Starts pointing straight up (rotation = -π/2).
  void _drawStar(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    Paint paint,
  ) {
    Path path = Path();
    //  Change number of star points here (currently 6).
    int points = 6;
    //  Change inner radius ratio here (currently radius / 2).
    double innerRadius = radius / 2;
    double rotation = -math.pi / 2; // Start angle: pointing straight up.
    double step = math.pi / points; // Angle between each vertex.

    path.moveTo(
      cx + radius * math.cos(rotation),
      cy + radius * math.sin(rotation),
    );

    // Alternate outer/inner radius for each of the 12 vertices.
    for (int i = 1; i < points * 2; i++) {
      double r = (i.isEven) ? radius : innerRadius;
      double theta = rotation + (i * step);
      path.lineTo(cx + r * math.cos(theta), cy + r * math.sin(theta));
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  // ==============================
  // HOME STRETCHES (COLORED ARMS)
  // ==============================

  /// Draws the 5-cell colored lanes that lead from the main path into the center.
  /// Each arm points toward the center from one side of the board.
  ///
  ///   Green  → horizontal arm on row 7, columns 1–5  (left side).
  ///   Yellow → vertical arm on column 7, rows 1–5    (top side).
  ///   Blue   → horizontal arm on row 7, columns 9–13 (right side).
  ///   Red    → vertical arm on column 7, rows 9–13   (bottom side).
  void _drawHomeStretches(Canvas canvas, double cellSize, Paint fill) {
    // ─── Green (Left Arm) ───
    fill.color = Colors.green.withValues(alpha: 1);
    for (int i = 1; i <= 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * cellSize, 7 * cellSize, cellSize, cellSize),
        fill,
      );
    }

    // ─── Yellow (Top Arm) ───
    fill.color = Colors.yellow;
    for (int i = 1; i <= 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(7 * cellSize, i * cellSize, cellSize, cellSize),
        fill,
      );
    }

    // ─── Blue (Right Arm) ───
    fill.color = Colors.blue.withValues(alpha: 1);
    for (int i = 9; i <= 13; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * cellSize, 7 * cellSize, cellSize, cellSize),
        fill,
      );
    }

    // ─── Red (Bottom Arm) ───
    fill.color = Colors.red.withValues(alpha: 1);
    for (int i = 9; i <= 13; i++) {
      canvas.drawRect(
        Rect.fromLTWH(7 * cellSize, i * cellSize, cellSize, cellSize),
        fill,
      );
    }
  }

  // ==============================
  // PLAYER BASE
  // ==============================

  /// Draws a single player's 6×6 base area at position ([x], [y]).
  ///
  /// Structure:
  ///   - Outer colored rectangle (6×6 cells).
  ///   - Inner white rectangle inset by 1 cell on each side (4×4 cells).
  void _drawBase(
    Canvas canvas,
    double x,
    double y,
    Color color,
    double cellSize,
    Paint fill,
    Paint stroke,
  ) {
    // ─── Outer Colored Box ───
    //  Change base size here relative to cell count (currently 6×6 cells).
    fill.color = color;
    Rect baseRect = Rect.fromLTWH(x, y, cellSize * 6, cellSize * 6);
    canvas.drawRect(baseRect, fill);
    canvas.drawRect(baseRect, stroke);

    // ─── Inner White Box ───
    // Inset 1 cell on each edge, giving a colored border around the white interior.
    // Change inner white box inset here (currently 1 cell = cellSize * 1).
    fill.color = Colors.white;
    Rect innerRect = Rect.fromLTWH(
      x + cellSize,
      y + cellSize,
      cellSize * 4,
      cellSize * 4,
    );
    canvas.drawRect(innerRect, fill);
    canvas.drawRect(innerRect, stroke);
  }

  // ==============================
  // CENTER SQUARE
  // ==============================

  /// Draws the outline of the 3×3-cell center square (the finishing area).
  /// The colored triangles are drawn on top of this by _drawCenterTriangles.
  void _drawCenter(Canvas canvas, double cellSize, Paint fill, Paint stroke) {
    // Center square occupies columns 6–8 and rows 6–8 (3×3 cells).
    Rect centerRect = Rect.fromLTWH(
      cellSize * 6,
      cellSize * 6,
      cellSize * 3,
      cellSize * 3,
    );
    canvas.drawRect(centerRect, stroke);
  }

  // ==============================
  // PATH GRID
  // ==============================

  /// Draws a 1-cell rectangular outline for every path cell on the board,
  /// skipping the 4 base corners and the 3×3 center square.
  ///
  /// Skipped regions (i = column, j = row):
  ///   - Top-left base:     i < 6  && j < 6
  ///   - Top-right base:    i > 8  && j < 6
  ///   - Bottom-left base:  i < 6  && j > 8
  ///   - Bottom-right base: i > 8  && j > 8
  ///   - Center:            6 ≤ i ≤ 8 && 6 ≤ j ≤ 8
  void _drawPathGride(Canvas canvas, double cellSize, Paint stroke) {
    for (int i = 0; i < 15; i++) {
      for (int j = 0; j < 15; j++) {
        bool isTopLeftBase = i < 6 && j < 6;
        bool isTopRightBase = i > 8 && j < 6;
        bool isBottomLeftBase = i < 6 && j > 8;
        bool isBottomRightBase = i > 8 && j > 8;
        bool isCenter = i >= 6 && i <= 8 && j >= 6 && j <= 8;

        if (!isTopLeftBase &&
            !isTopRightBase &&
            !isBottomRightBase &&
            !isBottomLeftBase &&
            !isCenter) {
          Rect cellRect = Rect.fromLTWH(
            i * cellSize,
            j * cellSize,
            cellSize,
            cellSize,
          );
          canvas.drawRect(cellRect, stroke);
        }
      }
    }
  }

  // ==============================
  // HOME PAWN SLOTS
  // ==============================

  /// Draws ghost-circle slot indicators inside each player's base,
  /// showing where pawns sit at rest before entering the game.
  ///
  /// Uses a temporary Pawn with PawnState.inBase to compute physical positions,
  /// then draws a semi-transparent white circle with a faint border.
  void _drawHomePawnSlots(Canvas canvas, Size size) {
    final double cell = size.width / 15;

    //  Change home slot pawn-slot circle size here (currently cell * 0.9).
    final double pawnSize = cell * 0.9;
    final double padding = (cell - pawnSize) / 2;
    final double slotRadius = pawnSize / 2;

    // Change home slot fill opacity here (currently 0.35).
    final Paint fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    //  Change home slot border opacity and thickness here.
    final Paint borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Iterate all 4 colors × 4 pawns.
    for (final color in PlayerColor.values) {
      for (int i = 0; i < 4; i++) {
        // Create a dummy pawn to get the base position from BoardCoordinates.
        final Pawn tempPawn = Pawn(
          id: i,
          color: color,
          state: PawnState.inBase,
        );

        final Offset pos = BoardCoordinates.getPhysicalLocation(size, tempPawn);

        // Compute the center of the slot circle.
        final Offset center = Offset(
          pos.dx + padding + pawnSize / 2,
          pos.dy + padding + pawnSize / 2,
        );

        canvas.drawCircle(center, slotRadius, fillPaint);
        canvas.drawCircle(center, slotRadius, borderPaint);
      }
    }
  }

  // ==============================
  // CENTER WIN TRIANGLES
  // ==============================

  /// Draws the 4 colored triangles inside the center square.
  /// Each triangle points from the center outward to one side,
  /// matching the color of the player whose home stretch it connects to.
  ///
  ///   Left  triangle → Green  (connects to left/green home stretch)
  ///   Top   triangle → Yellow (connects to top/yellow home stretch)
  ///   Right triangle → Blue   (connects to right/blue home stretch)
  ///   Bottom triangle → Red   (connects to bottom/red home stretch)
  ///
  /// All 4 triangles share the same center point and have equal base widths.
  /// ADJUSTABLE: Change triangle size by adjusting the cell multiplier (currently 1.5).
  void _drawCenterTriangles(Canvas canvas, Size size, Paint strokePaint) {
    final double cell = size.width / 15;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint greenPaint = Paint()..color = Colors.green;
    final Paint yellowPaint = Paint()..color = Colors.yellow;
    final Paint bluePaint = Paint()..color = Colors.blue;
    final Paint redPaint = Paint()..color = Colors.red;

    // ─── Top Triangle (Yellow) ───
    // Apex at center, base at top edge of center square.
    final Path topPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx - cell * 1.5, center.dy - cell * 1.5)
      ..lineTo(center.dx + cell * 1.5, center.dy - cell * 1.5)
      ..close();

    // ─── Right Triangle (Blue) ───
    // Apex at center, base at right edge of center square.
    final Path rightPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx + cell * 1.5, center.dy - cell * 1.5)
      ..lineTo(center.dx + cell * 1.5, center.dy + cell * 1.5)
      ..close();

    // ─── Bottom Triangle (Red) ───
    // Apex at center, base at bottom edge of center square.
    final Path bottomPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx + cell * 1.5, center.dy + cell * 1.5)
      ..lineTo(center.dx - cell * 1.5, center.dy + cell * 1.5)
      ..close();

    // ─── Left Triangle (Green) ───
    // Apex at center, base at left edge of center square.
    final Path leftPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx - cell * 1.5, center.dy + cell * 1.5)
      ..lineTo(center.dx - cell * 1.5, center.dy - cell * 1.5)
      ..close();

    // Fill first, then draw stroke on top for visibility.
    canvas.drawPath(leftPath, greenPaint);
    canvas.drawPath(topPath, yellowPaint);
    canvas.drawPath(rightPath, bluePaint);
    canvas.drawPath(bottomPath, redPaint);

    canvas.drawPath(leftPath, strokePaint);
    canvas.drawPath(topPath, strokePaint);
    canvas.drawPath(rightPath, strokePaint);
    canvas.drawPath(bottomPath, strokePaint);
  }

  // ==============================
  // PORTAL DRAWING
  // ==============================

  void _drawPortals(Canvas canvas, double cellSize) {
    if (portals.isEmpty) return;

    for (var portal in portals) {
      final Color portalColor = _getPortalColor(portal.type);
      final Offset posA = _getGridOffset(portal.a);
      final Offset posB = _getGridOffset(portal.b);

      final Offset centerA = Offset(
        posA.dx * cellSize + cellSize / 2,
        posA.dy * cellSize + cellSize / 2,
      );
      final Offset centerB = Offset(
        posB.dx * cellSize + cellSize / 2,
        posB.dy * cellSize + cellSize / 2,
      );

      // 1. Draw dashed connecting line between A and B
      final paintLine = Paint()
        ..color = portalColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      _drawDashedLine(canvas, centerA, centerB, paintLine);
      // (Static dots removed: now drawn by animated PortalWidgets in LudoScreen)
    }
  }

  Color _getPortalColor(PortalType type) {
    switch (type) {
      case PortalType.blue:
        return Colors.blue;
      case PortalType.red:
        return Colors.red;
      case PortalType.purple:
        return Colors.purple;
    }
  }

  Offset _getGridOffset(int absoluteIndex) {
    return BoardCoordinates.mainPath[absoluteIndex % 52];
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 5.0;
    const double dashSpace = 3.0;

    double distance = (p2 - p1).distance;
    Offset direction = (p2 - p1) / distance;

    double currentDist = 0;
    while (currentDist < distance) {
      canvas.drawLine(
        p1 + direction * currentDist,
        p1 + direction * (math.min(currentDist + dashWidth, distance)),
        paint,
      );
      currentDist += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant LudoBoardPainter oldDelegate) {
    // Repaint when the unique derived state string of portals changes
    return portalState != oldDelegate.portalState;
  }
}
