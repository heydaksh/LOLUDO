import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ludo_game/providers/game_provider.dart';
import 'package:ludo_game/screens/instructions_screen.dart';
import 'package:ludo_game/screens/ludo_screen.dart';
import 'package:ludo_game/screens/multiplayer_join/multiplayer_join_dialog.dart';
import 'package:ludo_game/screens/player_selection_screen.dart';
import 'package:provider/provider.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          /// Background
          Positioned.fill(
            child: Image.asset(
              "assets/images/start_game.webp",
              fit: BoxFit.cover,
            ),
          ),

          /// Dark overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                /// 🔥 BUTTONS CENTER
                Column(
                  children: [
                    _glassButton(
                      context,
                      text: "PLAY OFFLINE",
                      icon: Icons.people,
                      colors: [Colors.blue, Colors.blueAccent],
                      onTap: () async {
                        HapticFeedback.heavyImpact();
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PlayerSelectionScreen(),
                          ),
                        );

                        if (result != null && context.mounted) {
                          context.read<GameProvider>().initializePlayers(
                            result,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LudoScreen(),
                            ),
                          );
                        }
                      },
                    ),

                    SizedBox(height: size.height / 40),

                    _glassButton(
                      context,
                      text: "PLAY ONLINE",
                      icon: Icons.public,
                      colors: [Colors.green, Colors.teal],
                      onTap: () {
                        HapticFeedback.heavyImpact();

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const MultiplayerJoinDialog(),
                        );
                      },
                    ),
                  ],
                ),

                /// 🔥 BOTTOM ACTIONS
                Padding(
                  padding: EdgeInsets.only(
                    bottom: size.height / 50,
                    right: size.width / 50,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InstructionsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(size.width / 40),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.7),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Text(
                            '?',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 PREMIUM BUTTON
  Widget _glassButton(
    BuildContext context, {
    required String text,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size.width / 12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: size.width * 0.72,
            height: size.height / 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size.width / 12),

              /// 🔥 BASE GLASS LAYER
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),

              /// 🔥 GLASS BORDER
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: size.width / 300,
              ),

              /// 🔥 OUTER GLOW (COLOR)
              boxShadow: [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.35),
                  blurRadius: 25,
                  spreadRadius: 1,
                ),
              ],
            ),

            child: Stack(
              children: [
                /// 🔥 COLOR INFUSION LAYER (main visual)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size.width / 12),
                      gradient: LinearGradient(
                        colors: [
                          colors.first.withValues(alpha: 0.35),
                          colors.last.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),

                /// 🔥 LIGHT HIGHLIGHT (top shine)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: size.height / 70,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(size.width / 12),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                /// 🔥 INNER SHADOW (depth)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size.width / 12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: Offset(0, size.height / 200),
                        ),
                      ],
                    ),
                  ),
                ),

                /// 🔥 CONTENT
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: size.width / 18),
                      SizedBox(width: size.width / 30),
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: size.width / 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
