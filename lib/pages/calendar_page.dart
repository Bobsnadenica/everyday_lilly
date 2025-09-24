import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:archive/archive_io.dart';

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

  final Map<String, File> _photos = {};
  final Map<String, String> _notes = {};
  late int _currentYear;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: DateTime.now().month - 1);
    _currentYear = widget.calendar.year;
    _loadPhotos();
    scheduleDailyReminder();
  }

  @override
  void didUpdateWidget(covariant CalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.calendar.id != widget.calendar.id) {
      _photos.clear();
      _notes.clear();
      setState(() {}); // refresh UI when switching
      _loadPhotos();
    }
  }

  Future<Directory> _getCalendarDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final safeId = widget.calendar.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final calendarDir = Directory('${dir.path}/calendars/$safeId');
    if (!await calendarDir.exists()) {
      await calendarDir.create(recursive: true);
    }
    return calendarDir;
  }

  Future<File> _getNotesFile() async {
    final dir = await _getCalendarDirectory();
    return File('${dir.path}/notes.json');
  }

  Future<void> _loadPhotos() async {
    try {
      _photos.clear();
      _notes.clear();
      final calendarDir = await _getCalendarDirectory();
      final files = calendarDir.listSync();
      final Map<String, File> loadedPhotos = {};
      for (var file in files) {
        if (file is File && file.path.endsWith(".jpg")) {
          final name = file.uri.pathSegments.last.split('.').first;
          loadedPhotos[name] = file;
        }
      }
      // Load notes from notes.json
      final notesFile = await _getNotesFile();
      if (await notesFile.exists()) {
        try {
          final notesContent = await notesFile.readAsString();
          final Map<String, dynamic> json = jsonDecode(notesContent);
          _notes.addAll(json.map((key, value) => MapEntry(key, value.toString())));
        } catch (_) {
          // Corrupt notes.json — reset to empty to avoid crashing and re-save next write
          _notes.clear();
        }
      }
      if (loadedPhotos.isEmpty) {
        debugPrint('No photos found for calendar ${widget.calendar.name}');
      }
      if (!mounted) return;
      setState(() {
        _photos.addAll(loadedPhotos);
      });
    } catch (e) {
      debugPrint('Error loading photos: $e');
    }
  }

  Future<void> _saveNotes() async {
    try {
      final notesFile = await _getNotesFile();
      await notesFile.writeAsString(jsonEncode(_notes));
    } catch (e) {
      debugPrint('Error saving notes: $e');
    }
  }

  Future<void> _savePhoto(DateTime date, File file) async {
    try {
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
    } catch (e) {
      debugPrint('Error saving photo: $e');
    }
  }
  Future<void> _exportBackupZip() async {
    try {
      final calendarDir = await _getCalendarDirectory();
      final encoder = ZipFileEncoder();
      final tempDir = await getTemporaryDirectory();
      final zipPath = '${tempDir.path}/${widget.calendar.name}_backup.zip';
      encoder.create(zipPath);
      calendarDir.listSync(recursive: true).forEach((entity) {
        if (entity is File) {
          encoder.addFile(entity);
        }
      });
      encoder.close();
      await Share.shareXFiles([XFile(zipPath)], text: 'Backup of ${widget.calendar.name}');
    } catch (e) {
      debugPrint('Backup export failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create backup.')),
      );
    }
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
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => PhotoGallery(
            initialPhotoKey: key,
            photos: _photos,
            notes: _notes,
            onDelete: (photoKey) async {
              final file = _photos[photoKey];
              if (file != null && await file.exists()) {
                await file.delete();
              }
              setState(() {
                _photos.remove(photoKey);
                _notes.remove(photoKey);
              });
              await _saveNotes();
            },
            onNoteChanged: (photoKey, newNote) async {
              setState(() {
                if (newNote == null || newNote.isEmpty) {
                  _notes.remove(photoKey);
                } else {
                  _notes[photoKey] = newNote;
                }
              });
              await _saveNotes();
            },
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
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
                ListTile(
                  leading: const Icon(Icons.edit_note),
                  title: const Text('Add/Edit Note'),
                  onTap: () {
                    Navigator.pop(context);
                    _addOrEditNote(date);
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<void> _addOrEditNote(DateTime date) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final TextEditingController controller = TextEditingController(text: _notes[key] ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add/Edit Note'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Enter your note here',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final noteText = controller.text.trim();
                setState(() {
                  if (noteText.isEmpty) {
                    _notes.remove(key);
                  } else {
                    _notes[key] = noteText;
                  }
                });
                await _saveNotes();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
    DateTime? startDate;
    DateTime? endDate;
    double playbackSpeed = 1.0;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Export Time-Lapse'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Start Date: ${startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : 'Not selected'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            startDate = picked;
                            if (endDate != null && endDate!.isBefore(startDate!)) {
                              endDate = startDate;
                            }
                          });
                        }
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('End Date: ${endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : 'Not selected'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: startDate ?? DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            endDate = picked;
                            if (startDate != null && startDate!.isAfter(endDate!)) {
                              startDate = endDate;
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Playback Speed (sec/photo): '),
                      const SizedBox(width: 8),
                      DropdownButton<double>(
                        value: playbackSpeed,
                        items: const [
                          DropdownMenuItem(value: 0.5, child: Text('0.5')),
                          DropdownMenuItem(value: 1.0, child: Text('1.0')),
                          DropdownMenuItem(value: 2.0, child: Text('2.0')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() {
                              playbackSpeed = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (startDate == null || endDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select both start and end dates.')),
                    );
                    return;
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Export'),
              ),
            ],
          );
        });
      },
    );

    if (startDate == null || endDate == null) {
      return;
    }

    // Filter photos by date range
    final filteredKeys = _photos.keys.where((key) {
      final photoDate = DateTime.tryParse(key);
      if (photoDate == null) return false;
      return !photoDate.isBefore(startDate!) && !photoDate.isAfter(endDate!);
    }).toList()
      ..sort();

    if (filteredKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photos found in the selected date range.')),
      );
      return;
    }

    try {
      final calendarDir = await _getCalendarDirectory();

      // Prepare temp_frames directory
      final tempFramesDir = Directory('${calendarDir.path}/temp_frames');
      if (await tempFramesDir.exists()) {
        await tempFramesDir.delete(recursive: true);
      }
      await tempFramesDir.create(recursive: true);

      // Copy photos into temp_frames as frame_0001.jpg, frame_0002.jpg, ... and collect their paths
      final framePaths = <String>[];
      int i = 1;
      for (final key in filteredKeys) {
        final src = _photos[key]!;
        final dst = File('${tempFramesDir.path}/frame_${i.toString().padLeft(4, '0')}.jpg');
        if (await dst.exists()) await dst.delete();
        await src.copy(dst.path);
        framePaths.add(dst.path);
        i++;
      }
      print('About to call native encoder with ${framePaths.length} frames');
      // Debug print the generated frame paths
      print('Generated frame paths:');
      for (final path in framePaths) {
        print(path);
      }
      const channel = MethodChannel('everyday_lilly/timelapse');
      final tempDir = await getTemporaryDirectory();
      final outputMp4 = '${tempDir.path}/timelapse.mp4';

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Generating video...'),
              ],
            ),
          );
        },
      );

      String? resultPath;
      try {
        resultPath = await channel.invokeMethod<String>('generateTimelapse', {
          'imagePaths': framePaths,
          'outputPath': outputMp4,
          'fps': 1.0 / playbackSpeed,
          'width': 1080,
          'height': 1920,
        });
      } catch (e) {
        resultPath = null;
      }
      // Dismiss loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      if (resultPath != null) {
        await Share.shareXFiles(
          [XFile(resultPath)],
          text: 'My ${widget.calendar.name} time-lapse video...',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate time-lapse video.')),
        );
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unexpected error generating video.')),
      );
      debugPrint('Timelapse error: $e');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.calendar.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reminder':
                  _pickReminderTime();
                  break;
                case 'timelapse':
                  _exportTimeLapse();
                  break;
                case 'backup':
                  _exportBackupZip();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'reminder',
                child: Row(
                  children: const [
                    Icon(Icons.access_time, size: 20),
                    SizedBox(width: 8),
                    Text('Reminder'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'timelapse',
                child: Row(
                  children: const [
                    Icon(Icons.movie, size: 20),
                    SizedBox(width: 8),
                    Text('Export Timelapse'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'backup',
                child: Row(
                  children: const [
                    Icon(Icons.backup, size: 20),
                    SizedBox(width: 8),
                    Text('Backup'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FFF8), Color(0xFFE8F5E9)],
          ),
        ),
        child: PageView.builder(
          controller: _pageController,
          itemCount: 12,
          itemBuilder: (context, monthIndex) {
            final monthDate = DateTime(_currentYear, monthIndex + 1, 1);
            final daysInMonth = DateUtils.getDaysInMonth(_currentYear, monthIndex + 1);
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
                      final date = DateTime(_currentYear, monthIndex + 1, day);
                      final key = DateFormat('yyyy-MM-dd').format(date);
                      final photo = _photos[key];
                      final hasNote = _notes.containsKey(key);
                      final isFuture = date.isAfter(DateTime.now());

                      return GestureDetector(
                        onTap: () {
                          if (isFuture) return;
                          _openDayActions(date);
                        },
                        onLongPress: () {
                          if (!isFuture) _addOrEditNote(date);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isFuture
                                ? Colors.grey.shade300
                                : photo != null
                                    ? Colors.green.shade100
                                    : Colors.white,
                            border: Border.all(color: Colors.green.shade400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              if (photo != null)
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      photo,
                                      fit: BoxFit.cover,
                                      cacheWidth: 300,
                                      cacheHeight: 300,
                                    ),
                                  ),
                                ),
                              Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.black54 : Colors.white70,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$day',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              if (hasNote)
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.black54 : Colors.white70,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: Icon(
                                      Icons.note,
                                      size: 20,
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
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
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'jump_today',
            backgroundColor: Colors.green,
            child: const Icon(Icons.today),
            onPressed: () {
              _pageController.jumpToPage(DateTime.now().month - 1);
            },
          ),
        ],
      ),
    );
  }
}