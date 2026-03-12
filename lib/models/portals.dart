enum PortalType {
  blue, // normal teleport
  red, // teleport + forward 2
  purple, // teleport + reverse direction
}

class Portals {
  final int a;
  final int b;
  final PortalType type;
  int remainingTurns;

  Portals({
    required this.a,
    required this.b,
    required this.type,
    this.remainingTurns = 4,
  });

  int getOther(int position) {
    if (position == a) return b;
    if (position == b) return a;
    return position;
  }
}
