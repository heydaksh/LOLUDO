import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/providers/game_provider.dart';
import 'package:ludo_game/widgets/dashed_circle_painter.dart';

class PawnVisualsStack extends StatelessWidget {
  final Pawn pawn;
  final double pawnSize;
  final bool showRotatingIndicator;
  final GameProvider game;
  final Animation<double> rotationAnimation;
  final Animation<double> glowAnimation;

  const PawnVisualsStack({
    super.key,
    required this.pawn,
    required this.pawnSize,
    required this.showRotatingIndicator,
    required this.game,
    required this.rotationAnimation,
    required this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // ─── ROTATING SELECTION INDICATOR ───
        if (showRotatingIndicator)
          Positioned(
            // ADJUSTABLE: Change indicator circle size here (pawnSize * 1.3).
            width: pawnSize * 1.3,
            height: pawnSize * 1.3,
            child: AnimatedBuilder(
              animation: rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: rotationAnimation.value * 2 * math.pi,
                  child: CustomPaint(
                    painter: DashedCirclePainter(color: Colors.black),
                  ),
                );
              },
            ),
          ),

        // ─── PAWN BODY CONTAINER ───
        Container(
          width: pawnSize,
          height: pawnSize,
          decoration: BoxDecoration(
            boxShadow: [
              // Drop shadow.
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 6,
                offset: const Offset(2, 4),
              ),

              // Colored glow when moveable.
              if (game.canPawnMove(pawn))
                BoxShadow(
                  color: _getPawnColor(
                    pawn.color,
                  ).withValues(alpha: 0.8 * glowAnimation.value),
                  blurRadius: 15 * glowAnimation.value,
                  spreadRadius: 3 * glowAnimation.value,
                ),

              // Token glows when super powered.
              if (pawn.hasReverse)
                BoxShadow(
                  color: (pawn.state == PawnState.onHomeStretch ||
                          pawn.state == PawnState.finished)
                      ? Colors.transparent
                      : Colors.purpleAccent.withValues(alpha: 0.9),
                  blurRadius: 12,
                  spreadRadius: 4,
                ),

              // when shielded
              if (pawn.isShielded)
                BoxShadow(
                  color: (pawn.state == PawnState.onHomeStretch ||
                          pawn.state == PawnState.finished)
                      ? Colors.transparent
                      : Colors.cyanAccent.withValues(alpha: 0.9),
                  blurRadius: 12,
                  spreadRadius: 4,
                ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              /// PAWN BASE DISC
              Positioned(
                bottom: 0,
                child: Container(
                  // ADJUSTABLE: Change base disc size here.
                  width: pawnSize * 0.85,
                  height: pawnSize * 0.45,
                  decoration: BoxDecoration(
                    color: _getPawnDarkColor(pawn.color),
                    borderRadius: BorderRadius.circular(pawnSize),
                    border: Border.all(color: Colors.black87, width: 1),
                  ),
                ),
              ),

              /// PAWN CYLINDER BODY
              Positioned(
                // ADJUSTABLE: Change stem bottom offset here (pawnSize * 0.18).
                bottom: pawnSize * 0.18,
                child: Container(
                  // ADJUSTABLE: Change stem dimensions here.
                  width: pawnSize * 0.48,
                  height: pawnSize * 0.80,
                  decoration: BoxDecoration(
                    color: _getPawnColor(pawn.color),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black54, width: 1),
                  ),
                ),
              ),

              /// TOP HEAD
              Positioned(
                // ADJUSTABLE: Change head bottom offset here (pawnSize * 0.48).
                bottom: pawnSize * 0.48,
                child: Container(
                  // ADJUSTABLE: Change head size here (pawnSize * 0.40).
                  width: pawnSize * 0.40,
                  height: pawnSize * 0.40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.4),
                      radius: 0.8,
                      colors: [
                        Colors.white.withValues(alpha: 0.8),
                        _getPawnColor(pawn.color),
                        _getPawnDarkColor(pawn.color),
                      ],
                    ),
                    border: Border.all(color: Colors.black54, width: 1),
                  ),
                ),
              ),

              /// TOP DOT (shine)
              Positioned(
                // ADJUSTABLE: Change shine dot position here (pawnSize * 0.63).
                bottom: pawnSize * 0.63,
                child: Container(
                  // ADJUSTABLE: Change shine dot size here (pawnSize * 0.12).
                  width: pawnSize * 0.12,
                  height: pawnSize * 0.12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),

              // -- SUPER POWER ICONS ---
              if (pawn.hasReverse &&
                  pawn.state != PawnState.onHomeStretch &&
                  pawn.state != PawnState.finished)
                Positioned(
                  bottom: pawnSize * 0.85,
                  child: Icon(
                    Icons.u_turn_left,
                    color: Colors.purpleAccent,
                    size: pawnSize * 0.5,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              if (pawn.isShielded &&
                  pawn.state != PawnState.onHomeStretch &&
                  pawn.state != PawnState.finished)
                Positioned(
                  bottom: pawnSize * 0.85,
                  child: Icon(
                    Icons.shield,
                    color: Colors.cyanAccent,
                    size: pawnSize * 0.5,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getPawnColor(PlayerColor color) {
    switch (color) {
      case PlayerColor.green:
        return Colors.green;
      case PlayerColor.yellow:
        return Colors.yellow;
      case PlayerColor.blue:
        return Colors.blue;
      case PlayerColor.red:
        return Colors.red;
    }
  }

  Color _getPawnDarkColor(PlayerColor color) {
    switch (color) {
      case PlayerColor.green:
        return Colors.green.shade900;
      case PlayerColor.yellow:
        return Colors.yellow.shade900;
      case PlayerColor.blue:
        return Colors.blue.shade900;
      case PlayerColor.red:
        return Colors.red.shade900;
    }
  }
}
