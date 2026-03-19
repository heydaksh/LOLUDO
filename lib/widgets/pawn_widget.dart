import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ludo_game/providers/game_provider.dart';
import 'package:provider/provider.dart';

import '../models/game_models.dart';
import '../utils/board_coordinates.dart';

// ==============================
// PAWN WIDGET
// Renders a single Ludo pawn on the board.
// Handles: positioning, jump animation, finishing animation,
// overlap layout, rotating selection indicator, and tap detection.
// ==============================

class PawnWidget extends StatefulWidget {
  /// The pawn data model this widget represents.
  final Pawn pawn;

  /// Physical pixel size of the board — used to compute cell size & position.
  final Size boardSize;

  /// Whether this pawn belongs to the player whose turn it currently is.
  final bool isCurrentTurn;

  /// Callback triggered when the player taps this pawn.
  final VoidCallback onTap;

  /// Zero-based position of this pawn among all pawns on the same cell.
  final int overlapIndex;

  /// Total number of pawns sharing this cell.
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
  // ==============================
  // ANIMATION CONTROLLERS
  // ==============================

  // ADJUSTABLE: Change highlight pulse speed here (currently 600 ms).
  late AnimationController _highlightController;

  // ADJUSTABLE: Change indicator rotation speed — currently 3 seconds per full turn.
  late AnimationController _rotationController;

  // ADJUSTABLE: Change finishing animation speed here (currently 700 ms).
  late AnimationController _finishController;

  // ==============================
  // ANIMATIONS
  // ==============================

  // Glow opacity pulse (0.0 → 1.0), multiplied against box-shadow alpha.
  late Animation<double> _glowAnimation;

  // ADJUSTABLE: Change finishing vertical stretch here (begin: 1.0, end: 1.6).
  late Animation<double> _stretch;

  // ADJUSTABLE: Change finishing shake intensity here (begin: 0, end: 10).
  late Animation<double> _shake;

