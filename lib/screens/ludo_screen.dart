import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/screens/player_selection_screen.dart';
import 'package:ludo_game/utils/board_coordinates.dart';
import 'package:ludo_game/widgets/board_painter.dart';
import 'package:ludo_game/widgets/dice_widget.dart';
import 'package:ludo_game/widgets/pawn_widget.dart';
import 'package:ludo_game/widgets/portal_widget.dart';
import 'package:ludo_game/widgets/victory_overlay.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';

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

    final winner = context.select<GameProvider, PlayerColor?>((p) => p.winner);

    return Scaffold(
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
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOutBack,
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
            child: RepaintBoundary(child: _SettingsMenu()),
          ),

          // ─── 5. VICTORY OVERLAY ───
          // Covers the entire screen when a winner is determined.
          if (winner != null)
            Positioned.fill(child: VictoryOverlay(winnerColor: winner)),

          // ─── 6. TELEPORT FLASH ───
          const _TeleportFlashOverlay(),
        ],
      ),
    );
  }

  // ==============================
  // DICE ALIGNMENT HELPER
  // ==============================

  /// Maps the current player's turn to a screen-corner Alignment
  /// so the dice floats near their base corner.
  ///
  /// ADJUSTABLE: Change the dice corner position for each color here.
  ///   Green  → top-left     (-1, -0.8)
  ///   Yellow → top-right    ( 1, -0.8)
  ///   Blue   → bottom-right ( 1,  0.7)
  ///   Red    → bottom-left  (-1,  0.7)
  Alignment _getDiceAlignment(PlayerColor turn) {
    switch (turn) {
      case PlayerColor.green:
        return const Alignment(-1, -0.8);
      case PlayerColor.yellow:
        return const Alignment(1, -0.8);
      case PlayerColor.blue:
        return const Alignment(1, 0.7);
      case PlayerColor.red:
        return const Alignment(-1, 0.7);
    }
  }
}

// ==============================
// BACKGROUND LAYER
// Renders the background image at 70% opacity behind everything else.
// Isolated as its own widget so it never triggers rebuilds.
// ==============================

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/bg_image_3.webp',
      fit: BoxFit.cover,
      // ADJUSTABLE: Change background image opacity here (currently 0.7).
      opacity: const AlwaysStoppedAnimation(.7),
    );
  }
}

// ==============================
// SETTINGS MENU
// A gear icon that opens a popup menu with three options:
//   • Hacks  → Opens the cheat/toggle bottom sheet.
//   • Reset  → Restarts the current game.
//   • Exit   → Returns to the player selection screen.
// ==============================

class _SettingsMenu extends StatelessWidget {
  const _SettingsMenu();

