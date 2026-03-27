part of '../game_provider.dart';

extension GameProviderPower on GameProvider {
  Power spawnPower() {
    final random = Random();
    int position;

    do {
      position = random.nextInt(52);
    } while (isRestrictedTile(position) ||
        activePortals.any((p) => p.a == position || p.b == position) ||
        activePower.any((p) => p.position == position));

    final type = PowerType.values[random.nextInt(PowerType.values.length)];

    debugPrint(
      '🌟 [SPAWN] Generated power ${type.name} at valid position $position',
    );

    return Power(position: position, type: type);
  }

  Future<void> _checkPowerPickup(Pawn pawn) async {
    int absolutePos = BoardCoordinates.getAbsolutePosition(pawn);
    int powerIndex = activePower.indexWhere((p) => p.position == absolutePos);

    if (powerIndex != -1) {
      Power power = activePower.removeAt(powerIndex);
      debugPrint('🌟 [POWER] ${pawn.color.name} picked up ${power.type.name}!');
      if (isOnlineMultiplayer) syncBoardState();
      await _applyPower(pawn, power.type);
    }
  }

  Future<void> _applyPower(Pawn pawn, PowerType type) async {
    switch (type) {
      case PowerType.shield:
        pawn.shieldTurn = 1;
        syncPawnState(pawn);
        debugPrint(
          '🛡️ [SHIELD] Shield activated for ${pawn.color.name} pawn!',
        );
        break;

      case PowerType.reverse:
        pawn.hasReverse = true;
        syncPawnState(pawn);
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
          syncPawnState(pawn);
          syncPawnState(target);
          debugPrint('🔄 [SWAP] Swapped with ${target.color.name} pawn!');
        } else {
          debugPrint(
            '🔄 [SWAP FAILED] No eligible targets found (all enemies are in base, finished, or safe zones).',
          );
        }
        break;
    }
  }
}
