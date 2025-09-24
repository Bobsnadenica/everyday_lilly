import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:archive/archive_io.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

import '../models/calendar.dart';
import '../services/notifications.dart';
import 'photo_gallery.dart';

class CalendarPage extends StatefulWidget {
  final Calendar calendar;
  const CalendarPage({super.key, required this.calendar});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final ImagePicker _picker = ImagePicker();
  late final PageController _pageController;

  Map<String, File> get _photos => widget.calendar.photos;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: DateTime.now().month - 1);
    _loadPhotos();
    scheduleDailyReminder();
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

  void _openDayActions(DateTime date) {
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
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto(date);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Upload from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadFromGallery(date);
                  },
                ),
              ],
            ),
          );
        },
      );
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

    Share.shareXFiles(
      [XFile(zipPath)],
      text: 'My ${widget.calendar.name} time-lapse photos',
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.calendar.name),
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
        controller: _pageController,
        itemCount: 12,
        itemBuilder: (context, monthIndex) {
          final monthDate = DateTime(now.year, monthIndex + 1, 1);
          final daysInMonth = DateUtils.getDaysInMonth(now.year, monthIndex + 1);
          final weekdayOffset = monthDate.weekday - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  DateFormat('MMMM yyyy').format(monthDate),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      onTap: () => _openDayActions(date),
                      child: Container(
                        decoration: BoxDecoration(
                          color: photo != null ? Colors.green.shade100 : Colors.white,
                          border: Border.all(color: Colors.green.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            if (photo != null)
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(photo, fit: BoxFit.cover),
                                ),
                              ),
                            Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white70,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$day',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
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