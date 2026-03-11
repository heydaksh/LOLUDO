import 'package:flutter/material.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/providers/game_provider.dart';
import 'package:provider/provider.dart';

class VictoryOverlay extends StatelessWidget {
  final PlayerColor winnerColor;
  const VictoryOverlay({super.key, required this.winnerColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,

          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            padding: const .all(32),
            margin: const .symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: .circular(24),
              border: .all(color: _getWinnerColor(winnerColor), width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: .min,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.amber.shade600,
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  '${winnerColor.name.toUpperCase()} WINS!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _getWinnerColor(winnerColor),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'All tokens reached home safely.',
                  textAlign: .center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    context.read<GameProvider>().restartGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getWinnerColor(winnerColor),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: .circular(30)),
                  ),
                  child: const Text(
                    'PLAY AGAIN',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getWinnerColor(PlayerColor color) {
    switch (color) {
      case PlayerColor.green:
        return Colors.green;
      case PlayerColor.yellow:
        return Colors.yellow.shade700;
      case PlayerColor.blue:
        return Colors.blue;
      case PlayerColor.red:
        return Colors.red;
    }
  }
}
