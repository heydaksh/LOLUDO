import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ludo_game/models/game_models.dart';
import 'package:ludo_game/providers/game_provider.dart';
import 'package:ludo_game/screens/start_screen.dart';
import 'package:ludo_game/utils/app_config.dart';
import 'package:ludo_game/utils/audio_manager.dart';
import 'package:provider/provider.dart';

class VictoryOverlay extends StatefulWidget {
  final List<Player> allPlayers;
  final List<PlayerColor> winners;

  const VictoryOverlay({
    super.key,
    required this.allPlayers,
    required this.winners,
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
      duration: AppConfig.victoryOverlayDuration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    AudioManager.stopAllSounds();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isOnline = context.read<GameProvider>().isOnlineMultiplayer;

    if (widget.allPlayers.isEmpty || widget.winners.isEmpty) {
      return const SizedBox.shrink();
    }

    // 1. Determine if this was a win by default (Opponent quit)
    bool isDefaultWin = false;
    final topWinner = widget.allPlayers.firstWhere(
      (p) => p.color == widget.winners.first,
      orElse: () => widget.allPlayers.first,
    );
    // If the winner hasn't actually finished all their pawns, they won by default!
    if (!topWinner.hasWon) {
      isDefaultWin = true;
    }

    final losers = widget.allPlayers
        .where((p) => !widget.winners.contains(p.color))
        .toList();

    return Container(
      width: size.width,
      height: size.height,
      color: Colors.black.withValues(alpha: 0.85),
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// LOTTIE ANIMATIONS
          Positioned(
            top: size.height / 12,
            child: Container(
              height: 100,
              width: 100,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Lottie.asset(
                "assets/animations/triangle_reach.json",
                repeat: true,
                frameRate: FrameRate.max,
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
                frameRate: FrameRate.max,

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
                      color: _getColor(
                        widget.winners.isNotEmpty
                            ? widget.winners.first
                            : PlayerColor.green,
                      ),
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
                      /// DYNAMIC TITLE
                      Text(
                        isDefaultWin ? "MATCH ENDED" : "VICTORY!",
                        style: TextStyle(
                          fontSize: size.width / 15,
                          fontWeight: FontWeight.bold,
                          color: isDefaultWin
                              ? Colors.red.shade800
                              : Colors.orange.shade800,
                        ),
                      ),

                      const SizedBox(height: 5),

                      /// WINNER
                      if (widget.winners.isNotEmpty)
                        _buildWinner(size, widget.winners.first, isDefaultWin),

                      const SizedBox(height: 10),

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
                          ...losers.map(
                            (loser) => _buildRankCard(
                              size,
                              widget.allPlayers.length,
                              loser.color,
                              isLoser: true,
                              isDefaultWin: isDefaultWin,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// PLAY AGAIN BUTTON (Offline Only)
                      if (!isOnline) ...[
                        ElevatedButton(
                          onPressed: () {
                            context.read<GameProvider>().restartGame();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getColor(
                              widget.winners.isNotEmpty
                                  ? widget.winners.first
                                  : PlayerColor.green,
                            ),
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
                        const SizedBox(height: 10),
                      ],

                      /// EXIT BUTTON
                      ElevatedButton(
                        onPressed: () {
                          final provider = context.read<GameProvider>();
                          if (provider.isOnlineMultiplayer &&
                              provider.myLocalColor != null) {
                            provider.removePlayer(provider.myLocalColor!);
                          }
                          provider.exitGame();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StartScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getColor(
                            widget.winners.isNotEmpty
                                ? widget.winners.first
                                : PlayerColor.green,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              size.width / 10,
                            ),
                          ),
                        ),
                        child: Text(
                          "Exit to Menu",
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

  /// DYNAMIC TOP WINNER TEXT
  Widget _buildWinner(Size size, PlayerColor color, bool isDefaultWin) {
    String name = widget.allPlayers
        .firstWhere(
          (p) => p.color == color,
          orElse: () => widget.allPlayers.first,
        )
        .name;

    return Column(
      children: [
        Icon(
          isDefaultWin ? Icons.phonelink_erase : Icons.emoji_events,
          size: size.width / 6,
          color: isDefaultWin ? Colors.red.shade400 : Colors.amber,
        ),
        SizedBox(height: size.height / 80),
        Text(
          isDefaultWin ? "OPPONENT LEFT" : "$name WINS!",
          style: TextStyle(
            fontSize: size.width / 18,
            fontWeight: FontWeight.bold,
            color: _getColor(color),
          ),
        ),
        if (isDefaultWin)
          Text(
            "$name wins by default",
            style: TextStyle(
              fontSize: size.width / 28,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  /// RANK CARD
  Widget _buildRankCard(
    Size size,
    int rank,
    PlayerColor color, {
    bool isLoser = false,
    bool isDefaultWin = false,
  }) {
    String rankText;

    if (isLoser) {
      // If the game ended by default, label the loser as 'QUIT' instead of 'LOSS'
      rankText = isDefaultWin ? "QUIT" : "LOSS";
    } else {
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
    }

    String name = widget.allPlayers
        .firstWhere(
          (p) => p.color == color,
          orElse: () => widget.allPlayers.first,
        )
        .name;

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
                name,
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
