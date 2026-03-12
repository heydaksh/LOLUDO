import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/models/portals.dart';
import 'package:ludo_game/utils/audio_manager.dart';
import 'package:ludo_game/utils/board_coordinates.dart';
import 'package:ludo_game/utils/portal_utils.dart';

// ==============================
// GAME PROVIDER
// Central state manager for the entire Ludo game.
// Handles: player initialization, dice rolling, pawn movement,
// turn management, cut (capture) logic, and win detection.
// ==============================

class GameProvider extends ChangeNotifier {
  // ==============================
  // GAME STATE VARIABLES
  // ==============================

  /// List of all active players in the current game session.
  List<Player> players = [];

  /// The color of the player whose turn it currently is.
  PlayerColor currentTurn = PlayerColor.green;

  /// Set when a player wins. Null means game is still in progress.
  PlayerColor? winner;

  // ─── Dice State ───

  /// The number value currently showing on the dice (1–6).
  int diceResult = 1;

  /// True while the dice rolling animation is in progress.
  /// Prevents double-rolls during animation.
  bool isDiceRolling = false;

  /// True after the dice has been rolled but before the player has moved a pawn.
  /// Prevents re-rolling before moving.
  bool hasRolled = false;

  // ─── Animation Lock ───

  /// Prevents any new input while a pawn movement animation is in progress.
  /// Ensures sequential, non-overlapping animations.
  bool isAnimatingMove = false;

  // ─── Portal State ───

  /// List of currently active portal pairs on the main board path.
  List<Portals> activePortals = [];

  /// Tracks turns to decide when to spawn a new portal.
  int _turnsUntilNextPortal = 6;

  /// The pawn that was most recently teleported (used for visual feedback).
  Pawn? lastTeleportedPawn;

  // ==============================
  // CHEAT / DEBUG FEATURE FLAGS
  // ==============================

  /// When true, a single cut kills ALL opponent pawns on the same cell,
  /// not just one.
  bool eliminateAllOpponents = false;

  /// When true, the cutting pawn also destroys enemies on intermediate
  /// cells it passes through during its move (sweep mode).
  bool isBulldozerMode = false;

  /// When true, the dice always lands on 6 (debug/cheat mode).
  bool alwaysRollSix = false;

  // ─── Cheat Toggle Methods ───

  /// Toggles the "eliminate all opponents on a cell" cheat on/off.
  void toggleEliminateAll() {
    eliminateAllOpponents = !eliminateAllOpponents;
    debugPrint(' Eliminate All Opponents toggled: $eliminateAllOpponents');
    notifyListeners();
  }

  /// Toggles bulldozer (sweep capture) mode on/off.
  void toggleBulldozerMode() {
    isBulldozerMode = !isBulldozerMode;
    debugPrint(' Bulldozer Mode toggled: $isBulldozerMode');
    notifyListeners();
  }

  /// Toggles "always roll 6" cheat mode on/off.
  void toggleAlwaysRollSix() {
    alwaysRollSix = !alwaysRollSix;
    debugPrint(' Always Roll 6 toggled: $alwaysRollSix');
    notifyListeners();
  }

  // ==============================
  // CONSTRUCTOR / LIFECYCLE
  // ==============================

  /// Creates the provider and initializes a default 4-player game.
  GameProvider() {
    _initializeGame();
  }

  // ==============================
  // INITIALIZATION
  // ==============================

  /// Internal: Creates the default 4-player game with all pawns in base.
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

  /// Called from the player selection screen.
  /// Configures the game for the chosen number of players (2–4).
  /// 2-player mode uses Green vs Blue (face-to-face positions).
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

    // Create one Player object per active color, each with 4 fresh pawns.
    players = activeColors
        .map(
          (color) => Player(
            color: color,
            pawns: List.generate(4, (index) => Pawn(id: index, color: color)),
          ),
        )
        .toList();

    // First player in the list always goes first.
    currentTurn = activeColors.first;

    debugPrint("Active players: ${activeColors.map((e) => e.name).toList()}");

