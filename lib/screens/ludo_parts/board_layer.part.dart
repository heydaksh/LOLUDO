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
    // Optimization: Only listen to state that affects the board layout/content.
    final players = context.select<GameProvider, List<Player>>(
      (p) => p.players,
    );
    final currentTurn = context.select<GameProvider, PlayerColor>(
      (p) => p.currentTurn,
    );
    final activePortals = context.select<GameProvider, List<Portals>>(
      (p) => p.activePortals,
    );
    final activePower = context.select<GameProvider, List<Power>>(
      (p) => p.activePower,
    );
    final winner = context.select<GameProvider, List<PlayerColor>>(
      (p) => p.winner,
    );
    final removedPlayers = context.select<GameProvider, List<PlayerColor>>(
      (p) => p.removedPlayers,
    );
    // final isOnline = context.select<GameProvider, bool>(
    // (p) => p.isOnlineMultiplayer,
    // );
    final myColor = context.select<GameProvider, PlayerColor?>(
      (p) => p.myLocalColor,
    );
    final viewColor = myColor ?? PlayerColor.green;
    final isAnyPawnWinning = context.select<GameProvider, bool>(
      (p) => p.players
          .expand((player) => player.pawns)
          .any((pawn) => pawn.isWinningAnimation),
    );
    double boardTurns = 0.0;

    switch (viewColor) {
      case PlayerColor.red:
        boardTurns = 0.0;
        break;
      case PlayerColor.blue:
        boardTurns = 0.25;
        break; // 90 deg clockwise
      case PlayerColor.yellow:
        boardTurns = 0.5;
        break; // 180 deg
      case PlayerColor.green:
        boardTurns = -0.25;
        break; // -90 deg
    }
    final gameProvider = context.read<GameProvider>();

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

                final List<Pawn> allPawn = [];
                for (var player in players) {
                  if (gameProvider.isPlayerInGame(player.color)) {
                    allPawn.addAll(player.pawns);
                  }
                }

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
                    child: AnimatedRotation(
                      turns: boardTurns,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOutCubic,
                      child: Stack(
                        children: [
                          // ─── 1. BOARD CANVAS ───
                          // RepaintBoundary prevents the canvas from repainting
                          // when only pawn positions change.
                          RepaintBoundary(
                            child: CustomPaint(
                              size: boardSize,
                              painter: LudoBoardPainter(
                                portals: activePortals,
                                portalState: activePortals
                                    .map(
                                      (p) =>
                                          '${p.a}-${p.b}-${p.remainingTurns}',
                                    )
                                    .join('|'),
                              ),
                            ),
                          ),

                          // ─── 1.5 PORTAL WIDGETS (ANIMATED) ───
                          ...activePortals.expand((portal) {
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
                          ...activePower.map((power) {
                            final Offset pos =
                                BoardCoordinates.mainPath[power.position % 52];
                            final double cellSize = boardSize.width / 15;

                            return Positioned(
                              left: pos.dx * cellSize + (cellSize - 30) / 2,
                              top: pos.dy * cellSize + (cellSize - 30) / 2,
                              child: AnimatedRotation(
                                turns: -boardTurns,
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOutCubic,
                                child: PowerWidget(type: power.type),
                              ),
                            );
                          }),

                          ...winner.asMap().entries.map((entry) {
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
                                break;
                              case PlayerColor.yellow:
                                left = boardSize.width * (9.5 / 15);
                                top = boardSize.width * (0.5 / 15);
                                break;
                              case PlayerColor.blue:
                                left = boardSize.width * (9.5 / 15);
                                top = boardSize.width * (9.5 / 15);
                                break;
                              case PlayerColor.red:
                                left = boardSize.width * (0.5 / 15);
                                top = boardSize.width * (9.5 / 15);
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
                                  curve: Curves.easeInOut,
                                  key: ValueKey('Crown${color.name}'),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration:
                                      AppConfig.boardLayerTransitionDuration,
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
                                      child: child,
                                    );
                                  },
                                  child: AnimatedRotation(
                                    turns: -boardTurns,
                                    duration: const Duration(milliseconds: 600),

                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.4,
                                        ),
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

                              final int cellX =
                                  (pos.dx / (boardSize.width / 15)).round();
                              final int cellY =
                                  (pos.dy / (boardSize.height / 15)).round();

                              final String key = "$cellX-$cellY";

                              final List<Pawn> overlapping =
                                  positionMap[key] ?? [pawn];
                              final int overlapIndex = overlapping.indexOf(
                                pawn,
                              );
                              final int totalOverlapping = overlapping.length;

                              return PawnWidget(
                                // Stable key prevents unnecessary widget recycling.
                                key: ValueKey('${pawn.color.name}_${pawn.id}'),
                                pawn: pawn,
                                boardSize: boardSize,
                                isCurrentTurn: currentTurn == pawn.color,
                                overlapIndex: overlapIndex,
                                totalOverlapping: totalOverlapping,
                                boardTurns: boardTurns,
                                onTap: () {
                                  gameProvider.movePawn(pawn);
                                },
                              );
                            }).toList()
                            // ─── Sort: current player's pawns paint last (highest z) ───
                            ..sort((a, b) {
                              bool aIsCurrent = a.pawn.color == currentTurn;

                              bool bIsCurrent = b.pawn.color == currentTurn;

                              if (aIsCurrent && !bIsCurrent) return 1;
                              if (!aIsCurrent && bIsCurrent) return -1;

                              return 0;
                            }),

                          // ─── 3. WINNING LOTTIE ANIMATION ───
                          // Shown over the entire board when a pawn reaches the center.
                          // IgnorePointer ensures it doesn't block pawn taps.
                          if (isAnyPawnWinning)
                            Positioned.fill(
                              child: Builder(
                                builder: (context) {
                                  // Find the specific pawn that is winning to use as a Key
                                  final winningList = allPawn.where(
                                    (p) => p.isWinningAnimation,
                                  );
                                  final winningPawn = winningList.isNotEmpty
                                      ? winningList.first
                                      : null;

                                  return IgnorePointer(
                                    child: Center(
                                      child: AnimatedRotation(
                                        turns: -boardTurns,
                                        duration: const Duration(
                                          milliseconds: 600,
                                        ),
                                        child: SizedBox(
                                          width: boardSize.width,
                                          height: boardSize.width,
                                          child: Lottie.asset(
                                            'assets/animations/triangle_reach.json',
                                            // ✅ The Key guarantees the animation restarts from 0 for EVERY new pawn!
                                            key: winningPawn != null
                                                ? ValueKey(
                                                    'win_${winningPawn.color.name}_${winningPawn.id}',
                                                  )
                                                : null,
                                            fit: BoxFit.contain,
                                            repeat: false,
                                            frameRate: FrameRate.max,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                          // ----- player names-----
                          ...players.map((player) {
                            if (!gameProvider.isPlayerInGame(player.color)) {
                              return const SizedBox.shrink();
                            }
                            return PlayerNameLabel(
                              player: player,
                              boardSize: boardSize,
                              boardTurns: boardTurns,
                              isOffline: !gameProvider.isOnlineMultiplayer,
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
                                child: AnimatedRotation(
                                  turns: -boardTurns,
                                  duration: const Duration(milliseconds: 600),
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
                              ),
                            );
                          }),
                        ],
                      ),
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
