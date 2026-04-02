import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:ludo_game/main.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/models/portals.dart';
import 'package:ludo_game/models/powers.dart';
import 'package:ludo_game/screens/start_screen.dart';
import 'package:ludo_game/utils/app_config.dart';
import 'package:ludo_game/utils/audio_manager.dart';
import 'package:ludo_game/utils/board_coordinates.dart';
import 'package:ludo_game/widgets/board_painter.dart';
import 'package:ludo_game/widgets/dice_widget.dart';
import 'package:ludo_game/widgets/pause_overlay.dart';
import 'package:ludo_game/widgets/pawn_widget.dart';
import 'package:ludo_game/widgets/player_name_label.dart';
import 'package:ludo_game/widgets/portal_widget.dart';
import 'package:ludo_game/widgets/power_widget.dart';
import 'package:ludo_game/widgets/victory_overlay.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';

part 'ludo_parts/animations.part.dart';
part 'ludo_parts/background_layer.part.dart';
part 'ludo_parts/board_layer.part.dart';
part 'ludo_parts/settings_menu.part.dart';

// ==============================
// LUDO SCREEN
// The main game screen. Composed of several isolated sub-widgets
// to minimize unnecessary rebuilds:
//
//   _BackgroundLayer  — static background image (never rebuilds).
//   _BoardLayer       — board + all pawns (rebuilds on any game state change).
//   DiceWidget        — dice (isolated rebuild + RepaintBoundary).
//   _SettingsMenu     — popup menu for hacks/reset/exit.
//   VictoryOverlay    — shown only when winner != null.
//
// The dice floats near the current player's corner, animated with
// AnimatedAlign so it smoothly slides when the turn changes.
// ==============================

class LudoScreen extends StatelessWidget {
  const LudoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("LudoScreen build");

    // Use context.select to subscribe only to the two values this widget needs,
    // preventing full rebuilds when unrelated state changes.
    final currentTurn = context.select<GameProvider, PlayerColor>(
      (p) => p.currentTurn,
    );
    final isGameOver = context.select<GameProvider, bool>((p) => p.isGameOver);
    final winner = context.select<GameProvider, List<PlayerColor>>(
      (p) => p.winner,
    );
    final allPlayers = context.select<GameProvider, List<Player>>(
      (p) => p.players,
    );
    final gameSessionId = context.select<GameProvider, int>(
      (p) => p.gameSessionId,
    );
    final isOnline = context.select<GameProvider, bool>(
      (p) => p.isOnlineMultiplayer,
    );
    final myColor = context.select<GameProvider, PlayerColor?>(
      (p) => p.myLocalColor,
    );
    final roomStatus = context.select<GameProvider, String>(
      (p) => p.roomStatus,
    );

