import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageService {
  final String calendarId;
  StorageService(this.calendarId);

  String _safeId(String id) => id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

  Future<Directory> getCalendarDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'calendars', _safeId(calendarId)));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _notesFile() async {
    final dir = await getCalendarDirectory();
    return File(p.join(dir.path, 'notes.json'));
  }

  static String keyFor(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<Map<String, File>> loadPhotos() async {
    final dir = await getCalendarDirectory();
    final map = <String, File>{};
    if (!await dir.exists()) return map;
    await for (final e in dir.list(recursive: false, followLinks: false)) {
      if (e is File && p.extension(e.path).toLowerCase() == '.jpg') {
        map[p.basenameWithoutExtension(e.path)] = e;
      }
    }
    return map;
  }

  Future<List<String>> listPhotoKeysSorted() async {
    final photos = await loadPhotos();
    final keys = photos.keys.toList();
    keys.sort();
    return keys;
  }

  Future<Map<String, String>> loadNotes() async {
    final f = await _notesFile();
    if (!await f.exists()) return {};
    try {
      final data = await f.readAsString();
      final json = jsonDecode(data);
      return Map<String, String>.from(json.map((k, v) => MapEntry(k, v.toString())));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveNotes(Map<String, String> notes) async {
    final f = await _notesFile();
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(notes), flush: true);
    try {
      if (await f.exists()) await f.delete();
      await tmp.rename(f.path);
    } on FileSystemException {
      await f.writeAsString(jsonEncode(notes), flush: true);
      if (await tmp.exists()) await tmp.delete();
    }
  }

  Future<String?> getNoteFor(DateTime date) async {
    final notes = await loadNotes();
    return notes[keyFor(date)];
  }

  Future<void> saveNoteFor(DateTime date, String? text) async {
    final notes = await loadNotes();
    final k = keyFor(date);
    if (text == null || text.isEmpty) {
      notes.remove(k);
    } else {
      notes[k] = text;
    }
    await saveNotes(notes);
  }

  Future<File> photoFileFor(DateTime date) async {
    final dir = await getCalendarDirectory();
    return File(p.join(dir.path, '${keyFor(date)}.jpg'));
  }

  Future<bool> hasPhoto(DateTime date) async {
    final f = await photoFileFor(date);
    return f.exists();
  }

  Future<File> savePhotoFile(DateTime date, File source) async {
    final dir = await getCalendarDirectory();
    final key = keyFor(date);
    final dest = File(p.join(dir.path, '$key.jpg'));
    final tmp = File('${dest.path}.tmp');
    if (await tmp.exists()) await tmp.delete();
    await source.copy(tmp.path);
    if (await dest.exists()) await dest.delete();
    await tmp.rename(dest.path);
    return dest;
  }

  Future<File> savePhotoBytes(DateTime date, Uint8List bytes) async {
    final dest = await photoFileFor(date);
    final tmp = File('${dest.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    if (await dest.exists()) await dest.delete();
    await tmp.rename(dest.path);
    return dest;
  }

  Future<bool> deletePhoto(String key) async {
    final dir = await getCalendarDirectory();
    final f = File(p.join(dir.path, '$key.jpg'));
    if (await f.exists()) {
      await f.delete();
      return true;
    }
    return false;
  }

  Future<int> calendarSizeBytes() async {
    final dir = await getCalendarDirectory();
    var total = 0;
    await for (final e in dir.list(recursive: true, followLinks: false)) {
      if (e is File) total += await e.length();
    }
    return total;
  }

  Future<void> clearAll() async {
    final dir = await getCalendarDirectory();
    if (!await dir.exists()) return;
    await for (final e in dir.list(recursive: false, followLinks: false)) {
      try {
        if (e is File) {
          await e.delete();
        } else if (e is Directory) {
          await e.delete(recursive: true);
        }
      } catch (_) {}
    }
  }
}