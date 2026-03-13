// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:ludo_game/providers/game_provider.dart';
import 'package:ludo_game/screens/instructions_screen.dart';
import 'package:ludo_game/screens/start_screen.dart';
import 'package:ludo_game/utils/audio_manager.dart';
import 'package:provider/provider.dart';

// ==============================
// ENTRY POINT
// Initializes audio and launches the Flutter app.
// ==============================

void main() async {
  // Ensures Flutter engine is fully initialized before calling async platform APIs.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize audio players in low-latency mode before the app renders.
  await AudioManager.init();

  runApp(const MyApp());
}

// ==============================
// ROOT APP WIDGET
// ==============================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("App started");

    return MultiProvider(
      providers: [
        // Registers GameProvider as a singleton for the entire widget tree.
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Ludo',

        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),

        // The app always starts with the player selection flow.
        home: const _StartGameRouter(),
      ),
    );
  }
}

// ==============================
// START GAME ROUTER
// Handles the navigation sequence:
//   1. Show PlayerSelectionScreen (pick 2, 3, or 4 players).
//   2. Initialize players in GameProvider.
//   3. Navigate to LudoScreen (the main game board).
//
// Uses didChangeDependencies + _openedSelection flag to ensure
// the navigation is triggered exactly once after the widget is first built.
// ==============================

/// Routes the user from player selection into the game.
class _StartGameRouter extends StatefulWidget {
  const _StartGameRouter();

  @override
  State<_StartGameRouter> createState() => _StartGameRouterState();
}

class _StartGameRouterState extends State<_StartGameRouter> {
  /// Tracks whether the player-selection screen has already been pushed.
  /// Prevents re-opening selection on rebuild/hot-reload.
  bool _openedSelection = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_openedSelection) {
      _openedSelection = true;

      // addPostFrameCallback ensures navigation happens AFTER the first frame,
      // preventing Navigator calls during the initial build phase.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Push the player selection screen and wait for the player count result.
        final int? players = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StartScreen()),
        );

        debugPrint("Selected players: $players");

        // If the user confirmed a player count, configure the game accordingly.
        if (players != null) {
          context.read<GameProvider>().initializePlayers(players);
        }

        // Replace this router with the main game screen.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const InstructionsScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Displays a loading spinner while waiting for the player selection screen to appear.
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
