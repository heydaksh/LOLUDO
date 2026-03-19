part of '../game_provider.dart';

extension GameProviderDice on GameProvider {
  /// Rolls the dice for the current player.
  Future<void> rollDice() async {
    if (isGameOver || isDiceRolling || hasRolled || isAnimatingMove) return;

    try {
      isDiceRolling = true;

      // Generate the dice value BEFORE notifying listeners
      final rand = Random();

      if (alwaysRollSix) {
        diceResult = 4;
      } else {
        diceResult = rand.nextDouble() < 0.19 ? 6 : rand.nextInt(5) + 1;
      }
      debugPrint("Dice rolled: $diceResult");

      // --- APPLY DICE MULTIPLIER ---
      Player activePlayer = players.firstWhere((p) => p.color == currentTurn);
      if (activePlayer.hasMultiplier) {
        diceResult *= 2;
        activePlayer.hasMultiplier = false;
        debugPrint("🎲 Dice Multiplier applied! New roll: $diceResult");
      }
      refresh();

      // ADJUSTABLE: Change the dice animation display duration here
      await Future.delayed(const Duration(milliseconds: 600));
    } finally {
      // Guarantee these resets happen
      isDiceRolling = false;
    }

    hasRolled = true;

    // --- AUTOMATION LOGIC ---
    // Fetch all pawns that can legally move with the current dice result.
    List<Pawn> validPawns = _getValidPawns();

    if (validPawns.isEmpty) {
      debugPrint(
        '⚠️ [VALIDATION] No valid moves for ${currentTurn.name.toUpperCase()} with roll $diceResult. Auto-passing.',
      );
      refresh();

      await Future.delayed(const Duration(milliseconds: 1000));
      if (isGameOver || !players.any((p) => p.color == currentTurn)) {
        debugPrint('[ROLL ABORTED] Game state changed during dice roll.');
        return;
      }
      nextTurn();
    }
    // CONDITION 1, 2, & 3: If exactly 1 valid move exists, automate it!
    else if (validPawns.length == 1) {
      debugPrint(
        '🤖 [AUTOMATION] Only 1 valid move found. Auto-moving pawn ${validPawns.first.id}.',
      );
      refresh();

      // Short delay so the user can read the dice result before the pawn zips away
      await Future.delayed(const Duration(milliseconds: 400));

      if (isGameOver || !players.any((p) => p.color == currentTurn)) return;

      // Programmatically trigger the move
      movePawn(validPawns.first);
    }
    // Multiple options available, wait for user input.
    else {
      Player activePlayer = players.firstWhere((p) => p.color == currentTurn);

      if (activePlayer.isBot) {
        debugPrint('🤖 [BOT] Deciding between ${validPawns.length} options...');

        await Future.delayed(const Duration(milliseconds: 5000));
        if (isGameOver || !players.any((p) => p.color == currentTurn)) return;

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
    // 1. Can we finish a pawn and score?
    try {
      return validMoves.firstWhere((p) => p.step + diceResult == 56);
    } catch (_) {}

    // 2. Can we get a new pawn out of the base?
    try {
      return validMoves.firstWhere((p) => p.state == PawnState.inBase);
    } catch (_) {}

    // 3. Fallback: Move the pawn that is furthest along the board
    validMoves.sort((a, b) => b.step.compareTo(a.step));
    return validMoves.first;
  }

  /// Returns a list of pawns belonging to the current player that can legally move.
  List<Pawn> _getValidPawns() {
    Player activePlayer = players.firstWhere((p) => p.color == currentTurn);

    // We reuse the existing `canPawnMove` logic from movement_logic.part.dart
    return activePlayer.pawns.where((pawn) => canPawnMove(pawn)).toList();
  }
}
