import 'package:flutter/material.dart';
import 'package:ludo_game/models/game_models.dart';

// ==============================
// BOARD COORDINATES
// Pure utility class — no state, no widgets.
//
// Responsibilities:
//   1. Define the 52-cell main path as a list of grid Offsets.
//   2. Map each (color, pawnId) to a base slot position.
//   3. Convert a Pawn's logical state+step into a physical pixel Offset.
//   4. List the 8 safe-zone path indices.
//   5. Define the 5-cell home-stretch coordinates for each color.
//   6. Compute the absolute path index used for capture comparisons.
//
// Coordinate system:
//   x = column (left → right), y = row (top → bottom).
//   The board is 15×15 cells. Multiplying by cellSize gives pixel coords.
// ==============================

class BoardCoordinates {
  // ==============================
  // MAIN PATH (52 CELLS)
  // ==============================

  // NOTE: This list represents the 52-cell outer ring of the Ludo board,
  // traversed in the GREEN player's direction.
  // Each other color starts at a different offset but follows the same ring.
  //
  // Path segment labels (direction of travel for Green):
  //   • Left arm  (bottom half)  → moves right along row 6
  //   • Top arm   (left half)    → moves up along column 6
  //   • Top arm   (right half)   → moves down along column 8
  //   • Right arm (top half)     → moves right along row 6
  //   • Right arm (bottom half)  → moves left along row 8
  //   • Bottom arm(right half)   → moves down along column 8
  //   • Bottom arm(left half)    → moves up along column 6
  //   • Left arm  (top half)     → moves left along row 8
  //
  // Color starting index offsets:
  //   Green  = index  0   (1, 6)
  //   Yellow = index 13   (8, 1)
  //   Blue   = index 26   (13, 8)
  //   Red    = index 39   (6, 13)
  static const List<Offset> mainPath = [
    // ─── Left arm — bottom half (row 6, columns 1–5) ───
    Offset(1, 6), Offset(2, 6), Offset(3, 6), Offset(4, 6), Offset(5, 6),

    // ─── Top arm — left half (column 6, rows 5 → 0) ───
    Offset(6, 5),
    Offset(6, 4),
    Offset(6, 3),
    Offset(6, 2),
    Offset(6, 1),
    Offset(6, 0),

    // ─── Top corner — turn right (row 0, columns 7–8) ───
    Offset(7, 0), Offset(8, 0),

    // ─── Top arm — right half (column 8, rows 1–5) — Yellow Start at index 13 ───
    Offset(8, 1), Offset(8, 2), Offset(8, 3), Offset(8, 4), Offset(8, 5),

    // ─── Right arm — top half (row 6, columns 9–14) ───
    Offset(9, 6),
    Offset(10, 6),
    Offset(11, 6),
    Offset(12, 6),
    Offset(13, 6),
    Offset(14, 6),

    // ─── Right corner — turn down (column 14, rows 7–8) ───
    Offset(14, 7), Offset(14, 8),

    // ─── Right arm — bottom half (row 8, columns 13 → 9) — Blue Start at index 26 ───
    Offset(13, 8), Offset(12, 8), Offset(11, 8), Offset(10, 8), Offset(9, 8),

    // ─── Bottom arm — right half (column 8, rows 9–14) ───
    Offset(8, 9),
    Offset(8, 10),
    Offset(8, 11),
    Offset(8, 12),
    Offset(8, 13),
    Offset(8, 14),

    // ─── Bottom corner — turn left (row 14, columns 7–6) ───
    Offset(7, 14), Offset(6, 14),

    // ─── Bottom arm — left half (column 6, rows 13 → 9) — Red Start at index 39 ───
    Offset(6, 13), Offset(6, 12), Offset(6, 11), Offset(6, 10), Offset(6, 9),

    // ─── Left arm — top half (row 8, columns 5 → 0) ───
    Offset(5, 8),
    Offset(4, 8),
    Offset(3, 8),
    Offset(2, 8),
    Offset(1, 8),
    Offset(0, 8),

    // ─── Left corner — turn up (column 0, rows 7–6) ───
    Offset(0, 7), Offset(0, 6),
  ];

