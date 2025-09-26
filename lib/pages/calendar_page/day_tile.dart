import 'dart:io';
import 'package:flutter/material.dart';

class DayTile extends StatelessWidget {
  final DateTime date;
  final DateTime now;
  final File? photo;
  final bool hasNote;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const DayTile({
    super.key,
    required this.date,
    required this.now,
    required this.photo,
    required this.hasNote,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFuture = date.isAfter(now);
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    return GestureDetector(
      onTap: onTap,
      onLongPress: !isFuture ? onLongPress : null,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: photo != null
              ? Colors.transparent
              : (isFuture
                  ? (isDark ? Colors.red.withOpacity(0.2) : Colors.red.withOpacity(0.3))
                  : (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85))),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 6, offset: const Offset(0, 3)),
          ],
          border: isToday ? Border.all(color: Theme.of(context).colorScheme.secondary, width: 2) : null,
        ),
        child: Stack(
          children: [
            if (photo != null)
              Positioned.fill(
                child: ClipOval(
                  child: Image.file(photo!, fit: BoxFit.cover, cacheWidth: 300, cacheHeight: 300),
                ),
              ),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: photo != null ? Colors.white : (isDark ? Colors.white : Colors.black87),
                    shadows: photo != null
                        ? [Shadow(blurRadius: 4, color: Colors.black.withOpacity(0.7), offset: const Offset(1, 1))]
                        : null,
                  ),
                ),
              ),
            ),
            if (hasNote)
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 3, offset: const Offset(1, 1))],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.note, size: 20, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}