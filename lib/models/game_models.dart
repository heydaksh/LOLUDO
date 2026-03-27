// ==============================
// ENUMS
// ==============================

enum PlayerColor { green, yellow, blue, red }

enum PawnState { inBase, onPath, onHomeStretch, finished }

// ==============================
// PAWN MODEL
// ==============================

class Pawn {
  final int id;
  final PlayerColor color;

  /// Progress across the board:
  /// 0 (base), 0–50 (path), 51–55 (home stretch), 56 (finished)
  int step;

  PawnState state;
  int shieldTurn;
  bool hasReverse;

  bool get isShielded => shieldTurn > 0;

  /// Animation flags (UI-related, not game logic)
  bool isDeadAnimation;
  bool isWinningAnimation;

  Pawn({
    required this.id,
    required this.color,
    this.step = 0,
    this.state = PawnState.inBase,
    this.isDeadAnimation = false,
    this.isWinningAnimation = false,
    this.shieldTurn = 0,
    this.hasReverse = false,
  });

  /// Reset pawn after being captured
  void reset() {
    step = 0;
    state = PawnState.inBase;
    isDeadAnimation = false;
    isWinningAnimation = false;
    hasReverse = false;
    shieldTurn = 0;
  }
}

// ==============================
// PLAYER MODEL
// ==============================

class Player {
  final PlayerColor color;
  final List<Pawn> pawns;

  bool isActive;
  bool hasMultiplier;
  String name;
  bool isBot;

  int turnsWithoutSix;

  Player({
    required this.color,
    required this.pawns,
    this.isActive = true,
    this.hasMultiplier = false,
    this.name = '',
    this.isBot = false,
    this.turnsWithoutSix = 0,
  });

  /// True when all pawns reached final state
  bool get hasWon {
    return pawns.every((p) => p.state == PawnState.finished);
  }
}

// ==============================
// AI BOTS
// ===========================

class PlayerSetup {
  final String name;
  final bool isBot;

  PlayerSetup({required this.name, required this.isBot});
}
