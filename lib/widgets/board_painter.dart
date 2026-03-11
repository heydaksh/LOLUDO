import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/utils/board_coordinates.dart';

class LudoBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cellSize = size.width / 15;
    final Paint fillPaint = Paint()..style = PaintingStyle.fill;

    // Fill the whole board with white so the screen background doesn't show through transparent cells
    fillPaint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fillPaint);

    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 0.5;

    // Draw the 4 main player bases

    _drawBase(canvas, 0, 0, Colors.green, cellSize, fillPaint, strokePaint);
    _drawBase(
      canvas,
      9 * cellSize,
      0,
      Colors.yellow,
      cellSize,
      fillPaint,
      strokePaint,
    );
    _drawBase(
      canvas,
      0,
      9 * cellSize,
      Colors.red,
      cellSize,
      fillPaint,
      strokePaint,
    );
    _drawBase(
      canvas,
      9 * cellSize,
      9 * cellSize,
      Colors.blue,
      cellSize,
      fillPaint,
      strokePaint,
    );
    _drawHomePawnSlots(canvas, size);

    // draw center triangles and outline
    _drawCenter(canvas, cellSize, fillPaint, strokePaint);
    _drawCenterTriangles(canvas, size, strokePaint);

    //draw colored winning lines
    _drawHomeStretches(canvas, cellSize, fillPaint);
    // draw colored safe zones
    _drawSafeZones(canvas, cellSize, fillPaint);
    // draw path grid
    _drawPathGride(canvas, cellSize, strokePaint);
  }

  void _drawSafeZones(Canvas canvas, double cellSize, Paint fill) {
    // 0: Green Start, 8: Green Star
    // 13: Yellow Start, 21: Yellow Star
    // 26: Blue Start, 34: Blue Star
    // 39: Red Start, 47: Red Star

    // Getting the full path from BoardCoordinates
    // We don't want to redefine mainPath here, so we'll access it directly if we import it,
    // or just hardcode the 8 offsets if we don't want cross-dependencies. For cleaner code,
    // let's use the exact grid coordinates for these 8 spots based on BoardCoordinates.mainPath.

    final Map<Color, List<Offset>> safeZoneOffsets = {
      Colors.green: [
        const Offset(1, 6), // index 0
        const Offset(2, 8), // index 8
      ],
      Colors.yellow.shade700: [
        const Offset(8, 1), // index 13
        const Offset(6, 2), // index 21
      ],
      Colors.blue: [
        const Offset(13, 8), // index 26
        const Offset(12, 6), // index 34
      ],
      Colors.red: [
        const Offset(6, 13), // index 39
        const Offset(8, 12), // index 47
      ],
    };

    safeZoneOffsets.forEach((color, offsets) {
      fill.color = color;
      for (var offset in offsets) {
        _drawStar(
          canvas,
          offset.dx * cellSize + (cellSize / 2),
          offset.dy * cellSize + (cellSize / 2),
          cellSize * 0.35, // radius of star
          fill,
        );
      }
    });
  }

  void _drawStar(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    Paint paint,
  ) {
    Path path = Path();
    int points = 6;
    double innerRadius = radius / 2;
    double rotation = -math.pi / 2; // start pointing straight up
    double step = math.pi / points;

    path.moveTo(
      cx + radius * math.cos(rotation),
      cy + radius * math.sin(rotation),
    );

    for (int i = 1; i < points * 2; i++) {
      double r = (i.isEven) ? radius : innerRadius;
      double theta = rotation + (i * step);

      path.lineTo(cx + r * math.cos(theta), cy + r * math.sin(theta));
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHomeStretches(Canvas canvas, double cellSize, Paint fill) {
    // left arm - green
    fill.color = Colors.green.withValues(alpha: 1);
    for (int i = 1; i <= 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * cellSize, 7 * cellSize, cellSize, cellSize),
        fill,
      );
    }

    // Top Arm (Yellow )
    fill.color = Colors.yellow.shade700.withValues(alpha: 1);
    for (int i = 1; i <= 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(7 * cellSize, i * cellSize, cellSize, cellSize),
        fill,
      );
    }

    // Right Arm (Blue)
    fill.color = Colors.blue.withValues(alpha: 1);
    for (int i = 9; i <= 13; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * cellSize, 7 * cellSize, cellSize, cellSize),
        fill,
      );
    }

    // Bottom Arm (Red)
    fill.color = Colors.red.withValues(alpha: 1);
    for (int i = 9; i <= 13; i++) {
      canvas.drawRect(
        Rect.fromLTWH(7 * cellSize, i * cellSize, cellSize, cellSize),
        fill,
      );
    }
  }

  void _drawBase(
    Canvas canvas,
    double x,
    double y,
    Color color,
    double cellSize,
    Paint fill,
    Paint stroke,
  ) {
    // outer colored box
    fill.color = color;
    Rect baseRect = Rect.fromLTWH(x, y, cellSize * 6, cellSize * 6);
    canvas.drawRect(baseRect, fill);
    canvas.drawRect(baseRect, stroke);

    // Inner white box
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

  void _drawCenter(Canvas canvas, double cellSize, Paint fill, Paint stroke) {
    // the center finish area
    Rect centerRect = Rect.fromLTWH(
      cellSize * 6,
      cellSize * 6,
      cellSize * 3,
      cellSize * 3,
    );

    canvas.drawRect(centerRect, stroke);
  }

  void _drawPathGride(Canvas canvas, double cellSize, Paint stroke) {
    for (int i = 0; i < 15; i++) {
      for (int j = 0; j < 15; j++) {
        //skip the bases and centers only draw grid lines on the paths
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

  void _drawHomePawnSlots(Canvas canvas, Size size) {
    final double cell = size.width / 15;

    final double pawnSize = cell * 0.9;
    final double padding = (cell - pawnSize) / 2;
    final double slotRadius = pawnSize / 2;

    final Paint fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (final color in PlayerColor.values) {
      for (int i = 0; i < 4; i++) {
        final Pawn tempPawn = Pawn(
          id: i,
          color: color,
          state: PawnState.inBase,
        );

        final Offset pos = BoardCoordinates.getPhysicalLocation(size, tempPawn);

        final Offset center = Offset(
          pos.dx + padding + pawnSize / 2,
          pos.dy + padding + pawnSize / 2,
        );

        canvas.drawCircle(center, slotRadius, fillPaint);
        canvas.drawCircle(center, slotRadius, borderPaint);
      }
    }
  }

  //  4 triangles in the center.

  void _drawCenterTriangles(Canvas canvas, Size size, Paint strokePaint) {
    final double cell = size.width / 15;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint greenPaint = Paint()..color = Colors.green;
    final Paint yellowPaint = Paint()..color = Colors.yellow.shade700;
    final Paint bluePaint = Paint()..color = Colors.blue;
    final Paint redPaint = Paint()..color = Colors.red;

    // Top triangle (Yellow)
    final Path topPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx - cell * 1.5, center.dy - cell * 1.5)
      ..lineTo(center.dx + cell * 1.5, center.dy - cell * 1.5)
      ..close();

    // Right triangle (Blue)
    final Path rightPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx + cell * 1.5, center.dy - cell * 1.5)
      ..lineTo(center.dx + cell * 1.5, center.dy + cell * 1.5)
      ..close();

    // Bottom triangle (Red)
    final Path bottomPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx + cell * 1.5, center.dy + cell * 1.5)
      ..lineTo(center.dx - cell * 1.5, center.dy + cell * 1.5)
      ..close();

    // Left triangle (Green)
    final Path leftPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx - cell * 1.5, center.dy + cell * 1.5)
      ..lineTo(center.dx - cell * 1.5, center.dy - cell * 1.5)
      ..close();

    canvas.drawPath(leftPath, greenPaint);
    canvas.drawPath(topPath, yellowPaint);
    canvas.drawPath(rightPath, bluePaint);
    canvas.drawPath(bottomPath, redPaint);

    canvas.drawPath(leftPath, strokePaint);
    canvas.drawPath(topPath, strokePaint);
    canvas.drawPath(rightPath, strokePaint);
    canvas.drawPath(bottomPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
