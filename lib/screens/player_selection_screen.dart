import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/screens/developer_detail_screen.dart';
import 'package:ludo_game/screens/rotating_card.dart';
import 'package:ludo_game/utils/app_config.dart';

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

  final List<bool> _isBotList = [false, false, false, false];

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Toogle player ------
  void _togglePlayer(int index) {
    setState(() {
      selectedPlayers[index] = !selectedPlayers[index];
    });
  }

  // Start Game  ------

  void _startGame() {
    int count = selectedPlayers.where((e) => e).length;
    HapticFeedback.heavyImpact();
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

  // Player Base identify  ------

  Widget _playerBase(Color color, bool active, int index) {
    final size = MediaQuery.of(context).size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.heavyImpact();
            _togglePlayer(index);
          },
          child: AnimatedContainer(
            duration: AppConfig.playerSelectionTransitionDuration,
            width: size.width / 3.6,
            height: size.width / 3.6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size.width / 18),

              /// 🔥 NEW: layered gradient + depth
              gradient: active
                  ? LinearGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,

              color: active ? null : color.withValues(alpha: 0.35),

              /// 🔥 stronger border
              border: Border.all(
                color: active ? Colors.white : Colors.transparent,
                width: size.width / 120,
              ),

              /// 🔥 glow + elevation
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.7),
                        blurRadius: size.width / 18,
                        spreadRadius: size.width / 120,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: size.width / 30,
                        offset: Offset(0, size.height / 200),
                      ),
                    ]
                  : [],
            ),

            ///  inner content
            child: Stack(
              children: [
                /// selection indicator
                if (active)
                  Positioned(
                    top: size.height / 120,
                    right: size.width / 60,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: size.width / 14,
                    ),
                  ),

                Center(
                  child: AnimatedScale(
                    scale: active ? 1 : 0.9,
                    duration: AppConfig.toggleButtonAnimationDuration,
                    child: Container(
                      width: size.width / 7,
                      height: size.width / 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: size.width / 40,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person,
                        color: color,
                        size: size.width / 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: size.height / 120),

        /// 🔥 IMPROVED NAME FIELD
        SizedBox(
          width: size.width / 3.1,
          child: TextField(
            maxLength: 10,
            controller: _nameControllers[index],
            enabled: active,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: size.width / 30,
              color: active ? Colors.black : Colors.grey.shade900,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: active ? Colors.white : Colors.grey.shade300,

              contentPadding: EdgeInsets.symmetric(vertical: size.height / 140),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(size.width / 30),
                borderSide: BorderSide.none,
              ),

              /// 🔥 BOT TOGGLE REDESIGN
              suffixIcon: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _isBotList[index] = !_isBotList[index];
                  });
                },
                child: Container(
                  margin: EdgeInsets.all(size.width / 70),
                  padding: EdgeInsets.symmetric(horizontal: size.width / 40),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size.width / 40),
                    color: _isBotList[index]
                        ? Colors.black
                        : Colors.grey.shade500,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isBotList[index] ? Icons.smart_toy : Icons.person,
                        color: Colors.white,
                        size: size.width / 22,
                      ),
                      SizedBox(width: size.width / 80),
                      Text(
                        _isBotList[index] ? "BOT" : "",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width / 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                              Colors.yellow,
                              selectedPlayers[1],
                              1,
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: _playerBase(
                              Colors.blue,
                              selectedPlayers[2],
                              2,
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: _playerBase(
                              Colors.red,
                              selectedPlayers[3],
                              3,
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: _playerBase(
                              Colors.green,
                              selectedPlayers[0],
                              0,
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
                height: size.width / 8,
                width: size.width / 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black87,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                alignment: .center,
                child: Text(
                  'Creator',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: .bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
