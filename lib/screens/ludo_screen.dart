import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/screens/player_selection_screen.dart';
import 'package:ludo_game/utils/board_coordinates.dart';
import 'package:ludo_game/widgets/board_painter.dart';
import 'package:ludo_game/widgets/dice_widget.dart';
import 'package:ludo_game/widgets/pawn_widget.dart';
import 'package:ludo_game/widgets/victory_overlay.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';

class LudoScreen extends StatelessWidget {
  const LudoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("LudoScreen build");

    // Listen only to required values
    final currentTurn = context.select<GameProvider, PlayerColor>(
      (p) => p.currentTurn,
    );

    final winner = context.select<GameProvider, PlayerColor?>((p) => p.winner);

    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          const _BackgroundLayer(),

          // Board layer (isolated rebuild zone)
          const _BoardLayer(),

          // Dice overlay
          SafeArea(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOutBack,
              alignment: _getDiceAlignment(currentTurn),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: RepaintBoundary(child: DiceWidget()),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            child: RepaintBoundary(child: _SettingsMenu()),
          ),

          // Victory overlay
          if (winner != null)
            Positioned.fill(child: VictoryOverlay(winnerColor: winner)),
        ],
      ),
    );
  }

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

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/bg_image_3.webp',
      fit: BoxFit.cover,
      opacity: const AlwaysStoppedAnimation(.7),
    );
  }
}

class _SettingsMenu extends StatelessWidget {
  const _SettingsMenu();

  @override
  Widget build(BuildContext context) {
    return Container(
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
        onSelected: (value) {
          debugPrint("Settings menu selected: $value");

          if (value == 'Hacks') {
            _showHackMenu(context);
          } else if (value == 'Reset') {
            context.read<GameProvider>().restartGame();
          } else if (value == 'Exit') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PlayerSelectionScreen()),
            );
          }
        },
      ),
    );
  }

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
              height: 150,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          modalProvider.toggleBulldozerMode();
                          HapticFeedback.mediumImpact();
                        },
                        style: ElevatedButton.styleFrom(
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

                      ElevatedButton(
                        onPressed: () {
                          modalProvider.toggleEliminateAll();
                          HapticFeedback.mediumImpact();
                        },
                        style: ElevatedButton.styleFrom(
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

                      ElevatedButton(
                        onPressed: () {
                          modalProvider.toggleAlwaysRollSix();
                          HapticFeedback.mediumImpact();
                        },
                        style: ElevatedButton.styleFrom(
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
          padding: const EdgeInsets.all(10),
          child: AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final Size boardSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                final List<Pawn> allPawn = gameProvider.players
                    .expand((p) => p.pawns)
                    .toList();

                final bool isAnyPawnWinning = allPawn.any(
                  (p) => p.isWinningAnimation,
                );

                final Map<String, List<Pawn>> positionMap = {};
                for (var pawn in allPawn) {
                  final Offset pos = BoardCoordinates.getPhysicalLocation(
                    boardSize,
                    pawn,
                  );

                  final int cellX = (pos.dx / (boardSize.width / 15)).round();
                  final int cellY = (pos.dy / (boardSize.height / 15)).round();

                  final String key = "$cellX-$cellY";

                  positionMap.putIfAbsent(key, () => []).add(pawn);
                }

                return Stack(
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        size: boardSize,
                        painter: LudoBoardPainter(),
                      ),
                    ),

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

                      final List<Pawn> overlapping = positionMap[key] ?? [pawn];
                      final int overlapIndex = overlapping.indexOf(pawn);

                      final int totalOverlapping = overlapping.length;

                      return PawnWidget(
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
                    }).toList()..sort((a, b) {
                      bool aIsCurrent =
                          a.pawn.color == gameProvider.currentTurn;

                      bool bIsCurrent =
                          b.pawn.color == gameProvider.currentTurn;

                      if (aIsCurrent && !bIsCurrent) return 1;
                      if (!aIsCurrent && bIsCurrent) return -1;

                      return 0;
                    }),
                    if (isAnyPawnWinning)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Lottie.asset(
                            'assets/animations/triangle_reach.json',
                            fit: BoxFit
                                .cover, // Stretches it over the full board size
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
