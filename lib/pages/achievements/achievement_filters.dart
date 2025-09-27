import 'package:flutter/material.dart';
import 'package:everyday_lilly/pages/achievements/achievements_page.dart'; // To access AchievementFilter enum

class AchievementFilters extends StatelessWidget {
  final AchievementFilter filter;
  final ValueChanged<AchievementFilter> onChanged;

  const AchievementFilters({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Map<AchievementFilter, String> options = {
      AchievementFilter.all: 'All',
      AchievementFilter.unlocked: 'Unlocked',
      AchievementFilter.inProgress: 'In Progress',
      AchievementFilter.locked: 'Locked',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8,
        children: options.entries.map((entry) {
          final isSelected = filter == entry.key;

          return ChoiceChip(
            label: Text(
              entry.value,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onChanged(entry.key),
            showCheckmark: false,
            avatar: isSelected
                ? const Icon(Icons.check, size: 16)
                : null,
          );
        }).toList(),
      ),
    );
  }
}