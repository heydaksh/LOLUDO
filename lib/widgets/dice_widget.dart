import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/providers/game_provider.dart';
import 'package:ludo_game/utils/audio_manager.dart';
import 'package:provider/provider.dart';

// ==============================
// DICE WIDGET
// Displays an animated dice on the board.
//
// Visual states:
//   • Waiting to roll → bounces up/down rhythmically.
//   • Rolling         → spins in 3-D and rapidly cycles through random faces.
//   • Rolled          → shows the final result, border changes to neutral.
//
// Animation controllers:
//   _bounceController  — gentle up/down bob when waiting for input.
//   _rotateController  — 3-D spin triggered on tap.
//
// Internal dice display (_displayValue) is updated independently of the
// provider's diceResult so the animation can show random faces while rolling.
//
// The dice border color matches the current player's color.
// ==============================

/// Record type used with context.select to subscribe only to the 5 relevant
/// GameProvider fields, preventing unnecessary rebuilds on unrelated changes.
typedef _DiceState = ({
  bool isDiceRolling,
  bool hasRolled,
  int diceResult,
  bool hasWinner,
  PlayerColor currentTurn,
  bool isAnimatingMove,
});

class DiceWidget extends StatefulWidget {
  const DiceWidget({super.key});

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> with TickerProviderStateMixin {
  // ==============================
  // STATE VARIABLES
  // ==============================

  /// The number currently displayed on the dice face.
  /// Rapidly cycles through random values during the rolling animation.
  int _displayValue = 1;

  /// Periodic timer used to shuffle _displayValue during the rolling animation.
  // ADJUSTABLE: Change the face-shuffle interval during rolling (currently 50 ms).
  Timer? _rollingTimer;

  // ==============================
  // ANIMATION CONTROLLERS
  // ==============================

  /// Drives the vertical bounce animation shown when the dice is waiting to be rolled.
  // ADJUSTABLE: Change bounce animation duration here (currently 200 ms).
  late AnimationController _bounceController;

  /// Drives the 3-D spin animation triggered on tap.
  // ADJUSTABLE: Change spin animation duration here (currently 600 ms).
  late AnimationController _rotateController;

  // ─── Animations ───

  /// Translates the dice upward by 15 px during the bounce.
  // ADJUSTABLE: Change bounce height here (begin: 0, end: -15 px).
  late Animation<double> _bounceAnimation;

  /// Rotates the dice from 0 to 4π (two full spins) for the roll animation.
  // ADJUSTABLE: Change total rotation amount here (end: math.pi * 4 = 2 full spins).
  late Animation<double> _rotateAnimation;

  // ─── Local audio player ───
  // Not actively used for playback; AudioManager handles sounds.
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Tracks whether the dice was in "waiting for input" state on the previous frame.
  /// Used to correctly transition the bounce animation on/off.
  bool _wasWaitingForInput = false;

  // ==============================
  // LIFECYCLE METHODS
  // ==============================

  @override
  void initState() {
    super.initState();

    // ─── Bounce Controller ───
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // ADJUSTABLE: Bounce speed.
    );

    _bounceAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // ─── Rotate Controller ───
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // ADJUSTABLE: Spin speed.
    );

