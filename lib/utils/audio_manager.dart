import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

// ==============================
// AUDIO MANAGER
// Central static class for all game sound effects.
// Uses two separate AudioPlayer instances to allow concurrent playback
// (e.g., a safe-zone sound can play alongside a movement sound).
//
// All misc_sounds are loaded from the assets/ directory via AssetSource.
// ==============================

/// Handles all game sound effects.
/// Keeps audio playback optimized using low latency players.
class AudioManager {
  // ==============================
  // INTERNAL STATE
  // ==============================

  /// Returns whether any sound is currently playing.
  static bool get isSoundPlaying =>
      _effectPlayer.state == PlayerState.playing ||
      _safeZonePlayer.state == PlayerState.playing;

  /// Random generator for selecting random sound variations.
  static final Random _random = Random();

  /// Main player for most sound effects.
  /// Stopped and restarted on each new sound to avoid overlap.
  static final AudioPlayer _effectPlayer = AudioPlayer();

  /// Separate player dedicated to safe-zone landing misc_sounds.
  /// Kept separate so it never interrupts movement or knockout misc_sounds.
  static final AudioPlayer _safeZonePlayer = AudioPlayer();

  // ==============================
  // SOUND ASSET LISTS
  // ==============================
  // Each list holds asset paths relative to the assets/ directory.
  // Add or remove entries to adjust sound variety.
  // ADJUSTABLE: Add/remove sound file paths in each list to change sound effects.

  /// Sounds played when a pawn kills (captures) another pawn.
  static const List<String> knockOutSounds = [
    'kill_Sound/abe_sale.wav',
    'kill_Sound/bone_crack.wav',
    'kill_Sound/anime_ahh.wav',
    'kill_Sound/cat_laugh.wav',
    'kill_Sound/gop_gop_gop.wav',
    'kill_Sound/khatam.wav',
    'kill_Sound/ramayan_gayab.wav',
    'kill_Sound/tehelka_omlette.wav',
    'kill_Sound/laugh.wav',
    'kill_Sound/laugh2.wav',
    'kill_Sound/gta_kill.wav',
    'kill_Sound/pew_kill.wav',
  ];

  /// Sounds played when a pawn exits the base (rolled a 6).
  static const List<String> baseExitSounds = [
    'entry/faaah.wav',
    "entry/chaloo.wav",
    "entry/dun_dun_dun.wav",
    "entry/suuuu.wav",
    "entry/hato.wav",
  ];

  /// Sound played each time a pawn moves one step forward on the path.
  static const List<String> pawnMovementSound = ['misc_sounds/pawn_move.wav'];

  /// Sound played when the dice is rolled.
  static const List<String> diceRollSound = ['misc_sounds/dice_roll.wav'];

  /// Sound played when a pawn lands on a safe zone cell.
  static const List<String> safeHouseSound = ['misc_sounds/safe_zones.wav'];

  /// Sounds played when game is won
  static const List<String> gameWinSound = [
    'winning/winning.wav',
    'winning/winning2.wav',
    'winning/winning3.wav',
    'winning/winning4.wav',
  ];

  /// Sounds played when game is won
  static const List<String> passTurnSound = ['misc_sounds/pass_turn.wav'];

  /// Sound played when a pawn is teleported through a portal.
  static const List<String> portalTeleportSound = ['teleport/yayyyy.wav'];

  /// Sound played when a pawn reaches the center winning triangle.
  static const List<String> triangleReachSound = [
    'triangle_reach/triangle_reach.wav',
    'triangle_reach/triangle_reach2.wav',
  ];
  // Sound plays when game starts..
  static const List<String> gameStartSound = [
    'game_start/game_start.wav',
    'game_start/game_start2.wav',
    'game_start/game_start3.wav',
    'game_start/game_start4.wav',
  ];
  // Sound plays when any player is removed..
  static const List<String> removePlayerSound = [
    'misc_sounds/remove_player.wav',
  ];

  // ==============================
  // INITIALIZATION
  // ==============================

  /// Initializes both audio players in low-latency mode.
  ///
  /// Must be called once in [main()] before [runApp()] to ensure
  /// misc_sounds play without noticeable delay during gameplay.
  static Future<void> init() async {
    await _effectPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    await _effectPlayer.setReleaseMode(ReleaseMode.stop);

    await _safeZonePlayer.setPlayerMode(PlayerMode.mediaPlayer);
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

  /// Plays a random knockout sound when a pawn captures another pawn.
  static Future<void> playPassTurn() => _playRandom(passTurnSound);

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

  /// Plays the game start sound when the game starts.
  static Future<void> playGameStart() => _playRandom(gameStartSound);

  /// Plays the game win sound when the game is won.
  static Future<void> playGameWin() => _playRandom(gameWinSound);

  // Plays when any player is reomved.
  static Future<void> playRemovePlayer() => _playRandom(removePlayerSound);

  // ==============================
  // SAFE ZONE SOUND (SEPARATE PLAYER)
  // ==============================

  /// Plays the safe-house landing sound using the dedicated [_safeZonePlayer].
  ///
  /// Uses a separate player so this sound does not interrupt the movement
  /// or knockout misc_sounds that may be playing simultaneously.
  static Future<void> playSafeHouse() async {
    if (safeHouseSound.isEmpty) return;

    int index = _random.nextInt(safeHouseSound.length);
    String selectedSound = safeHouseSound[index];

    await _safeZonePlayer.stop();
    await _safeZonePlayer.play(AssetSource(selectedSound));
  }

  // ==============================
  // STOP AUDIO
  // ==============================

  /// Stops all currently playing sounds immediately.
  static Future<void> stopAllSounds() async {
    await _effectPlayer.stop();
    await _safeZonePlayer.stop();
  }
}
