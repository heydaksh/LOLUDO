import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ludo_game/models/powers.dart';

/// ==============================
/// POWER WIDGET
/// Animated power visual used on board tiles.
/// Represents things like Freeze, Shield, Reverse, etc.
/// ==============================

class PowerWidget extends StatefulWidget {
  final PowerType type;

  const PowerWidget({
    super.key,
    required this.type,
  });

  @override
  State<PowerWidget> createState() => _PowerWidgetState();
}

class _PowerWidgetState extends State<PowerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ==============================
  /// HELPERS
  /// ==============================

  IconData _getIcon() {
    switch (widget.type) {
      case PowerType.freeze:
        return Icons.ac_unit;
      case PowerType.shield:
        return Icons.shield;
      case PowerType.reverse:
        return Icons.u_turn_left;
      case PowerType.multiplier:
        return Icons.star;
      case PowerType.swap:
        return Icons.swap_calls;
    }
  }

  Color _getColor() {
    switch (widget.type) {
      case PowerType.freeze:
        return Colors.cyan;
      case PowerType.shield:
        return Colors.orange;
      case PowerType.reverse:
        return Colors.purple;
      case PowerType.multiplier:
        return Colors.amber;
      case PowerType.swap:
        return Colors.green;
    }
  }

  /// ==============================
  /// UI
  /// ==============================

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final icon = _getIcon();

    return ScaleTransition(
      scale: _pulseAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Ring
          RotationTransition(
            turns: _controller,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.6),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: CustomPaint(
                painter: _PowerRingPainter(color: color),
              ),
            ),
          ),
          // Icon Core
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerRingPainter extends CustomPainter {
  final Color color;

  _PowerRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw small sparkling arcs
    for (int i = 0; i < 4; i++) {
      final startAngle = (math.pi / 2) * i + (math.pi / 8);
      const sweepAngle = math.pi / 4;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PowerRingPainter oldDelegate) => false;
}
