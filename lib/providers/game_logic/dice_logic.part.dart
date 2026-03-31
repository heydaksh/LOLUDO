part of '../game_provider.dart';

extension GameProviderDice on GameProvider {
  /// Rolls the dice for the current player.
  /// Rolls the dice for the current player.
  Future<void> rollDice() async {
    if (isGameOver || isDiceRolling || hasRolled || isAnimatingMove) return;

    // Capture the turn at the START. If it changes during the 600ms roll, we discard.
    final PlayerColor turnAtStart = currentTurn;

    // Fast-cancel the turn timer locally before even notifying Firebase
    _turnTimer?.cancel();
    try {
      isDiceRolling = true;

      //  Firebase ko batane se PEHLE number generate karein
      final rand = Random();
      Player activePlayer = players.firstWhere((p) => p.color == currentTurn);

      if (alwaysRollSix) {
        diceResult = 6; // change dice value here
      } else {
        if (activePlayer.turnsWithoutSix >= 7) {
          diceResult = 6;
          debugPrint(
            "Badluck protection triggered for ${activePlayer.color.name}!.",
          );
        } else {
          diceResult = rand.nextInt(6) + 1;
        }
      }
      if (diceResult == 6) {
        activePlayer.turnsWithoutSix = 0;
      } else {
        activePlayer.turnsWithoutSix++;
      }
      debugPrint(
        "Dice rolled: $diceResult (Dry spell: ${activePlayer.turnsWithoutSix})",
      );

      // --- APPLY DICE MULTIPLIER ---
      if (activePlayer.hasMultiplier) {
        diceResult *= 2;
        activePlayer.hasMultiplier = false;
        debugPrint("🎲 Dice Multiplier applied! New roll: $diceResult");
      }

      //  AB Firebase ko sync karein, taaki naya number network par chala jaye
      syncDiceRolling(true);

      refresh();

      // ADJUSTABLE: Change the dice animation display duration here
      await Future.delayed(AppConfig.diceResultDisplayDuration);
    } finally {
      // Guarantee these resets happen before we mark it as "rolled"
      isDiceRolling = false;
    }

    hasRolled = true;
    refresh();

    //  If the turn timed out and changed, we must reset hasRolled so the next player can roll.
    if (currentTurn != turnAtStart) {
      debugPrint(
        "⚠️ [ROLL ABORTED] Turn changed while rolling. Discarding result.",
      );
      hasRolled = false;
      return;
    }

    syncDiceRoll(diceResult);

    // --- AUTOMATION LOGIC ---
    List<Pawn> validPawns = _getValidPawns();

    if (validPawns.isEmpty) {
      debugPrint(
        '⚠️ [VALIDATION] No valid moves for ${currentTurn.name.toUpperCase()} with roll $diceResult. Auto-passing.',
      );
      refresh();

      await Future.delayed(AppConfig.autoPassTurnDelay);
      if (isGameOver || !isPlayerInGame(currentTurn)) {
        debugPrint('[ROLL ABORTED] Game state changed during dice roll.');
        return;
      }
      nextTurn();
    } else if (validPawns.length == 1) {
      debugPrint(
        '🤖 [AUTOMATION] Only 1 valid move found. Auto-moving pawn ${validPawns.first.id}.',
      );
      refresh();

      await Future.delayed(AppConfig.autoMoveDelay);

      while (isPaused) {
        await Future.delayed(AppConfig.soundCheckInterval);
      }

      if (isGameOver || !isPlayerInGame(currentTurn)) return;

      movePawn(validPawns.first);
    } else {
      Player activePlayer = players.firstWhere((p) => p.color == currentTurn);

      if (activePlayer.isBot) {
        debugPrint(' [BOT] Deciding between ${validPawns.length} options...');

        await Future.delayed(AppConfig.botDecisionDelay);

        while (isPaused) {
          await Future.delayed(AppConfig.soundCheckInterval);
        }

        if (isGameOver || !isPlayerInGame(currentTurn)) return;

        Pawn bestPawn = _chooseBestPawnForBot(validPawns);
        movePawn(bestPawn);
      } else {
        debugPrint(
          ' [VALIDATION] ${validPawns.length} valid moves available. Waiting for player.',
        );
        refresh();
      }
    }
  }

