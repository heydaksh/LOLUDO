import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/providers/game_provider.dart';
import 'package:ludo_game/utils/audio_manager.dart';
import 'package:provider/provider.dart';

typedef _DiceState = ({
  bool isDiceRolling,
  bool hasRolled,
  int diceResult,
  bool hasWinner,
  PlayerColor currentTurn,
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
  late Animation<double> _bounceAnimation;

  late AnimationController _rotateController;
  late Animation<double> _rotateAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _wasWaitingForInput = false;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    final bool hasWinner = p.winner != null;

    if (!isDiceRolling && _rollingTimer?.isActive != true) {
      _displayValue = diceResult;
    }

    final bool shouldBounce = !isDiceRolling && !hasRolled && !hasWinner;

    if (shouldBounce && !_wasWaitingForInput) {
      if (!_bounceController.isAnimating) {
        _bounceController.repeat(reverse: true);
      }
    }

    if (!shouldBounce && _wasWaitingForInput) {
      if (_bounceController.isAnimating) {
        _bounceController.stop();
        _bounceController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
        );
      }
    }

    _wasWaitingForInput = shouldBounce;
  }

  Future<void> _startRollingAnimation(GameProvider gameProvider) async {
    AudioManager.playDiceRoll();

    Future<void> rollFuture = gameProvider.rollDice();

    _rotateController.reset();
    _rotateController.forward();

    _rollingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;

      setState(() {
        _displayValue = math.Random().nextInt(6) + 1;
      });
    });

    await Future.delayed(const Duration(milliseconds: 600));

    _rollingTimer?.cancel();

    if (mounted) {
      setState(() {
        _displayValue = gameProvider.diceResult;
      });
    }

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

  @override
  Widget build(BuildContext context) {
    final state = context.select<GameProvider, _DiceState>(
      (p) => (
        isDiceRolling: p.isDiceRolling,
        hasRolled: p.hasRolled,
        diceResult: p.diceResult,
        hasWinner: p.winner != null,
        currentTurn: p.currentTurn,
      ),
    );

    final bool shouldBounce =
        !state.isDiceRolling && !state.hasRolled && !state.hasWinner;

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

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();

        if (shouldBounce) {
          _startRollingAnimation(context.read<GameProvider>());
        }
      },
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
              ..setEntry(3, 2, 0.0014) // better perspective
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
            width: 70,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: turnColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
              border: Border.all(
                color: state.hasRolled ? Colors.black54 : turnColor,
                width: state.hasRolled ? 2 : 3,
              ),
            ),
            child: Center(
              child: Text(
                '$_displayValue',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
