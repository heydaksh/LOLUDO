part of '../ludo_screen.dart';

// ==============================
// TELEPORT FLASH OVERLAY
// Briefly shows a colored flash when a teleport occurs.
// ==============================

class _TeleportFlashOverlay extends StatelessWidget {
  const _TeleportFlashOverlay();

  @override
  Widget build(BuildContext context) {
    final teleportedPawn = context.select<GameProvider, Pawn?>(
      (p) => p.lastTeleportedPawn,
    );
    final isAnimatingMove = context.select<GameProvider, bool>(
      (p) => p.isAnimatingMove,
    );

    if (teleportedPawn == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedOpacity(
        duration: AppConfig.fastUiAnimationDuration,
        opacity: isAnimatingMove ? 0.3 : 1.0,
        child: Container(color: Colors.white),
      ),
    );
  }
}

// ==============================
// GAME START BLINKER
// A brief, non-blocking text overlay that blinks "GAME STARTS"
// in the center of the board when a new session begins.
// ==============================

class _GameStartBlinker extends StatefulWidget {
  const _GameStartBlinker({super.key});

  @override
  State<_GameStartBlinker> createState() => _GameStartBlinkerState();
}

class _GameStartBlinkerState extends State<_GameStartBlinker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConfig.moderateUiAnimationDuration,
    );
    _playAnimation();
  }

  Future<void> _playAnimation() async {
    debugPrint('[ANIMATION] Playing "Game Starts" blink sequence');
    AudioManager.playGameStart();
    // Blink 3 times
    for (int i = 0; i < 5; i++) {
      if (!mounted) return;
      await _controller.forward();
      if (!mounted) return;
      await _controller.reverse();
    }

    // Hide widget completely after sequence
    if (mounted) {
      setState(() {
        _isVisible = false;
      });
      // Trigger the bot if Player 1 is a computer!
      context.read<GameProvider>().triggerBotTurn();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    // [FIX]: Positioned.fill + AbsorbPointer creates an invisible shield
    // over the entire screen that blocks ALL taps (dice, pawns, settings)
    // until the animation finishes and _isVisible becomes false.
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Center(
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_controller),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Text(
                "GAME STARTS",
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
