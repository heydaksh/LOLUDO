import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/models/portals.dart';
import 'package:ludo_game/models/powers.dart';
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

  Map<PlayerColor, String> _startingConfig = {};

  /// Increments every time a new game starts to trigger one-time overlay animations.
  int gameSessionId = 0;

  /// List of all active players in the current game session.
  List<Player> players = [];

  /// List of players who have been removed/quit during the current match.
  List<PlayerColor> removedPlayers = [];

  /// The color of the player whose turn it currently is.
  PlayerColor currentTurn = PlayerColor.green;

  /// Set when a player wins. Null means game is still in progress.

  List<PlayerColor> winner = [];
  bool isGameOver = false;

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
  List<Power> activePower = [];
  int _turnsUntilNextPower = 8;
  bool useReverseMode = false;

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

  /// When true, special power tiles (Freeze, Shield, etc.) will spawn.
  bool enableSpecialPowers = true;

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

  /// Toggles whether special powers spawn on the board.
  void toggleSpecialPowers() {
    enableSpecialPowers = !enableSpecialPowers;
    debugPrint(' Special Powers toggled: $enableSpecialPowers');
    if (!enableSpecialPowers) {
      activePower.clear();
      debugPrint(' [POWER] Cleared all active powers from board.');
    }
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

    // [FIX] Save default config
    _startingConfig = {
      PlayerColor.green: "Player 1",
      PlayerColor.yellow: "Player 2",
      PlayerColor.blue: "Player 3",
      PlayerColor.red: "Player 4",
    };

    players = [
      Player(
        color: PlayerColor.green,
        name: "Player 1",
        pawns: List.generate(
          4,
          (index) => Pawn(id: index, color: PlayerColor.green),
        ),
      ),
      Player(
        color: PlayerColor.yellow,
        name: "Player 2",
        pawns: List.generate(
          4,
          (index) => Pawn(id: index, color: PlayerColor.yellow),
        ),
      ),
      Player(
        color: PlayerColor.blue,
        name: "Player 3",
        pawns: List.generate(
          4,
          (index) => Pawn(id: index, color: PlayerColor.blue),
        ),
      ),
      Player(
        color: PlayerColor.red,
        name: "Player 4",
        pawns: List.generate(
          4,
          (index) => Pawn(id: index, color: PlayerColor.red),
        ),
      ),
    ];
  }

  // ======================
  // SPAWN POWER
  // ======================

  // ======================
  // SPAWN POWER
  // ======================

  Power spawnPower() {
    final random = Random();
    int position;

    do {
      position = random.nextInt(52);
    } while (isRestrictedTile(position) ||
        activePortals.any((p) => p.a == position || p.b == position) ||
        activePower.any((p) => p.position == position));

    final type = PowerType.values[random.nextInt(PowerType.values.length)];

    // Logging power spawn using debugPrint as per your control instructions
    debugPrint(
      '🌟 [SPAWN] Generated power ${type.name} at valid position $position',
    );

    return Power(position: position, type: type);
  }

  /// Called from the player selection screen.
  /// Configures the game for the chosen number of players (2–4).
  /// 2-player mode uses Green vs Blue (face-to-face positions).
  void initializePlayers(Map<PlayerColor, String> selectedPlayersInfo) {
    debugPrint(
      "GameProvider: initializing ${selectedPlayersInfo.length} players",
    );
    gameSessionId++; // Trigger the start animation
    removedPlayers.clear();

    // [FIX] Save the exact starting configuration
    _startingConfig = Map.from(selectedPlayersInfo);

    players.clear();

    players = selectedPlayersInfo.entries.map((entry) {
      return Player(
        color: entry.key,
        name: entry.value.trim().isEmpty
            ? entry.key.name.toUpperCase()
            : entry.value.trim(),
        pawns: List.generate(4, (index) => Pawn(id: index, color: entry.key)),
      );
    }).toList();

    // First player in the list always goes first.
    currentTurn = players.first.color;

    debugPrint("Active players: ${players.map((e) => e.name).toList()}");

    notifyListeners();
  }

  /// Resets the entire game back to its starting state.
  /// Used by the "Play Again" / restart button.
  void restartGame() {
    debugPrint('🔄 Restarting game...');
    gameSessionId++; // Trigger the start animation

    /// Reset game state
    winner.clear();
    isGameOver = false;
    removedPlayers.clear();
    diceResult = 1;
    hasRolled = false;
    isDiceRolling = false;
    isAnimatingMove = false;

    activePortals.clear();
    _turnsUntilNextPortal = 6;
    lastTeleportedPawn = null;

    /// Recreate players using the preserved starting configuration
    if (_startingConfig.isNotEmpty) {
      players = _startingConfig.entries.map((entry) {
        return Player(
          color: entry.key,
          name: entry.value.trim().isEmpty
              ? entry.key.name.toUpperCase()
              : entry.value.trim(),
          pawns: List.generate(4, (index) => Pawn(id: index, color: entry.key)),
        );
      }).toList();

      /// Reset turn to the first player in the original lineup
      currentTurn = players.first.color;
    } else {
      /// Fallback safety
      _initializeGame();
    }

    notifyListeners();
  }

  // ========================
  // REMOVE PLAYER
  // ========================

  void removePlayer(PlayerColor color) {
    // 1. If it is the removed player's turn, pass the turn to the next player first.
    if (currentTurn == color) {
      nextTurn();
    }
    // [ADDED] Track the removed player so the UI can draw the icon
    if (!removedPlayers.contains(color)) {
      removedPlayers.add(color);
      AudioManager.playRemovePlayer();
      debugPrint(
        '🚫 [PLAYER REMOVED] ${color.name} added to removedPlayers list.',
      );
    }

    // 2. Remove the player from the active players list
    players.removeWhere((p) => p.color == color);

    // 3. If only 1 player is left in the game, they automatically win!
    if (players.length == 1) {
      PlayerColor remainingPlayer = players.first.color;

      if (!winner.contains(remainingPlayer)) {
        winner.add(remainingPlayer);
      }

      isGameOver = true;
      debugPrint(
        '[GAME OVER] ALL OPPONENTS REMOVED. ${remainingPlayer.name.toUpperCase()} WINS!',
      );
      AudioManager.playGameWin();
    }
    // 4. Fallback: check if the remaining players trigger the standard game-over condition.
    else if (winner.length >= players.length - 1) {
      isGameOver = true;
    }

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
    if (isGameOver || isDiceRolling || hasRolled || isAnimatingMove) return;

    try {
      isDiceRolling = true;

      // Generate the dice value BEFORE notifying listeners
      final rand = Random();

      if (alwaysRollSix) {
        diceResult = 6; //change dice value
      } else {
        diceResult = rand.nextDouble() < 0.19 ? 6 : rand.nextInt(5) + 1;
      }
      debugPrint("Dice rolled: $diceResult");

      // --- APPLY DICE MULTIPLIER ---
      Player activePlayer = players.firstWhere((p) => p.color == currentTurn);
      if (activePlayer.hasMultiplier) {
        diceResult *= 2;
        activePlayer.hasMultiplier = false;
        debugPrint("🎲 Dice Multiplier applied! New roll: $diceResult");
      }
      notifyListeners();

      // ADJUSTABLE: Change the dice animation display duration here
      await Future.delayed(const Duration(milliseconds: 600));
    } finally {
      // Guarantee these resets happen
      isDiceRolling = false;
      hasRolled = true;

      // RULE: If the rolled number gives no legal moves, auto-pass the turn.
      if (!_hasValidMoves()) {
        debugPrint(
          '⚠️ [VALIDATION] No valid moves for ${currentTurn.name.toUpperCase()} with roll $diceResult. Auto-passing.',
        );
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 1000));
        if (isGameOver || !players.any((p) => p.color == currentTurn)) {
          debugPrint('[ROLL ABORTED] Game state changed during dice roll.');
          return;
        }
        hasRolled = false;
        nextTurn();
      } else {
        debugPrint(' [VALIDATION] Valid moves available. Waiting for player.');
        notifyListeners();
      }
    }
  }

  // ─── Turn Management ───

  /// Advances the turn to the next player in the rotation (circular).
  void nextTurn() {
    if (isGameOver) return;
    useReverseMode = false;
    int currentIndex = players.indexWhere(
      (players) => players.color == currentTurn,
    );
    int nextIndex = currentIndex;

    // loop until find an active player who has now won yet..
    do {
      nextIndex = (nextIndex + 1) % players.length;
    } while (winner.contains(players[nextIndex].color) && !isGameOver);
    currentTurn = players[nextIndex].color;
    hasRolled = false;
    AudioManager.playPassTurn();
    debugPrint('Turn passed to ${currentTurn.name.toUpperCase()}');
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

    // ─── Power Spawn Countdown ───

    if (enableSpecialPowers) {
      _turnsUntilNextPower--;
      if (_turnsUntilNextPower <= 0) {
        if (activePower.length < 2) {
          final newPower = spawnPower();
          activePower.add(newPower);
          debugPrint(
            '🌟 [POWER] Spawned ${newPower.type.name} at ${newPower.position}',
          );
        }
        _turnsUntilNextPower = Random().nextInt(5) + 6;
      }

      activePower.removeWhere((p) {
        p.remainingTurns--;
        return p.remainingTurns <= 0;
      });
    } else {
      if (activePower.isNotEmpty) {
        activePower.clear();
      }
    }
    // --- Decrement Shield Turns for the next player ---
    Player upcomingPlayer = players.firstWhere((p) => p.color == currentTurn);
    for (var pawn in upcomingPlayer.pawns) {
      if (pawn.shieldTurn > 0) pawn.shieldTurn--;
    }

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
      if (pawn.state == PawnState.inBase &&
          (diceResult == 6 || diceResult == 12)) {
        return true;
      }

      // Unified check for both path and home stretch
      if (pawn.state == PawnState.onPath ||
          pawn.state == PawnState.onHomeStretch) {
        if (pawn.step + diceResult <= 56) {
          return true;
        } else {
          debugPrint(
            '[VALIDATION] ${pawn.color.name} pawn ${pawn.id} at step ${pawn.step} cannot move (needs ${56 - pawn.step} or less, rolled $diceResult).',
          );
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

    // [FIX] Reverse Mode Validation
    if (useReverseMode && pawn.hasReverse) {
      // Cannot reverse if in base, finished, or exactly at step 0
      if (pawn.state == PawnState.inBase || pawn.state == PawnState.finished)
        return false;
      if (pawn.step == 0) return false;
      return true; // Valid to reverse
    }

    if (pawn.state == PawnState.inBase) {
      return diceResult == 6 || diceResult == 12;
    }

    if (pawn.state == PawnState.onPath ||
        pawn.state == PawnState.onHomeStretch) {
      return (pawn.step + diceResult) <= 56;
    }

    return false;
  }

  // =================================
  // ─── Check Power Pickup  ───
  // =================================
  Future<void> _checkPowerPickup(Pawn pawn) async {
    int absolutePos = BoardCoordinates.getAbsolutePosition(pawn);
    int powerIndex = activePower.indexWhere((p) => p.position == absolutePos);

    if (powerIndex != -1) {
      Power power = activePower.removeAt(powerIndex);
      debugPrint('🌟 [POWER] ${pawn.color.name} picked up ${power.type.name}!');
      await _applyPower(pawn, power.type);
    }
  }

  // =================================
  // ─── APPLY POWERS..  ───
  // =================================
  Future<void> _applyPower(Pawn pawn, PowerType type) async {
    switch (type) {
      case PowerType.shield:
        pawn.shieldTurn = 1;
        debugPrint(
          '🛡️ [SHIELD] Shield activated for ${pawn.color.name} pawn!',
        );
        break;

      case PowerType.reverse:
        pawn.hasReverse = true;
        debugPrint(
          '🔄 [REVERSE] Reverse activated for ${pawn.color.name} pawn!',
        );
        break;

      case PowerType.multiplier:
        players.firstWhere((p) => p.color == pawn.color).hasMultiplier = true;
        debugPrint(
          '✖️ [MULTIPLIER] Multiplier activated for ${pawn.color.name} pawn!',
        );
        break;

      case PowerType.swap:
        // [FIX] Find all active enemies on the main path WHO ARE NOT ON SAFE ZONES
        List<Pawn> activeEnemies = players
            .where((p) => p.color != pawn.color)
            .expand((p) => p.pawns)
            .where((p) {
              if (p.state != PawnState.onPath) return false;
              int targetAbs = BoardCoordinates.getAbsolutePosition(p);
              return !BoardCoordinates.safeZones.contains(targetAbs);
            })
            .toList();

        if (activeEnemies.isNotEmpty) {
          Pawn target = activeEnemies[Random().nextInt(activeEnemies.length)];
          int myAbs = BoardCoordinates.getAbsolutePosition(pawn);
          int targetAbs = BoardCoordinates.getAbsolutePosition(target);

          // Helper to convert absolute positions back to relative steps based on color
          int getRelative(int absolute, PlayerColor color) {
            int offset = color == PlayerColor.green
                ? 0
                : color == PlayerColor.yellow
                ? 13
                : color == PlayerColor.blue
                ? 26
                : 39;
            return (absolute - offset + 52) % 52;
          }

          pawn.step = getRelative(targetAbs, pawn.color);
          target.step = getRelative(myAbs, target.color);
          debugPrint('🔄 [SWAP] Swapped with ${target.color.name} pawn!');
        } else {
          debugPrint(
            '🔄 [SWAP FAILED] No eligible targets found (all enemies are in base, finished, or safe zones).',
          );
        }
        break;
    }
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
    if (isGameOver) return;
    if (pawn.color != currentTurn ||
        !hasRolled ||
        isDiceRolling ||
        isAnimatingMove) {
      return;
    }

    // ─── FAST FAIL LOCKS ───
    if (pawn.state == PawnState.finished) return;

    // [FIX] Prevent reverse power from being wasted at step 0
    if (useReverseMode && pawn.hasReverse && pawn.step == 0) {
      debugPrint(
        '[INVALID MOVE] Cannot use reverse power on ${pawn.color.name} pawn ${pawn.id} because it is at step 0.',
      );
      return;
    }

    if (pawn.state == PawnState.inBase &&
        (diceResult != 6 && diceResult != 12)) {
      debugPrint(
        '[INVALID MOVE] Cannot move ${pawn.color.name} pawn ${pawn.id} from base without a 6 or 12.',
      );
      return;
    }

    // Unified lock to prevent execution of an overshoot move
    if (pawn.state == PawnState.onPath ||
        pawn.state == PawnState.onHomeStretch) {
      int remainingSteps = 56 - pawn.step;
      if (diceResult > remainingSteps) {
        debugPrint(
          '[INVALID MOVE] ${pawn.color.name} pawn ${pawn.id} needs $remainingSteps or less to avoid overshoot. Rolled $diceResult.',
        );
        return;
      }
    }
    try {
      // Lock board to prevent concurrent inputs during animation.
      isAnimatingMove = true;
      debugPrint(' [MOVE START] Moving ${pawn.color.name} pawn ${pawn.id}');

      // ─── Base Exit (Special Case) ───
      if (pawn.state == PawnState.inBase &&
          (diceResult == 6 || diceResult == 12)) {
        pawn.state = PawnState.onPath;
        pawn.step = 0;
        hasRolled = false; // Player gets another roll for exiting base
        AudioManager.playBaseExit();
        return; // Exits to the finally block
      }

      // ─── Step-by-Step Movement Loop ───
      if (pawn.state == PawnState.onPath ||
          pawn.state == PawnState.onHomeStretch) {
        int stepToTake = diceResult;
        bool cutOpponent = false;

        // check if user activetd its reverse power--
        bool isReversing = useReverseMode && pawn.hasReverse;

        for (int i = 0; i < stepToTake; i++) {
          if (isReversing) {
            if (pawn.step > 0) pawn.step--; // move backwards
          } else {
            pawn.step++;
          }

          // ─── Home Stretch Entry ───
          // Changed to >= 51 to catch teleport overshoot bugs
          if (pawn.step >= 51 && pawn.state == PawnState.onPath) {
            pawn.state = PawnState.onHomeStretch;
            debugPrint(
              ' [HOME STRETCH] ${pawn.color.name} pawn ${pawn.id} entered home stretch.',
            );
          }

          if (pawn.step == 56) {
            pawn.isWinningAnimation = true;
            AudioManager.playTriangleReach();
            notifyListeners();
            await Future.delayed(const Duration(milliseconds: 650));

            // [FIX] Safety check 1
            if (isGameOver || pawn.state == PawnState.inBase) {
              debugPrint(
                '[ANIMATION ABORTED] Game reset during win animation.',
              );
              return;
            }

            pawn.state = PawnState.finished;
          } else {
            AudioManager.playPawnMovement();
          }

          notifyListeners();
          await Future.delayed(const Duration(milliseconds: 250));

          // [FIX] Safety check 2: The most critical one during walking
          if (isGameOver || pawn.state == PawnState.inBase) {
            debugPrint(
              '[ANIMATION ABORTED] Game reset or pawn died during step movement.',
            );
            return;
          }

          if (isBulldozerMode && pawn.state == PawnState.onPath) {
            bool intermediateCut = await _attemptCut(
              pawn,
              isIntermediate: true,
            );
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
        // ------------------
        if (isReversing) {
          pawn.hasReverse = false; // Power consumed
          useReverseMode = false;
        }

        // ─── Standard Final-Cell Capture ───
        if (!isBulldozerMode || diceResult != 5) {
          if (pawn.state == PawnState.onPath) {
            bool finalCut = await _attemptCut(pawn);
            if (finalCut) cutOpponent = true;
          }
        }
        // ─── Final Portal Check (MUST HAPPEN BEFORE TURN MANAGEMENT) ───
        if (pawn.state == PawnState.onPath) {
          bool teleportCut = await _checkPortalTeleport(pawn);
          // If the teleport resulted in a cut, grant the bonus turn
          if (teleportCut) cutOpponent = true;
        }

        // --- POWER PICKUP CHECK ---
        if (pawn.state == PawnState.onPath && !isReversing) {
          await _checkPowerPickup(pawn);
        }

        // ─── Check Win Condition synchronously ───
        _checkWinCondition(currentTurn);

        bool playerJustWon = winner.contains(currentTurn);

        if (!playerJustWon &&
            (diceResult == 6 ||
                cutOpponent ||
                pawn.state == PawnState.finished)) {
          debugPrint(' [BONUS TURN] ${pawn.color.name} granted extra turn.');
          hasRolled = false;
        } else {
          nextTurn();
        }
      }
    } finally {
      // Release the animation lock so the board ALWAYS accepts input again.
      isAnimatingMove = false;
      debugPrint(' [MOVE END] Sequence finished.');
      notifyListeners();
    }
  }

  /// Checks if [pawn] is on a portal and applies teleportation logic if so.
  /// Checks if [pawn] is on a portal and applies teleportation logic if so.
  Future<bool> _checkPortalTeleport(Pawn pawn) async {
    final int absolutePos = BoardCoordinates.getAbsolutePosition(pawn);

    for (var portal in activePortals) {
      if (absolutePos == portal.a || absolutePos == portal.b) {
        debugPrint(
          '🌀 [TELEPORT] Pawn ${pawn.id} entered ${portal.type.name} portal!',
        );

        lastTeleportedPawn = pawn;
        notifyListeners();

        // [FIX] 1. Get the pure exit destination
        int destAbsolute = portal.getOther(absolutePos);

        // 2. Determine color offset
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

        // 3. Convert exit to relative step FIRST
        int newStep = (destAbsolute - colorOffset + 52) % 52;

        // [FIX] 4. Apply the modifiers in RELATIVE space so it enters the home stretch properly
        if (portal.type == PortalType.red) {
          newStep += 2;
        } else if (portal.type == PortalType.purple) {
          newStep -= 2;
        }

        // [FIX] 5. Clamp bounds to prevent array crashes or infinite loops
        if (newStep < 0) {
          newStep += 52; // Wrap backwards around main path
        } else if (newStep > 56) {
          newStep = 56; // Cap at center triangle
        }

        // Visual pause before jump
        await Future.delayed(const Duration(milliseconds: 300));

        // Safety check inside teleport (from Bug 6)
        if (isGameOver || pawn.state == PawnState.inBase) {
          debugPrint('[TELEPORT ABORTED] Game reset during portal sequence.');
          return false;
        }

        AudioManager.playPortalTeleport();

        pawn.step = newStep;

        if (pawn.step >= 51 && pawn.state == PawnState.onPath) {
          pawn.state = PawnState.onHomeStretch;

          // If the portal shot them directly into the center
          if (pawn.step == 56) {
            pawn.state = PawnState.finished;
            _checkWinCondition(pawn.color);
          }
        }

        notifyListeners();

        // Clear flash after teleport
        await Future.delayed(const Duration(milliseconds: 500));

        // Safety check before continuing
        if (isGameOver || pawn.state == PawnState.inBase) return false;

        lastTeleportedPawn = null;
        notifyListeners();

        // Check for capture at the new location
        bool cutOpponent = await _attemptCut(pawn);
        return cutOpponent;
      }
    }
    return false;
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
                if (oppPawn.isShielded) {
                  debugPrint(
                    '🛡️ [SHIELD] ${oppPawn.color.name}\'s shield reflected attack from ${pawn.color.name}!',
                  );

                  pawn.isDeadAnimation = true;
                  AudioManager.playKnockOut();
                  notifyListeners();
                  await Future.delayed(const Duration(milliseconds: 100));
                  pawn.reset();

                  return false; // The cut failed because the attacker died
                } else {
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
        ' [SAFE ZONE] ${pawn.color.name} landed on safe zone $myAbsolutePosition.',
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

    if (activePlayer.hasWon && !winner.contains(color)) {
      debugPrint(' [WINNER] ${color.name.toUpperCase()} HAS WON THE GAME!');
      AudioManager.playGameWin();
      winner.add(color);
    }
    if (winner.length >= players.length - 1) {
      isGameOver = true;
      debugPrint('[GAME OVER] ALL PLAYERS HAVE WON THE GAME!');
    }
  }

  // --- REVERSE POWER TOGGLE ---
  void toggleReverseMode() {
    useReverseMode = !useReverseMode;
    notifyListeners();
  }

  // ==============================
  // PORTAL LOGIC
  // ==============================

  Portals spawnPortal() {
    final random = Random();
    int a;
    int b;

    // Pick a valid tile for Portal side A
    do {
      a = random.nextInt(52);
    } while (isRestrictedTile(a) ||
        activePortals.any((p) => p.a == a || p.b == a) ||
        activePower.any((p) => p.position == a));

    // Pick a valid, non-overlapping tile for Portal side B
    do {
      b = random.nextInt(52);
    } while (b == a ||
        isRestrictedTile(b) ||
        activePortals.any((p) => p.a == b || p.b == b) ||
        activePower.any((p) => p.position == b));

    final type = PortalType.values[random.nextInt(3)];

    // Logging portal spawn using debugPrint as per your control instructions
    debugPrint('🌀 [SPAWN] Generated portal ${type.name} connecting $a <-> $b');

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
