import 'package:flutter/material.dart';

class QuoteDisplay extends StatelessWidget {
  final String? todaysQuote;
  const QuoteDisplay({super.key, required this.todaysQuote});

  @override
  Widget build(BuildContext context) {
    if (todaysQuote == null || todaysQuote!.trim().isEmpty) return const SizedBox.shrink();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(seconds: 2),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              todaysQuote!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}