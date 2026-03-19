part of '../game_provider.dart';

extension GameProviderPortal on GameProvider {
  Portals spawnPortal() {
    final random = Random();
    int a;
    int b;

    do {
      a = random.nextInt(52);
    } while (isRestrictedTile(a) ||
        activePortals.any((p) => p.a == a || p.b == a) ||
        activePower.any((p) => p.position == a));

    do {
      b = random.nextInt(52);
    } while (b == a ||
        isRestrictedTile(b) ||
        activePortals.any((p) => p.a == b || p.b == b) ||
        activePower.any((p) => p.position == b));

    final type = PortalType.values[random.nextInt(3)];
    debugPrint('🌀 [SPAWN] Generated portal ${type.name} connecting $a <-> $b');

    return Portals(a: a, b: b, type: type);
  }

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