    final viewColor = myColor ?? PlayerColor.green;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (roomStatus == 'ended_by_host') {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text(
              "Game ended by host",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.read<GameProvider>().exitGame();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StartScreen()),
          (route) => false,
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
      },
      child: Scaffold(
        backgroundColor: Colors.white,

        body: Stack(
          fit: StackFit.expand,
          children: [
            // ─── 1. BACKGROUND IMAGE ───
            // Static — wrapped in its own widget so it never rebuilds.
            const _BackgroundLayer(),

            // ─── 2. BOARD + PAWNS ───
            // Rebuilds whenever game state changes.
            const _BoardLayer(),

            // ─── 3. DICE OVERLAY ───
            // Floats to a corner matching the current player using AnimatedAlign.
            SafeArea(
              child: AnimatedAlign(
                // ADJUSTABLE: Change dice slide animation speed here (currently 450 ms).
                duration: AppConfig.standardUiAnimationDuration,
                curve: Curves.easeInOutCubic,
                alignment: _getDiceAlignment(currentTurn, viewColor),
                child: const Padding(
                  // ADJUSTABLE: Change dice padding from screen edge here (currently 10 px).
                  padding: EdgeInsets.all(10),
                  child: RepaintBoundary(child: DiceWidget()),
                ),
              ),
            ),

            // ─── 3.5 ACTIVE POWERS / CHEATS INDICATOR ───
            Positioned(
              bottom: 8,
              right: 10,
              child: Consumer<GameProvider>(
                builder: (context, provider, child) {
                  List<String> activeCheats = [];
                  if (provider.eliminateAllOpponents) {
                    activeCheats.add("Eliminate All");
                  }
                  if (provider.isBulldozerMode) activeCheats.add("Bulldozer");
                  if (provider.alwaysRollSix) activeCheats.add("Always Roll 6");
                  if (provider.enableSpecialPowers) {
                    activeCheats.add("Special Powers");
                  }

                  if (activeCheats.isEmpty) return const SizedBox.shrink();

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "ACTIVE RULES:",
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...activeCheats.map(
                          (cheat) => Text(
                            "• $cheat",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ─── 4. SETTINGS MENU ───
            Positioned(
              bottom: 10,
              child: const RepaintBoundary(child: _SettingsMenu()),
            ),

            // ─── 5. VICTORY OVERLAY ───
            // Covers the entire screen when a winner is determined.
            if (isGameOver)
              Positioned.fill(
                child: VictoryOverlay(winners: winner, allPlayers: allPlayers),
              ),

            // ----- Pause Overlay
            if (context.select<GameProvider, bool>((p) => p.isPaused) &&
                !isGameOver)
              const Positioned.fill(child: PauseOverlay()),

            // ─── 6. TELEPORT FLASH ───
            const _TeleportFlashOverlay(),

            // ─── 7. GAME START BLINKING ANIMATION ───
            _GameStartBlinker(key: ValueKey(gameSessionId)),

            ...allPlayers.map((player) {
              final hasReverse = player.pawns.any(
                (p) => p.hasReverse && p.state == PawnState.onPath,
              );
              if (!hasReverse) return const SizedBox.shrink();

              // In online mode, only show the button for the local player who owns it
              if (isOnline && player.color != myColor) {
                return const SizedBox.shrink();
              }

              // only allow clicking if its their turn.
              final isMyTurn = currentTurn == player.color;
              final useReverseMode = context.select<GameProvider, bool>(
                (p) => p.useReverseMode,
              );
              return SafeArea(
                child: AnimatedAlign(
                  alignment: _getPowerAlignment(player.color, viewColor),
                  duration: AppConfig.standardUiAnimationDuration,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: AnimatedOpacity(
                      duration: AppConfig.standardUiAnimationDuration,
                      opacity: isMyTurn ? 1.0 : 0.5,
                      child: ElevatedButton.icon(
                        onPressed: isMyTurn
                            ? () {
                                HapticFeedback.mediumImpact();
                                context
                                    .read<GameProvider>()
                                    .toggleReverseMode();
                              }
                            : null,
                        label: Text(
                          useReverseMode && isMyTurn ? 'Cancel' : "Use Reverse",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        icon: Icon(
                          Icons.u_turn_left,
                          color: useReverseMode && isMyTurn
                              ? Colors.white
                              : Colors.purple,
                          size: 14,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: useReverseMode && isMyTurn
                              ? Colors.purple
                              : Colors.white,
                          foregroundColor: Colors.purple,
                          elevation: 6,
                          minimumSize: const Size(0, 30),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ==============================
  // DICE ALIGNMENT HELPER
  // ==============================

  /// Maps the current player's turn to a screen-corner Alignment
  /// so the dice floats near their base corner.
  /// ADJUSTABLE: Change the dice corner position for each color here.
  ///   Green  → top-left     (-1, -0.85)
  ///   Yellow → top-right    ( 1, -0.85)
  ///   Blue   → bottom-right ( 1,  0.7)
  ///   Red    → bottom-left  (-1,  0.7)
  Alignment _getDiceAlignment(PlayerColor turn, PlayerColor viewColor) {
    int viewIndex = PlayerColor.values.indexOf(viewColor);
    int turnIndex = PlayerColor.values.indexOf(
      turn,
    ); // Fixed typo from turnIndaex too!
    int relativeTurn = (turnIndex - viewIndex + 4) % 4;

    switch (relativeTurn) {
      case 0:
        return const Alignment(-1, 0.7); // Bottom-Left (Viewer)
      case 1:
        return const Alignment(-1, -0.85); // Top-Left (Next Player)
      case 2: // ✅ FIXED: Added missing case 2
        return const Alignment(1, -0.85); // Top-Right (Opposite)
      case 3: // ✅ FIXED: Changed from 4 to 3
        return const Alignment(1, 0.7); // Bottom-Right (Previous Player)
      default:
        return const Alignment(-1, 0.7);
    }
  }

  Alignment _getPowerAlignment(PlayerColor turn, PlayerColor viewColor) {
    int viewIndex = PlayerColor.values.indexOf(viewColor);
    int turnIndex = PlayerColor.values.indexOf(turn);
    int relativeTurn = (turnIndex - viewIndex + 4) % 4;

    switch (relativeTurn) {
      case 0:
        return const Alignment(-1, 0.90); // Below Bottom-Left
      case 1:
        return const Alignment(-1, -0.65); // Below Top-Left
      case 2:
        return const Alignment(1, -0.65); // Below Top-Right
      case 3:
        return const Alignment(1, 0.90); // Below Bottom-Right
      default:
        return const Alignment(-1, 0.90);
    }
  }
}
