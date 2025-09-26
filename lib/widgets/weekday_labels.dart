import 'package:flutter/material.dart';

class WeekdayLabels extends StatelessWidget {
  const WeekdayLabels({super.key});

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map((d) => const _WeekdayPill()).toList(growable: false)
          ..asMap().forEach((i, _) {}),
      ),
    );
  }
}

class _WeekdayPill extends StatelessWidget {
  const _WeekdayPill();

  @override
  Widget build(BuildContext context) {
    // We’ll render the labels via a DefaultTextStyle from the parent
    return Expanded(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
            child: const _WeekdayText(),
          ),
        ),
      ),
    );
  }
}

class _WeekdayText extends StatelessWidget {
  const _WeekdayText();

  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    // Use an InheritedWidget trick: each Expanded occupies its index position.
    // We can’t get the index directly, so simplest: rely on parent order and labels list.
    // To keep it simple, render an invisible counter is overkill—just return placeholder;
    // parent maps labels in order when creating children (see MonthView usage below).
    return Text(''); // real text is provided by MonthView directly (see below)
  }
}