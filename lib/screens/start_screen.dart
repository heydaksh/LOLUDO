import 'package:flutter/material.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/screens/player_selection_screen.dart';
import 'package:ludo_game/screens/rotating_card.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // =========================
            // BACKGROUND IMAGE
            // =========================
            Positioned.fill(
              child: Image.asset(
                "assets/images/start_game.webp",
                fit: BoxFit.cover,
              ),
            ),

            // =========================
            // DARK OVERLAY
            // =========================
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.25)),
            ),

            // =========================
            // START BUTTON
            // =========================
            Positioned(
              bottom: size.height / 12,
              left: size.width / 15,
              right: size.width / 15,
              child: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final Map<PlayerColor, String>? result =
                        await Navigator.push<Map<PlayerColor, String>>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PlayerSelectionScreen(),
                          ),
                        );

                    if (result != null && context.mounted) {
                      Navigator.pop(context, result);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size.width / 12),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.green,
                          Colors.yellow,
                          Colors.blue,
                          Colors.red,
                        ],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                    child: Container(
                      height: size.height / 15,
                      width: size.width / 2,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: .center,
                        children: [
                          Text(
                            "START GAME",
                            style: TextStyle(
                              fontSize: size.width / 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          RotatingCredit(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
