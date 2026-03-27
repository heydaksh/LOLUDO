/// Centralized configuration for all timings, animation durations, and speeds.
/// Changing these values affects the pace and feel of the game.
class AppConfig {
  // ==============================
  // DICE TIMINGS
  // ==============================

  /// Duration of the upward/downward bounce when waiting for a roll.
  static const Duration diceBounceDuration = Duration(milliseconds: 200);

  /// Duration of the 3D spin rotation when the dice is rolled.
  static const Duration diceSpinDuration = Duration(milliseconds: 600);

  /// How fast the dice faces shuffle (change values) while rolling.
  static const Duration diceFaceShuffleInterval = Duration(milliseconds: 50);

  /// How long the final dice result is displayed before the game processes it.
  static const Duration diceResultDisplayDuration = Duration(milliseconds: 600);

  /// Duration of the return animation for the dice bounce controller.
  static const Duration diceBounceReturnDuration = Duration(milliseconds: 300);

  // ==============================
  // PAWN ANIMATIONS
  // ==============================

  /// Speed of the glowing pulse highlight for moveable pawns.
  static const Duration pawnHighlightPulseDuration = Duration(
    milliseconds: 600,
  );

  /// Speed of the rotating dashed indicator around a selectable pawn (1 full turn).
  static const Duration pawnSelectionIndicatorRotationDuration = Duration(
    milliseconds: 1500,
  );

  /// Duration of the pawn finishing sequence (stretch and shake) when entering the home zone.
  static const Duration pawnFinishAnimationDuration = Duration(
    milliseconds: 600,
  );

  /// Speed of a pawn sliding securely from one cell to another.
  static const Duration pawnSlideDuration = Duration(milliseconds: 200);

  /// Speed of the vertical jump arc in a single step of a pawn's movement.
  static const Duration pawnJumpDuration = Duration(milliseconds: 100);

  // ==============================
  // BOT & AUTOMATION TIMINGS
  // ==============================

  /// Delay before an automated move happens (when exactly 1 move is possible).
  static const Duration autoMoveDelay = Duration(milliseconds: 100);

  /// Delay when checking if sound is currently playing before auto-moving.
  static const Duration soundCheckInterval = Duration(milliseconds: 50);

  /// Delay before auto-passing the turn when no valid moves exist.
  static const Duration autoPassTurnDelay = Duration(milliseconds: 150);

  /// How long the bot \'thinks\' before executing a chosen move.
  static const Duration botDecisionDelay = Duration(milliseconds: 150);

  // ==============================
  // MOVEMENT & CAPTURE TIMINGS
  // ==============================

  /// Delay after a pawn completes moving along its path.
  static const Duration postMoveDelay = Duration(milliseconds: 650);

  /// Delay when a pawn executes a capture before removing the opponent's pawn.
  static const Duration captureExecutionDelay = Duration(milliseconds: 250);

  /// Delay before a captured pawn starts its respawn sequence back to base.
  static const Duration respawnStartDelay = Duration(milliseconds: 600);

  /// Delay before removing a player's pawns from the board if that player loses/quits.
  static const Duration removePawnsDelay = Duration(milliseconds: 300);

  /// Extra pause before checking consequences of a move (powers, portals).
  static const Duration moveConsequenceDelay = Duration(milliseconds: 500);

  /// Delay increment in loop searching for captures/victims.
  static const Duration captureSearchInterval = Duration(milliseconds: 100);

  /// Delay for visual pause just before a portal teleport executes.
  static const Duration portalPreTeleportDelay = Duration(milliseconds: 300);

  // ==============================
  // UI & OVERLAYS TIMINGS
  // ==============================

  /// Duration the victory message overlay remains visible.
  static const Duration victoryOverlayDuration = Duration(seconds: 2);

  /// Duration to show power popups before they hide.
  static const Duration powerWidgetDuration = Duration(seconds: 2);

  /// Duration for the long portal indicator animation.
  static const Duration portalWidgetLongDuration = Duration(seconds: 3);

  /// Duration for the short portal animation/blink.
  static const Duration portalWidgetShortDuration = Duration(milliseconds: 700);

  /// Periodic timer interval for rotating the user selection cards.
  static const Duration rotatingCardInterval = Duration(seconds: 2);

  /// Animation duration when a rotating card switches content.
  static const Duration rotatingCardAnimationDuration = Duration(
    milliseconds: 400,
  );

  /// Duration of player selection UI layout transitions.
  static const Duration playerSelectionTransitionDuration = Duration(
    milliseconds: 250,
  );

  /// Animation duration of toggle buttons in the selection screen.
  static const Duration toggleButtonAnimationDuration = Duration(
    milliseconds: 200,
  );

  /// Typical duration for general UI animations (like sidebars and menus).
  static const Duration standardUiAnimationDuration = Duration(
    milliseconds: 300,
  );

  /// Slightly faster UI transition in settings menu.
  static const Duration settingsMenuTransitionDuration = Duration(
    milliseconds: 250,
  );

  /// Delay for board camera/layer effects.
  static const Duration boardLayerTransitionDuration = Duration(
    milliseconds: 800,
  );

  /// Fast UI animation tick.
  static const Duration fastUiAnimationDuration = Duration(milliseconds: 200);

  /// Moderate UI animation tick.
  static const Duration moderateUiAnimationDuration = Duration(
    milliseconds: 330,
  );

  /// Delay before starting internal loops in providers.
  static const Duration providerInitDelay = Duration(milliseconds: 100);

  /// Delay used for short event loops in provider polling.
  static const Duration providerPollInterval = Duration(milliseconds: 30);
}
