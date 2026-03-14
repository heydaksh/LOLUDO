import 'package:flutter/material.dart';
import 'package:ludo_game/screens/ludo_screen.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        return;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image (Optional, reusing your player select background)
            Positioned.fill(
              child: Image.asset(
                "assets/images/bg_image.webp",
                fit: BoxFit.cover,
                opacity: AlwaysStoppedAnimation(.5),
              ),
            ),
            // Dark overlay to make text readable
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.75)),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Special Feature's",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Scrollable Rules List
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildRuleCard(
                            icon: Icons.highlight_remove_sharp,
                            color: Colors.amber,
                            title: "Eleminate All",
                            description:
                                "Allows a player to capture an opponent token even if multiple opponent tokens occupy the same block.",
                          ),
                          _buildRuleCard(
                            icon: Icons.shield,
                            color: Colors.green,
                            title: "Buldozer Mode",
                            description:
                                "When a pawn moves, every opponent token lying within the rolled dice path is automatically eliminated.",
                          ),
                          _buildRuleCard(
                            icon: Icons.cyclone,
                            color: Colors.blue,
                            title: "Magic Portals",
                            description:
                                "Land on a portal to teleport! \n• Blue: Normal Teleport \n• Red: Teleport + 2 Steps Forward \n• Purple: Teleport + 2 Steps Backward",
                          ),
                          _buildRuleCard(
                            icon: Icons.bolt,
                            color: Colors.amber,
                            title: "Power Tiles",
                            description:
                                "Special power tiles appear randomly on the board. Landing on them grants powerful abilities:\n\n"
                                "🛡 Shield – Makes the particular pawn uncapturable for 30 seconds. Attackers get eliminated instead.\n\n"
                                "↩ Reverse Move – Allows same pawn to perform one backward move using the dice value.\nTap 'Use Reverse' button to enble reverse move.\n\n"
                                "🎲 Dice Multiplier – Doubles the next dice result for a single move.(Result will be 4 if dice value is 2)\n\n"
                                "🔄 Swap Power – Lets you swap positions with an opponent pawn on the board.",
                          ),
                          _buildRuleCard(
                            icon: Icons.question_mark,
                            color: Colors.red,
                            title: "How to enable ?",
                            description:
                                "Click on the settings icon in the bottom left corner of the screen. Then click on the 'Hacks' button. Then click on the toggle buttons to enable the hacks.",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // PLAY BUTTON
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to the actual Ludo Board
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LudoScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                      ),
                      child: const Text(
                        "GOT IT! LET'S PLAY",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.4,
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
