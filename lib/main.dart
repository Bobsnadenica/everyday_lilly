import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
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

class Calendar {
  final String id;
  final String name;
  final Map<String, File> photos;

  Calendar({
    required this.id,
    required this.name,
    Map<String, File>? photos,
  }) : photos = photos ?? {};

  Map<String, dynamic> toJson() {
    // Save id, name. Optionally, could save photo keys (dates), but not File paths.
    return {
      'id': id,
      'name': name,
      // Optionally: 'photoKeys': photos.keys.toList(), // not needed for persistence
    };
  }

  factory Calendar.fromJson(Map<String, dynamic> json) {
    return Calendar(
      id: json['id'],
      name: json['name'],
      // Photos will be loaded from file system, so leave empty
    );
  }
}

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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Calendar> _calendars = [];
  late Calendar _selectedCalendar;

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('calendars');
    if (jsonString != null) {
      try {
        final List<dynamic> list = json.decode(jsonString);
        final calendars = list
            .map((item) => Calendar.fromJson(item))
            .toList();
        setState(() {
          _calendars = calendars;
          _selectedCalendar = _calendars.isNotEmpty ? _calendars.first : Calendar(id: 'everyday_lilly', name: 'Everyday Lilly');
        });
      } catch (_) {
        // If error, fallback to default
        setState(() {
          _calendars = [
            Calendar(id: 'everyday_lilly', name: 'Everyday Lilly'),
            Calendar(id: 'everyday_dandelion', name: 'Everyday Dandelion'),
          ];
          _selectedCalendar = _calendars.first;
        });
        await _saveCalendars();
      }
    } else {
      setState(() {
        _calendars = [
          Calendar(id: 'everyday_lilly', name: 'Everyday Lilly'),
          Calendar(id: 'everyday_dandelion', name: 'Everyday Dandelion'),
        ];
        _selectedCalendar = _calendars.first;
      });
      await _saveCalendars();
    }
  }

  Future<void> _saveCalendars() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _calendars.map((c) => c.toJson()).toList();
    await prefs.setString('calendars', json.encode(data));
  }

  void _selectCalendar(Calendar calendar) {
    setState(() {
      _selectedCalendar = calendar;
    });
    Navigator.of(context).pop();
  }

  Future<void> _addCalendar() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Calendar'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Calendar Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop(name);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final id = result.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      final newCalendar = Calendar(id: id, name: result);
      setState(() {
        _calendars.add(newCalendar);
        _selectedCalendar = newCalendar;
      });
      await _saveCalendars();
    }
  }

  Future<void> _renameCalendar(Calendar calendar) async {
    final nameController = TextEditingController(text: calendar.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Calendar'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Calendar Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop(name);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        final idx = _calendars.indexOf(calendar);
        if (idx != -1) {
          _calendars[idx] = Calendar(
            id: calendar.id,
            name: result,
            photos: calendar.photos,
          );
          // update selected if needed
          if (_selectedCalendar.id == calendar.id) {
            _selectedCalendar = _calendars[idx];
          }
        }
      });
      await _saveCalendars();
    }
  }

  Future<void> _deleteCalendar(Calendar calendar) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Calendar'),
        content: Text('Are you sure you want to delete "${calendar.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _calendars.remove(calendar);
        if (_calendars.isEmpty) {
          // Add a default calendar if all are deleted
          final defaultCal = Calendar(id: 'default', name: 'Default Calendar');
          _calendars.add(defaultCal);
          _selectedCalendar = defaultCal;
        } else if (_selectedCalendar.id == calendar.id) {
          _selectedCalendar = _calendars.first;
        }
      });
      await _saveCalendars();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCalendar.name),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              child: Center(
                child: Text(
                  'Calendars',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _calendars.length,
                itemBuilder: (context, index) {
                  final calendar = _calendars[index];
                  return ListTile(
                    title: Text(calendar.name),
                    selected: calendar.id == _selectedCalendar.id,
                    onTap: () => _selectCalendar(calendar),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'rename') {
                          _renameCalendar(calendar);
                        } else if (value == 'delete') {
                          _deleteCalendar(calendar);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'rename',
                          child: Text('Rename'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Calendar'),
                onPressed: _addCalendar,
              ),
            ),
          ],
        ),
      ),
      body: CalendarPage(calendar: _selectedCalendar),
    );
  }
}

