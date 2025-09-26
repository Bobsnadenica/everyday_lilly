import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  final String calendarId;
  StorageService(this.calendarId);

  String _safeId(String id) => id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

  Future<Directory> getCalendarDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final calendarDir = Directory('${dir.path}/calendars/${_safeId(calendarId)}');
    if (!await calendarDir.exists()) {
      await calendarDir.create(recursive: true);
    }
    return calendarDir;
  }

  Future<File> _notesFile() async {
    final dir = await getCalendarDirectory();
    return File('${dir.path}/notes.json');
  }

  static String keyFor(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<Map<String, File>> loadPhotos() async {
    final dir = await getCalendarDirectory();
    final Map<String, File> photos = {};
    if (await dir.exists()) {
      for (final entity in dir.listSync()) {
        if (entity is File && entity.path.endsWith('.jpg')) {
          final name = entity.uri.pathSegments.last.split('.').first;
          photos[name] = entity;
        }
      }
    }
    return photos;
  }

  Future<Map<String, String>> loadNotes() async {
    final f = await _notesFile();
    if (!await f.exists()) return {};
    try {
      final json = jsonDecode(await f.readAsString());
      return Map<String, String>.from(json.map((k, v) => MapEntry(k, v.toString())));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveNotes(Map<String, String> notes) async {
    final f = await _notesFile();
    await f.writeAsString(jsonEncode(notes));
  }

  Future<File> savePhotoFile(DateTime date, File source) async {
    final dir = await getCalendarDirectory();
    final key = keyFor(date);
    final dest = File('${dir.path}/$key.jpg');
    if (await dest.exists()) await dest.delete();
    return source.copy(dest.path);
  }

  Future<void> deletePhoto(String key) async {
    final dir = await getCalendarDirectory();
    final f = File('${dir.path}/$key.jpg');
    if (await f.exists()) await f.delete();
  }
}