import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ludo_game/providers/game_provider.dart';
import 'package:provider/provider.dart';

import '../models/game_models.dart';
import '../utils/board_coordinates.dart';

class PawnWidget extends StatefulWidget {
  final Pawn pawn;
  final Size boardSize;
  final bool isCurrentTurn;
  final VoidCallback onTap;
  final int overlapIndex;
  final int totalOverlapping;

  const PawnWidget({
    super.key,
    required this.pawn,
    required this.boardSize,
    required this.isCurrentTurn,
    required this.onTap,
    this.overlapIndex = 0,
    this.totalOverlapping = 1,
  });

  @override
  State<PawnWidget> createState() => _PawnWidgetState();
}

class _PawnWidgetState extends State<PawnWidget> with TickerProviderStateMixin {
  // Controllers
  late AnimationController _highlightController;
  late AnimationController _rotationController;
  late AnimationController _finishController;

  // Animations
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _finishScale;
  late Animation<double> _stretch;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();

    debugPrint("PawnWidget initState : ${widget.pawn.id}");

    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );

    _finishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _finishScale = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _finishController, curve: Curves.easeOut),
    );

    _stretch = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _finishController, curve: Curves.easeInOut),
    );

    _shake = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _finishController, curve: Curves.elasticIn),
    );

    _updateAnimationState();
  }

  @override
  void didUpdateWidget(covariant PawnWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final game = context.read<GameProvider>();

    // Trigger finish animation once
    if (widget.pawn.isWinningAnimation &&
        !_finishController.isAnimating &&
        _finishController.value == 0.0) {
      _finishController.forward(from: 0);
    }

    if (!widget.pawn.isWinningAnimation) {
      _finishController.value = 0.0;
    }

    if (oldWidget.isCurrentTurn != widget.isCurrentTurn ||
        oldWidget.pawn.state != widget.pawn.state ||
        game.hasRolled) {
      debugPrint("PawnWidget state updated : ${widget.pawn.id}");
      _updateAnimationState();
    }
  }

  // Controls highlight animation
  void _updateAnimationState() {
    final game = context.read<GameProvider>();

    final bool shouldAnimate = game.canPawnMove(widget.pawn);

    debugPrint("PawnWidget highlight animation: $shouldAnimate");

    if (shouldAnimate) {
      if (!_highlightController.isAnimating) {
        _highlightController.repeat(reverse: true);
      }
    } else {
      if (_highlightController.isAnimating) {
        _highlightController.stop();
      }
      _highlightController.value = 0.0;
    }
  }

  @override
  void dispose() {
    debugPrint("PawnWidget dispose : ${widget.pawn.id}");

    _highlightController.dispose();
    _rotationController.dispose();
    _finishController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final bool showRotatingIndicator = game.canPawnMove(widget.pawn);
    // Board position calculation
    final Offset position = BoardCoordinates.getPhysicalLocation(
      widget.boardSize,
      widget.pawn,
    );

    final double cellSize = widget.boardSize.width / 15;
    // slightly adjust base size, allow current turn to be slightly larger
    final double pawnSize =
        widget.isCurrentTurn && widget.pawn.state != PawnState.finished
        ? cellSize * 0.8
        : cellSize * 0.65;
    final double cellPadding = (cellSize - pawnSize) / 2;

    const double hitMargin = 15.0;

    // Overlap configuration
    double overlapScale = 1.0;
    Offset overlapOffset = Offset.zero;

    if (widget.totalOverlapping > 1 &&
        widget.pawn.state != PawnState.inBase &&
        widget.pawn.state != PawnState.finished) {
      overlapScale = widget.isCurrentTurn ? 0.9 : 0.65;

      final double shiftAmount = pawnSize * 0.25;

      switch (widget.totalOverlapping) {
        case 2:
          overlapOffset = widget.overlapIndex == 0
              ? Offset(-shiftAmount, -shiftAmount)
              : Offset(shiftAmount, shiftAmount);
          break;

        case 3:
          if (widget.overlapIndex == 0) {
            overlapOffset = Offset(-shiftAmount, -shiftAmount);
          } else if (widget.overlapIndex == 1) {
            overlapOffset = Offset(shiftAmount, -shiftAmount);
          } else {
            overlapOffset = Offset(0, shiftAmount);
          }
          break;

        default:
          if (widget.overlapIndex == 0) {
            overlapOffset = Offset(-shiftAmount, -shiftAmount);
          } else if (widget.overlapIndex == 1) {
            overlapOffset = Offset(shiftAmount, -shiftAmount);
          } else if (widget.overlapIndex == 2) {
            overlapOffset = Offset(-shiftAmount, shiftAmount);
          } else {
            overlapOffset = Offset(shiftAmount, shiftAmount);
          }
      }
    }

    double currentScale = overlapScale;

    if (widget.pawn.isDeadAnimation) {
      currentScale = 0.0;
    }

    if (widget.pawn.isWinningAnimation) {
      currentScale = 1.3;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      left: position.dx + cellPadding + overlapOffset.dx - hitMargin,
      top: position.dy + cellPadding + overlapOffset.dy - hitMargin,
      width: pawnSize + (hitMargin * 2),
      height: pawnSize + (hitMargin * 2),
      child: GestureDetector(
        // Improves tap responsiveness
        behavior: HitTestBehavior.translucent,
        onTap: () {
          debugPrint("Pawn tapped : ${widget.pawn.id}");
          if (!mounted) return;
          widget.onTap();
        },

        child: Padding(
          padding: const EdgeInsets.all(hitMargin),
          child: TweenAnimationBuilder<double>(
            key: ValueKey(widget.pawn.step),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 150),

            builder: (context, value, child) {
              final double jumpHeight =
                  (widget.pawn.state == PawnState.onPath ||
                      widget.pawn.state == PawnState.onHomeStretch)
                  ? 15.0
                  : 0.0;

              final double yOffset = -math.sin(value * math.pi) * jumpHeight;

              return Transform.translate(
                offset: Offset(0, yOffset),
                child: child,
              );
            },

            child: AnimatedBuilder(
              animation: _finishController,
              builder: (context, child) {
                final shakeOffset =
                    math.sin(_finishController.value * 20) * _shake.value;

                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Transform.translate(
                      offset: Offset(shakeOffset, shakeOffset),
                      child: Transform.scale(
                        scale: currentScale * (1 - _finishController.value),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..scale(1.0, _stretch.value),
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // Rotating dashed indicator
                              if (showRotatingIndicator)
                                Positioned(
                                  width: pawnSize * 1.3,
                                  height: pawnSize * 1.3,
                                  child: AnimatedBuilder(
                                    animation: _rotationController,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle:
                                            _rotationController.value *
                                            2 *
                                            math.pi,
                                        child: CustomPaint(
                                          painter: _DashedCirclePainter(
                                            color: Colors.black,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                              // Pawn UI
                              Container(
                                width: pawnSize,
                                height: pawnSize,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.45,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(2, 4),
                                    ),

                                    if (game.canPawnMove(widget.pawn))
                                      BoxShadow(
                                        color: _getPawnColor(widget.pawn.color)
                                            .withValues(
                                              alpha: 0.8 * _glowAnimation.value,
                                            ),
                                        blurRadius: 15 * _glowAnimation.value,
                                        spreadRadius: 3 * _glowAnimation.value,
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
                                        width: pawnSize * 0.85,
                                        height: pawnSize * 0.45,
                                        decoration: BoxDecoration(
                                          color: _getPawnDarkColor(
                                            widget.pawn.color,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            pawnSize,
                                          ),
                                          border: Border.all(
                                            color: Colors.black87,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    ),

                                    /// PAWN CYLINDER BODY
                                    Positioned(
                                      bottom: pawnSize * 0.18,
                                      child: Container(
                                        width: pawnSize * 0.48,
                                        height: pawnSize * 0.80,
                                        decoration: BoxDecoration(
                                          color: _getPawnColor(
                                            widget.pawn.color,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: Colors.black54,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    ),

                                    /// TOP HEAD
                                    Positioned(
                                      bottom: pawnSize * 0.48,
                                      child: Container(
                                        width: pawnSize * 0.40,
                                        height: pawnSize * 0.40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            center: const Alignment(-0.3, -0.4),
                                            radius: 0.8,
                                            colors: [
                                              Colors.white.withValues(
                                                alpha: 0.8,
                                              ),
                                              _getPawnColor(widget.pawn.color),
                                              _getPawnDarkColor(
                                                widget.pawn.color,
                                              ),
                                            ],
                                          ),
                                          border: Border.all(
                                            color: Colors.black54,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    ),

                                    /// TOP DOT (shine)
                                    Positioned(
                                      bottom: pawnSize * 0.63,
                                      child: Container(
                                        width: pawnSize * 0.12,
                                        height: pawnSize * 0.12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Color _getPawnColor(PlayerColor color) {
    switch (color) {
      case PlayerColor.green:
        return Colors.green;
      case PlayerColor.yellow:
        return Colors.yellow.shade600;
      case PlayerColor.blue:
        return Colors.blue;
      case PlayerColor.red:
        return Colors.red;
    }
  }

  Color _getPawnDarkColor(PlayerColor color) {
    switch (color) {
      case PlayerColor.green:
        return const Color.fromARGB(255, 62, 188, 68);
      case PlayerColor.yellow:
        return const Color.fromARGB(255, 239, 219, 0);
      case PlayerColor.blue:
        return const Color.fromARGB(255, 41, 129, 231);
      case PlayerColor.red:
        return const Color.fromARGB(255, 173, 60, 60);
    }
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;

    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromCircle(
      center: Offset(radius, radius),
      radius: radius,
    );

    for (int i = 0; i < 4; i++) {
      final double startAngle = (math.pi / 2) * i + (math.pi / 12);
      const double sweepAngle = math.pi / 3;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