class CalendarPage extends StatefulWidget {
  final Calendar calendar;

  const CalendarPage({super.key, required this.calendar});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final ImagePicker _picker = ImagePicker();
  Map<String, File> get _photos => widget.calendar.photos;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    scheduleDailyReminder(); // schedule with default time
  }

  Future<Directory> _getCalendarDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final calendarDir = Directory('${dir.path}/calendars/${widget.calendar.id}');
    if (!await calendarDir.exists()) {
      await calendarDir.create(recursive: true);
    }
    return calendarDir;
  }

  Future<void> _loadPhotos() async {
    final calendarDir = await _getCalendarDirectory();
    final files = calendarDir.listSync();
    final Map<String, File> loadedPhotos = {};
    for (var file in files) {
      if (file is File && file.path.endsWith(".jpg")) {
        final name = file.uri.pathSegments.last.split('.').first;
        loadedPhotos[name] = file;
      }
    }
    setState(() {
      _photos.clear();
      _photos.addAll(loadedPhotos);
    });
  }

  /// Save photo to the calendar-specific directory.
  Future<void> _savePhoto(DateTime date, File file) async {
    final calendarDir = await _getCalendarDirectory();
    final fileName = DateFormat('yyyy-MM-dd').format(date) + '.jpg';
    final newFile = File('${calendarDir.path}/$fileName');

    if (_photos.containsKey(fileName.split('.').first)) {
      await _photos[fileName.split('.').first]!.delete();
    }

    final savedImage = await file.copy(newFile.path);

    setState(() {
      _photos[fileName.split('.').first] = savedImage;
    });
  }

  Future<void> _takePhoto(DateTime date) async {
    if (date.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot add a photo for a future date.')),
      );
      return;
    }
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      await _savePhoto(date, File(pickedFile.path));
    }
  }

  Future<void> _uploadFromGallery(DateTime date) async {
    if (date.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot add a photo for a future date.')),
      );
      return;
    }
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      await _savePhoto(date, File(pickedFile.path));
    }
  }

  void _openGallery(DateTime date) {
    if (date.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot add a photo for a future date.')),
      );
      return;
    }
    final key = DateFormat('yyyy-MM-dd').format(date);
    final photo = _photos[key];
    if (photo != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoGallery(
            initialPhotoKey: key,
            photos: _photos,
            onDelete: (photoKey) async {
              final file = _photos[photoKey];
              if (file != null && await file.exists()) {
                await file.delete();
              }
              setState(() {
                _photos.remove(photoKey);
              });
            },
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
    final calendarDir = await _getCalendarDirectory();
    final zipPath = '${calendarDir.path}/everyday_lilly.zip';

    final encoder = ZipFileEncoder();
    encoder.create(zipPath);

    final keys = _photos.keys.toList()..sort();
    for (final key in keys) {
      final file = _photos[key]!;
      encoder.addFile(file);
    }

    encoder.close();

    Share.shareXFiles([XFile(zipPath)], text: 'My ${widget.calendar.name} time-lapse photos');
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.calendar.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            tooltip: 'Upload from Gallery',
            onPressed: () => _uploadFromGallery(now),
          ),
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
  final Function(String) onDelete;

  const PhotoGallery({
    super.key,
    required this.photos,
    required this.initialPhotoKey,
    required this.onDelete,
  });

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

  void _deletePhoto(int index) {
    final key = keys[index];
    widget.onDelete(key);
    setState(() {
      keys.removeAt(index);
    });
    if (keys.isEmpty) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lilly Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final key = keys[_controller.page!.round()];
              final file = widget.photos[key];
              if (file != null) Share.shareXFiles([XFile(file.path)]);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              final index = _controller.page!.round();
              _deletePhoto(index);
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final photo = widget.photos[keys[index]];
          if (photo == null) return const Center(child: Text('Photo missing'));
          return Center(child: Image.file(photo, fit: BoxFit.contain));
        },
      ),
    );
  }
}
