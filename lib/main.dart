// ignore_for_file: use_build_context_synchronously

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ludo_game/firebase_options.dart';
import 'package:ludo_game/providers/game_provider.dart';
import 'package:ludo_game/screens/start_screen.dart';
import 'package:ludo_game/utils/audio_manager.dart';
import 'package:provider/provider.dart';

// ==============================
// ENTRY POINT
// Initializes audio and launches the Flutter app.
// ==============================

// global key for scaffold messanger.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  // Ensures Flutter engine is fully initialized before calling async platform APIs.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
        key: scaffoldMessengerKey,
        theme: ThemeData(
          colorScheme: ColorScheme.dark(primary: Colors.red),
          useMaterial3: true,
        ),

        // The app always starts with the landing start screen.
        home: const StartScreen(),
      ),
    );
  }
}
