import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ludo_game/models/portals.dart';

/// ==============================
/// PORTAL WIDGET
/// Animated portal visual used on board tiles
/// ==============================

class PortalWidget extends StatefulWidget {
  final PortalType type;
  final int remainingTurns;

  const PortalWidget({
    super.key,
    required this.type,
    required this.remainingTurns,
  });

  @override
  State<PortalWidget> createState() => _PortalWidgetState();
}

class _PortalWidgetState extends State<PortalWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// ==============================
  /// LIFECYCLE
  /// ==============================

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ==============================
  /// HELPERS
  /// ==============================

  Color getColor() {
    switch (widget.type) {
      case PortalType.blue:
        return Colors.blue;

      case PortalType.red:
        return Colors.red;

      case PortalType.purple:
        return Colors.purple;
    }
  }

  /// ==============================
  /// UI
  /// ==============================

  @override
  Widget build(BuildContext context) {
    final color = getColor();

    return Stack(
      alignment: Alignment.center,
      children: [
        _buildOuterGlow(color),
        _buildRotatingRing(color),
        _buildInnerCore(color),
        _buildTurnIndicators(), // optional
      ],
    );
  }

  /// ==============================
  /// LAYERS
  /// ==============================

  Widget _buildOuterGlow(Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildRotatingRing(Color color) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: const Size(20, 20),
        painter: _PortalRingPainter(color: color),
      ),
    );
  }

  Widget _buildInnerCore(Color color) {
    return Container(
      width: 15,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }

  /// Optional visual indicator for portal lifetime
  Widget _buildTurnIndicators() {
    return Stack(
      children: List.generate(widget.remainingTurns, (index) {
        final angle = (2 * math.pi / 5) * index;

        return Transform.translate(
          offset: Offset(14 * math.cos(angle), 14 * math.sin(angle)),
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

/// ==============================
/// PORTAL RING PAINTER
/// ==============================

class _PortalRingPainter extends CustomPainter {
  final Color color;

  _PortalRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    for (int i = 0; i < 3; i++) {
      final startAngle = (2 * math.pi / 3) * i;
      const sweepAngle = math.pi / 3;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PortalRingPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
