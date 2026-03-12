import 'package:flutter/material.dart';
import 'package:ludo_game/screens/player_selection_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
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

          // optional dark overlay for readability
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.25)),
          ),

          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () async {
                // Await the player count from PlayerSelectionScreen,
                // then pop StartScreen with that value so _StartGameRouter
                // receives it and can navigate to LudoScreen.
                final int? count = await Navigator.push<int>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlayerSelectionScreen(),
                  ),
                );
                if (count != null && context.mounted) {
                  Navigator.pop(context, count);
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
                  child: Text(
                    "START GAME",
                    style: TextStyle(
                      fontSize: size.width / 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
