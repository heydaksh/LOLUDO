part of '../game_provider.dart';

extension GameProviderCheat on GameProvider {
  void _syncCheat(String cheatKey, bool value) {
    if (isOnlineMultiplayer && currentOnlineRoomId != null && isHost) {
      _db.child('rooms/$currentOnlineRoomId/cheats').update({cheatKey: value});
    }
  }

  void toggleEliminateAll() {
    eliminateAllOpponents = !eliminateAllOpponents;
    debugPrint(' Eliminate All Opponents toggled: $eliminateAllOpponents');
    _syncCheat('eliminateAll', eliminateAllOpponents);
    refresh();
  }

  void toggleBulldozerMode() {
    isBulldozerMode = !isBulldozerMode;
    debugPrint(' Bulldozer Mode toggled: $isBulldozerMode');
    _syncCheat('bulldozer', isBulldozerMode);
    refresh();
  }

  void toggleAlwaysRollSix() {
    alwaysRollSix = !alwaysRollSix;
    debugPrint(' Always Roll 6 toggled: $alwaysRollSix');
    _syncCheat('alwaysSix', alwaysRollSix);
    refresh();
  }

  void toggleSpecialPowers() {
    enableSpecialPowers = !enableSpecialPowers;
    debugPrint(' Special Powers toggled: $enableSpecialPowers');
    if (!enableSpecialPowers) {
      activePower.clear();
      debugPrint(' [POWER] Cleared all active powers from board.');
      syncBoardState(); // Make sure the board clears powers for clients immediately
    }
    _syncCheat('specialPowers', enableSpecialPowers);
    refresh();
  }

  void toggleReverseMode() {
    useReverseMode = !useReverseMode;
    refresh();
  }
}