  @override
  Widget build(BuildContext context) {
    return Container(
      // ADJUSTABLE: Change settings menu bar height here (currently 40 px).
      height: 40,
      alignment: Alignment.bottomRight,
      child: PopupMenuButton(
        color: Colors.transparent,
        icon: const Icon(Icons.settings),
        itemBuilder: (context) {
          return const [
            PopupMenuItem(
              value: 'Hacks',
              child: Text(
                'Hacks',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            PopupMenuItem(
              value: 'Reset',
              child: Text(
                'Reset',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            PopupMenuItem(
              value: 'Exit',
              child: Text('Exit', style: TextStyle(color: Colors.red)),
            ),
          ];
        },
        onSelected: (value) async {
          debugPrint("Settings menu selected: $value");

          if (value == 'Hacks') {
            _showHackMenu(context);
          } else if (value == 'Reset') {
            context.read<GameProvider>().restartGame();
          } else if (value == 'Exit') {
            showDialog(
              context: context,
              builder: (_) {
                return AlertDialog(
                  title: Text('Exit Game'),
                  content: Text('Are you sure you want to exit?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final int? count = await Navigator.push<int>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PlayerSelectionScreen(),
                          ),
                        );
                        // Re-initialize the game with the newly chosen player count.
                        if (count != null && context.mounted) {
                          context.read<GameProvider>().initializePlayers(count);
                        }
                      },
                      child: Text('Exit'),
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }

  // ==============================
  // Hack Menu -- cheat toogles.
  // ==============================

  /// Shows a bottom sheet with toggles for debug/cheat features:
  ///   • Bulldozer Mode      — kills enemies on all intermediate cells.
  ///   • Eliminate All       — kills ALL enemies on same cell at once.
  ///   • Always Roll 6       — forces dice to always return 6.
  ///
  /// Uses Consumer -GameProvider- so each button reflects live state.
  void _showHackMenu(BuildContext context) {
    showModalBottomSheet(
      showDragHandle: true,
      backgroundColor: Colors.white,
      context: context,
      builder: (_) {
        return Consumer<GameProvider>(
          builder: (context, modalProvider, child) {
            debugPrint("Hack menu rebuild");

            return SizedBox(
              // ADJUSTABLE: Change hack menu bottom sheet height here (currently 150 px).
              height: 150,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // ─── BULLDOZER MODE TOGGLE ───
                      // Sweep-captures enemies on every intermediate step.
                      ElevatedButton(
                        onPressed: () {
                          modalProvider.toggleBulldozerMode();
                          HapticFeedback.mediumImpact();
                        },
                        style: ElevatedButton.styleFrom(
                          // Turns orange when active, grey when inactive.
                          backgroundColor: modalProvider.isBulldozerMode
                              ? Colors.orange
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          elevation: 4,
                        ),
                        child: Text(
                          modalProvider.isBulldozerMode
                              ? 'Bulldozer: ON'
                              : 'Bulldozer: OFF',
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ─── ELIMINATE ALL TOGGLE ───
                      // Kills ALL opponent pawns on the same cell (not just one).
                      ElevatedButton(
                        onPressed: () {
                          modalProvider.toggleEliminateAll();
                          HapticFeedback.mediumImpact();
                        },
                        style: ElevatedButton.styleFrom(
                          // Green when active (all-clear mode), red when inactive.
                          backgroundColor: modalProvider.eliminateAllOpponents
                              ? Colors.green
                              : Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 4,
                        ),
                        child: Text(
                          modalProvider.eliminateAllOpponents
                              ? 'Eliminate All: ON'
                              : 'Eliminate All: OFF',
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ─── ALWAYS ROLL 6 TOGGLE ───
                      // Forces every dice roll to produce a 6.
                      ElevatedButton(
                        onPressed: () {
                          modalProvider.toggleAlwaysRollSix();
                          HapticFeedback.mediumImpact();
                        },
                        style: ElevatedButton.styleFrom(
                          // Purple when active, grey when inactive.
                          backgroundColor: modalProvider.alwaysRollSix
                              ? Colors.purple
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          elevation: 4,
                        ),
                        child: Text(
                          modalProvider.alwaysRollSix
                              ? 'Always 6: ON'
                              : 'Always 6: OFF',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==============================
// BOARD LAYER
// Renders the board canvas and all pawn widgets inside a square AspectRatio.
//
// Responsibilities:
//   1. Measure available space via LayoutBuilder.
//   2. Collect all pawns from all players.
//   3. Build a position map (cell key → list of pawns) for overlap detection.
//   4. Render the LudoBoardPainter canvas.
//   5. Render each PawnWidget, sorted so current-player pawns render on top.
//   6. Show the Lottie winning animation if any pawn is currently finishing.
//   7. Provide the "Pass Turn" button below the board.
// ==============================

class _BoardLayer extends StatelessWidget {
  const _BoardLayer();

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();

    debugPrint("BoardLayer rebuild");

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          // ADJUSTABLE: Change board outer padding here (currently 10 px).
          padding: const EdgeInsets.all(10),
          child: AspectRatio(
            // Keep the board square at all screen sizes.
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // The board canvas fills the maximum available square.
                final Size boardSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                // ─── Flatten all player pawns into one list ───
                final List<Pawn> allPawn = gameProvider.players
                    .expand((p) => p.pawns)
                    .toList();

                // ─── Detect any active winning animation ───
                final bool isAnyPawnWinning = allPawn.any(
                  (p) => p.isWinningAnimation,
                );

                // ─── Build overlap map ───
                // Groups pawns by their rounded cell key ("cellX-cellY").
                // Used by PawnWidget to spread overlapping pawns into a cluster.
                final Map<String, List<Pawn>> positionMap = {};
                for (var pawn in allPawn) {
                  final Offset pos = BoardCoordinates.getPhysicalLocation(
                    boardSize,
                    pawn,
                  );

                  // Round to the nearest cell to group nearby pawns together.
                  final int cellX = (pos.dx / (boardSize.width / 15)).round();
                  final int cellY = (pos.dy / (boardSize.height / 15)).round();

                  final String key = "$cellX-$cellY";

                  positionMap.putIfAbsent(key, () => []).add(pawn);
                }

                return Stack(
                  children: [
                    // ─── 1. BOARD CANVAS ───
                    // RepaintBoundary prevents the canvas from repainting
                    // when only pawn positions change.
                    RepaintBoundary(
                      child: CustomPaint(
                        size: boardSize,
                        painter: LudoBoardPainter(
                          portals: gameProvider.activePortals,
                        ),
                      ),
                    ),

                    // ─── 1.5 PORTAL WIDGETS (ANIMATED) ───
                    ...gameProvider.activePortals.expand((portal) {
                        final Offset posA = BoardCoordinates.mainPath[portal.a % 52];
                        final Offset posB = BoardCoordinates.mainPath[portal.b % 52];
                        
                        final double cellSize = boardSize.width / 15;
                        
                        return [
                            Positioned(
                                left: posA.dx * cellSize + (cellSize - 32) / 2,
                                top: posA.dy * cellSize + (cellSize - 32) / 2,
                                child: PortalWidget(
                                    type: portal.type,
                                    remainingTurns: portal.remainingTurns,
                                ),
                            ),
                            Positioned(
                                left: posB.dx * cellSize + (cellSize - 32) / 2,
                                top: posB.dy * cellSize + (cellSize - 32) / 2,
                                child: PortalWidget(
                                    type: portal.type,
                                    remainingTurns: portal.remainingTurns,
                                ),
                            ),
                        ];
                    }),

                    // ─── 2. PAWN WIDGETS ───
                    // Map each pawn to its PawnWidget, then sort so that
                    // the current player's pawns always render on top (z-order).
                    ...allPawn.map((pawn) {
                        final Offset pos = BoardCoordinates.getPhysicalLocation(
                          boardSize,
                          pawn,
                        );

                        final int cellX = (pos.dx / (boardSize.width / 15))
                            .round();
                        final int cellY = (pos.dy / (boardSize.height / 15))
                            .round();

                        final String key = "$cellX-$cellY";

                        final List<Pawn> overlapping =
                            positionMap[key] ?? [pawn];
                        final int overlapIndex = overlapping.indexOf(pawn);
                        final int totalOverlapping = overlapping.length;

                        return PawnWidget(
                          // Stable key prevents unnecessary widget recycling.
                          key: ValueKey('${pawn.color.name}_${pawn.id}'),
                          pawn: pawn,
                          boardSize: boardSize,
                          isCurrentTurn: gameProvider.currentTurn == pawn.color,
                          overlapIndex: overlapIndex,
                          totalOverlapping: totalOverlapping,
                          onTap: () {
                            debugPrint("Pawn tapped from board");
                            gameProvider.movePawn(pawn);
                          },
                        );
                      }).toList()
                      // ─── Sort: current player's pawns paint last (highest z) ───
                      ..sort((a, b) {
                        bool aIsCurrent =
                            a.pawn.color == gameProvider.currentTurn;

                        bool bIsCurrent =
                            b.pawn.color == gameProvider.currentTurn;

                        if (aIsCurrent && !bIsCurrent) return 1;
                        if (!aIsCurrent && bIsCurrent) return -1;

                        return 0;
                      }),

                    // ─── 3. WINNING LOTTIE ANIMATION ───
                    // Shown over the entire board when a pawn reaches the center.
                    // IgnorePointer ensures it doesn't block pawn taps.
                    if (isAnyPawnWinning)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Lottie.asset(
                            'assets/animations/triangle_reach.json',
                            fit: BoxFit.cover,
                            repeat: false,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),

        // ─── PASS TURN BUTTON ───
        // Allows the current player to manually skip their turn.
        Align(
          alignment: Alignment.center,
          child: ElevatedButton(
            onPressed: () {
              debugPrint("Pass turn pressed");
              HapticFeedback.mediumImpact();
              gameProvider.nextTurn();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              foregroundColor: Colors.black,
              elevation: 4,
            ),
            child: const Text('Pass Turn'),
          ),
        ),
      ],
    );
  }
}

// ==============================
// TELEPORT FLASH OVERLAY
// Briefly shows a colored flash when a teleport occurs.
// ==============================

class _TeleportFlashOverlay extends StatelessWidget {
  const _TeleportFlashOverlay();

  @override
  Widget build(BuildContext context) {
    final teleportedPawn = context.select<GameProvider, Pawn?>(
      (p) => p.lastTeleportedPawn,
    );

    if (teleportedPawn == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: 0.3,
        child: Container(color: Colors.white),
      ),
    );
  }
}
