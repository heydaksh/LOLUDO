import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

// ==============================
// AUDIO MANAGER
// Central static class for all game sound effects.
// Uses two separate AudioPlayer instances to allow concurrent playback
// (e.g., a safe-zone sound can play alongside a movement sound).
//
// All sounds are loaded from the assets/ directory via AssetSource.
// ==============================

/// Handles all game sound effects.
/// Keeps audio playback optimized using low latency players.
class AudioManager {
  // ==============================
  // INTERNAL STATE
  // ==============================

  /// Random generator for selecting random sound variations.
  static final Random _random = Random();

  /// Main player for most sound effects.
  /// Stopped and restarted on each new sound to avoid overlap.
  static final AudioPlayer _effectPlayer = AudioPlayer();

  /// Separate player dedicated to safe-zone landing sounds.
  /// Kept separate so it never interrupts movement or knockout sounds.
  static final AudioPlayer _safeZonePlayer = AudioPlayer();

  // ==============================
  // SOUND ASSET LISTS
  // ==============================
  // Each list holds asset paths relative to the assets/ directory.
  // Add or remove entries to adjust sound variety.
  // ADJUSTABLE: Add/remove sound file paths in each list to change sound effects.

  /// Sounds played when a pawn kills (captures) another pawn.
  static const List<String> knockOutSounds = [
    'kill_Sound/abe-sale.wav',
    'kill_Sound/bone_crack.wav',
    'kill_Sound/anime_ahh.wav',
    'kill_Sound/cat-laugh.wav',
    'kill_Sound/gopgopgop.wav',
    'kill_Sound/khatam.wav',
    'kill_Sound/ramayan_gayab.wav',
    'kill_Sound/tehelka_omlette.wav',
  ];

  /// Sounds played when a pawn exits the base (rolled a 6).
  static const List<String> baseExitSounds = [
    'entry/faaah.wav',
    'entry/chaloo.wav',
  ];

  /// Sound played each time a pawn moves one step forward on the path.
  static const List<String> pawnMovementSound = ['sounds/jump.wav'];

  /// Sound played when the dice is rolled.
  static const List<String> diceRollSound = ['sounds/dice_roll.wav'];

  /// Sound played when a pawn lands on a safe zone cell.
  static const List<String> safeHouseSound = ['sounds/mac_quack.wav'];

  /// Sound played when a pawn is teleported through a portal.
  /// Reuses the triangle_reach asset for a distinct "whoosh" feel.
  static const List<String> portalTeleportSound = [
    'sounds/triangle_reach.wav',
  ];

  /// Sound played when a pawn reaches the center winning triangle.
  static const List<String> triangleReachSound = ['sounds/triangle_reach.wav'];

  // ==============================
  // INITIALIZATION
  // ==============================

  /// Initializes both audio players in low-latency mode.
  ///
  /// Must be called once in [main()] before [runApp()] to ensure
  /// sounds play without noticeable delay during gameplay.
  static Future<void> init() async {
    await _effectPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _effectPlayer.setReleaseMode(ReleaseMode.stop);

    await _safeZonePlayer.setPlayerMode(PlayerMode.lowLatency);
    await _safeZonePlayer.setReleaseMode(ReleaseMode.stop);
  }

  // ==============================
  // INTERNAL HELPER
  // ==============================

  /// Picks a random file from [soundList] and plays it via [_effectPlayer].
  /// Stops any currently-playing effect before starting the new one.
  static Future<void> _playRandom(List<String> soundList) async {
    if (soundList.isEmpty) return;

    int index = _random.nextInt(soundList.length);
    String selectedSound = soundList[index];

    await _effectPlayer.stop();
    await _effectPlayer.play(AssetSource(selectedSound));
  }

  // ==============================
  // GAME SOUND TRIGGERS
  // ==============================

  /// Plays a random knockout sound when a pawn captures another pawn.
  static Future<void> playKnockOut() => _playRandom(knockOutSounds);

  /// Plays a random entry sound when a pawn exits the base.
  static Future<void> playBaseExit() => _playRandom(baseExitSounds);

  /// Plays the movement jump sound each time a pawn steps forward.
  static Future<void> playPawnMovement() => _playRandom(pawnMovementSound);

  /// Plays the dice roll sound when the dice is thrown.
  static Future<void> playDiceRoll() => _playRandom(diceRollSound);

  /// Plays the triangle-reach sound when a pawn enters the winning center.
  static Future<void> playTriangleReach() => _playRandom(triangleReachSound);

  /// Plays the portal teleport sound when a pawn is instantly teleported.
  static Future<void> playPortalTeleport() => _playRandom(portalTeleportSound);

  // ==============================
  // SAFE ZONE SOUND (SEPARATE PLAYER)
  // ==============================

  /// Plays the safe-house landing sound using the dedicated [_safeZonePlayer].
  ///
  /// Uses a separate player so this sound does not interrupt the movement
  /// or knockout sounds that may be playing simultaneously.
  static Future<void> playSafeHouse() async {
    if (safeHouseSound.isEmpty) return;

    int index = _random.nextInt(safeHouseSound.length);
    String selectedSound = safeHouseSound[index];

    await _safeZonePlayer.stop();
    await _safeZonePlayer.play(AssetSource(selectedSound));
  }
}
