import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ludo_game/providers/game_provider.dart';
import 'package:ludo_game/widgets/pawn_visuals_stack.dart';
import 'package:provider/provider.dart';

import '../models/game_models.dart';
import '../utils/app_config.dart';
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
  final double boardTurns;

  const PawnWidget({
    super.key,
    required this.pawn,
    required this.boardSize,
    required this.isCurrentTurn,
    required this.onTap,
    this.overlapIndex = 0,
    this.totalOverlapping = 1,
    this.boardTurns = 0.0,
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
  late Animation<double> glowAnimation;

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
      duration: AppConfig.pawnHighlightPulseDuration,
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: AppConfig.pawnSelectionIndicatorRotationDuration,
    )..repeat();

    glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );

    _finishController = AnimationController(
      vsync: this,
      duration: AppConfig.pawnFinishAnimationDuration,
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
    final double pawnSize = widget.pawn.state == PawnState.finished
        ? cellSize * 0.45
        : (widget.isCurrentTurn ? cellSize * 0.8 : cellSize * 0.65);
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
      duration: AppConfig.pawnSlideDuration,
      curve: Curves.easeInOut,
      left: position.dx + cellPadding + overlapOffset.dx - hitMargin,
      top: position.dy + cellPadding + overlapOffset.dy - hitMargin,
      width: pawnSize + (hitMargin * 2),
      height: pawnSize + (hitMargin * 2),

      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          final provider = context.read<GameProvider>();

          if (provider.isPaused) return;

          if (provider.isOnlineMultiplayer &&
              provider.currentTurn != provider.myLocalColor) {
            return;
          }

          debugPrint("Pawn Tapped: ${widget.pawn.id}");
          if (!mounted) return;
          widget.onTap();
        },

        child: Padding(
          padding: const EdgeInsets.all(hitMargin),

          // ─── JUMP ANIMATION ───
          // A sine-arc hop fires once per step advance (keyed on pawn.step).
          child: AnimatedRotation(
            turns: -widget.boardTurns,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(widget.pawn.step),
              tween: Tween(begin: 0.0, end: 1.0),
              // ADJUSTABLE: Change per-step jump animation duration here (currently 150 ms).
              duration: AppConfig.pawnJumpDuration,

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
                            // child: PawnVisualsStack(showRotatingIndicator, pawnSize, game),
                            child: PawnVisualsStack(
                              pawn: widget.pawn,
                              showRotatingIndicator: showRotatingIndicator,
                              pawnSize: pawnSize,
                              game: game,
                              rotationAnimation: _rotationController,
                              glowAnimation: glowAnimation,
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
      ),
    );
  }
}
