// ==============================
// GAME MODELS
// Core data models for the Ludo game.
//
// Defines:
//   - PlayerColor  : enum of the 4 player colors.
//   - PawnState    : enum of all possible pawn lifecycle states.
//   - Pawn         : represents a single piece on the board.
//   - Player       : represents a player who owns 4 pawns.
// ==============================

// ==============================
// ENUMS
// ==============================

/// The four player colors used throughout the game.
/// Order matches the default turn order: green → yellow → blue → red.
enum PlayerColor { green, yellow, blue, red }

/// The lifecycle state of a single pawn.
///
/// State transitions:
///   inBase → (roll 6) → onPath → (step 51) → onHomeStretch → (step 56) → finished
enum PawnState {
  /// Locked inside the starting square. Requires a dice roll of 6 to exit.
  inBase,

  /// Moving along the 52-cell main outer track.
  onPath,

  /// Moving along the final colored home-stretch arm (steps 51–55) toward the center.
  onHomeStretch,

  /// The pawn has reached the center triangle (step 56). Scores a point for the player.
  finished,
}

// ==============================
// PAWN MODEL
// ==============================

/// Represents a single Ludo game piece.
///
/// Each player has 4 pawns, identified by [id] (0–3) and [color].
/// Movement progress is tracked by [step], which increments each time
/// the pawn moves one cell forward on the board.
class Pawn {
  // ─── Identity ───

  /// Zero-based index of this pawn within its player's pawn list (0–3).
  final int id;

  /// The player color this pawn belongs to.
  final PlayerColor color;

  // ─── Movement State ───

  /// Current movement progress.
  ///
  /// Meaning varies by [state]:
  ///   - inBase         → always 0 (unused).
  ///   - onPath         → 0–50: index into the player's relative main-path segment.
  ///   - onHomeStretch  → 51–55: position along the colored home-stretch arm.
  ///   - finished       → 56: has reached the center triangle.
  int step;

  /// The current lifecycle state of this pawn. See [PawnState].
  PawnState state;

  // ─── Animation Flags ───

  /// True while the pawn's death (knockout) animation is playing.
  /// During this time the pawn is visually collapsed to scale 0.
  bool isDeadAnimation;

  /// True while the pawn's center-arrival (winning) animation is playing.
  /// During this time the pawn is visually expanded and shaking.
  bool isWinningAnimation;

  Pawn({
    required this.id,
    required this.color,
    this.step = 0,
    this.state = PawnState.inBase,
    this.isDeadAnimation = false,
    this.isWinningAnimation = false,
  });

  // ==============================
  // HELPER METHODS
  // ==============================

  /// Resets this pawn back to its initial state (returns it to its home base).
  /// Called when a pawn is captured by an opponent.
  void reset() {
    step = 0;
    state = PawnState.inBase;
    isDeadAnimation = false;
    isWinningAnimation = false;
  }
}

// ==============================
// PLAYER MODEL
// ==============================

/// Represents a player in the game.
/// Owns exactly 4 [pawns] and is identified by [color].
class Player {
  /// The color identifier for this player.
  final PlayerColor color;

  /// The 4 pawns belonging to this player.
  final List<Pawn> pawns;

  /// Whether this player is currently participating in the game.
  /// Can be used to skip inactive players in multi-player setups.
  bool isActive;

  Player({required this.color, required this.pawns, this.isActive = true});

  // ==============================
  // COMPUTED PROPERTIES
  // ==============================

  /// Returns true if ALL 4 of this player's pawns have reached [PawnState.finished].
  /// Used by GameProvider to detect a win condition.
  bool get hasWon {
    return pawns.every((p) => p.state == PawnState.finished);
  }
}
