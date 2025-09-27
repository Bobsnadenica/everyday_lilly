import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
TimeOfDay reminderTime = const TimeOfDay(hour: 20, minute: 0);

bool _initialized = false;

Future<void> initNotifications() async {
  tzdata.initializeTimeZones();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await _plugin.initialize(initSettings);
  if (Platform.isAndroid) {
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }
  }
  _initialized = true;
}

Future<void> _ensureInit() async {
  if (_initialized) return;
  tzdata.initializeTimeZones();

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  await _plugin.initialize(const InitializationSettings(android: androidInit));
  _initialized = true;
}

Future<void> scheduleDailyReminder({TimeOfDay? time}) async {
  if (!Platform.isAndroid) return; // keep it simple for now
  await _ensureInit();
  if (time != null) reminderTime = time;

  final now = TimeOfDay.now();
  final hour = reminderTime.hour;
  final minute = reminderTime.minute;

  final location = tz.getLocation(tz.local.name);
  final nowTz = tz.TZDateTime.now(location);
  var scheduled = tz.TZDateTime(
    location,
    nowTz.year,
    nowTz.month,
    nowTz.day,
    hour,
    minute,
  );
  if (scheduled.isBefore(nowTz)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }

  const androidDetails = AndroidNotificationDetails(
    'everyday_lilly_daily',
    'Daily Reminders',
    channelDescription: 'Daily photo reminder',
    importance: Importance.max,
    priority: Priority.high,
  );
  const details = NotificationDetails(android: androidDetails);

  await _plugin.zonedSchedule(
    1001,
    'Everyday Lilly',
    'Don’t forget today’s photo 📸',
    scheduled,
    details,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}