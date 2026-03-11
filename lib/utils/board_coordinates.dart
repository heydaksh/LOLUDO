import 'package:flutter/material.dart';
import 'package:ludo_game/models/game_models.dart';

class BoardCoordinates {
  // x = column
  // y = row

  //  index = is the greens starting square at (1, 0)

  static const List<Offset> mainPath = [
    // left arm - bottom half
    Offset(1, 6), Offset(2, 6), Offset(3, 6), Offset(4, 6), Offset(5, 6),
    // top arm - left half
    Offset(6, 5),
    Offset(6, 4),
    Offset(6, 3),
    Offset(6, 2),
    Offset(6, 1),
    Offset(6, 0),
    // Top arm (turn right)
    Offset(7, 0), Offset(8, 0),
    // Top arm (right half) - Yellow Start is index 13 at (8, 1)
    Offset(8, 1), Offset(8, 2), Offset(8, 3), Offset(8, 4), Offset(8, 5),
    // Right arm (top half)
    Offset(9, 6),
    Offset(10, 6),
    Offset(11, 6),
    Offset(12, 6),
    Offset(13, 6),
    Offset(14, 6),
    // Right arm (turn down)
    Offset(14, 7), Offset(14, 8),
    // Right arm (bottom half) - Blue Start is index 26 at (13, 8)
    Offset(13, 8), Offset(12, 8), Offset(11, 8), Offset(10, 8), Offset(9, 8),
    // Bottom arm (right half)
    Offset(8, 9),
    Offset(8, 10),
    Offset(8, 11),
    Offset(8, 12),
    Offset(8, 13),
    Offset(8, 14),
    // Bottom arm (turn left)
    Offset(7, 14), Offset(6, 14),
    // Bottom arm (left half) - Red Start is index 39 at (6, 13)
    Offset(6, 13), Offset(6, 12), Offset(6, 11), Offset(6, 10), Offset(6, 9),
    // Left arm (top half)
    Offset(5, 8),
    Offset(4, 8),
    Offset(3, 8),
    Offset(2, 8),
    Offset(1, 8),
    Offset(0, 8),
    // Left arm (turn up)
    Offset(0, 7), Offset(0, 6),
  ];

  static Offset getBasePosition(PlayerColor color, int pawnId) {
    // these are offsets withen the 6x6 base areas.
    List<Offset> baseOffsets = [
      const Offset(1.5, 1.5),
      const Offset(3.5, 1.5),
      const Offset(1.5, 3.5),
      const Offset(3.5, 3.5),
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

  static Offset getPhysicalLocation(Size boardSize, Pawn pawn) {
    double cellSize = boardSize.width / 15;
    Offset gridPos;

    if (pawn.state == PawnState.inBase) {
      gridPos = getBasePosition(pawn.color, pawn.id);
    } else if (pawn.state == PawnState.onHomeStretch) {
      // pawn.step is 51 to 55. We need index 0 to 4 for the array.
      int homeIndex = (pawn.step - 51).clamp(0, 4);

      gridPos = homeStretches[pawn.color]![homeIndex];
    } else if (pawn.state == PawnState.finished) {
      // Move to the triangle of the respective color
      // And apply a small offset based on pawn.id so they are scattered

      // We will form a tiny 2x2 cluster inside each triangle
      final List<Offset> finishOffsets = [
        const Offset(-0.2, -0.2),
        const Offset(0.2, -0.2),
        const Offset(-0.2, 0.2),
        const Offset(0.2, 0.2),
      ];
      final Offset scatter = finishOffsets[pawn.id];

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
      // onPath
      int absoluteStep = getAbsolutePosition(pawn);
      gridPos = mainPath[absoluteStep];
    }

    return Offset(gridPos.dx * cellSize, gridPos.dy * cellSize);
  }

  //safe zones
  static const List<int> safeZones = [0, 8, 13, 21, 26, 34, 39, 47];
  // the colored home scretches - x y corrdinates
  static const Map<PlayerColor, List<Offset>> homeStretches = {
    PlayerColor.green: [
      Offset(1, 7),
      Offset(2, 7),
      Offset(3, 7),
      Offset(4, 7),
      Offset(5, 7),
    ],
    PlayerColor.yellow: [
      Offset(7, 1),
      Offset(7, 2),
      Offset(7, 3),
      Offset(7, 4),
      Offset(7, 5),
    ],
    PlayerColor.blue: [
      Offset(13, 7),
      Offset(12, 7),
      Offset(11, 7),
      Offset(10, 7),
      Offset(9, 7),
    ],
    PlayerColor.red: [
      Offset(7, 13),
      Offset(7, 12),
      Offset(7, 11),
      Offset(7, 10),
      Offset(7, 9),
    ],
  };
  // helper to get absolute path index (0 - 51) for cutting
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
    return (pawn.step + colorOffset) % 52;
  }
}
