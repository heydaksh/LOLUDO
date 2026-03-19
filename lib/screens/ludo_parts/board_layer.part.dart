part of '../ludo_screen.dart';

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
    // ignore: unused_local_variable
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
                                  margin: EdgeInsets.all(baseSize * 0.15),
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
        const SizedBox(height: 20),
      ],
    );
  }
}
