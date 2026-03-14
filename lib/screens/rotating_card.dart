import 'dart:async';

import 'package:flutter/material.dart';

class RotatingCredit extends StatefulWidget {
  const RotatingCredit({super.key});

  @override
  State<RotatingCredit> createState() => _RotatingCreditState();
}

class _RotatingCreditState extends State<RotatingCredit> {
  int currentIndex = 0;
  Timer? _timer;

  final List<String> messages = [
    'Made with ❤️',
    'Coded with ☕',
    'Built with 🔥',
    'Crafted with ✨',
  ];

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;

      setState(() {
        currentIndex = (currentIndex + 1) % messages.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.4),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(
        messages[currentIndex],
        key: ValueKey(messages[currentIndex]),
        style: TextStyle(
          fontSize: size.width / 35,
          color: Colors.white.withValues(alpha: 0.85),
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
