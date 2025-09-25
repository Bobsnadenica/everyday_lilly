import 'package:flutter/material.dart';
import 'home_page.dart';

class FrontPage extends StatelessWidget {
  const FrontPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              _backgroundImage,
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(_horizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Logo(),
                  const SizedBox(height: 28),
                  _Title(),
                  const SizedBox(height: 16),
                  _Description(),
                  const SizedBox(height: 44),
                  _OpenCalendarButton(onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                      (Route<dynamic> route) => false,
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Constants ---
const double _logoSize = 100;
const double _logoIconSize = 60;
const double _logoBorderRadius = 24;
const double _horizontalPadding = 32.0;
const double _buttonPaddingH = 40;
const double _buttonPaddingV = 16;
const double _buttonBorderRadius = 16;
const double _buttonFontSize = 18;
const String _backgroundImage = 'assets/lily_background.jpg';

// --- Private helper widgets ---

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: _logoSize,
      height: _logoSize,
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(_logoBorderRadius),
      ),
      child: const Icon(
        Icons.local_florist,
        size: _logoIconSize,
        color: Colors.green,
      ),
    );
  }
}

class _Title extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      "Everyday Lilly",
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.green.shade800,
            fontWeight: FontWeight.bold,
          ),
      textAlign: TextAlign.center,
    );
  }
}

class _Description extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      "Capture a photo each day and see your growth journey unfold.\n"
      "Inspired by my daughter Lilly.\n"
      "I love you, Lilly <3",
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade700,
          ),
    );
  }
}

class _OpenCalendarButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _OpenCalendarButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
            horizontal: _buttonPaddingH, vertical: _buttonPaddingV),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonBorderRadius),
        ),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 5,
      ),
      onPressed: onPressed,
      child: const Text(
        "Open Calendar",
        style: TextStyle(fontSize: _buttonFontSize),
      ),
    );
  }
}