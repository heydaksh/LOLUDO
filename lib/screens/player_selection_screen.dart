import 'package:flutter/material.dart';

class PlayerSelectionScreen extends StatelessWidget {
  const PlayerSelectionScreen({super.key});

  void _startGame(BuildContext context, int players) {
    debugPrint("PlayerSelection: selected $players players");

    Navigator.pop(context, players);
  }

  Widget _buildPlayerOption(
    BuildContext context,
    int players,
    List<Color?> previewColors,
  ) {
    return GestureDetector(
      onTap: () => _startGame(context, players),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black54),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              "$players Players",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // Board preview
            SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                children: [
                  _baseCircle(Alignment.topLeft, previewColors[0]),
                  _baseCircle(Alignment.topRight, previewColors[1]),
                  _baseCircle(Alignment.bottomRight, previewColors[2]),
                  _baseCircle(Alignment.bottomLeft, previewColors[3]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _baseCircle(Alignment alignment, Color? color) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? Colors.grey.withValues(alpha: 0.2),
          border: Border.all(color: Colors.black54),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("PlayerSelectionScreen build");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Select Players"), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // 2 players (left vs right)
              _buildPlayerOption(context, 2, [
                Colors.green,
                null,
                Colors.blue,
                null,
              ]),

              // 3 players
              _buildPlayerOption(context, 3, [
                Colors.green,
                Colors.yellow,
                Colors.blue,
                null,
              ]),

              // 4 players
              _buildPlayerOption(context, 4, [
                Colors.green,
                Colors.yellow,
                Colors.blue,
                Colors.red,
              ]),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
