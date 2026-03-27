import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/models/portals.dart';
import 'package:ludo_game/models/powers.dart';
import 'package:ludo_game/screens/start_screen.dart';
import 'package:ludo_game/utils/app_config.dart';
import 'package:ludo_game/utils/audio_manager.dart';
import 'package:ludo_game/utils/board_coordinates.dart';
import 'package:ludo_game/widgets/board_painter.dart';
import 'package:ludo_game/widgets/dice_widget.dart';
import 'package:ludo_game/widgets/pawn_widget.dart';
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
                alignment: _getDiceAlignment(currentTurn),
                child: const Padding(
                  // ADJUSTABLE: Change dice padding from screen edge here (currently 10 px).
                  padding: EdgeInsets.all(10),
                  child: RepaintBoundary(child: DiceWidget()),
                ),
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

            // ─── 6. TELEPORT FLASH ───
            const _TeleportFlashOverlay(),

            // ─── 7. GAME START BLINKING ANIMATION ───
            _GameStartBlinker(key: ValueKey(gameSessionId)),

            ...allPlayers.map((player) {
              final hasReverse = player.pawns.any(
                (p) => p.hasReverse && p.state == PawnState.onPath,
              );
              if (!hasReverse) return const SizedBox.shrink();

              // only allow clicking if its their turn.
              final isMyTurn = currentTurn == player.color;
              final useReverseMode = context.select<GameProvider, bool>(
                (p) => p.useReverseMode,
              );
              return SafeArea(
                child: AnimatedAlign(
                  alignment: _getPowerAlignment(player.color),
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
                            fontSize: 12,
                          ),
                        ),
                        icon: Icon(
                          Icons.u_turn_left,
                          color: useReverseMode && isMyTurn
                              ? Colors.white
                              : Colors.purple,
                          size: 18,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: useReverseMode && isMyTurn
                              ? Colors.purple
                              : Colors.white,
                          foregroundColor: Colors.purple,
                          elevation: 6,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
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
  Alignment _getDiceAlignment(PlayerColor turn) {
    switch (turn) {
      case PlayerColor.green:
        return const Alignment(-1, -0.85);
      case PlayerColor.yellow:
        return const Alignment(1, -0.85);
      case PlayerColor.blue:
        return const Alignment(1, 0.7);
      case PlayerColor.red:
        return const Alignment(-1, 0.7);
    }
  }

  Alignment _getPowerAlignment(PlayerColor turn) {
    switch (turn) {
      case PlayerColor.green:
        return const Alignment(-1, -0.65); // Below green dice
      case PlayerColor.yellow:
        return const Alignment(1, -0.65); // Below yellow dice
      case PlayerColor.blue:
        return const Alignment(1, 0.90); // Below blue dice
      case PlayerColor.red:
        return const Alignment(-1, 0.90); // Below red dice
    }
  }
}
