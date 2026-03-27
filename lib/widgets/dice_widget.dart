import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/providers/game_provider.dart';
import 'package:ludo_game/utils/app_config.dart';
import 'package:ludo_game/utils/audio_manager.dart';
import 'package:provider/provider.dart';

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
  int _displayValue = 1;
  Timer? _rollingTimer;

  late AnimationController _bounceController;
  late AnimationController _rotateController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotateAnimation;
  bool _wasWaitingForInput = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: AppConfig.diceBounceDuration,
    );

    _bounceAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: AppConfig.diceSpinDuration,
    );

    _rotateAnimation = Tween<double>(begin: 0, end: math.pi * 4).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeOutExpo),
    );
  }

  @override
  void dispose() {
    _rollingTimer?.cancel();
    _bounceController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  // Creates authentic Ludo dice dots instead of text/icons
  // Creates authentic Ludo dice dots instead of text/icons
  Widget _buildDiceDots(int value, Color color, double size) {
    final double dotSize = size / 5.0; // Adjusted dot size

    Widget dot() => Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    // [FIXED]: Added SizedBox so the Stack takes up the full dice space!
    // Varna saare dots center me overlap ho kar 1 dot dikhte hain.
    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: EdgeInsets.all(size / 5.5),
        child: Stack(
          children: [
            if (value > 1) Align(alignment: Alignment.topRight, child: dot()),
            if (value > 3) Align(alignment: Alignment.topLeft, child: dot()),
            if (value == 6)
              Align(alignment: Alignment.centerLeft, child: dot()),
            if (value % 2 != 0)
              Align(alignment: Alignment.center, child: dot()),
            if (value == 6)
              Align(alignment: Alignment.centerRight, child: dot()),
            if (value > 3)
              Align(alignment: Alignment.bottomRight, child: dot()),
            if (value > 1) Align(alignment: Alignment.bottomLeft, child: dot()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double diceWidth = size.width / 5.5;
    final double diceHeight = size.width / 7;

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

    final bool shouldBounce =
        !state.isDiceRolling &&
        !state.hasRolled &&
        !state.hasWinner &&
        !state.isAnimatingMove;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (state.isDiceRolling) {
        if (!(_rollingTimer?.isActive ?? false)) {
          AudioManager.playDiceRoll();
          _rotateController.reset();
          _rotateController.forward();

          _rollingTimer = Timer.periodic(AppConfig.diceFaceShuffleInterval, (
            timer,
          ) {
            if (!mounted) return;
            setState(() {
              _displayValue = math.Random().nextInt(6) + 1;
            });
          });
        }
      } else {
        if (_rollingTimer?.isActive ?? false) {
          _rollingTimer?.cancel();
          setState(() {
            _displayValue = state.diceResult;
          });
        } else if (_displayValue != state.diceResult &&
            !state.isAnimatingMove) {
          setState(() {
            _displayValue = state.diceResult;
          });
        }
      }

      if (shouldBounce) {
        if (!_wasWaitingForInput) {
          _bounceController.repeat(reverse: true);
          _wasWaitingForInput = true;
        }
      } else {
        if (_wasWaitingForInput) {
          _bounceController.stop();
          _bounceController.animateTo(
            0,
            duration: AppConfig.diceBounceReturnDuration,
          );
          _wasWaitingForInput = false;
        }
      }
    });

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
        final provider = context.read<GameProvider>();

        if (provider.isPaused) return;
        if (provider.isOnlineMultiplayer &&
            provider.currentTurn != provider.myLocalColor) {
          return;
        }

        if (shouldBounce) {
          provider.rollDice();
        }
      },
      child: Transform.rotate(
        angle: shouldFlip ? math.pi : 0,
        child: AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _bounceAnimation.value),
              child: child,
            );
          },
          child: AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              final double value = _rotateAnimation.value;
              final Matrix4 transform = Matrix4.identity()
                ..setEntry(3, 2, 0.0014)
                ..rotateX(value)
                ..rotateY(value * 0.7);

              return Transform(
                alignment: Alignment.center,
                transform: transform,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(value > math.pi ? math.pi : 0),
                  child: child,
                ),
              );
            },
            child: Container(
              width: diceWidth,
              height: diceHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size.width / 25),
                boxShadow: [
                  BoxShadow(
                    color: turnColor.withValues(alpha: 0.3),
                    blurRadius: size.width / 45,
                    offset: Offset(size.width / 200, size.width / 120),
                  ),
                ],
                border: Border.all(
                  color: state.hasRolled ? Colors.black54 : turnColor,
                  width: state.hasRolled ? size.width / 200 : size.width / 160,
                ),
              ),
              child: _buildDiceDots(
                _displayValue,
                state.hasRolled
                    ? Colors.black87
                    : turnColor.withValues(alpha: 0.9),
                math.min(diceWidth, diceHeight),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
