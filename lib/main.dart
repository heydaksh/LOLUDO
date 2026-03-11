// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:ludo_game/providers/game_provider.dart';
import 'package:ludo_game/screens/ludo_screen.dart';
import 'package:ludo_game/screens/player_selection_screen.dart';
import 'package:ludo_game/utils/audio_manager.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AudioManager.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("App started");

    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => GameProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Ludo',

        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),

        // Player selection screen opens first
        home: const _StartGameRouter(),
      ),
    );
  }
}

/// Handles navigation from player selection → game
class _StartGameRouter extends StatefulWidget {
  const _StartGameRouter();

  @override
  State<_StartGameRouter> createState() => _StartGameRouterState();
}

class _StartGameRouterState extends State<_StartGameRouter> {
  bool _openedSelection = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_openedSelection) {
      _openedSelection = true;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final int? players = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlayerSelectionScreen()),
        );

        debugPrint("Selected players: $players");

        if (players != null) {
          context.read<GameProvider>().initializePlayers(players);
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LudoScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