    _rotateAnimation = Tween<double>(begin: 0, end: math.pi * 4).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeOutExpo),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final p = context.read<GameProvider>();
    final bool isDiceRolling = p.isDiceRolling;
    final bool hasRolled = p.hasRolled;
    final int diceResult = p.diceResult;
    final bool hasWinner = p.isGameOver;

    // Sync _displayValue with the provider result only when not mid-animation.
    if (!isDiceRolling && _rollingTimer?.isActive != true) {
      _displayValue = diceResult;
    }

    // The dice bounces when it's idle and waiting to be tapped.
    final bool shouldBounce = !isDiceRolling && !hasRolled && !hasWinner;

    // Start bouncing if transitioning into "waiting for input" state.
    if (shouldBounce && !_wasWaitingForInput) {
      if (!_bounceController.isAnimating) {
        _bounceController.repeat(reverse: true);
      }
    }

    // Stop bouncing when the state changes away from "waiting for input".
    if (!shouldBounce && _wasWaitingForInput) {
      if (_bounceController.isAnimating) {
        _bounceController.stop();
        // Smoothly settle back to neutral position.
        // ADJUSTABLE: Change the settle animation duration here (currently 300 ms).
        _bounceController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
        );
      }
    }

    _wasWaitingForInput = shouldBounce;
  }

  // ==============================
  // ROLLING ANIMATION
  // ==============================

  /// Initiates the full roll sequence:
  ///   1. Plays dice roll sound.
  ///   2. Triggers the 3-D spin animation.
  ///   3. Starts a periodic timer to shuffle display values (random face effect).
  ///   4. After 600 ms, stops the timer and locks display to the real result.
  ///   5. Awaits the provider's rollDice() to complete (applies game rules).
  Future<void> _startRollingAnimation(GameProvider gameProvider) async {
    if (_rollingTimer?.isActive ?? false) return;
    AudioManager.playDiceRoll();

    // Start provider logic in parallel with the animation.
    Future<void> rollFuture = gameProvider.rollDice();

    // Kick off the 3-D spin.
    _rotateController.reset();
    _rotateController.forward();

    // Rapidly shuffle the displayed number to simulate randomness.
    // ADJUSTABLE: Change shuffle tick rate here (currently 50 ms per face).
    _rollingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        _displayValue = math.Random().nextInt(6) + 1;
      });
    });

    // ADJUSTABLE: Change how long the face-shuffle runs before showing the result (currently 600 ms).
    await Future.delayed(const Duration(milliseconds: 600));

    _rollingTimer?.cancel();

    // Snap to the actual result.
    if (mounted) {
      setState(() {
        _displayValue = gameProvider.diceResult;
      });
    }

    // Wait for the provider's rollDice() to fully complete before allowing input.
    await rollFuture;
  }

  @override
  void dispose() {
    _rollingTimer?.cancel();
    _bounceController.dispose();
    _rotateController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ==============================
  // BUILD METHOD
  // ==============================

  @override
  Widget build(BuildContext context) {
    // Subscribe only to the 5 relevant fields to avoid full-widget rebuilds.
    final state = context.select<GameProvider, _DiceState>(
      (p) => (
        isDiceRolling: p.isDiceRolling,
        hasRolled: p.hasRolled,
        diceResult: p.diceResult,
        hasWinner: p.isGameOver,
        currentTurn: p.currentTurn,
        isAnimatingMove: p.isAnimatingMove,
      ),
    );

    // True only when the dice is idle and waiting to be tapped.
    final bool shouldBounce =
        !state.isDiceRolling &&
        !state.hasRolled &&
        !state.hasWinner &&
        !state.isAnimatingMove;

    // ─── Turn Color ───
    // The dice border glows in the current player's color.
    Color turnColor;
    switch (state.currentTurn) {
      case PlayerColor.green:
        turnColor = Colors.green;
        break;
      case PlayerColor.yellow:
        turnColor = Colors.yellow.shade700;
        break;
      case PlayerColor.blue:
        turnColor = Colors.blue;
        break;
      case PlayerColor.red:
        turnColor = Colors.red;
        break;
    }

    final bool shouldFlip =
        state.currentTurn == PlayerColor.green ||
        state.currentTurn == PlayerColor.yellow;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Only allow rolling when the dice is in its idle/bouncing state.
        if (shouldBounce) {
          _startRollingAnimation(context.read<GameProvider>());
        }
      },

      // ─── FLIP FOR OPPOSITE PLAYERS ───
      // Inverts the dice 180deg so players sitting across (Green & Yellow) can read it easily.
      child: Transform.rotate(
        angle: shouldFlip ? math.pi : 0,
        // ─── BOUNCE LAYER ───
        // Translates the entire dice up/down using _bounceAnimation value.
        child: AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _bounceAnimation.value),
              child: child,
            );
          },

          // ─── 3-D ROTATION LAYER ───
          // Applies a perspective-correct X+Y rotation during the roll animation.
          child: AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              final double value = _rotateAnimation.value;

              // perspective + X-axis + Y-axis (0.7× speed for natural feel)
              // ADJUSTABLE: Change perspective depth here (currently 0.0014).
              // ADJUSTABLE: Change Y-axis rotation ratio here (currently value * 0.7).
              final Matrix4 transform = Matrix4.identity()
                ..setEntry(3, 2, 0.0014)
                ..rotateX(value)
                ..rotateY(value * 0.7);

              return Transform(
                alignment: Alignment.center,
                transform: transform,
                child: Transform(
                  alignment: Alignment.center,
                  // Flip Y-axis halfway through the spin to create a "flip" effect.
                  transform: Matrix4.rotationY(value > math.pi ? math.pi : 0),
                  child: child,
                ),
              );
            },

            // ─── DICE FACE ───
            child: Container(
              // ADJUSTABLE: Change dice container width here (currently 70 px).
              width: 70,
              // ADJUSTABLE: Change dice container height here (currently 60 px).
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                // ADJUSTABLE: Change dice corner radius here (currently 16).
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: turnColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
                border: Border.all(
                  // Border shows turn color when idle, dims to black54 after rolling.
                  color: state.hasRolled ? Colors.black54 : turnColor,
                  // ADJUSTABLE: Change idle border width here (currently 3 px when idle, 2 px after roll).
                  width: state.hasRolled ? 2 : 3,
                ),
              ),
              child: Center(
                child: Text(
                  '$_displayValue',
                  style: const TextStyle(
                    // ADJUSTABLE: Change dice number font size here (currently 40).
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
