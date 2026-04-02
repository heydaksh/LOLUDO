import 'package:flutter/material.dart';
import 'package:ludo_game/providers/game_provider.dart';
import 'package:ludo_game/screens/start_screen.dart';
import 'package:provider/provider.dart';

// ==============================
// PAUSE OVERLAY
// ==============================

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final size = MediaQuery.of(context).size;

    // Only allow resume if offline, OR if the current player is the host, OR if they are the one who paused it.
    bool canResume =
        !provider.isOnlineMultiplayer ||
        provider.isHost ||
        provider.myLocalColor?.name == provider.pausedByColor;

    String pauserName = provider.pausedByName ?? "a player";

    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Center(
          child: Container(
            width: size.width * 0.8,
            padding: EdgeInsets.all(size.width / 15),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 10),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pause_circle_filled,
                  color: Colors.orange,
                  size: size.width / 6,
                ),
                const SizedBox(height: 20),
                Text(
                  'Game Paused',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width / 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Paused by $pauserName',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: size.width / 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                if (canResume)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      provider.setPauseState(false);
                    },
                    child: Text(
                      'Resume',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width / 22,
                      ),
                    ),
                  )
                else
                  Text(
                    'Waiting for them to resume...',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: size.width / 26,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    if (provider.isHost) {
                      provider.endGameHost();
                    } else if (provider.isOnlineMultiplayer &&
                        provider.myLocalColor != null) {
                      provider.removePlayer(provider.myLocalColor!);
                      provider.exitGame();
                    } else {
                      provider.exitGame();
                    }
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const StartScreen()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    provider.isHost ? 'End Game' : 'Exit Game',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: size.width / 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
