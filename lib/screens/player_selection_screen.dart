import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/screens/developer_detail_screen.dart';
import 'package:ludo_game/screens/rotating_card.dart';

class PlayerSelectionScreen extends StatefulWidget {
  const PlayerSelectionScreen({super.key});

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  final List<bool> selectedPlayers = [true, false, true, false];

  final List<TextEditingController> _nameControllers = [
    TextEditingController(text: "Green"),
    TextEditingController(text: "Yellow"),
    TextEditingController(text: "Blue"),
    TextEditingController(text: "Red"),
  ];

  final List<bool> _isBotList = [false, true, true, true];
  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _togglePlayer(int index) {
    setState(() {
      selectedPlayers[index] = !selectedPlayers[index];
    });
  }

  void _startGame() {
    int count = selectedPlayers.where((e) => e).length;
    HapticFeedback.mediumImpact();
    if (count < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text(
            "Please select at least 2 players",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }
    Map<PlayerColor, PlayerSetup> selectedData = {};

    if (selectedPlayers[0]) {
      selectedData[PlayerColor.green] = PlayerSetup(
        name: _nameControllers[0].text,
        isBot: _isBotList[0],
      );
    }
    if (selectedPlayers[1]) {
      selectedData[PlayerColor.yellow] = PlayerSetup(
        name: _nameControllers[1].text,
        isBot: _isBotList[1],
      );
    }
    if (selectedPlayers[2]) {
      selectedData[PlayerColor.blue] = PlayerSetup(
        name: _nameControllers[2].text,
        isBot: _isBotList[2],
      );
    }
    if (selectedPlayers[3]) {
      selectedData[PlayerColor.red] = PlayerSetup(
        name: _nameControllers[3].text,
        isBot: _isBotList[3],
      );
    }

    Navigator.pop(context, selectedData);
  }

  Widget _playerBase(Color color, bool active, int index) {
    final size = MediaQuery.of(context).size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            _togglePlayer(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: size.width / 3.6,
            height: size.width / 3.6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size.width / 20),
              gradient: active
                  ? LinearGradient(
                      colors: [color, color.withValues(alpha: 0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: active ? null : color.withValues(alpha: 0.55),
              border: Border.all(
                color: active ? Colors.white : Colors.transparent,
                width: size.width / 120,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: size.width / 22,
                        spreadRadius: size.width / 150,
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
                child: active
                    ? Icon(Icons.check, color: color, size: size.width / 12)
                    : null,
              ),
            ),
          ),
        ),

        SizedBox(height: size.height / 120),

        SizedBox(
          width: size.width / 3.6,
          child: TextField(
            controller: _nameControllers[index],
            enabled: active,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: size.width / 32,
              color: active ? Colors.black : Colors.grey.shade600,
            ),
            decoration: InputDecoration(
              suffixIcon: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _isBotList[index] = !_isBotList[index];
                  });
                },
                child: Icon(
                  _isBotList[index] ? Icons.smart_toy_outlined : Icons.person,
                  color: active ? color : Colors.grey,
                  size: size.width / 20,
                ),
              ),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                vertical: size.height / 140,
                horizontal: size.width / 60,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(size.width / 40),
              ),
              filled: true,
              fillColor: active
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.grey.shade300,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/player_select.webp",
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.28)),
          ),

          SafeArea(
            child: Column(
              children: [
                SizedBox(height: size.height / 20),

                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: size.width * 0.8,
                      height: size.width * 0.95,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: _playerBase(
                              Colors.green,
                              selectedPlayers[0],
                              0,
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: _playerBase(
                              Colors.yellow,
                              selectedPlayers[1],
                              1,
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: _playerBase(
                              Colors.blue,
                              selectedPlayers[2],
                              2,
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: _playerBase(
                              Colors.red,
                              selectedPlayers[3],
                              3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (selectedPlayers.any((e) => e))
                  Padding(
                    padding: EdgeInsets.only(bottom: size.height / 40),
                    child: ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.black,
                        elevation: 6,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(size.width / 12),
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
                          child: Column(
                            mainAxisAlignment: .center,
                            children: [
                              Text(
                                "START GAME",
                                style: TextStyle(
                                  fontSize: size.width / 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: Colors.white,
                                ),
                              ),
                              RotatingCredit(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            right: size.width / 25,
            bottom: size.height / 35,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                showDeveloperDialog(context);
              },
              child: Container(
                height: size.width / 12,
                width: size.width / 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.85),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.question_mark,
                  color: Colors.white,
                  size: size.width / 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
