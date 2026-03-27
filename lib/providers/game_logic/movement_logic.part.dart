part of '../game_provider.dart';

extension GameProviderMovement on GameProvider {
  /// Returns true if this specific [pawn] can legally move right now.
  bool canPawnMove(Pawn pawn) {
    if (pawn.color != currentTurn) return false;
    if (!hasRolled) return false;

    if (useReverseMode && pawn.hasReverse) {
      if (pawn.state == PawnState.inBase || pawn.state == PawnState.finished) {
        return false;
      }
      if (pawn.step == 0) return false;
      return true;
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

  /// Called when the player taps a pawn to move it.
  Future<void> movePawn(Pawn pawn) async {
    if (isGameOver) return;
    if (pawn.color != currentTurn ||
        !hasRolled ||
        isDiceRolling ||
        isAnimatingMove) {
      return;
    }

    if (pawn.state == PawnState.finished) return;

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
      isAnimatingMove = true;

      if (pawn.state == PawnState.inBase &&
          (diceResult == 6 || diceResult == 12)) {
        pawn.state = PawnState.onPath;
        pawn.step = 0;
        hasRolled = false;

        AudioManager.playBaseExit();
        refresh();

        syncPawnState(pawn);
        if (isOnlineMultiplayer) {
          _db.child('rooms/$currentOnlineRoomId').update({'hasRolled': false});
        }
        triggerBotTurn(); // Tell the bot to roll again after leaving base
        return;
      }

      if (pawn.state == PawnState.onPath ||
          pawn.state == PawnState.onHomeStretch) {
        int stepToTake = diceResult;
        bool cutOpponent = false;
        bool isReversing = useReverseMode && pawn.hasReverse;

        for (int i = 0; i < stepToTake; i++) {
          if (isReversing) {
            if (pawn.step > 0) pawn.step--;
            if (pawn.step < 51 && pawn.state == PawnState.onHomeStretch) {
              pawn.state = PawnState.onPath;
            }
          } else {
            pawn.step++;
            if (pawn.step >= 51 && pawn.state == PawnState.onPath) {
              pawn.state = PawnState.onHomeStretch;
            }
          }

          if (pawn.step >= 51 && pawn.state == PawnState.onPath) {
            pawn.state = PawnState.onHomeStretch;
          }

          if (pawn.step == 56) {
            pawn.isWinningAnimation = true;
            AudioManager.playTriangleReach();
            refresh();
            await Future.delayed(AppConfig.postMoveDelay);

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

          refresh();
          syncPawnState(pawn);
          // Add small pause before checking capture
          await Future.delayed(AppConfig.captureExecutionDelay);

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
            _checkWinCondition(pawn.color);
            Future.delayed(const Duration(milliseconds: 2500), () {
              pawn.isWinningAnimation = false;
              refresh();
            });
          }
        }

        if (isReversing) {
          pawn.hasReverse = false;
          useReverseMode = false;
        }

        if (!isBulldozerMode || diceResult != 5) {
          if (pawn.state == PawnState.onPath) {
            bool finalCut = await _attemptCut(pawn);
            if (finalCut) cutOpponent = true;
          }
        }

        if (pawn.state == PawnState.onPath) {
          bool teleportCut = await _checkPortalTeleport(pawn);
          if (teleportCut) cutOpponent = true;
        }

        if (pawn.state == PawnState.onPath && !isReversing) {
          await _checkPowerPickup(pawn);
        }

        _checkWinCondition(currentTurn);
        bool playerJustWon = winner.contains(currentTurn);

        // Wait for special sounds (kill/win) to finish before proceeding
        if (cutOpponent || pawn.state == PawnState.finished) {
          int timeoutCounter = 0;
          while (isPaused ||
              (AudioManager.isSoundPlaying && timeoutCounter < 15)) {
            await Future.delayed(AppConfig.soundCheckInterval);
            if (!isPaused && AudioManager.isSoundPlaying) timeoutCounter++;
          }
        }

        if (!playerJustWon &&
            (diceResult == 6 ||
                cutOpponent ||
                pawn.state == PawnState.finished)) {
          debugPrint(' [BONUS TURN] ${pawn.color.name} granted extra turn.');
          hasRolled = false;
          // [FIXED]: Firebase must be notified of bonus turn so it doesn't lock your dice!
          if (isOnlineMultiplayer && currentOnlineRoomId != null) {
            _db.child('rooms/$currentOnlineRoomId').update({
              'hasRolled': false,
            });
          }
          triggerBotTurn();
        } else {
          nextTurn();
        }
      }
    } finally {
      isAnimatingMove = false;
      debugPrint(' [MOVE END] Sequence finished.');
      syncPawnState(pawn);

      refresh();
    }
  }

  Future<bool> _checkPortalTeleport(Pawn pawn) async {
    final int absolutePos = BoardCoordinates.getAbsolutePosition(pawn);

    for (var portal in activePortals) {
      if (absolutePos == portal.a || absolutePos == portal.b) {
        lastTeleportedPawn = pawn;
        refresh();

        int destAbsolute = portal.getOther(absolutePos);
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

        int newStep = (destAbsolute - colorOffset + 52) % 52;

        if (portal.type == PortalType.red) {
          newStep += 2;
        } else if (portal.type == PortalType.purple) {
          newStep -= 2;
        }

        if (newStep < 0) {
          newStep += 52;
        } else if (newStep > 56) {
          newStep = 56;
        }

        await Future.delayed(AppConfig.portalPreTeleportDelay);

        if (isGameOver || pawn.state == PawnState.inBase) {
          debugPrint('[TELEPORT ABORTED] Game reset during portal sequence.');
          return false;
        }

        AudioManager.playPortalTeleport();
        pawn.step = newStep;
        syncPawnState(pawn);

        if (pawn.step >= 51 && pawn.state == PawnState.onPath) {
          pawn.state = PawnState.onHomeStretch;
          if (pawn.step == 56) {
            pawn.state = PawnState.finished;
            _checkWinCondition(pawn.color);
          }
        }

        refresh();
        // Short visual pause so it registers on its cell.
        await Future.delayed(AppConfig.moveConsequenceDelay);
        if (isGameOver || pawn.state == PawnState.inBase) return false;

        lastTeleportedPawn = null;
        refresh();

        bool cutOpponent = await _attemptCut(pawn);
        return cutOpponent;
      }
    }
    return false;
  }
}
