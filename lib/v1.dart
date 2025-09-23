import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive_io.dart';

/// ===================
/// NOTIFICATIONS SETUP
/// ===================
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

TimeOfDay reminderTime = const TimeOfDay(hour: 10, minute: 0); // default

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  tz.initializeTimeZones();
}

Future<void> scheduleDailyReminder({TimeOfDay? time}) async {
  final reminder = time ?? reminderTime;
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
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  return scheduledDate;
}

/// =============
/// MAIN APP CODE
/// =============
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
      home: const CalendarPage(),
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final ImagePicker _picker = ImagePicker();
  final Map<String, File> _photos = {};

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    scheduleDailyReminder(); // schedule with default time
  }

  Future<void> _loadPhotos() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync();
    for (var file in files) {
      if (file is File && file.path.endsWith(".jpg")) {
        final name = file.uri.pathSegments.last.split('.').first;
        _photos[name] = file;
      }
    }
    setState(() {});
  }

  Future<void> _takePhoto(DateTime date) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = DateFormat('yyyy-MM-dd').format(date) + '.jpg';
      final newFile = File('${dir.path}/$fileName');

      // replace existing photo if exists
      if (_photos.containsKey(fileName.split('.').first)) {
        await _photos[fileName.split('.').first]!.delete();
      }

      final savedImage = await File(pickedFile.path).copy(newFile.path);

      setState(() {
        _photos[fileName.split('.').first] = savedImage;
      });
    }
  }

  void _openGallery(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final photo = _photos[key];
    if (photo != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoGallery(
            initialPhotoKey: key,
            photos: _photos,
          ),
        ),
      );
    } else {
      _takePhoto(date);
    }
  }

  Future<void> _pickReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: reminderTime,
    );
    if (time != null) {
      setState(() {
        reminderTime = time;
      });
      scheduleDailyReminder(time: time);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder set for ${time.format(context)}')),
      );
    }
  }

Future<void> _exportTimeLapse() async {
  final dir = await getApplicationDocumentsDirectory();
  final zipPath = '${dir.path}/everyday_lilly.zip';

  final encoder = ZipFileEncoder();
  encoder.create(zipPath);

  final keys = _photos.keys.toList()..sort();
  for (final key in keys) {
    final file = _photos[key]!;
    encoder.addFile(file); // Add file directly, no Archive needed
  }

  encoder.close();

  Share.shareFiles([zipPath], text: 'My Everyday Lilly time-lapse photos');
}


  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Everyday Lilly'),
        actions: [
          IconButton(
            icon: const Icon(Icons.access_time),
            tooltip: 'Set Reminder Time',
            onPressed: _pickReminderTime,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export/Share Time-Lapse',
            onPressed: _exportTimeLapse,
          ),
        ],
      ),
      body: PageView.builder(
        itemCount: 12,
        itemBuilder: (context, monthIndex) {
          final monthDate = DateTime(now.year, monthIndex + 1, 1);
          final daysInMonth =
              DateUtils.getDaysInMonth(now.year, monthIndex + 1);
          final weekdayOffset = monthDate.weekday - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  DateFormat('MMMM yyyy').format(monthDate),
                  style:
                      const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: daysInMonth + weekdayOffset,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemBuilder: (context, index) {
                    if (index < weekdayOffset) return const SizedBox.shrink();
                    final day = index - weekdayOffset + 1;
                    final date = DateTime(now.year, monthIndex + 1, day);
                    final key = DateFormat('yyyy-MM-dd').format(date);
                    final photo = _photos[key];

                    return GestureDetector(
                      onTap: () => _openGallery(date),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            if (photo != null)
                              Positioned.fill(
                                child: Image.file(photo, fit: BoxFit.cover),
                              ),
                            Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                color: Colors.white70,
                                padding: const EdgeInsets.all(2),
                                child: Text(
                                  '$day',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ========================
/// SWIPEABLE PHOTO GALLERY
/// ========================
class PhotoGallery extends StatefulWidget {
  final Map<String, File> photos;
  final String initialPhotoKey;

  const PhotoGallery(
      {super.key, required this.photos, required this.initialPhotoKey});

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  late final PageController _controller;
  late final List<String> keys;

  @override
  void initState() {
    super.initState();
    keys = widget.photos.keys.toList()..sort();
    final initialIndex = keys.indexOf(widget.initialPhotoKey);
    _controller = PageController(initialPage: initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lilly Photos')),
      body: PageView.builder(
        controller: _controller,
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final photo = widget.photos[keys[index]]!;
          return Center(child: Image.file(photo, fit: BoxFit.contain));
        },
      ),
    );
  }
}
