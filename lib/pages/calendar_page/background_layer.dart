import 'dart:math';
import 'package:flutter/material.dart';

String getBackgroundForTime() {
  final hour = DateTime.now().hour;
  final random = Random();
  final List<String> morning = List.generate(12, (i) => 'morning${i + 1}.jpg');
  final List<String> afternoon = List.generate(12, (i) => 'afternoon${i + 1}.jpg');
  final List<String> evening = List.generate(12, (i) => 'evening${i + 1}.jpg');
  final List<String> night = List.generate(12, (i) => 'night${i + 1}.jpg');

  if (hour >= 6 && hour < 12) {
    return 'assets/backgrounds/morning/${morning[random.nextInt(morning.length)]}';
  } else if (hour >= 12 && hour < 18) {
    return 'assets/backgrounds/afternoon/${afternoon[random.nextInt(afternoon.length)]}';
  } else if (hour >= 18 && hour < 20) {
    return 'assets/backgrounds/evening/${evening[random.nextInt(evening.length)]}';
  } else {
    return 'assets/backgrounds/night/${night[random.nextInt(night.length)]}';
  }
}

class BackgroundLayer extends StatelessWidget {
  final String backgroundPath;
  final bool isDark;

  const BackgroundLayer({
    super.key,
    required this.backgroundPath,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(backgroundPath, fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [Colors.black.withOpacity(0.55), Colors.black.withOpacity(0.15)]
                    : [Colors.black.withOpacity(0.35), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}