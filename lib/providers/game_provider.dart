import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/utils/audio_manager.dart';
import 'package:ludo_game/utils/board_coordinates.dart';

class GameProvider extends ChangeNotifier {
  // Game state variables
  List<Player> players = [];
  PlayerColor currentTurn = PlayerColor.green;
  PlayerColor? winner;

  // Dice state
  int diceResult = 1;
  bool isDiceRolling = false;
  bool hasRolled = false; // track if the player has rolled but not moved yet.

  // Animation lock state
  bool isAnimatingMove = false;

  // Multi-elimination feature
  bool eliminateAllOpponents = false;
  bool isBulldozerMode = false;
  bool alwaysRollSix = false;

  void toggleEliminateAll() {
    eliminateAllOpponents = !eliminateAllOpponents;
    debugPrint(' Eliminate All Opponents toggled: $eliminateAllOpponents');
    notifyListeners();
  }

  void toggleBulldozerMode() {
    isBulldozerMode = !isBulldozerMode;
    debugPrint(' Bulldozer Mode toggled: $isBulldozerMode');
    notifyListeners();
  }

  void toggleAlwaysRollSix() {
    alwaysRollSix = !alwaysRollSix;
    debugPrint(' Always Roll 6 toggled: $alwaysRollSix');
    notifyListeners();
  }

  GameProvider() {
    _initializeGame();
  }

  // -- Initialization --

  void _initializeGame() {
    debugPrint('🎮 Initializing new game...');
    players = [
      Player(
        color: PlayerColor.green,
        pawns: List.generate(
          4,
          (index) => Pawn(id: index, color: PlayerColor.green),
        ),
      ),
      Player(
        color: PlayerColor.yellow,
        pawns: List.generate(
          4,
          (index) => Pawn(id: index, color: PlayerColor.yellow),
        ),
      ),
      Player(
        color: PlayerColor.blue,
        pawns: List.generate(
          4,
          (index) => Pawn(id: index, color: PlayerColor.blue),
        ),
      ),
      Player(
        color: PlayerColor.red,
        pawns: List.generate(
          4,
          (index) => Pawn(id: index, color: PlayerColor.red),
        ),
      ),
    ];
  }

  void initializePlayers(int playerCount) {
    debugPrint("GameProvider: initializing $playerCount players");

    players.clear();

    List<PlayerColor> activeColors;

    switch (playerCount) {
      case 2:
        // Face-to-face players
        activeColors = [PlayerColor.green, PlayerColor.blue];
        break;

      case 3:
        activeColors = [
          PlayerColor.green,
          PlayerColor.yellow,
          PlayerColor.blue,
        ];
        break;

      case 4:
      default:
        activeColors = [
          PlayerColor.green,
          PlayerColor.yellow,
          PlayerColor.blue,
          PlayerColor.red,
        ];
    }

    players = activeColors
        .map(
          (color) => Player(
            color: color,
            pawns: List.generate(4, (index) => Pawn(id: index, color: color)),
          ),
        )
        .toList();

    currentTurn = activeColors.first;

    debugPrint("Active players: ${activeColors.map((e) => e.name).toList()}");

    notifyListeners();
  }

  // Restart the game completely
  void restartGame() {
    debugPrint('🔄 Restarting game...');
    winner = null;
    currentTurn = PlayerColor.green;
    diceResult = 1;
    hasRolled = false;
    isDiceRolling = false;
    isAnimatingMove = false;
    _initializeGame();
    notifyListeners();
  }

  // -- Core Actions --

