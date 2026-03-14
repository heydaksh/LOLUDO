import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/providers/game_provider.dart';
import 'package:ludo_game/screens/player_selection_screen.dart';
import 'package:provider/provider.dart';

class VictoryOverlay extends StatefulWidget {
  final List<PlayerColor> winners;
  final List<Player> allPlayers;

  const VictoryOverlay({
    super.key,
    required this.winners,
    required this.allPlayers,
  });

  @override
  State<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<VictoryOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final loser = widget.allPlayers.firstWhere(
      (p) => !widget.winners.contains(p.color),
      orElse: () => widget.allPlayers.last,
    );

    return Container(
      width: size.width,
      height: size.height,
      color: Colors.black.withValues(alpha: 0.85),
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// LOTTIE
          Positioned(
            top: size.height / 12,
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // color: Colors.red,
              ),
              child: Lottie.asset(
                "assets/animations/triangle_reach.json",
                repeat: true,
                frameRate: FrameRate(120),
              ),
            ),
          ),
          Positioned(
            top: size.height / 21,
            child: SizedBox(
              height: size.height / 5,
              child: Lottie.asset(
                "assets/animations/victory_trophy.json",
                repeat: false,
                frameRate: FrameRate(120),
                animate: true,
              ),
            ),
          ),

          /// MAIN RESULT CARD
          Positioned(
            top: size.height / 4,
            child: Center(
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.elasticOut,
                ),
                child: Container(
                  width: size.width / 1.3,
                  padding: EdgeInsets.all(size.width / 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(size.width / 20),
                    border: Border.all(
                      color: _getColor(widget.winners.first),
                      width: size.width / 100,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// TITLE
                      Text(
                        "VICTORY!",
                        style: TextStyle(
                          fontSize: size.width / 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),

                      SizedBox(height: 5),

                      /// WINNER
                      _buildWinner(size, widget.winners.first),

                      SizedBox(height: 10),

                      /// RANK LIST
                      Column(
                        children: [
                          ...List.generate(
                            widget.winners.length,
                            (index) => _buildRankCard(
                              size,
                              index + 1,
                              widget.winners[index],
                            ),
                          ),

                          _buildRankCard(
                            size,
                            widget.allPlayers.length,
                            loser.color,
                            isLoser: true,
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      /// PLAY AGAIN BUTTON
                      ElevatedButton(
                        onPressed: () {
                          context.read<GameProvider>().restartGame();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width / 7,
                            vertical: size.height / 60,
                          ),
                          backgroundColor: _getColor(widget.winners.first),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              size.width / 10,
                            ),
                          ),
                        ),
                        child: Text(
                          "PLAY AGAIN",
                          style: TextStyle(
                            fontSize: size.width / 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          final Map<PlayerColor, String>? result =
                              await Navigator.push<Map<PlayerColor, String>>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PlayerSelectionScreen(),
                                ),
                              );
                          // Re-initialize the game with the newly chosen players/names.
                          if (result != null && context.mounted) {
                            context.read<GameProvider>().restartGame();
                            context.read<GameProvider>().initializePlayers(
                              result,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width / 10,
                            vertical: size.height / 60,
                          ),
                          backgroundColor: _getColor(widget.winners.first),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              size.width / 10,
                            ),
                          ),
                        ),
                        child: Text(
                          "Exit",
                          style: TextStyle(
                            fontSize: size.width / 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// TOP WINNER
  Widget _buildWinner(Size size, PlayerColor color) {
    String name = widget.allPlayers.firstWhere((p) => p.color == color).name;

    return Column(
      children: [
        Icon(Icons.emoji_events, size: size.width / 6, color: Colors.amber),

        SizedBox(height: size.height / 80),

        Text(
          "$name WINS!",
          style: TextStyle(
            fontSize: size.width / 18,
            fontWeight: FontWeight.bold,
            color: _getColor(color),
          ),
        ),
      ],
    );
  }

  /// RANK CARD
  /// RANK CARD
  Widget _buildRankCard(
    Size size,
    int rank,
    PlayerColor color, {
    bool isLoser = false,
  }) {
    String rankText;

    switch (rank) {
      case 1:
        rankText = "1ST";
        break;
      case 2:
        rankText = "2ND";
        break;
      case 3:
        rankText = "3RD";
        break;
      default:
        rankText = "${rank}TH";
    }

    if (isLoser) rankText = "LOSS";

    String name = widget.allPlayers.firstWhere((p) => p.color == color).name;

    return Container(
      margin: EdgeInsets.symmetric(vertical: size.height / 120),
      padding: EdgeInsets.symmetric(
        vertical: size.height / 80,
        horizontal: size.width / 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size.width / 20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            rankText,
            style: TextStyle(
              fontSize: size.width / 24,
              fontWeight: FontWeight.bold,
              color: isLoser ? Colors.red : Colors.black,
            ),
          ),

          Row(
            children: [
              Container(
                width: size.width / 20,
                height: size.width / 20,
                decoration: BoxDecoration(
                  color: _getColor(color),
                  shape: BoxShape.circle,
                ),
              ),

              SizedBox(width: size.width / 30),

              Text(
                name, // Display dynamic name instead of color uppercase
                style: TextStyle(
                  fontSize: size.width / 24,
                  fontWeight: FontWeight.bold,
                  color: _getColor(color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColor(PlayerColor color) {
    switch (color) {
      case PlayerColor.green:
        return Colors.green;
      case PlayerColor.yellow:
        return Colors.yellow;
      case PlayerColor.blue:
        return Colors.blue;
      case PlayerColor.red:
        return Colors.red;
    }
  }
}
