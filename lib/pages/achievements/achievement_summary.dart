import 'package:flutter/material.dart';

class AchievementSummary extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;

  const AchievementSummary({super.key, required this.achievements});

  @override
  Widget build(BuildContext context) {
    final unlockedCount = achievements.where((a) {
      final u = (a['unlocked'] as bool?) ?? false;
      final p = (a['progress'] as int?) ?? 0;
      return u || p >= 100;
    }).length;

    final total = achievements.length;

    // Calculate average progress across all achievements
    final overallProgress = achievements.fold<double>(0, (sum, a) {
      final p = ((a['progress'] as int?) ?? 0).clamp(0, 100).toDouble();
      return sum + p;
    }) / (100 * total);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: bgColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$unlockedCount of $total achievements unlocked',
              style: TextStyle(fontWeight: FontWeight.w700, color: textColor, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: overallProgress),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(overallProgress * 100).round()}%',
                style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}