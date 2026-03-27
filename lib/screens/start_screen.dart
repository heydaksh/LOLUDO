// lib/screens/start_screen.dart
import 'package:flutter/material.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/providers/game_provider.dart';
import 'package:ludo_game/screens/ludo_screen.dart';
import 'package:ludo_game/screens/multiplayer_join/multiplayer_join_dialog.dart';
import 'package:ludo_game/screens/player_selection_screen.dart';
import 'package:provider/provider.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/start_game.webp",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.25)),
          ),
          Positioned(
            bottom: size.height / 12,
            left: size.width / 15,
            right: size.width / 15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // =========================
                // OFFLINE / LOCAL PLAY BUTTON
                // =========================
                SizedBox(
                  width: double.infinity,
                  height: size.height / 16,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // 1. Wait for player config to return
                      final Map<PlayerColor, PlayerSetup>? result =
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PlayerSelectionScreen(),
                            ),
                          );

                      // 2. If valid, initialize game and jump to board
                      if (result != null && context.mounted) {
                        context.read<GameProvider>().initializePlayers(result);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LudoScreen()),
                        );
                      }
                    },
                    icon: const Icon(Icons.people, color: Colors.white),
                    label: const Text(
                      "PLAY OFFLINE (LOCAL)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height / 40),

                // =========================
                // ONLINE MULTIPLAYER BUTTON
                // =========================
                SizedBox(
                  width: double.infinity,
                  height: size.height / 16,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) => const MultiplayerJoinDialog(),
                      );
                    },
                    icon: const Icon(Icons.public, color: Colors.white),
                    label: const Text(
                      "PLAY ONLINE (WITH FRIENDS)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
