part of '../game_provider.dart';

extension GameProviderCheat on GameProvider {
  void toggleEliminateAll() {
    eliminateAllOpponents = !eliminateAllOpponents;
    debugPrint(' Eliminate All Opponents toggled: $eliminateAllOpponents');
    refresh();
  }

  void toggleBulldozerMode() {
    isBulldozerMode = !isBulldozerMode;
    debugPrint(' Bulldozer Mode toggled: $isBulldozerMode');
    refresh();
  }

  void toggleAlwaysRollSix() {
    alwaysRollSix = !alwaysRollSix;
    debugPrint(' Always Roll 6 toggled: $alwaysRollSix');
    refresh();
  }

  void toggleSpecialPowers() {
    enableSpecialPowers = !enableSpecialPowers;
    debugPrint(' Special Powers toggled: $enableSpecialPowers');
    if (!enableSpecialPowers) {
      activePower.clear();
      debugPrint(' [POWER] Cleared all active powers from board.');
    }
    refresh();
  }

  void toggleReverseMode() {
    useReverseMode = !useReverseMode;
    refresh();
  }
}
