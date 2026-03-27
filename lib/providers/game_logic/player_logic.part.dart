part of '../game_provider.dart';

extension GameProviderPlayer on GameProvider {
  void initializePlayers(Map<PlayerColor, PlayerSetup> selectedPlayersInfo) {
    debugPrint(
      "GameProvider: initializing ${selectedPlayersInfo.length} players",
    );
    gameSessionId++;
    removedPlayers.clear();

    // Ensure online mode is completely disabled for local play
    isOnlineMultiplayer = false;
    currentOnlineRoomId = null;
    isHost = false;
    myLocalColor = null;
    _roomSubscription?.cancel();

    _startingConfig = Map.from(selectedPlayersInfo);
    players.clear();

    players = selectedPlayersInfo.entries.map((entry) {
      return Player(
        color: entry.key,
        name: entry.value.name.trim().isEmpty
            ? entry.key.name.toUpperCase()
            : entry.value.name.trim(),
        isBot: entry.value.isBot,
        pawns: List.generate(4, (index) => Pawn(id: index, color: entry.key)),
      );
    }).toList();

    currentTurn = players.first.color;
    isPaused = false;
    refresh();
  }

  void restartGame() {
    debugPrint('🔄 Restarting game...');
    gameSessionId++;

    winner.clear();
    isGameOver = false;
    isPaused = false;
    removedPlayers.clear();
    diceResult = 1;
    hasRolled = false;
    isDiceRolling = false;
    isAnimatingMove = false;

    activePortals.clear();
    _turnsUntilNextPortal = 6;
    lastTeleportedPawn = null;

    if (_startingConfig.isNotEmpty) {
      players = _startingConfig.entries.map((entry) {
        return Player(
          color: entry.key,
          name: entry.value.name.trim().isEmpty
              ? entry.key.name.toUpperCase()
              : entry.value.name.trim(),
          isBot: entry.value.isBot,
          pawns: List.generate(4, (index) => Pawn(id: index, color: entry.key)),
        );
      }).toList();

      currentTurn = players.first.color;
    } else {
      _initializeGame();
    }

    refresh();
  }

  void removePlayer(PlayerColor color) {
    if (currentTurn == color) {
      nextTurn();
    }
    if (!removedPlayers.contains(color)) {
      removedPlayers.add(color);
      AudioManager.playRemovePlayer();
      debugPrint(
        '🚫 [PLAYER REMOVED] ${color.name} added to removedPlayers list.',
      );
    }

    players.removeWhere((p) => p.color == color);

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
    } else if (winner.length >= players.length - 1) {
      isGameOver = true;
    }

    refresh();
  }

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

  void exitGame() {
    debugPrint('🚪 Exiting game...');
    isGameOver = false;

    // Disconnect from Firebase if exiting an online game
    if (isOnlineMultiplayer &&
        currentOnlineRoomId != null &&
        myLocalColor != null) {
      _db
          .child('rooms/$currentOnlineRoomId/players/${myLocalColor!.name}')
          .update({'isOnline': false});
    }

    isOnlineMultiplayer = false;
    currentOnlineRoomId = null;
    isHost = false;
    myLocalColor = null;
    _roomSubscription?.cancel();

    _startingConfig.clear();
    players.clear();
    winner.clear();
    removedPlayers.clear();
    activePortals.clear();
    activePower.clear();
    refresh();
  }
}
