import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/models/portals.dart';
import 'package:ludo_game/models/powers.dart';
import 'package:ludo_game/utils/audio_manager.dart';
import 'package:ludo_game/utils/board_coordinates.dart';
import 'package:ludo_game/utils/portal_utils.dart';

part 'game_logic/capture_logic.part.dart';
part 'game_logic/cheat_logic.part.dart';
part 'game_logic/dice_logic.part.dart';
part 'game_logic/movement_logic.part.dart';
part 'game_logic/player_logic.part.dart';
part 'game_logic/portal_logic.part.dart';
part 'game_logic/power_logic.part.dart';

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

  Map<PlayerColor, PlayerSetup> _startingConfig = {};

  /// Increments every time a new game starts to trigger one-time overlay animations.
  int gameSessionId = 0;

  /// List of all active players in the current game session.
  List<Player> players = [];

  /// List of players who have been removed/quit during the current match.
  List<PlayerColor> removedPlayers = [];

  /// The color of the player whose turn it currently is.
  PlayerColor currentTurn = PlayerColor.green;

  /// List of winners. Empty means game is still in progress.
  List<PlayerColor> winner = [];
  bool isGameOver = false;

  // ─── Dice State ───

  /// The number value currently showing on the dice (1–6).
  int diceResult = 1;

  /// True while the dice rolling animation is in progress.
  bool isDiceRolling = false;

  /// True after the dice has been rolled but before the player has moved a pawn.
  bool hasRolled = false;

  // ─── Animation Lock ───

  /// Prevents any new input while a pawn movement animation is in progress.
  bool isAnimatingMove = false;

  // ─── Portal State ───

  /// List of currently active portal pairs on the main board path.
  List<Portals> activePortals = [];
  List<Power> activePower = [];
  int _turnsUntilNextPower = 8;
  bool useReverseMode = false;

  /// Tracks turns to decide when to spawn a new portal.
  int _turnsUntilNextPortal = 6;

  /// The pawn that was most recently teleported.
  Pawn? lastTeleportedPawn;

  // ==============================
  // CHEAT / DEBUG FEATURE FLAGS
  // ==============================

  bool eliminateAllOpponents = false;
  bool isBulldozerMode = false;
  bool alwaysRollSix = false;
  bool enableSpecialPowers = true;

  // ==============================
  // CONSTRUCTOR / LIFECYCLE
  // ==============================

  GameProvider() {
    _initializeGame();
  }

  // ==============================
  // INITIALIZATION
  // ==============================

  void _initializeGame() {
    debugPrint('🎮 Initializing new game...');

    _startingConfig = {
      PlayerColor.green: PlayerSetup(name: "Player 1", isBot: false),
      PlayerColor.yellow: PlayerSetup(name: "Player 2", isBot: false),
      PlayerColor.blue: PlayerSetup(name: "Player 3", isBot: false),
      PlayerColor.red: PlayerSetup(name: "Player 4", isBot: false),
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

  // ─── Turn Management ───

  void nextTurn() {
    if (isGameOver) return;
    useReverseMode = false;
    int currentIndex = players.indexWhere(
      (players) => players.color == currentTurn,
    );
    int nextIndex = currentIndex;

    do {
      nextIndex = (nextIndex + 1) % players.length;
    } while (winner.contains(players[nextIndex].color) && !isGameOver);
    currentTurn = players[nextIndex].color;
    hasRolled = false;
    AudioManager.playPassTurn();
    debugPrint('Turn passed to ${currentTurn.name.toUpperCase()}');

    _turnsUntilNextPortal--;
    if (_turnsUntilNextPortal <= 0) {
      if (activePortals.length < 2) {
        final newPortal = spawnPortal();
        activePortals.add(newPortal);
        debugPrint(
          ' [PORTAL] Spawned ${newPortal.type.name} portal at ${newPortal.a} <-> ${newPortal.b}',
        );
      }
      final options = [6, 10, 12, 14];
      _turnsUntilNextPortal = options[Random().nextInt(options.length)];
    }

    activePortals.removeWhere((p) {
      p.remainingTurns--;
      if (p.remainingTurns <= 0) {
        debugPrint('🌀 [PORTAL] Expired portal at ${p.a}');
        return true;
      }
      return false;
    });

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
    Player upcomingPlayer = players.firstWhere((p) => p.color == currentTurn);
    for (var pawn in upcomingPlayer.pawns) {
      if (pawn.shieldTurn > 0) pawn.shieldTurn--;
    }

    notifyListeners();
    triggerBotTurn();
  }

  void triggerBotTurn() async {
    if (isGameOver) return;
    Player upcommingPlayer = players.firstWhere((p) => p.color == currentTurn);

    if (upcommingPlayer.isBot) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (currentTurn == upcommingPlayer.color &&
          !isDiceRolling &&
          !hasRolled &&
          !isAnimatingMove) {
        rollDice();
      }
    }
  }

  /// Refreshes the UI by notifying listeners.
  /// Used by extensions since notifyListeners is protected.
  void refresh() => notifyListeners();
}
