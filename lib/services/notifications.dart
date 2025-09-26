import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// NOTE: You must have flutter_timezone in your pubspec.yaml
import 'package:flutter_timezone/flutter_timezone.dart'; 
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// --- CONSTANTS AND GLOBAL SETUP ---

const String _channelId = 'daily_reminder_channel_id';
const int _notificationId = 1001; 

// Changed to 'final' to allow access to properties inside NotificationDetails.
final AndroidNotificationChannel _dailyChannel = const AndroidNotificationChannel(
  _channelId,
  'Daily Lilly Reminder',
  description: 'A daily reminder to capture your Lilly photo for today.',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Default time.
TimeOfDay reminderTime = const TimeOfDay(hour: 10, minute: 0);

bool _tzConfigured = false;

// --- NATIVE CHANNEL METHOD ---

/// Helper to explicitly open the Android Exact Alarm settings page
Future<void> openExactAlarmSettings() async {
  if (!Platform.isAndroid) return;
  const platform = MethodChannel('everyday_lilly/alarm_settings');
  try {
    await platform.invokeMethod('openExactAlarmSettings');
    debugPrint('Opened exact alarm settings screen for user to grant permission.');
  } catch (e) {
    debugPrint('Failed to open exact alarm settings: $e');
  }
}

// --- INITIALIZATION ---

/// Initializes time zones and notification settings.
Future<void> initNotifications() async {
  if (!_tzConfigured) {
    tz.initializeTimeZones();
    try {
      final dynamic tzInfo = await FlutterTimezone.getLocalTimezone();
      String timeZoneName;
      try {
        timeZoneName = (tzInfo as dynamic).timezone as String;
      } catch (_) {
        try {
          timeZoneName = (tzInfo as dynamic).local as String;
        } catch (_) {
          if (tzInfo is String) {
            timeZoneName = tzInfo;
          } else {
            final s = tzInfo.toString();
            final match = RegExp(r'\(([^,]+),').firstMatch(s);
            timeZoneName = match != null ? match.group(1)! : 'UTC';
          }
        }
      }
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Timezone set to: $timeZoneName');
    } catch (e) {
      debugPrint('Could not determine local timezone. Keeping existing: ${tz.local.name}. Error: $e');
    }
    _tzConfigured = true;
  } else {
    debugPrint('Timezone already configured: ${tz.local.name}');
  }

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: android);

  await flutterLocalNotificationsPlugin.initialize(
    settings,
    onDidReceiveNotificationResponse: (details) {
      debugPrint('Notification tapped: ${details.payload}');
    },
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin != null) {
    // 1. Create the channel
    await androidPlugin.createNotificationChannel(_dailyChannel);

    // 2. Request basic notification permission (Android 13+)
    await androidPlugin.requestNotificationsPermission();

    final enabled = await androidPlugin.areNotificationsEnabled();
    debugPrint('Notifications enabled at system level: $enabled');
  }
}

// --- REMINDER SCHEDULING ---

/// Schedules the daily recurring notification.
Future<void> scheduleDailyReminder({TimeOfDay? time}) async {
  try {
    // tz is initialized during app startup

    // Ensure tz.local is correct before scheduling
    if (tz.local.name == 'UTC') {
      try {
        final dynamic tzInfo = await FlutterTimezone.getLocalTimezone();
        String timeZoneName;

        if (tzInfo is String) {
          timeZoneName = tzInfo;
        } else {
          // Fallback: extract from object string like TimezoneInfo(Europe/Sofia, ...)
          final s = tzInfo.toString();
          final match = RegExp(r'\(([^,]+),').firstMatch(s);
          timeZoneName = match != null ? match.group(1)! : 'UTC';
        }

        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('Dynamic timezone set to: $timeZoneName');
      } catch (e) {
        debugPrint('Failed to set dynamic timezone: $e');
      }
    }

    final reminder = time ?? reminderTime;
    
    // 1. Cancel any existing notification with the same ID
    await flutterLocalNotificationsPlugin.cancel(_notificationId);

final now = tz.TZDateTime.now(tz.local);
var scheduledTime = tz.TZDateTime(
  tz.local,
  now.year,
  now.month,
  now.day,
  reminder.hour,
  reminder.minute,
);
if (scheduledTime.isBefore(now)) {
  scheduledTime = scheduledTime.add(const Duration(days: 1));
}

   debugPrint('Scheduling daily reminder for $scheduledTime in timezone ${tz.local.name}');
   debugPrint('tz.local: ${tz.local.name}  scheduled offset: ${scheduledTime.timeZoneOffset}');

    const payload = 'daily_reminder';

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        _notificationId,
        'Everyday Lilly: Time to snap!',
        'It’s time for your daily photo. Capture the moment! 📸',
        scheduledTime,
        NotificationDetails( // Not const
          android: AndroidNotificationDetails(
            _channelId,
            _dailyChannel.name, // Accessing name is fine now
            channelDescription: _dailyChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            fullScreenIntent: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Key for daily recurrence
        payload: payload,
      );
    } catch (e) {
      debugPrint('Exact scheduling failed, retrying inexact: $e');
      await flutterLocalNotificationsPlugin.zonedSchedule(
        _notificationId,
        'Everyday Lilly: Time to snap!',
        'It’s time for your daily photo. Capture the moment! 📸',
        scheduledTime,
        NotificationDetails( // Not const
          android: AndroidNotificationDetails(
            _channelId,
            _dailyChannel.name, // Accessing name is fine now
            channelDescription: _dailyChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            fullScreenIntent: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Key for daily recurrence
        payload: payload,
      );
    }

    debugPrint('Daily recurring reminder scheduled successfully.');
    if (time != null) {
      reminderTime = time;
    }
  } catch (e) {
    debugPrint('Notification scheduling failed: $e');
  }
}

// --- BOOT/REBOOT HANDLER ---

/// Handles device reboot by rescheduling notifications.
Future<void> handleBoot() async {
  if (Platform.isAndroid) {
    debugPrint('Handling device reboot: rescheduling notifications.');
    // We call initNotifications first to ensure tz.local is set, 
    // then schedule the reminder.
    await initNotifications(); 
    await scheduleDailyReminder(time: reminderTime);
  }
}

// --- TESTING UTILITY ---

/// Schedules a one-time test notification in 30 seconds.
Future<void> scheduleTestNotification() async {
  try {
    final testTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 30));

    debugPrint('tz.local(test): ${tz.local.name}  testTime: $testTime  offset: ${testTime.timeZoneOffset}');
    debugPrint('Scheduling test notification for $testTime (30 seconds from now)');

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        2002,
        'Everyday Lilly Test',
        'This notification works! You are 30 seconds into the future. 🚀',
        testTime,
        NotificationDetails( // Not const
          android: AndroidNotificationDetails(
            _channelId,
            _dailyChannel.name,
            channelDescription: 'Test channel for immediate check.',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
        payload: 'test_reminder',
      );
    } catch (e) {
      debugPrint('Exact scheduling failed, retrying inexact: $e');
      await flutterLocalNotificationsPlugin.zonedSchedule(
        2002,
        'Everyday Lilly Test',
        'This notification works! You are 30 seconds into the future. 🚀',
        testTime,
        NotificationDetails( // Not const
          android: AndroidNotificationDetails(
            _channelId,
            _dailyChannel.name,
            channelDescription: 'Test channel for immediate check.',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: null,
        payload: 'test_reminder',
      );
    }

    debugPrint('Test notification scheduled successfully.');
  } catch (e) {
    debugPrint('Failed to schedule test notification: $e');
  }
}