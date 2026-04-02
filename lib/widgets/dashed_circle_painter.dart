// ==============================
// DASHED CIRCLE PAINTER
// Custom painter that draws 4 evenly-spaced arc segments
// to create a dashed-circle indicator around a selectable pawn.
// Rotated by _rotationController for a spinning effect.
// ==============================

import 'dart:math' as math;

import 'package:flutter/material.dart';

class DashedCirclePainter extends CustomPainter {
  final Color color;

  DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;

    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      // Change stroke thickness here (currently 2.5).
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromCircle(
      center: Offset(radius, radius),
      radius: radius,
    );

    // Change number of arc segments here (currently 4).
    for (int i = 0; i < 4; i++) {
      // Change arc gap (start offset) here — currently π/12.
      final double startAngle = (math.pi / 2) * i + (math.pi / 12);
      // Change arc dash length (sweep) here — currently π/3.
      const double sweepAngle = math.pi / 3;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
