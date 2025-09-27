import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:everyday_lilly/services/storage_service.dart';

class CalendarAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String calendarId;
  final VoidCallback onHome;
  final VoidCallback onAchievements;
  final VoidCallback onBackYear;
  final VoidCallback onForwardYear;
  final VoidCallback onReminder;
  final VoidCallback onTimelapse;
  final VoidCallback onBackup;

  const CalendarAppBar({
    super.key,
    required this.calendarId,
    required this.onHome,
    required this.onAchievements,
    required this.onBackYear,
    required this.onForwardYear,
    required this.onReminder,
    required this.onTimelapse,
    required this.onBackup,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    final kb = bytes / 1024;
    if (kb < 1024) return "${kb.toStringAsFixed(2)} KB";
    final mb = kb / 1024;
    return "${mb.toStringAsFixed(2)} MB";
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const SizedBox.shrink(),
      backgroundColor: Colors.black54,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(icon: const Icon(Icons.home), onPressed: onHome),
        IconButton(
          icon: const Icon(Icons.emoji_events_outlined),
          tooltip: 'Achievements',
          onPressed: onAchievements,
        ),
        IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBackYear),
        IconButton(icon: const Icon(Icons.arrow_forward), onPressed: onForwardYear),
        PopupMenuButton<String>(
          color: Colors.black87,
          onSelected: (v) async {
            switch (v) {
              case 'reminder':
                onReminder();
                break;
              case 'timelapse':
                onTimelapse();
                break;
              case 'backup':
                final storage = StorageService(calendarId);
                final calendarSize = await storage.calendarSizeBytes();
                final formattedSize = _formatBytes(calendarSize);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Backup Confirmation'),
                    content: Text('Your calendar size is $formattedSize. Do you want to proceed with backup?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Backup Now'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  onBackup();
                }
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'reminder',
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Reminder', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'timelapse',
              child: Row(
                children: [
                  Icon(Icons.movie, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Export Timelapse', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'backup',
              child: Row(
                children: [
                  Icon(Icons.backup, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Backup', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}