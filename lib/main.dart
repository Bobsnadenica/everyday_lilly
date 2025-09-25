import 'package:flutter/material.dart';
import 'services/notifications.dart';
import 'pages/front_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();
  runApp(const MyApp());
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