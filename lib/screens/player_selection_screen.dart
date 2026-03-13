import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlayerSelectionScreen extends StatefulWidget {
  const PlayerSelectionScreen({super.key});

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  final List<bool> selectedPlayers = [true, false, true, false];

  void _togglePlayer(int index) {
    setState(() {
      selectedPlayers[index] = !selectedPlayers[index];
    });
  }

  void _startGame() {
    int count = selectedPlayers.where((e) => e).length;

    if (count < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: .floating,
          backgroundColor: Colors.red,
          content: Text(
            "Please select at least 2 players",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    Navigator.pop(context, count);
  }

  Widget _playerBase(Color color, bool active) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        int index = _getIndex(color);
        _togglePlayer(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size.width / 3.5,
        height: size.width / 3.5,
        decoration: BoxDecoration(
          color: active ? color : color.withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? Colors.black : Colors.transparent,
            width: active ? 3 : 0,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Container(
            width: size.width / 8,
            height: size.width / 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: active ? Icon(Icons.check, color: color, size: 30) : null,
          ),
        ),
      ),
    );
  }

  int _getIndex(Color color) {
    if (color == Colors.green) return 0;
    if (color == Colors.yellow) return 1;
    if (color == Colors.blue) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        fit: StackFit.expand,
        children: [
          // =========================
          // BACKGROUND IMAGE
          // =========================
          Positioned.fill(
            child: Image.asset(
              "assets/images/player_select.webp",
              fit: BoxFit.cover,
            ),
          ),

          // optional dark overlay for readability
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.25)),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: size.height / 20),

                  // LUDO BOARD STYLE
                  SizedBox(
                    width: size.width * 0.8,
                    height: size.width * 0.8,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: _playerBase(Colors.green, selectedPlayers[0]),
                        ),

                        Align(
                          alignment: Alignment.topRight,
                          child: _playerBase(Colors.yellow, selectedPlayers[1]),
                        ),

                        Align(
                          alignment: Alignment.bottomRight,
                          child: _playerBase(Colors.blue, selectedPlayers[2]),
                        ),

                        Align(
                          alignment: Alignment.bottomLeft,
                          child: _playerBase(Colors.red, selectedPlayers[3]),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: size.height / 20),

                  selectedPlayers.any((e) => e)
                      ? ElevatedButton(
                          onPressed: _startGame,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                size.width / 12,
                              ),
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.green,
                                  Colors.yellow,
                                  Colors.blue,
                                  Colors.red,
                                ],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                            child: Container(
                              height: size.height / 15,
                              width: size.width / 2,
                              alignment: Alignment.center,
                              child: Text(
                                "START GAME",
                                style: TextStyle(
                                  fontSize: size.width / 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        )
                      : SizedBox(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