  // ==============================
  // SAFE ZONES
  // ==============================

  /// Indices in [mainPath] that are safe-zone cells.
  /// Pawns on these cells cannot be captured.
  ///
  /// Index  0 → Green  Start  (1, 6)
  /// Index  8 → Green  Star   (2, 8)
  /// Index 13 → Yellow Start  (8, 1)
  /// Index 21 → Yellow Star   (6, 2)
  /// Index 26 → Blue   Start  (13, 8)
  /// Index 34 → Blue   Star   (12, 6)
  /// Index 39 → Red    Start  (6, 13)
  /// Index 47 → Red    Star   (8, 12)
  static const List<int> safeZones = [0, 8, 13, 21, 26, 34, 39, 47];

  // ==============================
  // HOME STRETCHES
  // ==============================

  /// The 5 grid cells that make up each player's colored home-stretch arm.
  /// Traversed in order: home stretch index 0 (step 51) → index 4 (step 55).
  /// Step 56 = center triangle (handled separately in getPhysicalLocation).
  ///
  /// Each list has exactly 5 entries corresponding to steps 51–55.
  static const Map<PlayerColor, List<Offset>> homeStretches = {
    // Green: left horizontal arm pointing right, along row 7.
    PlayerColor.green: [
      Offset(1, 7),
      Offset(2, 7),
      Offset(3, 7),
      Offset(4, 7),
      Offset(5, 7),
    ],
    // Yellow: top vertical arm pointing down, along column 7.
    PlayerColor.yellow: [
      Offset(7, 1),
      Offset(7, 2),
      Offset(7, 3),
      Offset(7, 4),
      Offset(7, 5),
    ],
    // Blue: right horizontal arm pointing left, along row 7.
    PlayerColor.blue: [
      Offset(13, 7),
      Offset(12, 7),
      Offset(11, 7),
      Offset(10, 7),
      Offset(9, 7),
    ],
    // Red: bottom vertical arm pointing up, along column 7.
    PlayerColor.red: [
      Offset(7, 13),
      Offset(7, 12),
      Offset(7, 11),
      Offset(7, 10),
      Offset(7, 9),
    ],
  };

  // ==============================
  // BASE POSITION LOOKUP
  // ==============================

  /// Returns the grid Offset for a pawn [pawnId] (0–3) of the given [color]
  /// when the pawn is sitting in its home base.
  ///
  /// The 4 base slots are arranged in a 2×2 pattern inside the 6×6 base area:
  ///   id 0 → top-left     id 1 → top-right
  ///   id 2 → bottom-left  id 3 → bottom-right
  ///
  /// The base area origin differs per color:
  ///   Green  → top-left     corner (0, 0)
  ///   Yellow → top-right    corner (9, 0)
  ///   Blue   → bottom-right corner (9, 9)
  ///   Red    → bottom-left  corner (0, 9)
  static Offset getBasePosition(PlayerColor color, int pawnId) {
    // ADJUSTABLE: Change the slot positions within the 6×6 base here.
    List<Offset> baseOffsets = [
      const Offset(1.5, 1.5), // id 0: top-left slot
      const Offset(3.5, 1.5), // id 1: top-right slot
      const Offset(1.5, 3.5), // id 2: bottom-left slot
      const Offset(3.5, 3.5), // id 3: bottom-right slot
    ];
    switch (color) {
      case PlayerColor.green:
        return Offset(0 + baseOffsets[pawnId].dx, 0 + baseOffsets[pawnId].dy);
      case PlayerColor.yellow:
        return Offset(9 + baseOffsets[pawnId].dx, 0 + baseOffsets[pawnId].dy);
      case PlayerColor.blue:
        return Offset(9 + baseOffsets[pawnId].dx, 9 + baseOffsets[pawnId].dy);
      case PlayerColor.red:
        return Offset(0 + baseOffsets[pawnId].dx, 9 + baseOffsets[pawnId].dy);
    }
  }