    notifyListeners();
  }

  /// Resets the entire game back to its starting state.
  /// Used by the "Play Again" / restart button.
  void restartGame() {
    debugPrint('🔄 Restarting game...');
    winner = null;
    currentTurn = PlayerColor.green;
    diceResult = 1;
    hasRolled = false;
    isDiceRolling = false;
    isAnimatingMove = false;
    activePortals.clear();
    _turnsUntilNextPortal = 6;
    lastTeleportedPawn = null;
    _initializeGame();
    notifyListeners();
  }

  // ==============================
  // CORE GAME ACTIONS
  // ==============================

  // ─── Dice Rolling ───

  /// Rolls the dice for the current player.
  ///
  /// Flow:
  ///   1. Guard: skip if game is over, already rolling, already rolled, or animating.
  ///   2. Generate a dice result (biased toward 6: ~20% base chance).
  ///   3. Show animation for 1 second.
  ///   4. Check if any legal move is available.
  ///   5. Auto-pass the turn (after 500 ms delay) if no moves are possible.
  Future<void> rollDice() async {
    if (winner != null || isDiceRolling || hasRolled || isAnimatingMove) return;

    isDiceRolling = true;

    // Generate the dice value BEFORE notifying listeners
    // so the UI can immediately begin showing the correct face.
    if (alwaysRollSix) {
      // CHEAT MODE: always produce a 6.
      diceResult = 6;
    } else {
      final rand = Random();

      // ADJUSTABLE: Change the probability of rolling a 6 here (currently 20%).
      if (rand.nextDouble() < 0.20) {
        diceResult = 6;
      } else {
        // Normal roll: 1–7 range intentional — values >6 act as a 7.
        // ADJUSTABLE: Change dice range here (rand.nextInt upper bound).
        diceResult = rand.nextInt(5) + 1;
      }
    }
    debugPrint("Dice rolled: $diceResult");
    notifyListeners();

    // ADJUSTABLE: Change the dice animation display duration here (currently 1000 ms).
    await Future.delayed(const Duration(milliseconds: 1000));

    isDiceRolling = false;
    hasRolled = true;

    debugPrint(
      ' [ROLL] ${currentTurn.name.toUpperCase()} rolled a $diceResult',
    );

    // RULE: If the rolled number gives no legal moves, auto-pass the turn.
    if (!_hasValidMoves()) {
      debugPrint(
        '⚠️ [VALIDATION] No valid moves for ${currentTurn.name.toUpperCase()} with roll $diceResult. Auto-passing turn.',
      );

      notifyListeners(); // Show the dice result in UI before passing turn.

      // ADJUSTABLE: Change the delay before auto-passing the turn (currently 500 ms).
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

  // ─── Turn Management ───

  /// Advances the turn to the next player in the rotation (circular).
  void nextTurn() {
    int currentIndex = players.indexWhere(
      (player) => player.color == currentTurn,
    );

    // Wrap around to the first player when the last player finishes.
    int nextIndex = (currentIndex + 1) % players.length;

    currentTurn = players[nextIndex].color;

    hasRolled = false;

    debugPrint(' [TURN] Turn passed to ${currentTurn.name.toUpperCase()}');

    // ─── Portal Spawn Countdown ───
    _turnsUntilNextPortal--;
    if (_turnsUntilNextPortal <= 0) {
      if (activePortals.length < 2) {
        final newPortal = spawnPortal();
        activePortals.add(newPortal);
        debugPrint(
          ' [PORTAL] Spawned ${newPortal.type.name} portal at ${newPortal.a} <-> ${newPortal.b}',
        );
      }
      final options = [6, 10, 12, 14]; // reset timer
      _turnsUntilNextPortal = options[Random().nextInt(options.length)];
    }

    // ─── Portal Expiration ───
    activePortals.removeWhere((p) {
      p.remainingTurns--;
      if (p.remainingTurns <= 0) {
        debugPrint('🌀 [PORTAL] Expired portal at ${p.a}');
        return true;
      }
      return false;
    });

    notifyListeners();
  }

  // ==============================
  // MOVEMENT VALIDATION
  // ==============================

  /// Returns true if the current player has at least one pawn
  /// that can legally move with the current [diceResult].
  ///
  /// Rules checked:
  ///   - Base pawn → needs diceResult == 6 to exit.
  ///   - onPath pawn → can always move.
  ///   - onHomeStretch pawn → can move only if diceResult ≤ remaining steps to center.
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
        // Check if the pawn can actually move without overshooting the center.
        // Step 56 = center (winning position).
        int remainingSteps = 56 - pawn.step;
        if (diceResult <= remainingSteps) {
          return true;
        }
      }
    }
    return false; // No pawns can legally move.
  }

  /// Returns true if this specific [pawn] can legally move right now.
  ///
  /// Checks:
  ///   - Must be current player's pawn.
  ///   - Dice must have been rolled.
  ///   - Base pawn needs 6.
  ///   - Home-stretch pawn must not overshoot center.
  bool canPawnMove(Pawn pawn) {
    if (pawn.color != currentTurn) return false;
    if (!hasRolled) return false;

    // Base pawn needs 6 to exit.
    if (pawn.state == PawnState.inBase) {
      return diceResult == 6;
    }

    // Pawn on path can move normally.
    if (pawn.state == PawnState.onPath) {
      return true;
    }

    // Home stretch must not overshoot center (step 56).
    if (pawn.state == PawnState.onHomeStretch) {
      int remainingSteps = 56 - pawn.step;
      return diceResult <= remainingSteps;
    }

    return false;
  }

  // ==============================
  // PAWN MOVEMENT
  // ==============================

  /// Called when the player taps a pawn to move it.
  ///
  /// Movement Flow:
  ///   1. Guard checks (winner, turn, rolled, animating).
  ///   2. Validation (can't move from base without 6, can't overshoot).
  ///   3. Lock the board (isAnimatingMove = true).
  ///   4. Handle base-exit separately (pawn exits, player gets extra turn, return).
  ///   5. Step-by-step movement loop:
  ///       a. Increment pawn.step.
  ///       b. Transition to home-stretch at step 51.
  ///       c. Handle winning animation at step 56.
  ///       d. Play movement sound and wait for jump animation per step.
  ///       e. Bulldozer mode: attempt intermediate captures.
  ///   6. Standard capture check after the full move.
  ///   7. Turn management: grant extra turn on 6, cut, or finish; else nextTurn().
  ///   8. Release animation lock.
  Future<void> movePawn(Pawn pawn) async {
    if (winner != null) return;
    if (pawn.color != currentTurn ||
        !hasRolled ||
        isDiceRolling ||
        isAnimatingMove) {
      return;
    }

    // ─── Movement Validation Locks ───

    // A pawn in base can only exit on a dice roll of 6.
    if (pawn.state == PawnState.inBase && diceResult != 6) {
      debugPrint(
        ' [INVALID MOVE] Cannot move ${pawn.color.name} pawn ${pawn.id} from base without a 6.',
      );
      return;
    }

    // A pawn on the home stretch cannot overshoot the center (step 56).
    if (pawn.state == PawnState.onHomeStretch) {
      int remainingSteps = 56 - pawn.step;
      if (diceResult > remainingSteps) {
        debugPrint(
          ' [INVALID MOVE] ${pawn.color.name} pawn ${pawn.id} needs $remainingSteps or less, but rolled $diceResult.',
        );
        return;
      }
    }

    // Lock board to prevent concurrent inputs during animation.
    isAnimatingMove = true;
    debugPrint(' [MOVE START] Moving ${pawn.color.name} pawn ${pawn.id}');

    // ─── Base Exit (Special Case) ───

    // Rolling a 6 on a base pawn exits it without consuming a step move.
    // Player is rewarded with another turn (hasRolled stays false).
    if (pawn.state == PawnState.inBase && diceResult == 6) {
      pawn.state = PawnState.onPath;
      pawn.step = 0;
      hasRolled = false; // Player gets another roll for exiting base with a 6.

      AudioManager.playBaseExit();
      debugPrint(
        ' [BASE EXIT] ${pawn.color.name} pawn ${pawn.id} left base. Extra turn granted.',
      );

      isAnimatingMove = false;
      notifyListeners();
      return;
    }

    // ─── Step-by-Step Movement Loop ───

    if (pawn.state == PawnState.onPath ||
        pawn.state == PawnState.onHomeStretch) {
      int stepToTake = diceResult;
      bool cutOpponent = false;

      for (int i = 0; i < stepToTake; i++) {
        pawn.step++;

        // ─── Home Stretch Entry ───
        // At step 51, the pawn transitions from the main path to the home stretch.
        // ADJUSTABLE: Change the home-stretch entry step here (currently 51).
        if (pawn.step == 51 && pawn.state == PawnState.onPath) {
          pawn.state = PawnState.onHomeStretch;
          debugPrint(
            ' [HOME STRETCH] ${pawn.color.name} pawn ${pawn.id} entered home stretch.',
          );
        }

        // ─── Winning Position ───
        // Step 56 means the pawn has reached the center triangle and won.
        // ADJUSTABLE: Change the winning step value here (currently 56).
        if (pawn.step == 56) {
          pawn.isWinningAnimation = true;

          AudioManager.playTriangleReach();

          notifyListeners();

          // ADJUSTABLE: Change the winning animation pause duration here (currently 650 ms).
          await Future.delayed(const Duration(milliseconds: 650));

          pawn.state = PawnState.finished;
        } else {
          AudioManager.playPawnMovement();
        }

        notifyListeners();

        // Wait for the UI jump animation to finish before taking the next step.
        // ADJUSTABLE: Change per-step animation delay here (currently 250 ms).
        await Future.delayed(const Duration(milliseconds: 250));

        // ─── Bulldozer Mode: Sweep Capture ───
        // If bulldozer mode is active, try to capture opponents at each intermediate cell.
        if (isBulldozerMode && pawn.state == PawnState.onPath) {
          bool intermediateCut = await _attemptCut(pawn, isIntermediate: true);
          if (intermediateCut) cutOpponent = true;
        }

        // ─── Win Condition Deferred Check ───
        // Wrap inside a Future.delayed so the finished state propagates to the UI first.
        if (pawn.step == 56) {
          Future.delayed(const Duration(milliseconds: 600), () {
            pawn.isWinningAnimation = false;
            _checkWinCondition(pawn.color);
            notifyListeners();
          });
        }
      }

      // ─── Standard Final-Cell Capture ───
      // After completing the full move, check if the pawn landed on an opponent.
      // Skipped when bulldozer mode already handled it, or the move was 5 in bulldozer.
      if (!isBulldozerMode || diceResult != 5) {
        if (pawn.state == PawnState.onPath) {
          bool finalCut = await _attemptCut(pawn);
          if (finalCut) cutOpponent = true;
        }
      }

      // ─── Turn Management: Extra Turn Rules ───
      // A player gets an extra turn if they:
      //   • Rolled a 6
      //   • Cut (captured) an opponent pawn
      //   • Finished a pawn (reached the center)
      if (diceResult == 6 || cutOpponent || pawn.state == PawnState.finished) {
        debugPrint(
          ' [BONUS TURN] ${pawn.color.name} granted extra turn. (Roll: $diceResult, Cut: $cutOpponent, Finished: ${pawn.state == PawnState.finished})',
        );
        hasRolled = false;
      } else {
        nextTurn();
      }

      // Release the animation lock so the board accepts input again.
      isAnimatingMove = false;
      debugPrint(' [MOVE END] Sequence finished.');

      // ─── Final Portal Check ───
      // If the pawn landed on a portal after finishing its move, trigger teleport.
      if (pawn.state == PawnState.onPath) {
        await _checkPortalTeleport(pawn);
      }

      notifyListeners();
    }
  }

  /// Checks if [pawn] is on a portal and applies teleportation logic if so.
  Future<void> _checkPortalTeleport(Pawn pawn) async {
    final int absolutePos = BoardCoordinates.getAbsolutePosition(pawn);

    for (var portal in activePortals) {
      if (absolutePos == portal.a || absolutePos == portal.b) {
        debugPrint(
          '🌀 [TELEPORT] Pawn ${pawn.id} entered ${portal.type.name} portal!',
        );

        lastTeleportedPawn = pawn;
        notifyListeners();

        // 1. Teleport to target absolute position
        int targetAbsolute = applyPortal(absolutePos, portal);

        // 2. Convert absolute back to relative step
        // (absolute - colorOffset) % 52
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

        int newStep = (targetAbsolute - colorOffset + 52) % 52;

        // Visual pause before jump
        await Future.delayed(const Duration(milliseconds: 300));

        pawn.step = newStep;
        AudioManager.playPortalTeleport();

        notifyListeners();

        // Clear flash after teleport
        await Future.delayed(const Duration(milliseconds: 500));
        lastTeleportedPawn = null;
        notifyListeners();

        // Check for capture at the new location
        await _attemptCut(pawn);
        break;
      }
    }
  }

  // ==============================
  // CAPTURE (CUT) LOGIC
  // ==============================

  /// Checks if [pawn] has landed on (or passed through, in bulldozer mode)
  /// a cell occupied by one or more opponent pawns, and captures them.
  ///
  /// Parameters:
  ///   - [pawn]: The attacking pawn.
  ///   - [isIntermediate]: True when called mid-step in bulldozer mode.
  ///                       Suppresses the safe-zone sound on intermediate steps.
  ///
  /// Returns true if at least one opponent pawn was captured.
  Future<bool> _attemptCut(Pawn pawn, {bool isIntermediate = false}) async {
    bool localCut = false;
    int myAbsolutePosition = BoardCoordinates.getAbsolutePosition(pawn);

    // Safe zones cannot be the site of a capture.
    if (!BoardCoordinates.safeZones.contains(myAbsolutePosition)) {
      // Iterate through all other players to look for opponents on same cell.
      for (var player in players) {
        if (player.color != pawn.color) {
          for (var oppPawn in player.pawns) {
            if (oppPawn.state == PawnState.onPath) {
              int oppAbsolutePosition = BoardCoordinates.getAbsolutePosition(
                oppPawn,
              );

              // If positions match, this opponent pawn is captured.
              if (oppAbsolutePosition == myAbsolutePosition) {
                debugPrint(
                  ' [CUT] ${pawn.color.name} cut ${player.color.name}\'s pawn ${oppPawn.id} at absolute position $myAbsolutePosition!',
                );

                oppPawn.isDeadAnimation = true;
                AudioManager.playKnockOut();
                notifyListeners();

                // ADJUSTABLE: Change knockout animation delay before returning pawn to base (currently 100 ms).
                await Future.delayed(const Duration(milliseconds: 100));

                oppPawn.reset();
                localCut = true;

                if (!eliminateAllOpponents) {
                  break; // Only cut one pawn per opponent player (standard rule).
                }
              }
            }
          }
          if (localCut && !eliminateAllOpponents) {
            break; // Stop checking other opponents once one is cut (standard rule).
          }
        }
      }
    } else {
      // Pawn is on a safe zone — no capture possible.
      if (!isIntermediate) {
        AudioManager.playSafeHouse();
      }
      debugPrint(
        '🛡️ [SAFE ZONE] ${pawn.color.name} landed on safe zone $myAbsolutePosition.',
      );
    }
    return localCut;
  }

  // ==============================
  // WIN CONDITION
  // ==============================

  /// Checks if the player of [color] has all 4 pawns in the finished state.
  /// Sets [winner] if true, which freezes the game.
  void _checkWinCondition(PlayerColor color) {
    Player activePlayer = players.firstWhere((p) => p.color == color);
    if (activePlayer.hasWon) {
      debugPrint('🎉 [WINNER] ${color.name.toUpperCase()} HAS WON THE GAME!');
      winner = color;
    }
  }

  // ==============================
  // PORTAL LOGIC
  // ==============================

  Portals spawnPortal() {
    final random = Random();
    int a;
    int b;

    do {
      a = random.nextInt(52);
    } while (isRestrictedTile(a));
    do {
      b = random.nextInt(52);
    } while (b == a || isRestrictedTile(b));

    final type = PortalType.values[random.nextInt(3)];
    return Portals(a: a, b: b, type: type);
  }

  // ==============================
  // APPLY PORTAL
  // ==============================

  int applyPortal(int position, Portals portal) {
    if (position != portal.a && position != portal.b) {
      return position;
    }

    int newPosition = portal.getOther(position);

    switch (portal.type) {
      case PortalType.blue:
        return newPosition;
      case PortalType.red:
        return (newPosition + 2) % 52;
      case PortalType.purple:
        return (newPosition - 2 + 52) % 52;
    }
  }
}
