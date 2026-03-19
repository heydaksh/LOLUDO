part of '../ludo_screen.dart';

// ==============================
// BACKGROUND LAYER
// Renders the background image at 70% opacity behind everything else.
// Isolated as its own widget so it never triggers rebuilds.
// ==============================

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/bg_image.webp',
      fit: BoxFit.cover,
      // ADJUSTABLE: Change background image opacity here (currently 0.7).
      opacity: const AlwaysStoppedAnimation(.3),
    );
  }
}
