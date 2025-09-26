import 'dart:io';
import 'dart:math';
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
import '../pages/front_page.dart';

class CalendarPage extends StatefulWidget {
  final Calendar calendar;
  const CalendarPage({super.key, required this.calendar});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<String> _quotes = [];
  String? _todaysQuote;
  String _getBackgroundForTime() {
    final hour = DateTime.now().hour;
    final random = Random();
    final List<String> morning = List.generate(12, (i) => 'morning${i + 1}.jpg');
    final List<String> afternoon = List.generate(12, (i) => 'afternoon${i + 1}.jpg');
    final List<String> evening = List.generate(12, (i) => 'evening${i + 1}.jpg');
    final List<String> night = List.generate(12, (i) => 'night${i + 1}.jpg');

    if (hour >= 6 && hour < 12) {
      return 'assets/backgrounds/morning/${morning[random.nextInt(morning.length)]}';
    } else if (hour >= 12 && hour < 18) {
      return 'assets/backgrounds/afternoon/${afternoon[random.nextInt(afternoon.length)]}';
    } else if (hour >= 18 && hour < 20) {
      return 'assets/backgrounds/evening/${evening[random.nextInt(evening.length)]}';
    } else {
      return 'assets/backgrounds/night/${night[random.nextInt(night.length)]}';
    }
  }
  final ImagePicker _picker = ImagePicker();
  late final PageController _pageController;

  late String _backgroundPath;

  final Map<String, File> _photos = {};
  final Map<String, String> _notes = {};
  late int _currentYear;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: DateTime.now().month - 1);
    _currentYear = DateTime.now().year;
    _backgroundPath = _getBackgroundForTime();
    _ensureCalendarDirectory();
    _loadPhotos();
    _loadQuotes();
    scheduleDailyReminder();
  }

  Future<void> _ensureCalendarDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final safeId = widget.calendar.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final calendarDir = Directory('${dir.path}/calendars/$safeId');
    if (!await calendarDir.exists()) {
      await calendarDir.create(recursive: true);
    }
  }

  Future<void> _loadQuotes() async {
    try {
      final data = await rootBundle.loadString('assets/quotes/motivational_quotes.txt');
      final allQuotes = data.split('\n').where((line) => line.trim().isNotEmpty).toList();
      if (allQuotes.isNotEmpty) {
        setState(() {
          _quotes = allQuotes;
          final random = Random();
          _todaysQuote = _quotes[random.nextInt(_quotes.length)];
        });
      }
    } catch (e) {
      debugPrint('Error loading quotes: $e');
    }
  }

  @override
  void didUpdateWidget(covariant CalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.calendar.id != widget.calendar.id) {
      setState(() {
        _photos.clear();
        _notes.clear();
      });
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
      final notesFile = await _getNotesFile();
      if (await notesFile.exists()) {
        try {
          final notesContent = await notesFile.readAsString();
          final Map<String, dynamic> json = jsonDecode(notesContent);
          _notes.addAll(json.map((key, value) => MapEntry(key, value.toString())));
        } catch (_) {
          _notes.clear();
        }
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
      final key = DateFormat('yyyy-MM-dd').format(date);
      final fileName = '$key.jpg';
      final newFile = File('${calendarDir.path}/$fileName');

      if (_photos.containsKey(key)) {
        await _photos[key]!.delete();
      }

      final savedImage = await file.copy(newFile.path);

      setState(() {
        _photos[key] = savedImage;
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
      const channel = MethodChannel('everyday_lilly/timelapse');
      final tempDir = await getTemporaryDirectory();
      final outputMp4 = '${tempDir.path}/timelapse.mp4';

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
      Navigator.of(context, rootNavigator: true).pop();
      if (!mounted) return;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBackground(isDark),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: PageView.builder(
                controller: _pageController,
                itemCount: 12,
                itemBuilder: (context, monthIndex) {
                  return _buildMonthView(monthIndex, now);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the background layers for the calendar page.
  Widget _buildBackground(bool isDark) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            _backgroundPath,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [Colors.black.withOpacity(0.55), Colors.black.withOpacity(0.15)]
                    : [Colors.black.withOpacity(0.35), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the AppBar for the calendar page.
  AppBar _buildAppBar() {
    return AppBar(
      title: const SizedBox.shrink(),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Go to Front Page',
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const FrontPage()),
              (Route<dynamic> route) => false,
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _currentYear--;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            setState(() {
              _currentYear++;
            });
          },
        ),
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
    );
  }

  /// Builds the month grid view for the given month index and current date.
  Widget _buildMonthView(int monthIndex, DateTime now) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthDate = DateTime(_currentYear, monthIndex + 1, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_currentYear, monthIndex + 1);
    final weekdayOffset = monthDate.weekday - 1;
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.5)
                  : Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              DateFormat('MMMM yyyy').format(monthDate),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _WeekdayLabel('Mon'),
              _WeekdayLabel('Tue'),
              _WeekdayLabel('Wed'),
              _WeekdayLabel('Thu'),
              _WeekdayLabel('Fri'),
              _WeekdayLabel('Sat'),
              _WeekdayLabel('Sun'),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: daysInMonth + weekdayOffset,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < weekdayOffset) return const SizedBox.shrink();
              final day = index - weekdayOffset + 1;
              final date = DateTime(_currentYear, monthIndex + 1, day);
              final key = DateFormat('yyyy-MM-dd').format(date);
              final photo = _photos[key];
              final hasNote = _notes.containsKey(key);
              final isFuture = date.isAfter(now);
              final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
              return GestureDetector(
                onTap: () {
                  if (isFuture) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You cannot add a photo for a future date.')),
                    );
                    return;
                  }
                  _openDayActions(date);
                },
                onLongPress: () {
                  if (!isFuture) _addOrEditNote(date);
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: photo != null
                        ? Colors.transparent
                        : (isFuture
                            ? (isDark
                                ? Colors.red.withOpacity(0.2)
                                : Colors.red.withOpacity(0.3))
                            : (isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.white.withOpacity(0.85))),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: isToday
                        ? Border.all(
                            color: Theme.of(context).colorScheme.secondary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Stack(
                    children: [
                      if (photo != null)
                        Positioned.fill(
                          child: ClipOval(
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
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: photo != null
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black87),
                              shadows: photo != null
                                  ? [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black.withOpacity(0.7),
                                        offset: const Offset(1, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      if (hasNote)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 3,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(
                              Icons.note,
                              size: 20,
                              color: Colors.white,
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
        if (_todaysQuote != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(seconds: 2),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _todaysQuote!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;
  const _WeekdayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}