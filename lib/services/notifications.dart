import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

TimeOfDay reminderTime = const TimeOfDay(hour: 10, minute: 0);

Future<void> initNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: android);

  await flutterLocalNotificationsPlugin.initialize(settings);
  tz.initializeTimeZones();

  // ✅ Ask for permission on Android 13+
  final granted = await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  debugPrint('Notification permission requested, granted: $granted');
  if (granted == true) {
    await scheduleDailyReminder(); // Schedule the daily reminder once permissions are granted
  }
}

Future<void> scheduleDailyReminder({TimeOfDay? time}) async {
  final reminder = time ?? reminderTime;
  try {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Everyday Lilly 🌸',
      'Don’t forget to take today’s Lilly photo!',
      _nextInstanceOfTime(reminder.hour, reminder.minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel_id',
          'Daily Reminder',
          channelDescription: 'Reminder to take your Lilly photo',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  } catch (e) {
    debugPrint('Notification scheduling failed: $e');
  }
}

tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final now = tz.TZDateTime.now(tz.local);
  var scheduled =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}