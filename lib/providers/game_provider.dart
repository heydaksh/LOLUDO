import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:ludo_game/main.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/models/portals.dart';
import 'package:ludo_game/models/powers.dart';
import 'package:ludo_game/utils/app_config.dart';
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

  String roomStatus = 'waiting';
  Map<String, dynamic> onlinePlayersMap = {};
  String myPlayerName = '';

  // Reference for firebase Database
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  PlayerColor? myLocalColor;
  Timer? _turnTimer;
  bool isHost = false;
  // variable to store current RoomID.
  String? currentOnlineRoomId;
  bool isOnlineMultiplayer = false;

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

  /// Tracks if the game is manually paused by the user.
  bool isPaused = false;
  String? pausedByColor;
  String? pausedByName;

  Future<void> setPauseState(bool pause) async {
    if (isOnlineMultiplayer && currentOnlineRoomId != null) {
      // Sync the pause state to Firebase
      await _db.child('rooms/$currentOnlineRoomId/pauseState').update({
        'isPaused': pause,
        'pausedByColor': pause ? myLocalColor?.name : null,
        'pausedByName': pause ? myPlayerName : null,
      });
    } else {
      // Offline local mode
      isPaused = pause;
      pausedByColor = pause ? 'local' : null;
      pausedByName = pause ? 'Local Player' : null;
      refresh();
    }
  }
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
    isPaused = false;

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
  /// Centrally determine the next color that is actually in the game.
  PlayerColor _getNextActiveColor(PlayerColor current) {
    int currentIndex = players.indexWhere((p) => p.color == current);
    int nextIndex = currentIndex;

    do {
      nextIndex = (nextIndex + 1) % players.length;
    } while ((winner.contains(players[nextIndex].color) ||
            !isPlayerInGame(players[nextIndex].color)) &&
        !isGameOver);

    return players[nextIndex].color;
  }

  void nextTurn() {
    if (isGameOver) return;
    useReverseMode = false;

    currentTurn = _getNextActiveColor(currentTurn);

    hasRolled = false;
    isDiceRolling = false;

    AudioManager.playPassTurn();
    debugPrint('Turn passed to ${currentTurn.name.toUpperCase()}');

    // ==========================================
    // PORTAL AND POWER LOGIC (HOST OR OFFLINE ONLY)
    // ==========================================
    if (!isOnlineMultiplayer || isHost) {
      _processBoardItemsForNewTurn();
    }

    Player upcomingPlayer = players.firstWhere((p) => p.color == currentTurn);
    for (var pawn in upcomingPlayer.pawns) {
      if (pawn.shieldTurn > 0) pawn.shieldTurn--;

      if (pawn.shieldTurn == 0) {
        // showPowerToast(
        //   '⚠️ ${pawn.color.name.toUpperCase()}\'s Shield Expired!',
        //   Colors.orange.shade800,
        //   Icons.gpp_bad,
        // );
      }

      if (isOnlineMultiplayer && isHost) {
        syncPawnState(pawn);
      }
    }

    notifyListeners();
    syncTurnChange();
    _startTurnTimer(); // start turn timer for offline play
    triggerBotTurn();
  }

  void triggerBotTurn() async {
    if (isGameOver) return;
    Player upcommingPlayer = players.firstWhere((p) => p.color == currentTurn);

    if (upcommingPlayer.isBot) {
      if (isOnlineMultiplayer && !isHost) return;

      await Future.delayed(AppConfig.providerInitDelay);

      while (isPaused) {
        await Future.delayed(AppConfig.providerPollInterval);
      }

      if (currentTurn == upcommingPlayer.color &&
          !isDiceRolling &&
          !hasRolled &&
          !isAnimatingMove) {
        rollDice();
      }
    }
  }

  void _processBoardItemsForNewTurn() {
    bool boardChanged = false;

    // --- PORTALS ---
    _turnsUntilNextPortal--;
    if (_turnsUntilNextPortal <= 0) {
      if (activePortals.length < 2) {
        final newPortal = spawnPortal();
        activePortals.add(newPortal);
        boardChanged = true;
      }
      _turnsUntilNextPortal = [6, 10, 12, 14][Random().nextInt(4)];
    }

    int startPortalCount = activePortals.length;
    activePortals.removeWhere((p) {
      p.remainingTurns--;
      return p.remainingTurns <= 0;
    });
    if (activePortals.length != startPortalCount) boardChanged = true;

    // --- POWERS ---
    if (enableSpecialPowers) {
      _turnsUntilNextPower--;
      if (_turnsUntilNextPower <= 0) {
        if (activePower.length < 2) {
          final newPower = spawnPower();
          activePower.add(newPower);
          boardChanged = true;
        }
        _turnsUntilNextPower = Random().nextInt(5) + 6;
      }

      int startPowerCount = activePower.length;
      activePower.removeWhere((p) {
        p.remainingTurns--;
        return p.remainingTurns <= 0;
      });
      if (activePower.length != startPowerCount) boardChanged = true;
    } else if (activePower.isNotEmpty) {
      activePower.clear();
      boardChanged = true;
    }

    // Push the new layout to everyone if something appeared or disappeared
    if (isOnlineMultiplayer && boardChanged) {
      syncBoardState();
    }
  }

  Future<void> syncBoardState() async {
    if (!isOnlineMultiplayer || currentOnlineRoomId == null) return;

    List<Map<String, dynamic>> portalsData = activePortals
        .map(
          (p) => {
            'a': p.a,
            'b': p.b,
            'type': p.type.name,
            'remainingTurns': p.remainingTurns,
          },
        )
        .toList();

    List<Map<String, dynamic>> powersData = activePower
        .map(
          (p) => {
            'position': p.position,
            'type': p.type.name,
            'remainingTurns': p.remainingTurns,
          },
        )
        .toList();

    await _db.child('rooms/$currentOnlineRoomId/boardState').update({
      'portals': portalsData,
      'powers': powersData,
    });
  }

  // ------ FIREBASE -------
  // ------ create room -------
  Future<void> createOnlineRoom(String hostPlayerName) async {
    try {
      if (players.isEmpty) _initializeGame();

      // setup lobby data
      myPlayerName = hostPlayerName;
      roomStatus = 'waiting';
      onlinePlayersMap = {};

      isOnlineMultiplayer = true;
      isHost = true;
      myLocalColor = PlayerColor.green; // host is always green
      currentOnlineRoomId = (10000 + Random().nextInt(900000)).toString();

      debugPrint("Creating online Room with id : $currentOnlineRoomId");

      Map<String, dynamic> initialPawnState = {};
      for (var player in players) {
        for (var pawn in player.pawns) {
          String pawnId = "${player.color.name}_${pawn.id}";
          initialPawnState[pawnId] = {
            'step': 0,
            'state': PawnState.inBase.name,
            'shieldTurn': 0,
            'hasReverse': false,
          };
        }
      }

      // We add a timeout so it throws an error instead of hanging forever
      await _db
          .child('rooms/$currentOnlineRoomId')
          .set({
            'status': 'waiting',
            'currentTurn': PlayerColor.green.name,
            'diceResult': 1,
            'hasRolled': false,
            'players': {
              PlayerColor.green.name: {
                'color': PlayerColor.green.name,
                'name': hostPlayerName,
                'isOnline': true,
              },
            },
            'pawns': initialPawnState,

            'boardState': {'protals': [], 'powers': []},
            'cheats': {
              'eliminateAll': false,
              'bulldozer': false,
              'alwaysSix': false,

              'specialPowers': true,
            },
            'pauseState': {
              'isPaused': false,
              'pausedByColor': null,
              'pausedByName': null,
            },
          })
          .timeout(const Duration(seconds: 10));

      refresh();
      _setupPresence(currentOnlineRoomId!, myLocalColor!.name);
      _setupRoomListeners();
    } catch (e) {
      debugPrint("Error creating room: $e");
      currentOnlineRoomId = null; // reset if failed
      isOnlineMultiplayer = false;
      rethrow; // Pass error back to UI
    }
  }

  // ------ Join room -------
  Future<bool> joinOnlineRoom(String roomId, String playerName) async {
    try {
      if (players.isEmpty) _initializeGame();

      // Add timeout to prevent infinite hanging
      final roomSnapshot = await _db
          .child('rooms/$roomId')
          .get()
          .timeout(const Duration(seconds: 10));

      if (!roomSnapshot.exists) {
        debugPrint("Room not found!!");
        return false;
      }

      Map roomData = roomSnapshot.value as Map;
      if (roomData['status'] == 'playing') {
        throw "Game has already started!";
      }

      myPlayerName = playerName;
      roomStatus = 'waiting';

      Map playersData = roomData['players'] ?? {};

      if (playersData.length >= 4) {
        debugPrint("Room is Full...!");
        return false;
      }

      List<PlayerColor> availableColor = PlayerColor.values.toList();
      playersData.forEach((key, value) {
        availableColor.removeWhere((color) => color.name == value['color']);
      });

      // ==========================================
      // SMART COLOR ASSIGNMENT (Diagonal Seating)
      // ==========================================
      PlayerColor assignedColor;

      if (playersData.length == 1 &&
          availableColor.contains(PlayerColor.blue)) {
        // 2nd player joins -> place them opposite to Green (Host)
        assignedColor = PlayerColor.blue;
      } else if (playersData.length == 2 &&
          availableColor.contains(PlayerColor.yellow)) {
        // 3rd player joins -> adjacent corner
        assignedColor = PlayerColor.yellow;
      } else {
        // Fallback for 4th player (Red), or if players leave/rejoin out of order
        assignedColor = availableColor.first;
      }

      myLocalColor = assignedColor;

      // ... [Keep the rest of the database saving and setup the same] ...
      await _db
          .child('rooms/$roomId/players/${assignedColor.name}')
          .set({
            'color': assignedColor.name,
            'name': playerName,
            'isOnline': true,
          })
          .timeout(const Duration(seconds: 10));

      isOnlineMultiplayer = true;
      currentOnlineRoomId = roomId;

      _setupRoomListeners();
      _setupPresence(roomId, assignedColor.name);
      return true;
    } catch (e) {
      debugPrint("Error joining room: $e");
      rethrow;
    }
  }

  // setup room listeners

  StreamSubscription? _roomSubscription;

  void _setupRoomListeners() {
    if (currentOnlineRoomId == null) return;

    _roomSubscription = _db.child('rooms/$currentOnlineRoomId').onValue.listen((
      event,
    ) {
      if (event.snapshot.value == null) {
        if (isOnlineMultiplayer && !isHost) {
          roomStatus = 'ended_by_host';
          refresh();
        }
        return;
      }

      Map roomData = event.snapshot.value as Map;

      // ==========================================
      // 1. SYNC TURN
      // ==========================================
      if (roomData['currentTurn'] != null) {
        PlayerColor incomingTurn = PlayerColor.values.firstWhere(
          (e) => e.name == roomData['currentTurn'],
        );

        if (currentTurn != incomingTurn) {
          currentTurn = incomingTurn;
          _startTurnTimer();

          // If the turn change came from a remote client, the Host must spawn items!
          if (isHost) {
            _processBoardItemsForNewTurn();
          }

          Player upcomingPlayer = players.firstWhere(
            (p) => p.color == currentTurn,
          );
          for (var pawn in upcomingPlayer.pawns) {
            if (pawn.shieldTurn > 0) {
              pawn.shieldTurn--;

              if (pawn.shieldTurn == 0) {
                showPowerToast(
                  '⚠️ ${pawn.color.name.toUpperCase()}\'s Shield Expired!',
                  Colors.orange.shade800,
                  Icons.gpp_bad,
                );
              }
              if (isHost) syncPawnState(pawn);
            }
          }

          // [FIXED]: Trigger the bot remotely if the turn switched to a bot
          triggerBotTurn();
        }
      }

      // ==========================================
      // 2. SYNC DICE
      // ==========================================
      if (roomData['diceResult'] != null) {
        // Robust casting to handle different numeric types from Firebase
        diceResult = (roomData['diceResult'] as num).toInt();

        // Sync both state flags to ensure animations and turn-blocks are consistent
        isDiceRolling = roomData['isDiceRolling'] ?? false;
        hasRolled = roomData['hasRolled'] ?? false;

        if (hasRolled) {
          // Cancel turn timer if someone rolled
          _turnTimer?.cancel();
        }
      }

      // ==========================================
      // 3. SYNC PORTALS & POWERS
      // ==========================================
      if (roomData['boardState'] != null) {
        Map boardStateData = roomData['boardState'];

        List portalsList = boardStateData['portals'] ?? [];
        activePortals = portalsList
            .map(
              (p) => Portals(
                a: p['a'],
                b: p['b'],
                type: PortalType.values.firstWhere((e) => e.name == p['type']),
                remainingTurns: p['remainingTurns'],
              ),
            )
            .toList();

        List powersList = boardStateData['powers'] ?? [];
        activePower = powersList
            .map(
              (p) => Power(
                position: p['position'],
                type: PowerType.values.firstWhere((e) => e.name == p['type']),
                remainingTurns: p['remainingTurns'],
              ),
            )
            .toList();
      } else {
        activePortals.clear();
        activePower.clear();
      }

      // ==========================================
      // 4. SYNC PAWNS
      // ==========================================
      if (roomData['pawns'] != null) {
        Map pawnsData = roomData['pawns'];
        for (var player in players) {
          for (var pawn in player.pawns) {
            String pawnId = '${player.color.name}_${pawn.id}';
            var pData = pawnsData[pawnId];

            if (pData != null) {
              int newStep = pData['step'];
              PawnState newState = PawnState.values.firstWhere(
                (e) => e.name == pData['state'],
              );

              // --- REMOTE SOUND & ANIMATION TRIGGERS ---
              // These only trigger if the state actually changed, meaning this
              // local client didn't make the move (otherwise state would already match).

              // 1. Triangle Reach (Winning Animation Trigger)
              // Trigger when it hits step 56, BEFORE it reaches 'finished' state.
              // This allows the pawn to shrink (black hole effect) precisely at the track tip.
              if (pawn.step != 56 && newStep == 56) {
                pawn.isWinningAnimation = true;
                AudioManager.playTriangleReach();

                // Extend to 2.5 seconds to match local animation timing
                Future.delayed(const Duration(milliseconds: 2500), () {
                  pawn.isWinningAnimation = false;
                  refresh();
                });
              }
              // 2. Kill / Knockout (Moved back to Base)
              else if (pawn.state != PawnState.inBase &&
                  newState == PawnState.inBase) {
                pawn.isDeadAnimation = true;
                AudioManager.playKnockOut();

                Future.delayed(const Duration(milliseconds: 600), () {
                  pawn.isDeadAnimation = false;
                  refresh();
                });
              }
              // 3. Base Exit (Moved out of Base)
              else if (pawn.state == PawnState.inBase &&
                  newState == PawnState.onPath) {
                AudioManager.playBaseExit();
              }
              // 4. Movement / Teleport
              else if ((pawn.state == PawnState.onPath ||
                      pawn.state == PawnState.onHomeStretch) &&
                  (newState == PawnState.onPath ||
                      newState == PawnState.onHomeStretch)) {
                int stepDiff = (newStep - pawn.step).abs();

                if (stepDiff > 12) {
                  // A large jump implies a teleport portal or swap power was used
                  AudioManager.playPortalTeleport();
                } else if (stepDiff > 0) {
                  // Normal single-step movement
                  AudioManager.playPawnMovement();
                }
              }

              // Apply the new state and parameters
              pawn.step = newStep;
              pawn.state = newState;
              pawn.shieldTurn = pData['shieldTurn'] ?? 0;
              pawn.hasReverse = pData['hasReverse'] ?? false;

              // 5. Game Win Detection
              // Check win condition after applying state so the victory sound plays for everyone
              if (newState == PawnState.finished) {
                _checkWinCondition(pawn.color);
              }
            }
          }
        }
      }

      // ==========================================
      //  4.2 SYNC ROOM STATUS & KICKED PLAYERS
      // ==========================================
      if (roomData['status'] != null) {
        String newStatus = roomData['status'];

        //  When the game starts, silently delete all non-joined players
        // from the local list so the Turn Logic and Victory Logic calculate correctly!
        if (roomStatus == 'waiting' && newStatus == 'playing') {
          Map pMap = roomData['players'] ?? {};
          players.removeWhere((p) => !pMap.containsKey(p.color.name));
        }

        roomStatus = newStatus;
      }

      // ==========================================
      // 5. SYNC PLAYER NAMES, LOBBY, & ONLINE STATUS
      // ==========================================
      if (roomData['players'] != null) {
        Map playersMap = roomData['players'];
        onlinePlayersMap = Map<String, dynamic>.from(
          playersMap,
        ); // Updates the UI lobby list

        List<Player> activePlayersList = List.from(players);
        for (var p in activePlayersList) {
          var pData = playersMap[p.color.name];
          if (pData != null) {
            p.name = pData['name'];
            bool isPlayerOnline = pData['isOnline'] == true;
          } else {
            // If they are missing from Firebase while the game is playing,
            // it means the host kicked them mid-game. We must remove them!
            if (roomStatus == 'playing' && !removedPlayers.contains(p.color)) {
              removePlayer(p.color);
            }
          }
        }
      } else {
        onlinePlayersMap = {};
      }

      // ==========================================
      // 6. SYNC CHEATS & SNACKBAR NOTIFICATIONS
      // ==========================================
      if (roomData['cheats'] != null) {
        Map cheatsMap = roomData['cheats'];

        void checkAndNotify(String name, bool oldVal, bool newVal) {
          if (oldVal != newVal && !isHost) {
            String msg = newVal
                ? "$name was ENABLED by Host!"
                : "$name was DISABLED by Host!";
            scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text(
                  msg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: newVal
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }

        bool newEliminate = cheatsMap['eliminateAll'] ?? false;
        checkAndNotify("Eliminate All", eliminateAllOpponents, newEliminate);
        eliminateAllOpponents = newEliminate;

        bool newBulldozer = cheatsMap['bulldozer'] ?? false;
        checkAndNotify("Bulldozer Mode", isBulldozerMode, newBulldozer);
        isBulldozerMode = newBulldozer;

        bool newAlwaysSix = cheatsMap['alwaysSix'] ?? false;
        checkAndNotify("Always Roll 6", alwaysRollSix, newAlwaysSix);
        alwaysRollSix = newAlwaysSix;

        bool newSpecial = cheatsMap['specialPowers'] ?? true;
        checkAndNotify("Special Powers", enableSpecialPowers, newSpecial);
        enableSpecialPowers = newSpecial;
      }
      // ==========================================
      // 7. SYNC PAUSE STATE
      // ==========================================
      if (roomData['pauseState'] != null) {
        bool incomingPause = roomData['pauseState']['isPaused'] ?? false;
        if (isPaused != incomingPause) {
          isPaused = incomingPause;
          pausedByColor = roomData['pauseState']['pausedByColor'];
          pausedByName = roomData['pauseState']['pausedByName'];
        }
      } else {
        isPaused = false;
        pausedByColor = null;
        pausedByName = null;
      }
      // Update the UI with the fresh data
      refresh();
    });
  }

  // manages the online status of player..
  void _setupPresence(String roomId, String colorName) {
    DatabaseReference playerRef = _db.child('rooms/$roomId/players/$colorName');

    playerRef.update({'isOnline': true});

    playerRef.onDisconnect().update({'isOnline': false});
  }

  void _startTurnTimer() {
    // Only the host manages the authoritative turn timer to avoid race conditions.
    if (isOnlineMultiplayer && !isHost) return;

    _turnTimer?.cancel();

    _turnTimer = Timer(const Duration(seconds: 15), () async {
      debugPrint("Time out for ${currentTurn.name}! Skipping Turn..");

      if (isOnlineMultiplayer) {
        // Find the next available color using our centralized helper.
        PlayerColor nextColor = _getNextActiveColor(currentTurn);

        await _db.child('rooms/$currentOnlineRoomId').update({
          'currentTurn': nextColor.name,
          'hasRolled': false,
        });
      } else {
        nextTurn();
      }
    });
  }

  // ---------------------------------------------------
  // FIREBASE SYNC HELPERS
  // ---------------------------------------------------

  ///  To sync the dice roll to Firebase.
  Future<void> syncDiceRoll(int newDiceResult) async {
    if (!isOnlineMultiplayer || currentOnlineRoomId == null) return;

    await _db.child('rooms/$currentOnlineRoomId').update({
      'diceResult': diceResult,
      'hasRolled': true,
      'isDiceRolling': isDiceRolling,
      'status': 'playing',
    });
  }

  /// Sync whether the dice is currently spinning/rolling
  Future<void> syncDiceRolling(bool rolling) async {
    if (!isOnlineMultiplayer || currentOnlineRoomId == null) return;

    await _db.child('rooms/$currentOnlineRoomId').update({
      'isDiceRolling': rolling,
      'diceResult': diceResult,
    });
  }

  /// To send the new position of player to firebase.
  Future<void> syncPawnState(Pawn pawn) async {
    if (!isOnlineMultiplayer || currentOnlineRoomId == null) return;

    String pawnId = '${pawn.color.name}_${pawn.id}';
    await _db.child('rooms/$currentOnlineRoomId/pawns/$pawnId').update({
      'step': pawn.step,
      'state': pawn.state.name,
      'shieldTurn': pawn.shieldTurn,
      'hasReverse': pawn.hasReverse,
    });
  }

  ///  To sync the turn change (e.g. Green to Yellow).
  Future<void> syncTurnChange() async {
    if (!isOnlineMultiplayer || currentOnlineRoomId == null) return;

    await _db.child('rooms/$currentOnlineRoomId').update({
      'currentTurn': currentTurn.name,
      'hasRolled': false,
      'isDiceRolling': false,
    });
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }

  void refresh() => notifyListeners();

  // ==============================
  // TOAST NOTIFICATION HELPER
  // ==============================
  void showPowerToast(String message, Color bgColor, IconData icon) {
    // Hide any existing toast instantly so they don't queue up forever
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),
    );
  }

  /// Centrally determine if a color is part of the current game session.
  bool isPlayerInGame(PlayerColor color) {
    if (isOnlineMultiplayer) {
      // In online mode, check if the color is in the players map AND not removed
      return onlinePlayersMap.containsKey(color.name) &&
          !removedPlayers.contains(color);
    } else {
      // In offline mode, the 'players' list only contains selected players
      return players.any((p) => p.color == color) &&
          !removedPlayers.contains(color);
    }
  }

  // ------ Host Controls -------
  Future<void> startGameHost() async {
    if (currentOnlineRoomId == null) return;
    await _db.child('rooms/$currentOnlineRoomId').update({'status': 'playing'});
  }

  Future<void> kickPlayer(String colorName, String playerName) async {
    if (currentOnlineRoomId == null) return;
    // Only remove their slot from the room. No permanent ban list!
    await _db.child('rooms/$currentOnlineRoomId/players/$colorName').remove();
  }
}
