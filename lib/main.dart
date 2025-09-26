import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'services/notifications.dart';
import 'pages/front_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Sofia'));
  debugPrint('Timezone forced to Europe/Sofia');
  debugPrint('Initializing notifications...');
  await initNotifications();
  await testScheduledNotification2Min();
  debugPrint('Notifications initialized.');
  runApp(const MyApp());
}

Future<void> testScheduledNotification2Min() async {
  final testTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 2));
  debugPrint('Scheduling for: $testTime using tz.local: ${tz.local.name}');

  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    'Scheduled Test',
    'Should pop up in 2 minutes',
    testTime,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminder_channel',
        'Daily Reminder Notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
}

ThemeMode _getThemeModeForTime() {
  final hour = DateTime.now().hour;
  if (hour >= 6 && hour < 18) {
    return ThemeMode.light;
  } else {
    return ThemeMode.dark;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Everyday Lilly',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.black,
      ),
      themeMode: _getThemeModeForTime(),
      home: const FrontPage(),
    );
  }
}