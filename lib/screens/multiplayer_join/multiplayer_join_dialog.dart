// lib/screens/multiplayer_join/multiplayer_join_dialog.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ludo_game/providers/game_provider.dart';
import 'package:ludo_game/screens/ludo_screen.dart';
import 'package:provider/provider.dart';

class MultiplayerJoinDialog extends StatefulWidget {
  const MultiplayerJoinDialog({super.key});

  @override
  State<MultiplayerJoinDialog> createState() => _MultiplayerJoinDialogState();
}

class _MultiplayerJoinDialogState extends State<MultiplayerJoinDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();

  bool isCreating = false;
  bool isJoining = false;
  bool _navigatedToGame = false;
  bool _kickedHandled = false;

  late AnimationController _controller;
  late Animation<double> scaleAnim;
  late Animation<double> fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final provider = context.watch<GameProvider>();

    // Safely execute navigation and kick kicks outside of the build phase
    // Safely execute navigation and kick logic outside of the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // 1. Auto-start game when Host hits start & status changes to 'playing'
      if (provider.roomStatus == 'playing' &&
          provider.currentOnlineRoomId != null) {
        if (!_navigatedToGame) {
          _navigatedToGame = true;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LudoScreen()),
          );
        }
      }

      // 2. Handle if this specific client gets removed from the lobby
      if (provider.currentOnlineRoomId != null &&
          !provider.isHost &&
          provider.myLocalColor != null) {
        // Check if our assigned color is still in the room's active player list
        bool amIStillInRoom = provider.onlinePlayersMap.containsKey(
          provider.myLocalColor!.name,
        );

        // If the map loaded but we are missing, the host removed us!
        if (provider.onlinePlayersMap.isNotEmpty &&
            !amIStillInRoom &&
            !_kickedHandled) {
          _kickedHandled = true;
          provider.exitGame(); // Disconnect and clean up state
          Navigator.pop(context); // Close dialog back to main menu

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
              content: Text(
                "You were removed by the Host.",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      }
    });

    return FadeTransition(
      opacity: fadeAnim,
      child: ScaleTransition(
        scale: scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(size.width / 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _title(size, context, provider),
                      SizedBox(height: size.height / 40),

                      if (provider.currentOnlineRoomId == null)
                        _textField(
                          controller: _nameController,
                          hint: "Your Name",
                          icon: Icons.person,
                          size: size,
                        ),

                      SizedBox(height: size.height / 40),

                      if (provider.currentOnlineRoomId != null)
                        _lobbyUI(size, provider)
                      else
                        _joinCreateUI(size, provider),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= UI PARTS =================
  Widget _title(Size size, BuildContext context, GameProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Play Online",
          style: TextStyle(
            fontSize: size.width / 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),

        // [FIXED]: Close Button to Disband Room
        GestureDetector(
          onTap: () {
            // Clean up the room data before closing the dialog
            if (provider.currentOnlineRoomId != null) {
              provider.exitGame();
            }
            Navigator.pop(context);
          },
          child: Icon(
            Icons.cancel,
            color: Colors.white70,
            size: size.width / 14,
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Size size,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size.width / 25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: TextField(
        keyboardType: hint == 'Your Name'
            ? TextInputType.text
            : TextInputType.number,
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white70),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _gradientButton({
    required String text,
    required VoidCallback? onTap,
    required List<Color> colors,
    required bool loading,
    required Size size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: size.height / 60),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(colors: colors),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  height: size.width / 25,
                  width: size.width / 25,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: size.width / 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  // ================= LOBBY (WAITING ROOM) =================

  Widget _lobbyUI(Size size, GameProvider provider) {
    return Column(
      children: [
        Text(
          "Room Code",
          style: TextStyle(color: Colors.white70, fontSize: size.width / 30),
        ),
        SizedBox(height: size.height / 80),
        SelectableText(
          provider.currentOnlineRoomId!,
          style: TextStyle(
            fontSize: size.width / 12,
            fontWeight: FontWeight.bold,
            color: Colors.greenAccent,
            letterSpacing: 6,
          ),
        ),
        SizedBox(height: size.height / 40),

        // ----- PLAYER LIST LOBBY -----
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(size.width / 30),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Players Joined (${provider.onlinePlayersMap.length}/4)",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: size.height / 60),

              ...provider.onlinePlayersMap.entries.map((entry) {
                final colorName = entry.key;
                final data = entry.value;
                final pName = data['name'];
                final isMe = pName == provider.myPlayerName;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: size.width / 40,
                            backgroundColor: _getColorFromName(colorName),
                          ),
                          SizedBox(width: size.width / 30),
                          Text(
                            pName + (isMe ? " (You)" : ""),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isMe
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      // Only Host can see remove buttons, and Host cannot kick themselves
                      if (provider.isHost && !isMe)
                        GestureDetector(
                          onTap: () => provider.kickPlayer(colorName, pName),
                          child: Icon(
                            Icons.remove_circle,
                            color: Colors.redAccent,
                            size: size.width / 18,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        SizedBox(height: size.height / 30),

        // ----- START BUTTON / WAITING TEXT -----
        if (provider.isHost)
          _gradientButton(
            text: "Start Game",
            colors: [Colors.green, Colors.teal],
            loading: false,
            size: size,
            onTap: () {
              if (provider.onlinePlayersMap.length < 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Need at least 2 players to start!",
                      textAlign: TextAlign.center,
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              provider.startGameHost();
            },
          )
        else
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.orangeAccent,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  "Waiting for Host to start...",
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: size.width / 26,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _getColorFromName(String name) {
    switch (name) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  // ================= JOIN / CREATE =================

  Widget _joinCreateUI(Size size, GameProvider provider) {
    return Column(
      children: [
        _gradientButton(
          text: "Create Room",
          colors: [Colors.blue, Colors.purple],
          loading: isCreating,
          size: size,
          onTap: isCreating
              ? null
              : () async {
                  if (_nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          'Please enter your name !',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  setState(() => isCreating = true);
                  try {
                    await provider.createOnlineRoom(
                      _nameController.text.trim(),
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  } finally {
                    if (mounted) setState(() => isCreating = false);
                  }
                },
        ),

        SizedBox(height: size.height / 40),
        Text(
          "OR",
          style: TextStyle(color: Colors.white, fontSize: size.width / 25),
        ),
        SizedBox(height: size.height / 40),

        _textField(
          controller: _roomCodeController,
          hint: "Enter Room Code",
          icon: Icons.vpn_key,
          size: size,
        ),

        SizedBox(height: size.height / 40),

        _gradientButton(
          text: "Join Room",
          colors: [Colors.orange, Colors.red],
          loading: isJoining,
          size: size,
          onTap: isJoining
              ? null
              : () async {
                  if (_nameController.text.trim().isEmpty ||
                      _roomCodeController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          'Please enter name and room code',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  setState(() => isJoining = true);
                  try {
                    HapticFeedback.mediumImpact();
                    await provider.joinOnlineRoom(
                      _roomCodeController.text.trim(),
                      _nameController.text.trim(),
                    );
                    // No Navigator.push here!
                    // The state change triggers the _lobbyUI to display.
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  } finally {
                    if (mounted) setState(() => isJoining = false);
                  }
                },
        ),
      ],
    );
  }
}
