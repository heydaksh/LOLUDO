import 'package:flutter/material.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/providers/game_provider.dart';
import 'package:provider/provider.dart';

// ==============================
// VICTORY OVERLAY
// Full-screen overlay displayed when a player wins.
//
// Appearance:
//   - Semi-transparent black backdrop over the entire game board.
//   - Centered white card with:
//       • Trophy icon.
//       • "[COLOR] WINS!" headline in the winner's color.
//       • Subtitle text.
//       • "PLAY AGAIN" button that restarts the game.
//
// Animation:
//   - The card scales in from 0→1 with an elastic spring curve
//     for a celebratory pop-in effect.
// ==============================

class VictoryOverlay extends StatelessWidget {
  /// The color of the player who won.
  final PlayerColor winnerColor;

  const VictoryOverlay({super.key, required this.winnerColor});

  // ==============================
  // BUILD METHOD
  // ==============================

  @override
  Widget build(BuildContext context) {
    return Container(
      // ADJUSTABLE: Change backdrop opacity here (currently 0.7).
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        // ─── CARD SCALE-IN ANIMATION ───
        // The victory card pops in from scale 0 → 1 on first render.
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          // ADJUSTABLE: Change card pop-in animation duration here (currently 800 ms).
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,

          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },

          // ─── VICTORY CARD ───
          child: Container(
            // ADJUSTABLE: Change card inner padding here (currently 32 px).
            padding: const EdgeInsets.all(32),
            // ADJUSTABLE: Change card horizontal margin here (currently 32 px).
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              // ADJUSTABLE: Change card corner radius here (currently 24).
              borderRadius: BorderRadius.circular(24),
              // The card border uses the winner's color for a custom highlight.
              // ADJUSTABLE: Change border width here (currently 4 px).
              border: Border.all(color: _getWinnerColor(winnerColor), width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── TROPHY ICON ───
                Icon(
                  Icons.emoji_events,
                  color: Colors.amber.shade600,
                  // ADJUSTABLE: Change trophy icon size here (currently 80 px).
                  size: 80,
                ),

                const SizedBox(height: 16),

                // ─── WINNER HEADLINE ───
                // Format: "GREEN WINS!", "BLUE WINS!", etc.
                Text(
                  '${winnerColor.name.toUpperCase()} WINS!',
                  style: TextStyle(
                    // ADJUSTABLE: Change headline font size here (currently 32).
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _getWinnerColor(winnerColor),
                  ),
                ),

                const SizedBox(height: 8),

                // ─── SUBTITLE ───
                const Text(
                  'All tokens reached home safely.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),

                const SizedBox(height: 32),

                // ─── PLAY AGAIN BUTTON ───
                // Calls GameProvider.restartGame() to reset all state
                // and start a fresh round with the same player count.
                ElevatedButton(
                  onPressed: () {
                    context.read<GameProvider>().restartGame();
                  },
                  style: ElevatedButton.styleFrom(
                    // Button background uses the winner's color.
                    backgroundColor: _getWinnerColor(winnerColor),
                    foregroundColor: Colors.white,
                    // ADJUSTABLE: Change button padding here.
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      // ADJUSTABLE: Change button corner radius here (currently 30).
                      borderRadius: BorderRadius.circular(30),
                    ),
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

  // ==============================
  // COLOR HELPER
  // ==============================

  /// Returns the display color for the given winning [PlayerColor].
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