  // ==============================
  // LIFECYCLE METHODS
  // ==============================

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

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );

    _finishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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

    // Trigger finish animation exactly once when the winning flag becomes true.
    if (widget.pawn.isWinningAnimation &&
        !_finishController.isAnimating &&
        _finishController.value == 0.0) {
      _finishController.forward(from: 0);
    }

    // Reset controller when the winning animation flag clears.
    if (!widget.pawn.isWinningAnimation) {
      _finishController.value = 0.0;
    }

    // Re-evaluate highlight state when turn, pawn state, or roll changes.
    if (oldWidget.isCurrentTurn != widget.isCurrentTurn ||
        oldWidget.pawn.state != widget.pawn.state ||
        game.hasRolled) {
      debugPrint("PawnWidget state updated : ${widget.pawn.id}");
      _updateAnimationState();
    }
  }

  /// Starts or stops the highlight pulse based on whether this pawn can move.
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

  // ==============================
  // BUILD METHOD
  // ==============================

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final bool showRotatingIndicator = game.canPawnMove(widget.pawn);

    // ─── 1. BOARD POSITION ───
    final Offset position = BoardCoordinates.getPhysicalLocation(
      widget.boardSize,
      widget.pawn,
    );

    // ADJUSTABLE: Change pawn size ratios here relative to cell size.
    //   Current player: cellSize * 0.8 | Others: cellSize * 0.65
    final double cellSize = widget.boardSize.width / 15;
    final double pawnSize =
        widget.isCurrentTurn && widget.pawn.state != PawnState.finished
        ? cellSize * 0.8
        : cellSize * 0.65;
    final double cellPadding = (cellSize - pawnSize) / 2;

    // ADJUSTABLE: Change tappable hit-area margin here (currently 15.0 px).
    const double hitMargin = 15.0;

    // ─── 2. OVERLAP LAYOUT ───
    double overlapScale = 1.0;
    Offset overlapOffset = Offset.zero;

    if (widget.totalOverlapping > 1 &&
        widget.pawn.state != PawnState.inBase &&
        widget.pawn.state != PawnState.finished) {
      // ADJUSTABLE: Change overlap scale for current/other pawns here.
      overlapScale = widget.isCurrentTurn ? 0.9 : 0.65;

      // ADJUSTABLE: Change the spread distance of overlapping pawns (pawnSize * 0.25).
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

    // ─── 3. SCALE OVERRIDES ───
    double currentScale = overlapScale;

    // Collapse pawn to invisible during the knockout animation.
    if (widget.pawn.isDeadAnimation) {
      currentScale = 0.0;
    }

    // ADJUSTABLE: Change the winning-burst visual scale here (currently 1.3).
    if (widget.pawn.isWinningAnimation) {
      currentScale = 1.3;
    }

    // ==============================
    // UI LAYOUT
    // ==============================

    return AnimatedPositioned(
      // ADJUSTABLE: Change pawn slide speed between cells here (currently 220 ms).
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      left: position.dx + cellPadding + overlapOffset.dx - hitMargin,
      top: position.dy + cellPadding + overlapOffset.dy - hitMargin,
      width: pawnSize + (hitMargin * 2),
      height: pawnSize + (hitMargin * 2),

      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          debugPrint("Pawn tapped : ${widget.pawn.id}");
          if (!mounted) return;
          widget.onTap();
        },

        child: Padding(
          padding: const EdgeInsets.all(hitMargin),

          // ─── JUMP ANIMATION ───
          // A sine-arc hop fires once per step advance (keyed on pawn.step).
          child: TweenAnimationBuilder<double>(
            key: ValueKey(widget.pawn.step),
            tween: Tween(begin: 0.0, end: 1.0),
            // ADJUSTABLE: Change per-step jump animation duration here (currently 150 ms).
            duration: const Duration(milliseconds: 150),

            builder: (context, value, child) {
              // ADJUSTABLE: Change maximum jump height here (currently 15.0 px).
              final double jumpHeight =
                  (widget.pawn.state == PawnState.onPath ||
                      widget.pawn.state == PawnState.onHomeStretch)
                  ? 15.0
                  : 0.0;

              // Sine curve: 0 at start, peaks at midpoint, returns to 0.
              final double yOffset = -math.sin(value * math.pi) * jumpHeight;

              return Transform.translate(
                offset: Offset(0, yOffset),
                child: child,
              );
            },

            // ─── FINISHING ANIMATION LAYER ───
            child: AnimatedBuilder(
              animation: _finishController,
              builder: (context, child) {
                // Fast sine wave * growing amplitude = shake effect.
                final shakeOffset =
                    math.sin(_finishController.value * 20) * _shake.value;

                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Transform.translate(
                      offset: Offset(shakeOffset, shakeOffset),
                      child: Transform.scale(
                        // Pawn shrinks to invisible as the animation progresses.
                        scale: currentScale * (1 - _finishController.value),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.diagonal3Values(
                            1.0,
                            _stretch.value,
                            1.0,
                          ),

                          // ─── PAWN VISUAL STACK ───
                          child: Stack(
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

                              // ─── PAWN BODY CONTAINER ───
                              Container(
                                width: pawnSize,
                                height: pawnSize,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    // Drop shadow.
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.45,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(2, 4),
                                    ),

                                    // Colored glow when moveable.
                                    if (game.canPawnMove(widget.pawn))
                                      BoxShadow(
                                        color: _getPawnColor(widget.pawn.color)
                                            .withValues(
                                              alpha: 0.8 * _glowAnimation.value,
                                            ),
                                        blurRadius: 15 * _glowAnimation.value,
                                        spreadRadius: 3 * _glowAnimation.value,
                                      ),

                                    // Token glows when super powered.
                                    if (widget.pawn.hasReverse)
                                      BoxShadow(
                                        color:
                                            widget.pawn.state ==
                                                PawnState.onHomeStretch
                                            ? Colors.transparent
                                            : Colors.purpleAccent.withValues(
                                                alpha: 0.9,
                                              ),
                                        blurRadius: 12,
                                        spreadRadius: 4,
                                      ),

                                    // when shielded
                                    if (widget.pawn.isShielded)
                                      BoxShadow(
                                        color:
                                            widget.pawn.state ==
                                                PawnState.onHomeStretch
                                            ? Colors.transparent
                                            : Colors.cyanAccent.withValues(
                                                alpha: 0.9,
                                              ),
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
                                      // ADJUSTABLE: Change stem bottom offset here (pawnSize * 0.18).
                                      bottom: pawnSize * 0.18,
                                      child: Container(
                                        // ADJUSTABLE: Change stem dimensions here.
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
                                      // ADJUSTABLE: Change shine dot position here (pawnSize * 0.63).
                                      bottom: pawnSize * 0.63,
                                      child: Container(
                                        // ADJUSTABLE: Change shine dot size here (pawnSize * 0.12).
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

                                    // -- SUPER POWER ICONS ---
                                    if (widget.pawn.hasReverse)
                                      Positioned(
                                        bottom: pawnSize * 0.85,
                                        child: Icon(
                                          Icons.u_turn_left,
                                          color: Colors.purpleAccent,
                                          size: pawnSize * 0.5,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (widget.pawn.isShielded)
                                      Positioned(
                                        bottom: pawnSize * 0.85,
                                        child: Icon(
                                          Icons.shield,
                                          color: Colors.cyanAccent,
                                          size: pawnSize * 0.5,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black,
                                              blurRadius: 4,
                                            ),
                                          ],
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

  // ==============================
  // COLOR HELPERS
  // ==============================

  /// Returns the primary (lighter) color for the given [PlayerColor].
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

  /// Returns the darker shade of [PlayerColor] for the disc and head gradient shadow.
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

// ==============================
// DASHED CIRCLE PAINTER
// Custom painter that draws 4 evenly-spaced arc segments
// to create a dashed-circle indicator around a selectable pawn.
// Rotated by _rotationController for a spinning effect.
// ==============================

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;

    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      // ADJUSTABLE: Change stroke thickness here (currently 2.5).
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromCircle(
      center: Offset(radius, radius),
      radius: radius,
    );

    // ADJUSTABLE: Change number of arc segments here (currently 4).
    for (int i = 0; i < 4; i++) {
      // ADJUSTABLE: Change arc gap (start offset) here — currently π/12.
      final double startAngle = (math.pi / 2) * i + (math.pi / 12);
      // ADJUSTABLE: Change arc dash length (sweep) here — currently π/3.
      const double sweepAngle = math.pi / 3;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
