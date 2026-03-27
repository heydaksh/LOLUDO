part of '../game_provider.dart';

extension GameProviderCapture on GameProvider {
  Future<bool> _attemptCut(Pawn pawn, {bool isIntermediate = false}) async {
    bool localCut = false;
    int myAbsolutePosition = BoardCoordinates.getAbsolutePosition(pawn);

    if (!BoardCoordinates.safeZones.contains(myAbsolutePosition)) {
      for (var player in players) {
        if (player.color != pawn.color && isPlayerInGame(player.color)) {
          for (var oppPawn in player.pawns) {
            if (oppPawn.state == PawnState.onPath) {
              int oppAbsolutePosition = BoardCoordinates.getAbsolutePosition(
                oppPawn,
              );

              if (oppAbsolutePosition == myAbsolutePosition) {
                if (oppPawn.isShielded) {
                  debugPrint(
                    '🛡️ [SHIELD] ${oppPawn.color.name}\'s shield reflected attack from ${pawn.color.name}!',
                  );

                  pawn.isDeadAnimation = true;
                  AudioManager.playKnockOut();
                  refresh();
                  await Future.delayed(AppConfig.captureSearchInterval);
                  pawn.reset();
                  syncPawnState(pawn);
                  return false;
                } else {
                  debugPrint(
                    ' [CUT] ${pawn.color.name} cut ${player.color.name}\'s pawn ${oppPawn.id} at absolute position $myAbsolutePosition!',
                  );

                  oppPawn.isDeadAnimation = true;
                  AudioManager.playKnockOut();
                  refresh();

                  await Future.delayed(AppConfig.captureSearchInterval);

                  oppPawn.reset();
                  syncPawnState(oppPawn);
                  localCut = true;

                  if (!eliminateAllOpponents) {
                    break;
                  }
                }
              }
            }
          }
          if (localCut && !eliminateAllOpponents) {
            break;
          }
        }
      }
    } else {
      if (!isIntermediate) {
        AudioManager.playSafeHouse();
      }
      debugPrint(
        ' [SAFE ZONE] ${pawn.color.name} landed on safe zone $myAbsolutePosition.',
      );
    }
    return localCut;
  }
}