  Pawn _chooseBestPawnForBot(List<Pawn> validMoves) {
    Pawn? bestPawn;
    int highestScore = -9999;
    final random = Random();

    for (var pawn in validMoves) {
      int moveScore = 0;

      // --- Winning move ----
      if (pawn.state == PawnState.onPath ||
          pawn.state == PawnState.onHomeStretch) {
        if (pawn.step + diceResult == 56) {
          moveScore += 2000;
        }
      }

      // --- Deploy form base ---

      if (pawn.state == PawnState.inBase &&
          (diceResult == 6 /*add diceResult == 12 to open in 12*/ )) {
        moveScore += 300;
      }

      // ---Path logic---
      if (pawn.state == PawnState.onPath) {
        int currentAbs = BoardCoordinates.getAbsolutePosition(pawn);
        int nextStep = pawn.step + diceResult;

        // entering the safe home stretch
        if (pawn.step < 51 && nextStep >= 51) {
          moveScore += 400;
        } else if (nextStep < 51) {
          int colorOffset = 0;
          switch (pawn.color) {
            case PlayerColor.green:
              colorOffset = 0;
              break;
            case PlayerColor.blue:
              colorOffset = 26;
              break;
            case PlayerColor.red:
              colorOffset = 39;
              break;
            case PlayerColor.yellow:
              colorOffset = 13;
              break;
          }
          int nextAbs = (nextStep + colorOffset) % 52;

          // --- Haunting ---

          bool canCut = false;
          if (!BoardCoordinates.safeZones.contains(nextAbs)) {
            for (var player in players) {
              if (player.color != pawn.color && isPlayerInGame(player.color)) {
                for (var oppPawn in player.pawns) {
                  if (oppPawn.state == PawnState.onPath &&
                      !oppPawn.isShielded) {
                    int oppAbs = BoardCoordinates.getAbsolutePosition(oppPawn);
                    if (oppAbs == nextAbs) {
                      canCut = true;
                      moveScore += 1000 + (oppPawn.step * 10);
                    }
                  }
                }
              }
            }
          }
          // ---- Escaping Danger ----
          bool isVulnerable = false;
          if (!BoardCoordinates.safeZones.contains(currentAbs)) {
            for (var player in players) {
              if (player.color != pawn.color && isPlayerInGame(player.color)) {
                for (var oppPawn in player.pawns) {
                  if (oppPawn.state == PawnState.onPath) {
                    int oppAbs = BoardCoordinates.getAbsolutePosition(oppPawn);

                    int diff = (currentAbs - oppAbs + 52) % 52;
                    if (diff > 0 && diff <= 6) {
                      isVulnerable = true;
                    }
                  }
                }
              }
            }
          }
          // if we are in danger, move pawn or run
          if (isVulnerable && !canCut) {
            moveScore += 600;
          }
          // seeking for safe zones..
          if (BoardCoordinates.safeZones.contains(nextAbs)) {
            moveScore += 250;
          }

          // seeking for portals and powers..

          if (activePortals.any((p) => p.a == nextAbs || p.b == nextAbs)) {
            moveScore += 350;
          }
          if (activePower.any((p) => p.position == nextAbs)) {
            moveScore += 450;
          }
        }
      }

      // GENERAL PROGRESS

      if (pawn.state != PawnState.inBase) {
        moveScore += pawn.step;
      }
      moveScore += random.nextInt(40);
      // compare to find the best move
      if (moveScore > highestScore) {
        highestScore = moveScore;
        bestPawn = pawn;
      }
    }
    return bestPawn ?? validMoves.first;
  }

  /// Returns a list of pawns belonging to the current player that can legally move.
  List<Pawn> _getValidPawns() {
    Player activePlayer = players.firstWhere((p) => p.color == currentTurn);

    // We reuse the existing `canPawnMove` logic from movement_logic.part.dart
    return activePlayer.pawns.where((pawn) => canPawnMove(pawn)).toList();
  }
}
