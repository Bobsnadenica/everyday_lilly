import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:everyday_lilly/services/achievement_service.dart';

import '../../models/calendar.dart';
import '../../services/storage_service.dart';
import '../../services/backup_service.dart';
import '../../services/timelapse_service.dart';
import '../../services/notifications.dart';
import '../front_page.dart';
import '../photo_gallery.dart';
import 'package:everyday_lilly/pages/achievements/achievements_page.dart';
import 'calendar_appbar.dart';
import 'background_layer.dart';
import 'month_view.dart';

class CalendarPage extends StatefulWidget {
  final Calendar calendar;
  const CalendarPage({super.key, required this.calendar});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const String _savedReminderKey = 'saved_reminder_time';

  late final PageController _pageController;
  late int _currentYear;
  late String _backgroundPath;

  late StorageService _storage;
  late BackupService _backup;
  final TimelapseService _timelapse = TimelapseService();

  final ImagePicker _picker = ImagePicker();

  final Map<String, File> _photos = {};
  final Map<String, String> _notes = {};
  List<String> _quotes = [];
  String? _todaysQuote;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: DateTime.now().month - 1);
    _currentYear = DateTime.now().year;
    _backgroundPath = getBackgroundForTime();

    _storage = StorageService(widget.calendar.id);
    _backup = BackupService(getCalendarDirectory: _storage.getCalendarDirectory);

    _loadAll();
    _loadSavedReminder();
  }

  Future<void> _loadSavedReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTimeStr = prefs.getString(_savedReminderKey);
    if (savedTimeStr != null) {
      final parts = savedTimeStr.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          final savedTime = TimeOfDay(hour: hour, minute: minute);
          await scheduleDailyReminder(time: savedTime);
        }
      }
    }
  }

  Future<void> _loadAll() async {
    final photos = await _storage.loadPhotos();
    final notes = await _storage.loadNotes();
    await _loadQuotes();

    if (!mounted) return;
    setState(() {
      _photos
        ..clear()
        ..addAll(photos);
      _notes
        ..clear()
        ..addAll(notes);
    });
  }

  Future<void> _loadQuotes() async {
    try {
      final bundle = rootBundle;
      final data = await bundle.loadString('assets/quotes/motivational_quotes.txt');
      final all = data.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (all.isNotEmpty) {
        final rnd = Random();
        _quotes = all;
        _todaysQuote = _quotes[rnd.nextInt(_quotes.length)];
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant CalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.calendar.id != widget.calendar.id) {
      _storage = StorageService(widget.calendar.id);
      _backup = BackupService(getCalendarDirectory: _storage.getCalendarDirectory);
      _loadAll();
    }
  }

  void _changeYear(bool forward) => setState(() => _currentYear += forward ? 1 : -1);

  Future<void> _takePhoto(DateTime date) async {
    if (date.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot add a photo for a future date.')),
      );
      return;
    }
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      final saved = await _storage.savePhotoFile(date, File(picked.path));
      await AchievementService.recordPhotoTaken();
      final key = StorageService.keyFor(date);
      setState(() => _photos[key] = saved);
    }
  }

  Future<void> _uploadFromGallery(DateTime date) async {
    if (date.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot add a photo for a future date.')),
      );
      return;
    }
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final saved = await _storage.savePhotoFile(date, File(picked.path));
      await AchievementService.recordPhotoTaken();
      final key = StorageService.keyFor(date);
      setState(() => _photos[key] = saved);
    }
  }

  Future<void> _addOrEditNote(DateTime date) async {
    final key = StorageService.keyFor(date);
    final controller = TextEditingController(text: _notes[key] ?? '');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add/Edit Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(hintText: 'Enter your note here'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final note = controller.text.trim();
              setState(() {
                if (note.isEmpty) {
                  _notes.remove(key);
                } else {
                  _notes[key] = note;
                }
              });
              await _storage.saveNotes(_notes);
// ✅ Track note achievement
if (note.isNotEmpty) {
  await AchievementService.recordNoteAdded();
}

if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _openDayActions(DateTime date) {
    final key = StorageService.keyFor(date);
    final photo = _photos[key];
    if (date.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot add a photo for a future date.')),
      );
      return;
    }

    if (photo != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => PhotoGallery(
            initialPhotoKey: key,
            photos: _photos,
            notes: _notes,
            onDelete: (photoKey) async {
              await _storage.deletePhoto(photoKey);
              setState(() {
                _photos.remove(photoKey);
                _notes.remove(photoKey);
              });
              await _storage.saveNotes(_notes);
            },
            onNoteChanged: (photoKey, newNote) async {
              setState(() {
                if (newNote == null || newNote.isEmpty) {
                  _notes.remove(photoKey);
                } else {
                  _notes[photoKey] = newNote;
                }
              });
              await _storage.saveNotes(_notes);
            },
          ),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Take Photo'), onTap: () {
                Navigator.pop(context);
                _takePhoto(date);
              }),
              ListTile(leading: const Icon(Icons.photo_library), title: const Text('Upload from Gallery'), onTap: () {
                Navigator.pop(context);
                _uploadFromGallery(date);
              }),
              ListTile(leading: const Icon(Icons.edit_note), title: const Text('Add/Edit Note'), onTap: () {
                Navigator.pop(context);
                _addOrEditNote(date);
              }),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _pickReminderTime() async {
    final time = await showTimePicker(context: context, initialTime: reminderTime);
    if (time != null) {
      // Schedule the reminder first
      await scheduleDailyReminder(time: time);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedReminderKey, '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder set for ${time.format(context)}')),
      );
    }
  }

  Future<void> _exportBackupZip() async {
    await _backup.exportBackupZip(context, widget.calendar.name);
  }

  Future<void> _exportTimeLapse() async {
    DateTime? startDate;
    DateTime? endDate;
    double playbackSpeed = 1.0;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
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
                        context: ctx,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setStateDialog(() {
                          startDate = picked;
                          if (endDate != null && endDate!.isBefore(startDate!)) endDate = startDate;
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
                        context: ctx,
                        initialDate: endDate ?? DateTime.now(),
                        firstDate: startDate ?? DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setStateDialog(() {
                          endDate = picked;
                          if (startDate != null && startDate!.isAfter(endDate!)) startDate = endDate;
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
                      onChanged: (v) => setStateDialog(() => playbackSpeed = v!),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (startDate == null || endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select both start and end dates.')),
                  );
                  return;
                }
                Navigator.pop(ctx);
              },
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );

    if (startDate == null || endDate == null) return;

    final filteredKeys = _photos.keys.where((key) {
      final d = DateTime.tryParse(key);
      return d != null && !d.isBefore(startDate!) && !d.isAfter(endDate!);
    }).toList()
      ..sort();

    if (filteredKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photos found in the selected date range.')),
      );
      return;
    }

    final ordered = filteredKeys.map((k) => _photos[k]!).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Generating video...')]),
      ),
    );

    final path = await _timelapse.generateFromFiles(ordered, fps: 1.0 / playbackSpeed);
    if (mounted) Navigator.of(context, rootNavigator: true).pop();

    if (path != null) {
      await Share.shareXFiles([XFile(path)], text: 'My ${widget.calendar.name} time-lapse video...');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate time-lapse video.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CalendarAppBar(
        calendarId: widget.calendar.id,
        onHome: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const FrontPage()),
            (route) => false,
          );
        },
        onBackYear: () => _changeYear(false),
        onForwardYear: () => _changeYear(true),
        onReminder: _pickReminderTime,
        onTimelapse: _exportTimeLapse,
        onBackup: _exportBackupZip,
        onAchievements: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AchievementsPage()),
          );
        },
      ),
      body: Stack(
        children: [
          BackgroundLayer(backgroundPath: _backgroundPath, isDark: isDark),
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 50),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: 12,
                      itemBuilder: (_, monthIndex) => MonthView(
                        currentYear: _currentYear,
                        monthIndex: monthIndex,
                        now: now,
                        calendar: widget.calendar,
                        photos: _photos,
                        notes: _notes,
                        onOpenDay: _openDayActions,
                        onEditNote: _addOrEditNote,
                        todaysQuote: _todaysQuote,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}