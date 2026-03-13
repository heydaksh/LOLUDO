enum PowerType { freeze, shield, reverse, multiplier, swap }

class Power {
  final int position;
  final PowerType type;
  int remainingTurns;

  Power({required this.position, required this.type, this.remainingTurns = 6});
}