  // Rolls the dice, with small delay for animation
  Future<void> rollDice() async {
    if (winner != null || isDiceRolling || hasRolled || isAnimatingMove) return;

    isDiceRolling = true;

    // Generate random number FIRST so the UI can pre-fetch it contextually
    if (alwaysRollSix) {
      diceResult = 6;
    } else {
      final rand = Random();
      if (rand.nextDouble() < 0.20) {
        diceResult = 6;
      } else {
        diceResult = rand.nextInt(7) + 1;
      }
    }
    debugPrint("Dice rolled: $diceResult");
    notifyListeners();

    // Smoother and shorter animation time
    await Future.delayed(const Duration(milliseconds: 1000));

    isDiceRolling = false;
    hasRolled = true;

    debugPrint(
      '🎲 [ROLL] ${currentTurn.name.toUpperCase()} rolled a $diceResult',
    );

    // RULE: Check if the current player actually has any legal moves
    if (!_hasValidMoves()) {
      debugPrint(
        '⚠️ [VALIDATION] No valid moves for ${currentTurn.name.toUpperCase()} with roll $diceResult. Auto-passing turn.',
      );

      notifyListeners(); // Update UI to show the dice result first

      // Wait for exactly 1 second before passing the turn, so user sees bad roll
      await Future.delayed(const Duration(milliseconds: 500));

      hasRolled = false;
      nextTurn();
      return;
    }

    debugPrint(
      ' [VALIDATION] Valid moves available. Waiting for player interaction.',
    );
    notifyListeners();
  }

  // Pass the turn to the next player
  void nextTurn() {
    int currentIndex = players.indexWhere(
      (player) => player.color == currentTurn,
    );

    int nextIndex = (currentIndex + 1) % players.length;

    currentTurn = players[nextIndex].color;

    hasRolled = false;

    debugPrint(' [TURN] Turn passed to ${currentTurn.name.toUpperCase()}');

    notifyListeners();
  }

  /// Checks if the current player can actually make a move with the rolled dice
  bool _hasValidMoves() {
    Player activePlayer = players.firstWhere((p) => p.color == currentTurn);
    for (var pawn in activePlayer.pawns) {
      if (pawn.state == PawnState.inBase && diceResult == 6) {
        return true;
      }
      if (pawn.state == PawnState.onPath) {
        return true;
      }
      if (pawn.state == PawnState.onHomeStretch) {
        // Check if the pawn can actually move without overshooting the center
        int remainingSteps = 56 - pawn.step;
        if (diceResult <= remainingSteps) {
          return true;
        }
      }
    }
    return false; // No pawns can legally move
  }

  // move pawn according to situations like onpath, on base etc
  bool canPawnMove(Pawn pawn) {
    if (pawn.color != currentTurn) return false;
    if (!hasRolled) return false;

    // Base pawn needs 6
    if (pawn.state == PawnState.inBase) {
      return diceResult == 6;
    }

    // Pawn on path can move normally
    if (pawn.state == PawnState.onPath) {
      return true;
    }

    // Home stretch must not overshoot center
    if (pawn.state == PawnState.onHomeStretch) {
      int remainingSteps = 56 - pawn.step;
      return diceResult <= remainingSteps;
    }

    return false;
  }

