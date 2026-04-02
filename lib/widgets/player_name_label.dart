import 'package:flutter/material.dart';
import 'package:ludo_game/models/game_models.dart';

class PlayerNameLabel extends StatelessWidget {
  final Player player;
  final Size boardSize;
  final double boardTurns;
  final bool isOffline;

  const PlayerNameLabel({
    super.key,
    required this.player,
    required this.boardSize,
    required this.boardTurns,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    final double cell = boardSize.width / 15;

    //  Position exactly in the middle of the 1-cell thick outer colored border
    final double edge = cell * 0.7;

    // Centers of the 6x6 bases
    final double base1Center = cell * 3;
    final double base2Center = cell * 12;

    double x = 0;
    double y = 0;

    // Anchor the labels to the "outermost" edge of each specific base
    switch (player.color) {
      case PlayerColor.green:
        x = edge;
        y = base1Center;
        break;
      case PlayerColor.yellow:
        x = base2Center;
        y = edge;
        break;
      case PlayerColor.blue:
        x = boardSize.width - edge;
        y = base2Center;
        break;
      case PlayerColor.red:
        x = base1Center;
        y = boardSize.width - edge;
        break;
    }

    final double horizontalPadding = boardSize.width * 0.015;
    final double verticalPadding = boardSize.width * 0.008;

    final bool isUpperPlayer =
        player.color == PlayerColor.blue || player.color == PlayerColor.yellow;
    final bool flip180 = isOffline && isUpperPlayer;

    return Positioned(
      left: x,
      top: y,
      //  FractionalTranslation beautifully shifts the text so its dead-center
      // sits exactly on our calculated X and Y points!
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: AnimatedRotation(
          turns: -boardTurns + (flip180 ? 0.5 : 0.0),
          duration: const Duration(milliseconds: 600),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(boardSize.width * 0.02),
              border: Border.all(
                color: Colors.black54,
                width: boardSize.width * 0.003,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: boardSize.width * 0.01,
                ),
              ],
            ),
            child: Text(
              player.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: boardSize.width * 0.030,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