  // ==============================
  // PHYSICAL LOCATION RESOLVER
  // ==============================

  /// Converts a [pawn]'s current state and step into a pixel [Offset]
  /// relative to the top-left corner of the board canvas.
  ///
  /// Resolution priority:
  ///   1. inBase         → lookup via getBasePosition.
  ///   2. onHomeStretch  → lookup via homeStretches map (step 51–55 → index 0–4).
  ///   3. finished       → fixed center-triangle position + small scatter offset.
  ///   4. onPath         → lookup mainPath[getAbsolutePosition(pawn)].
  static Offset getPhysicalLocation(Size boardSize, Pawn pawn) {
    double cellSize = boardSize.width / 15;
    Offset gridPos;

    if (pawn.state == PawnState.inBase) {
      // ─── Base Position ───
      gridPos = getBasePosition(pawn.color, pawn.id);

    } else if (pawn.state == PawnState.onHomeStretch) {
      // ─── Home Stretch Position ───
      // pawn.step is 51–55 → convert to 0–4 index into homeStretches list.
      // ADJUSTABLE: Change the home-stretch entry step offset here (currently 51).
      int homeIndex = (pawn.step - 51).clamp(0, 4);
      gridPos = homeStretches[pawn.color]![homeIndex];

    } else if (pawn.state == PawnState.finished) {
      // ─── Finished / Center Triangle Position ───
      // Pawns scatter in a 2×2 cluster so all 4 finished pawns are visible.
      // ADJUSTABLE: Change finish cluster scatter offsets here.
      final List<Offset> finishOffsets = [
        const Offset(-0.2, -0.2), // id 0: top-left
        const Offset(0.2, -0.2),  // id 1: top-right
        const Offset(-0.2, 0.2),  // id 2: bottom-left
        const Offset(0.2, 0.2),   // id 3: bottom-right
      ];
      final Offset scatter = finishOffsets[pawn.id];

      // ADJUSTABLE: Change the center anchor grid coordinates per color here.
      switch (pawn.color) {
        case PlayerColor.green:
          gridPos = Offset(6.1 + scatter.dx, 6.9 + scatter.dy);
          break;
        case PlayerColor.yellow:
          gridPos = Offset(7.0 + scatter.dx, 6.0 + scatter.dy);
          break;
        case PlayerColor.blue:
          gridPos = Offset(7.9 + scatter.dx, 7.0 + scatter.dy);
          break;
        case PlayerColor.red:
          gridPos = Offset(7.0 + scatter.dx, 7.8 + scatter.dy);
          break;
      }

    } else {
      // ─── Main Path Position ───
      // getAbsolutePosition wraps the relative step to a 0–51 ring index.
      int absoluteStep = getAbsolutePosition(pawn);
      gridPos = mainPath[absoluteStep];
    }

    // Convert grid coordinates to pixel coordinates.
    return Offset(gridPos.dx * cellSize, gridPos.dy * cellSize);
  }

  // ==============================
  // ABSOLUTE PATH INDEX
  // ==============================

  /// Converts a pawn's relative [step] (0–50) to an absolute index (0–51)
  /// into the shared [mainPath] list, accounting for each color's starting offset.
  ///
  /// Used to detect if two pawns from different colors share the same physical cell.
  ///
  /// Color offsets (the mainPath index each color starts at):
  ///   Green  →  0
  ///   Yellow → 13
  ///   Blue   → 26
  ///   Red    → 39
  static int getAbsolutePosition(Pawn pawn) {
    int colorOffset = 0;
    switch (pawn.color) {
      case PlayerColor.green:
        colorOffset = 0;
        break;
      case PlayerColor.yellow:
        colorOffset = 13;
        break;
      case PlayerColor.blue:
        colorOffset = 26;
        break;
      case PlayerColor.red:
        colorOffset = 39;
        break;
    }
    // Modulo 52 wraps the index so the path forms a continuous ring.
    return (pawn.step + colorOffset) % 52;
  }
}