  // Handles the logic when user taps a pawn
  Future<void> movePawn(Pawn pawn) async {
    if (winner != null) return;
    if (pawn.color != currentTurn ||
        !hasRolled ||
        isDiceRolling ||
        isAnimatingMove) {
      return;
    }

    // Movement Validation Locks
    if (pawn.state == PawnState.inBase && diceResult != 6) {
      debugPrint(
        ' [INVALID MOVE] Cannot move ${pawn.color.name} pawn ${pawn.id} from base without a 6.',
      );
      return;
    }
    if (pawn.state == PawnState.onHomeStretch) {
      int remainingSteps = 56 - pawn.step;
      if (diceResult > remainingSteps) {
        debugPrint(
          ' [INVALID MOVE] ${pawn.color.name} pawn ${pawn.id} needs $remainingSteps or less, but rolled $diceResult.',
        );
        return;
      }
    }

    // Lock board for animation synchronization
    isAnimatingMove = true;
    debugPrint(' [MOVE START] Moving ${pawn.color.name} pawn ${pawn.id}');

    // Unlocking from base
    if (pawn.state == PawnState.inBase && diceResult == 6) {
      pawn.state = PawnState.onPath;
      pawn.step = 0;
      hasRolled = false; // Player gets another turn for rolling a 6

      AudioManager.playBaseExit();
      debugPrint(
        ' [BASE EXIT] ${pawn.color.name} pawn ${pawn.id} left base. Extra turn granted.',
      );

      isAnimatingMove = false;
      notifyListeners();
      return;
    }

    // Step-by-step physical movement
    if (pawn.state == PawnState.onPath ||
        pawn.state == PawnState.onHomeStretch) {
      int stepToTake = diceResult;
      bool cutOpponent = false;

      for (int i = 0; i < stepToTake; i++) {
        pawn.step++;

        // Transition to home stretch
        if (pawn.step == 51 && pawn.state == PawnState.onPath) {
          pawn.state = PawnState.onHomeStretch;
          debugPrint(
            ' [HOME STRETCH] ${pawn.color.name} pawn ${pawn.id} entered home stretch.',
          );
        }
        // Reached the center
        if (pawn.step == 56) {
          pawn.isWinningAnimation = true;

          AudioManager.playTriangleReach();

          notifyListeners();

          await Future.delayed(const Duration(milliseconds: 650));

          pawn.state = PawnState.finished;
        } else {
          AudioManager.playPawnMovement();
        }

        notifyListeners();
        // Wait for the UI jump animation to finish before taking the next step
        await Future.delayed(const Duration(milliseconds: 250));

        // Sweep Capture Mode logic: kill enemies while actively moving
        if (isBulldozerMode && pawn.state == PawnState.onPath) {
          bool intermediateCut = await _attemptCut(pawn, isIntermediate: true);
          if (intermediateCut) cutOpponent = true;
        }

        if (pawn.step == 56) {
          Future.delayed(const Duration(milliseconds: 600), () {
            pawn.isWinningAnimation = false;
            _checkWinCondition(pawn.color);
            notifyListeners();
          });
        }
      }

      // Standard cutting logic check at the end of the move
      if (!isBulldozerMode || diceResult != 5) {
        if (pawn.state == PawnState.onPath) {
          bool finalCut = await _attemptCut(pawn);
          if (finalCut) cutOpponent = true;
        }
      }

      // Turn Management: Extra turn if rolled 6, cut an opponent, or finished a pawn
      if (diceResult == 6 || cutOpponent || pawn.state == PawnState.finished) {
        debugPrint(
          ' [BONUS TURN] ${pawn.color.name} granted extra turn. (Roll: $diceResult, Cut: $cutOpponent, Finished: ${pawn.state == PawnState.finished})',
        );
        hasRolled = false;
      } else {
        nextTurn();
      }

      // Release animation lock
      isAnimatingMove = false;
      debugPrint(' [MOVE END] Sequence finished.');
      notifyListeners();
    }
  }

  Future<bool> _attemptCut(Pawn pawn, {bool isIntermediate = false}) async {
    bool localCut = false;
    int myAbsolutePosition = BoardCoordinates.getAbsolutePosition(pawn);

    // Only attempt to cut if we are not on a safe zone.
    if (!BoardCoordinates.safeZones.contains(myAbsolutePosition)) {
      // Loop through all players to find opponents
      for (var player in players) {
        if (player.color != pawn.color) {
          for (var oppPawn in player.pawns) {
            if (oppPawn.state == PawnState.onPath) {
              int oppAbsolutePosition = BoardCoordinates.getAbsolutePosition(
                oppPawn,
              );

              // If position matches - cut
              if (oppAbsolutePosition == myAbsolutePosition) {
                debugPrint(
                  ' [CUT] ${pawn.color.name} cut ${player.color.name}\'s pawn ${oppPawn.id} at absolute position $myAbsolutePosition!',
                );

                oppPawn.isDeadAnimation = true;
                AudioManager.playKnockOut();
                notifyListeners();

                // Wait for UI to show death animation before snapping back to base
                await Future.delayed(const Duration(milliseconds: 100));

                oppPawn.reset();
                localCut = true;

                if (!eliminateAllOpponents) {
                  break; // Break inner loop (pawns of this opponent)
                }
              }
            }
          }
          if (localCut && !eliminateAllOpponents) {
            break; // Break outer loop (other opponents)
          }
        }
      }
    } else {
      if (!isIntermediate) {
        AudioManager.playSafeHouse();
      }
      debugPrint(
        '🛡️ [SAFE ZONE] ${pawn.color.name} landed on safe zone $myAbsolutePosition.',
      );
    }
    return localCut;
  }

  void _checkWinCondition(PlayerColor color) {
    // Find the player who just finished game
    Player activePlayer = players.firstWhere((p) => p.color == color);
    if (activePlayer.hasWon) {
      debugPrint('🎉 [WINNER] ${color.name.toUpperCase()} HAS WON THE GAME!');
      winner = color;
    }
  }
}
