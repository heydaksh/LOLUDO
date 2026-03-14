import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/screens/player_selection_screen.dart';
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
                duration: const Duration(milliseconds: 300),
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
              child: RepaintBoundary(child: _SettingsMenu()),
            ),

            // ─── 5. VICTORY OVERLAY ───
            // Covers the entire screen when a winner is determined.
            // ─── 5. VICTORY OVERLAY ───
            if (isGameOver)
              Positioned.fill(
                child: VictoryOverlay(winners: winner, allPlayers: allPlayers),
              ),

            // ─── 6. TELEPORT FLASH ───
            const _TeleportFlashOverlay(),

            // ─── 7. GAME START BLINKING ANIMATION ───
            _GameStartBlinker(key: ValueKey(gameSessionId)),
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
  ///
  /// ADJUSTABLE: Change the dice corner position for each color here.
  ///   Green  → top-left     (-1, -0.8)
  ///   Yellow → top-right    ( 1, -0.8)
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
      'assets/images/bg_image.webp',
      fit: BoxFit.cover,
      // ADJUSTABLE: Change background image opacity here (currently 0.7).
      opacity: const AlwaysStoppedAnimation(.3),
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
    final size = MediaQuery.of(context).size;
    final gameProvider = context.watch<GameProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SizedBox(
        height: size.height / 18,
        child: Align(
          alignment: Alignment.bottomRight,
          child: Container(
            margin: EdgeInsets.only(right: size.width / 40),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              color: Colors.grey.shade900,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(size.width / 25),
              ),
              icon: Icon(
                Icons.settings,
                color: Colors.white,
                size: size.width / 16,
              ),

              itemBuilder: (context) => [
                /// HACKS
                PopupMenuItem(
                  value: 'Hacks',
                  child: Row(
                    children: [
                      Icon(
                        Icons.flash_on,
                        color: Colors.orange,
                        size: size.width / 20,
                      ),
                      SizedBox(width: size.width / 40),
                      Text(
                        "Hack Menu",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width / 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                /// RESET
                PopupMenuItem(
                  value: 'Reset',
                  child: Row(
                    children: [
                      Icon(
                        Icons.restart_alt,
                        color: Colors.green,
                        size: size.width / 20,
                      ),
                      SizedBox(width: size.width / 40),
                      Text(
                        "Restart Game",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width / 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // remove player
                PopupMenuItem(
                  value: 'Remove',
                  child: Row(
                    children: [
                      Icon(
                        Icons.sports_gymnastics,
                        color: Colors.cyanAccent,
                        size: size.width / 20,
                      ),
                      SizedBox(width: size.width / 40),
                      Text(
                        "Remove Player",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width / 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Pass Turn
                PopupMenuItem(
                  value: 'PassTurn',
                  child: Row(
                    children: [
                      Icon(
                        Icons.skip_next_sharp,
                        color: Colors.blue,
                        size: size.width / 20,
                      ),
                      SizedBox(width: size.width / 40),
                      Text(
                        "Pass Turn",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width / 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                /// EXIT
                PopupMenuItem(
                  value: 'Exit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.exit_to_app,
                        color: Colors.red,
                        size: size.width / 20,
                      ),
                      SizedBox(width: size.width / 40),
                      Text(
                        "Exit Game",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: size.width / 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              onSelected: (value) async {
                debugPrint("Settings menu selected: $value");

                if (value == 'Hacks') {
                  _showHackMenu(context);
                } else if (value == 'Reset') {
                  showDialog(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        title: Row(
                          children: [
                            Icon(
                              Icons.restart_alt,
                              color: Colors.green,
                              size: size.width / 10,
                            ),
                            SizedBox(width: size.width / 40),
                            Text(
                              "Reset Game",
                              style: TextStyle(
                                fontSize: size.width / 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          "Are you sure you want to reset the game?",
                          style: TextStyle(fontSize: size.width / 28),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: size.width / 28,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<GameProvider>().restartGame();
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Reset",
                              style: TextStyle(
                                fontSize: size.width / 28,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                } else if (value == 'Remove') {
                  _showRemovePlayerDialog(context);
                } else if (value == 'PassTurn') {
                  HapticFeedback.mediumImpact();
                  gameProvider.nextTurn();
                } else if (value == 'Exit') {
                  showDialog(
                    context: context,
                    builder: (_) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(size.width / 18),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(size.width / 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              size.width / 18,
                            ),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              /// ICON
                              Icon(
                                Icons.exit_to_app,
                                size: size.width / 8,
                                color: Colors.red,
                              ),

                              SizedBox(height: size.height / 80),

                              /// TITLE
                              Text(
                                "Exit Game",
                                style: TextStyle(
                                  fontSize: size.width / 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: size.height / 100),

                              /// MESSAGE
                              Text(
                                "Are you sure you want to exit the game?",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: size.width / 26,
                                  color: Colors.black54,
                                ),
                              ),

                              SizedBox(height: size.height / 40),

                              /// BUTTONS
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  /// CANCEL
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: size.width / 15,
                                        vertical: size.height / 70,
                                      ),
                                      backgroundColor: Colors.grey,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          size.width / 10,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                        fontSize: size.width / 26,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),

                                  /// EXIT
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.pop(context);

                                      final Map<PlayerColor, String>? result =
                                          await Navigator.push<
                                            Map<PlayerColor, String>
                                          >(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const PlayerSelectionScreen(),
                                            ),
                                          );

                                      if (result != null && context.mounted) {
                                        context
                                            .read<GameProvider>()
                                            .initializePlayers(result);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: size.width / 15,
                                        vertical: size.height / 70,
                                      ),
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          size.width / 10,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      "Exit",
                                      style: TextStyle(
                                        fontSize: size.width / 26,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ),
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
    final size = MediaQuery.of(context).size;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Consumer<GameProvider>(
          builder: (context, modalProvider, child) {
            return Container(
              height: size.height / 4.5,
              padding: EdgeInsets.symmetric(
                horizontal: size.width / 25,
                vertical: size.height / 80,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(size.width / 18),
                ),
                boxShadow: const [
                  BoxShadow(blurRadius: 20, color: Colors.black26),
                ],
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  /// BULLDOZER MODE
                  _hackCard(
                    size: size,
                    icon: Icons.shield,
                    title: "Bulldozer",
                    subtitle: "Sweep enemies",
                    active: modalProvider.isBulldozerMode,
                    color: Colors.orange,
                    onTap: () {
                      modalProvider.toggleBulldozerMode();
                      HapticFeedback.mediumImpact();
                    },
                  ),

                  SizedBox(width: size.width / 25),

                  /// ELIMINATE ALL
                  _hackCard(
                    size: size,
                    icon: Icons.flash_on,
                    title: "Eliminate",
                    subtitle: "Break stack rule",
                    active: modalProvider.eliminateAllOpponents,
                    color: Colors.green,
                    onTap: () {
                      modalProvider.toggleEliminateAll();
                      HapticFeedback.mediumImpact();
                    },
                  ),

                  SizedBox(width: size.width / 25),

                  /// ALWAYS 6
                  _hackCard(
                    size: size,
                    icon: Icons.casino,
                    title: "Always 6",
                    subtitle: "Fixed dice",
                    active: modalProvider.alwaysRollSix,
                    color: Colors.purple,
                    onTap: () {
                      modalProvider.toggleAlwaysRollSix();
                      HapticFeedback.mediumImpact();
                    },
                  ),

                  SizedBox(width: size.width / 25),

                  /// SPECIAL POWERS
                  _hackCard(
                    size: size,
                    icon: Icons.bolt,
                    title: "Powers",
                    subtitle: "Power tiles",
                    active: modalProvider.enableSpecialPowers,
                    color: Colors.amber,
                    onTap: () {
                      modalProvider.toggleSpecialPowers();
                      HapticFeedback.mediumImpact();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // remove player
  void _showRemovePlayerDialog(BuildContext context) {
    final size = MediaQuery.of(context).size;

    showDialog(
      context: context,
      builder: (_) {
        return Consumer<GameProvider>(
          builder: (context, provider, child) {
            final players = provider.players;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(size.width / 18),
              ),
              child: Container(
                padding: EdgeInsets.all(size.width / 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.width / 18),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// TITLE
                    Text(
                      "Remove Player(s)",
                      style: TextStyle(
                        fontSize: size.width / 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Who don't want to play",
                      style: TextStyle(
                        fontSize: size.width / 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: size.height / 40),

                    /// PLAYER LIST
                    ...players.map((player) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColor(player.color),
                        ),

                        title: Text(
                          player.color.name.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: size.width / 26,
                          ),
                        ),

                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            provider.removePlayer(player.color);

                            Navigator.pop(context);
                          },
                        ),
                      );
                    }),

                    SizedBox(height: size.height / 80),

                    /// CLOSE BUTTON
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getColor(PlayerColor color) {
    switch (color) {
      case PlayerColor.green:
        return Colors.green;
      case PlayerColor.yellow:
        return Colors.yellow;
      case PlayerColor.blue:
        return Colors.blue;
      case PlayerColor.red:
        return Colors.red;
    }
  }

  Widget _hackCard({
    required Size size,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: size.width / 3,
        padding: EdgeInsets.all(size.width / 25),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
              : null,
          color: active ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(size.width / 18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? Colors.white : Colors.black54,
              size: size.width / 12,
            ),

            SizedBox(height: size.height / 120),

            Text(
              title,
              style: TextStyle(
                fontSize: size.width / 26,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : Colors.black,
              ),
            ),

            SizedBox(height: size.height / 200),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.width / 35,
                color: active ? Colors.white70 : Colors.black54,
              ),
            ),

            SizedBox(height: size.height / 150),

            Icon(
              active ? Icons.toggle_on : Icons.toggle_off,
              color: active ? Colors.white : Colors.black38,
              size: size.width / 10,
            ),
          ],
        ),
      ),
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
    final boardSize = MediaQuery.of(context).size;

    //  Fetch the list of removed players
    final removedPlayers = context.select<GameProvider, List<PlayerColor>>(
      (p) => p.removedPlayers,
    );
    debugPrint("BoardLayer rebuild");

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          // ADJUSTABLE: Change board outer padding here (currently 10 px).
          padding: const EdgeInsets.symmetric(horizontal: 7),
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

                return Center(
                  child: SizedBox(
                    height: boardSize.width,
                    width: boardSize.width,
                    child: Stack(
                      children: [
                        // ─── 1. BOARD CANVAS ───
                        // RepaintBoundary prevents the canvas from repainting
                        // when only pawn positions change.
                        RepaintBoundary(
                          child: CustomPaint(
                            size: boardSize,
                            painter: LudoBoardPainter(
                              portals: gameProvider.activePortals,
                              portalState: gameProvider.activePortals
                                  .map(
                                    (p) => '${p.a}-${p.b}-${p.remainingTurns}',
                                  )
                                  .join('|'),
                              // portalState: gameProvider.activePortals
                              //     .map((p) => '${p.a}-${p.b}-${p.remainingTurns}')
                              //     .join('|'),
                            ),
                          ),
                        ),

                        // ─── 1.5 PORTAL WIDGETS (ANIMATED) ───
                        ...gameProvider.activePortals.expand((portal) {
                          final Offset posA =
                              BoardCoordinates.mainPath[portal.a % 52];
                          final Offset posB =
                              BoardCoordinates.mainPath[portal.b % 52];

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

                        // ─── 1.6 POWER WIDGETS (ANIMATED) ───
                        ...gameProvider.activePower.map((power) {
                          final Offset pos =
                              BoardCoordinates.mainPath[power.position % 52];
                          final double cellSize = boardSize.width / 15;

                          return Positioned(
                            left: pos.dx * cellSize + (cellSize - 30) / 2,
                            top: pos.dy * cellSize + (cellSize - 30) / 2,
                            child: PowerWidget(type: power.type),
                          );
                        }),

                        ...gameProvider.winner.asMap().entries.map((entry) {
                          final int rank = entry.key + 1;
                          final PlayerColor color = entry.value;

                          double left = 0;
                          double top = 0;

                          final double baseSize = boardSize.width * (5 / 15);

                          // determine which color's base is in..
                          switch (color) {
                            case PlayerColor.green:
                              left = boardSize.width * (0.5 / 15);
                              top = boardSize.width * (0.5 / 15);
                              debugPrint(
                                'Positioning Green Crown responsively at $left, $top',
                              );
                              break;
                            case PlayerColor.yellow:
                              left = boardSize.width * (9.5 / 15);
                              top = boardSize.width * (0.5 / 15);
                              debugPrint(
                                'Positioning Yellow Crown responsively at $left, $top',
                              );
                              break;
                            case PlayerColor.blue:
                              left = boardSize.width * (9.5 / 15);
                              top = boardSize.width * (9.5 / 15);
                              debugPrint(
                                'Positioning Blue Crown responsively at $left, $top',
                              );
                              break;
                            case PlayerColor.red:
                              left = boardSize.width * (0.5 / 15);
                              top = boardSize.width * (9.5 / 15);
                              debugPrint(
                                'Positioning Red Crown responsively at $left, $top',
                              );
                              break;
                          }

                          Color crownColor;
                          String rankText;
                          if (rank == 1) {
                            crownColor = Colors.amber; // golden crown
                            rankText = "1st";
                          } else if (rank == 2) {
                            crownColor = Colors.grey.shade300; // sliver crown
                            rankText = "2nd";
                          } else {
                            crownColor = const Color(0xFFCD7F32); // Bronze
                            rankText = "3rd";
                          }

                          return Positioned(
                            left: left,
                            top: top,
                            width: baseSize,
                            height: baseSize,
                            child: IgnorePointer(
                              child: TweenAnimationBuilder<double>(
                                curve: Curves.elasticOut,
                                key: ValueKey('Crown${color.name}'),
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 800),
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  margin: .all(baseSize * 0.15),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.emoji_events,
                                          color: crownColor,
                                          size: baseSize * 0.35,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black87,
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        Text(
                                          rankText,
                                          style: TextStyle(
                                            color: crownColor,
                                            fontSize: baseSize * 0.15,
                                            fontWeight: FontWeight.bold,
                                            shadows: const [
                                              Shadow(
                                                color: Colors.black87,
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        // ─── 2. PAWN WIDGETS ───
                        // Map each pawn to its PawnWidget, then sort so that
                        // the current player's pawns always render on top (z-order).
                        ...allPawn.map((pawn) {
                            final Offset pos =
                                BoardCoordinates.getPhysicalLocation(
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
                              isCurrentTurn:
                                  gameProvider.currentTurn == pawn.color,
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

                        // -- player names-----
                        ...gameProvider.players.map((player) {
                          double padding = boardSize.width * 0;
                          bool shouldFlip =
                              player.color == PlayerColor.green ||
                              player.color == PlayerColor.yellow;
                          return Positioned(
                            left:
                                (player.color == PlayerColor.green ||
                                    player.color == PlayerColor.red)
                                ? padding
                                : null,
                            right:
                                (player.color == PlayerColor.yellow ||
                                    player.color == PlayerColor.blue)
                                ? padding
                                : null,
                            top:
                                (player.color == PlayerColor.green ||
                                    player.color == PlayerColor.yellow)
                                ? padding
                                : null,
                            bottom:
                                (player.color == PlayerColor.red ||
                                    player.color == PlayerColor.blue)
                                ? padding
                                : null,
                            child: Transform.rotate(
                              angle: shouldFlip ? math.pi : 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(230),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.black54,
                                    width: 1.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  player.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        boardSize.width *
                                        0.030, // Scales dynamically
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        ...removedPlayers.map((color) {
                          // A player base is exactly 6/15ths of the total board width.
                          double baseSize = boardSize.width * (6 / 15);
                          double? left, right, top, bottom;

                          // Snap the container to the exact corner of the removed player's base
                          switch (color) {
                            case PlayerColor.green:
                              left = 0;
                              top = 0;
                              break;
                            case PlayerColor.yellow:
                              right = 0;
                              top = 0;
                              break;
                            case PlayerColor.blue:
                              right = 0;
                              bottom = 0;
                              break;
                            case PlayerColor.red:
                              left = 0;
                              bottom = 0;
                              break;
                          }

                          return Positioned(
                            left: left,
                            right: right,
                            top: top,
                            bottom: bottom,
                            width: baseSize,
                            height: baseSize,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(160),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white54,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons
                                      .person_off_rounded, // The "removed" icon
                                  color: Colors.white,
                                  size:
                                      baseSize *
                                      0.35, // Scales perfectly with the board
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 20),
        // ─── PASS TURN BUTTON ───
        // Allows the current player to manually skip their turn.
        // ─── ACTION BUTTONS (POWERS) ───
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 2. Reverse Power Button (Only shows if current player has the power)
              if (gameProvider.players
                  .firstWhere((p) => p.color == gameProvider.currentTurn)
                  .pawns
                  .any((p) => p.hasReverse && p.state == PawnState.onPath)) ...[
                const SizedBox(width: 15),

                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    gameProvider.toggleReverseMode();
                  },
                  icon: Icon(
                    Icons.u_turn_left,
                    color: gameProvider.useReverseMode
                        ? Colors.white
                        : Colors.purple,
                  ),
                  label: Text(
                    gameProvider.useReverseMode
                        ? 'Cancel Reverse'
                        : 'Use Reverse',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gameProvider.useReverseMode
                        ? Colors.purple
                        : Colors.white,
                    foregroundColor: gameProvider.useReverseMode
                        ? Colors.white
                        : Colors.purple,
                    elevation: 4,
                  ),
                ),
              ],
            ],
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
// ==============================
// GAME START BLINKER
// A brief, non-blocking text overlay that blinks "GAME STARTS"
// in the center of the board when a new session begins.
// ==============================

class _GameStartBlinker extends StatefulWidget {
  const _GameStartBlinker({super.key});

  @override
  State<_GameStartBlinker> createState() => _GameStartBlinkerState();
}

class _GameStartBlinkerState extends State<_GameStartBlinker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 330),
    );
    _playAnimation();
  }

  Future<void> _playAnimation() async {
    debugPrint('[ANIMATION] Playing "Game Starts" blink sequence');
    AudioManager.playGameStart();
    // Blink 3 times
    for (int i = 0; i < 5; i++) {
      if (!mounted) return;
      await _controller.forward();
      if (!mounted) return;
      await _controller.reverse();
    }

    // Hide widget completely after sequence
    if (mounted) {
      setState(() {
        _isVisible = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    // [FIX]: Positioned.fill + AbsorbPointer creates an invisible shield
    // over the entire screen that blocks ALL taps (dice, pawns, settings)
    // until the animation finishes and _isVisible becomes false.
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Center(
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_controller),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Text(
                "GAME STARTS",
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
