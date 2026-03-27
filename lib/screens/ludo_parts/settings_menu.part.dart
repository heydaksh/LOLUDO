part of '../ludo_screen.dart';

// ==============================
// SETTINGS MENU
// A gear icon that opens a popup menu with three options:
//   • Hacks  → Opens the cheat/toggle bottom sheet.
//   • Reset  → Restarts the current game.
//   • Exit   → Returns to the player selection screen.
// ==============================

class _SettingsMenu extends StatelessWidget {
  const _SettingsMenu();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final gameProvider = context.watch<GameProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SizedBox(
        height: size.height / 18,
        child: Align(
          alignment: Alignment.bottomRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // PAUSE / RESUME BUTTON
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();

                  gameProvider.setPauseState(!gameProvider.isPaused);
                },
                child: Container(
                  margin: EdgeInsets.only(right: size.width / 40),
                  padding: EdgeInsets.all(size.width / 50),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                  child: Icon(
                    gameProvider.isPaused ? Icons.play_arrow : Icons.pause,
                    color: gameProvider.isPaused ? Colors.green : Colors.orange,
                    size: size.width / 16,
                  ),
                ),
              ),

              // SETTINGS POPUP MENU
              if (gameProvider.isHost || !gameProvider.isOnlineMultiplayer)
                Container(
                  margin: EdgeInsets.only(right: size.width / 40),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                  child: PopupMenuButton<String>(
                    color: Colors.grey.shade900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(size.width / 25),
                    ),
                    icon: Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: size.width / 16,
                    ),
                    itemBuilder: (context) => [
                      /// HACKS
                      PopupMenuItem(
                        value: 'Hacks',
                        child: Row(
                          children: [
                            Icon(
                              Icons.flash_on,
                              color: Colors.orange,
                              size: size.width / 20,
                            ),
                            SizedBox(width: size.width / 40),
                            Text(
                              "Hack Menu",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: size.width / 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// RESET
                      PopupMenuItem(
                        value: 'Reset',
                        child: Row(
                          children: [
                            Icon(
                              Icons.restart_alt,
                              color: Colors.green,
                              size: size.width / 20,
                            ),
                            SizedBox(width: size.width / 40),
                            Text(
                              "Restart Game",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: size.width / 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // remove player
                      PopupMenuItem(
                        value: 'Remove',
                        child: Row(
                          children: [
                            Icon(
                              Icons.sports_gymnastics,
                              color: Colors.cyanAccent,
                              size: size.width / 20,
                            ),
                            SizedBox(width: size.width / 40),
                            Text(
                              "Remove Player",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: size.width / 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Pass Turn
                      PopupMenuItem(
                        value: 'PassTurn',
                        child: Row(
                          children: [
                            Icon(
                              Icons.skip_next_sharp,
                              color: Colors.blue,
                              size: size.width / 20,
                            ),
                            SizedBox(width: size.width / 40),
                            Text(
                              "Pass Turn",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: size.width / 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// EXIT
                      PopupMenuItem(
                        value: 'Exit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.exit_to_app,
                              color: Colors.red,
                              size: size.width / 20,
                            ),
                            SizedBox(width: size.width / 40),
                            Text(
                              "Exit Game",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: size.width / 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      debugPrint("Settings menu selected: $value");
                      if (value == 'Hacks') {
                        _showHackMenu(context);
                      } else if (value == 'Reset') {
                        showDialog(
                          context: context,
                          builder: (_) {
                            return AlertDialog(
                              backgroundColor: Colors.grey.shade900,
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.restart_alt,
                                    color: Colors.green,
                                    size: size.width / 10,
                                  ),
                                  SizedBox(width: size.width / 40),
                                  Text(
                                    "Reset Game",
                                    style: TextStyle(
                                      fontSize: size.width / 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(
                                "Are you sure you want to reset the game?",
                                style: TextStyle(fontSize: size.width / 28),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontSize: size.width / 28,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.read<GameProvider>().restartGame();
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    "Reset",
                                    style: TextStyle(
                                      fontSize: size.width / 28,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      } else if (value == 'Remove') {
                        _showRemovePlayerDialog(context);
                      } else if (value == 'PassTurn') {
                        HapticFeedback.mediumImpact();
                        gameProvider.nextTurn();
                      } else if (value == 'Exit') {
                        showDialog(
                          context: context,
                          builder: (_) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  size.width / 18,
                                ),
                              ),
                              child: Container(
                                padding: EdgeInsets.all(size.width / 18),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade900,
                                  borderRadius: BorderRadius.circular(
                                    size.width / 18,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    /// ICON
                                    Icon(
                                      Icons.exit_to_app,
                                      size: size.width / 8,
                                      color: Colors.red,
                                    ),
                                    SizedBox(height: size.height / 80),

                                    /// TITLE
                                    Text(
                                      "Exit Game",
                                      style: TextStyle(
                                        fontSize: size.width / 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: size.height / 100),

                                    /// MESSAGE
                                    Text(
                                      "Are you sure you want to exit the game?",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: size.width / 26,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: size.height / 40),

                                    /// BUTTONS
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        /// CANCEL
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: size.width / 15,
                                              vertical: size.height / 70,
                                            ),
                                            backgroundColor: Colors.grey,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    size.width / 10,
                                                  ),
                                            ),
                                          ),
                                          child: Text(
                                            "Cancel",
                                            style: TextStyle(
                                              fontSize: size.width / 26,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),

                                        /// EXIT
                                        ElevatedButton(
                                          onPressed: () async {
                                            Navigator.pop(
                                              context,
                                            ); // Close dialog
                                            // Kill all active game states and bot functions
                                            context
                                                .read<GameProvider>()
                                                .exitGame();
                                            // Erase the whole route history and return to Start
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const StartScreen(),
                                              ),
                                              (route) => false,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: size.width / 15,
                                              vertical: size.height / 70,
                                            ),
                                            backgroundColor: Colors.red,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    size.width / 10,
                                                  ),
                                            ),
                                          ),
                                          child: Text(
                                            "Exit",
                                            style: TextStyle(
                                              fontSize: size.width / 26,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================
  // Hack Menu -- cheat toogles.
  // ==============================

  /// Shows a bottom sheet with toggles for debug/cheat features:
  ///   • Bulldozer Mode      — kills enemies on all intermediate cells.
  ///   • Eliminate All       — kills ALL enemies on same cell at once.
  ///   • Always Roll 6       — forces dice to always return 6.
  ///
  /// Uses Consumer -GameProvider- so each button reflects live state.
  void _showHackMenu(BuildContext context) {
    final size = MediaQuery.of(context).size;

    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Consumer<GameProvider>(
          builder: (context, modalProvider, child) {
            return Container(
              height: size.height / 4.5,
              padding: EdgeInsets.symmetric(
                horizontal: size.width / 25,
                vertical: size.height / 80,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(size.width / 18),
                ),
                boxShadow: const [
                  BoxShadow(blurRadius: 20, color: Colors.black26),
                ],
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  /// BULLDOZER MODE
                  _hackCard(
                    size: size,
                    icon: Icons.shield,
                    title: "Bulldozer",
                    subtitle: "Sweep enemies",
                    active: modalProvider.isBulldozerMode,
                    color: Colors.orange,
                    onTap: () {
                      modalProvider.toggleBulldozerMode();
                      HapticFeedback.mediumImpact();
                    },
                  ),

                  SizedBox(width: size.width / 25),

                  /// ELIMINATE ALL
                  _hackCard(
                    size: size,
                    icon: Icons.flash_on,
                    title: "Eliminate",
                    subtitle: "Break stack rule",
                    active: modalProvider.eliminateAllOpponents,
                    color: Colors.green,
                    onTap: () {
                      modalProvider.toggleEliminateAll();
                      HapticFeedback.mediumImpact();
                    },
                  ),

                  SizedBox(width: size.width / 25),

                  /// ALWAYS 6
                  _hackCard(
                    size: size,
                    icon: Icons.casino,
                    title: "Always 6",
                    subtitle: "Fixed dice",
                    active: modalProvider.alwaysRollSix,
                    color: Colors.purple,
                    onTap: () {
                      modalProvider.toggleAlwaysRollSix();
                      HapticFeedback.mediumImpact();
                    },
                  ),

                  SizedBox(width: size.width / 25),

                  /// SPECIAL POWERS
                  _hackCard(
                    size: size,
                    icon: Icons.bolt,
                    title: "Powers",
                    subtitle: "Power tiles",
                    active: modalProvider.enableSpecialPowers,
                    color: Colors.amber,
                    onTap: () {
                      modalProvider.toggleSpecialPowers();
                      HapticFeedback.mediumImpact();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // remove player
  void _showRemovePlayerDialog(BuildContext context) {
    final size = MediaQuery.of(context).size;

    showDialog(
      context: context,
      builder: (_) {
        return Consumer<GameProvider>(
          builder: (context, provider, child) {
            final players = provider.players
                .where((p) => provider.isPlayerInGame(p.color))
                .toList();

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(size.width / 18),
              ),
              child: Container(
                padding: EdgeInsets.all(size.width / 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.width / 18),
                  color: Colors.grey.shade900,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// TITLE
                    Text(
                      "Remove Player(s)",
                      style: TextStyle(
                        fontSize: size.width / 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Who don't want to play",
                      style: TextStyle(
                        fontSize: size.width / 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: size.height / 40),

                    /// PLAYER LIST
                    ...players.map((player) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColor(player.color),
                        ),

                        title: Text(
                          player.color.name.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: size.width / 26,
                          ),
                        ),

                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            provider.removePlayer(player.color);

                            Navigator.pop(context);
                          },
                        ),
                      );
                    }),

                    SizedBox(height: size.height / 80),

                    /// CLOSE BUTTON
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

  Widget _hackCard({
    required Size size,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConfig.settingsMenuTransitionDuration,
        width: size.width / 3,
        padding: EdgeInsets.all(size.width / 25),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
              : null,
          color: active ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(size.width / 18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? Colors.white : Colors.black54,
              size: size.width / 12,
            ),

            SizedBox(height: size.height / 120),

            Text(
              title,
              style: TextStyle(
                fontSize: size.width / 26,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : Colors.black,
              ),
            ),

            SizedBox(height: size.height / 200),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.width / 35,
                color: active ? Colors.white70 : Colors.black54,
              ),
            ),

            SizedBox(height: size.height / 150),

            Icon(
              active ? Icons.toggle_on : Icons.toggle_off,
              color: active ? Colors.white : Colors.black38,
              size: size.width / 10,
            ),
          ],
        ),
      ),
    );
  }
}
