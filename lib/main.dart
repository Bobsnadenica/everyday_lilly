import 'package:flutter/material.dart';
import 'services/notifications.dart';
import 'pages/front_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Everyday Lilly',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const FrontPage(),
    );
  }
}