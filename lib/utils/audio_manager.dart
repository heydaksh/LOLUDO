import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

/// Handles all game sound effects.
/// Keeps audio playback optimized using low latency players.
class AudioManager {
  /// Random generator for selecting random sound variations
  static final Random _random = Random();

  /// Main player for most sound effects
  static final AudioPlayer _effectPlayer = AudioPlayer();

  /// Separate player for safe-zone sound
  /// (so it doesn't interrupt other effects)
  static final AudioPlayer _safeZonePlayer = AudioPlayer();

  // ==============================
  // 🔊 SOUND LISTS
  // ==============================

  /// Sounds played when a pawn kills another pawn
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

  /// Sounds when pawn exits the base
  static const List<String> baseExitSounds = [
    'entry/faaah.wav',
    'entry/chaloo.wav',
  ];

  /// Pawn movement sound
  static const List<String> pawnMovementSound = ['sounds/jump.wav'];

  /// Dice rolling sound
  static const List<String> diceRollSound = ['sounds/dice_roll.wav'];

  /// Safe house landing sound
  static const List<String> safeHouseSound = ['sounds/mac_quack.wav'];

  /// Sound when pawn reaches winning triangle
  static const List<String> triangleReachSound = ['sounds/triangle_reach.wav'];

  // ==============================
  // ⚙️ INITIALIZATION
  // ==============================

  /// Initialize audio players for low latency playback
  static Future<void> init() async {
    await _effectPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _effectPlayer.setReleaseMode(ReleaseMode.stop);

    await _safeZonePlayer.setPlayerMode(PlayerMode.lowLatency);
    await _safeZonePlayer.setReleaseMode(ReleaseMode.stop);
  }

  // ==============================
  // 🎵 INTERNAL HELPER
  // ==============================

  /// Plays a random sound from a given sound list
  static Future<void> _playRandom(List<String> soundList) async {
    if (soundList.isEmpty) return;

    int index = _random.nextInt(soundList.length);
    String selectedSound = soundList[index];

    await _effectPlayer.stop();
    await _effectPlayer.play(AssetSource(selectedSound));
  }

  // ==============================
  // 🎮 GAME SOUND TRIGGERS
  // ==============================

  /// Pawn kills another pawn
  static Future<void> playKnockOut() => _playRandom(knockOutSounds);

  /// Pawn exits base
  static Future<void> playBaseExit() => _playRandom(baseExitSounds);

  /// Pawn movement
  static Future<void> playPawnMovement() => _playRandom(pawnMovementSound);

  /// Dice roll
  static Future<void> playDiceRoll() => _playRandom(diceRollSound);

  /// Pawn reaches winning triangle
  static Future<void> playTriangleReach() => _playRandom(triangleReachSound);

  // ==============================
  // 🛡 SAFE ZONE SOUND
  // ==============================

  /// Plays safe house landing sound
  /// Uses a separate player to avoid interrupting movement sounds
  static Future<void> playSafeHouse() async {
    if (safeHouseSound.isEmpty) return;

    int index = _random.nextInt(safeHouseSound.length);
    String selectedSound = safeHouseSound[index];

    await _safeZonePlayer.stop();
    await _safeZonePlayer.play(AssetSource(selectedSound));
  }
}
