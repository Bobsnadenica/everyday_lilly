import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/calendar.dart';
import '../../widgets/weekday_labels.dart';
import 'day_tile.dart';
import 'quote_display.dart';

class MonthView extends StatelessWidget {
  final int currentYear;
  final int monthIndex;
  final DateTime now;
  final Calendar calendar;

  final Map<String, File> photos;
  final Map<String, String> notes;
  final void Function(DateTime) onOpenDay;
  final void Function(DateTime) onEditNote;
  final String? todaysQuote;

  const MonthView({
    super.key,
    required this.currentYear,
    required this.monthIndex,
    required this.now,
    required this.calendar,
    required this.photos,
    required this.notes,
    required this.onOpenDay,
    required this.onEditNote,
    required this.todaysQuote,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthDate = DateTime(currentYear, monthIndex + 1, 1);
    final daysInMonth = DateUtils.getDaysInMonth(currentYear, monthIndex + 1);
    final weekdayOffset = monthDate.weekday - 1;

    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              DateFormat('MMMM yyyy').format(monthDate),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map((d) => Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: daysInMonth + weekdayOffset,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < weekdayOffset) return const SizedBox.shrink();
              final day = index - weekdayOffset + 1;
              final date = DateTime(currentYear, monthIndex + 1, day);
              final key = DateFormat('yyyy-MM-dd').format(date);
              final photo = photos[key];
              final hasNote = notes.containsKey(key);
              final isFuture = date.isAfter(now);

              return DayTile(
                date: date,
                now: now,
                photo: photo,
                hasNote: hasNote,
                onTap: () {
                  if (isFuture) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You cannot add a photo for a future date.')),
                    );
                    return;
                  }
                  onOpenDay(date);
                },
                onLongPress: () {
                  if (!isFuture) onEditNote(date);
                },
              );
            },
          ),
        ),
        QuoteDisplay(todaysQuote: todaysQuote),
        const SizedBox(height: 20),
      ],
    );
  }
}