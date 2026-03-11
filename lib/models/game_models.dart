enum PlayerColor { green, yellow, blue, red }

enum PawnState {
  inBase, // Locked inside the starting square (needs a 6 to get out)
  onPath, // Moving along the main outer track
  onHomeStretch, // Moving up the final colored row towards the center
  finished, // Reached the very center, point scored!
}

class Pawn {
  final int id;
  final PlayerColor color;
  int step;
  PawnState state;
  bool isDeadAnimation;
  bool isWinningAnimation;

  Pawn({
    required this.id,
    required this.color,
    this.step = 0,
    this.state = PawnState.inBase,
    this.isDeadAnimation = false,
    this.isWinningAnimation = false,
  });

  // helper method to reset a pawn

  void reset() {
    step = 0;
    state = PawnState.inBase;
    isDeadAnimation = false;
    isWinningAnimation = false;
  }
}

class Player {
  final PlayerColor color;
  final List<Pawn> pawns;

  bool isActive;

  Player({required this.color, required this.pawns, this.isActive = true});

  // helper to check if all pawns for this player have reached the center
  bool get hasWon {
    return pawns.every((p) => p.state == PawnState.finished);
  }
}
