import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AchievementService {
  // Keys for SharedPreferences
  static const _photosTakenKey = 'photos_taken';
  static const _daysWithPhotosKey = 'days_with_photos';
  static const _daysWithPhotosLastDateKey = 'days_with_photos_last_date';
  static const _notesAddedKey = 'notes_added';
  static const _daysWithNotesKey = 'days_with_notes';
  static const _daysWithNotesLastDateKey = 'days_with_notes_last_date';
  static const _backupsExportedKey = 'backups_exported';
  static const _photosSharedKey = 'photos_shared';
  static const _calendarsCreatedKey = 'calendars_created';

  /// Returns the number of photos taken.
  static Future<int> getPhotosTaken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_photosTakenKey) ?? 0;
  }

  /// Increments the number of photos taken by 1.
  static Future<void> incrementPhotosTaken() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_photosTakenKey) ?? 0;
    await prefs.setInt(_photosTakenKey, current + 1);
  }

  /// Returns the number of days with photos added.
  static Future<int> getDaysWithPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_daysWithPhotosKey) ?? 0;
  }

  /// Increments the number of unique days with photos added by 1 if today hasn't been counted yet.
  static Future<void> incrementDaysWithPhotosIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = prefs.getString(_daysWithPhotosLastDateKey);
    if (lastDate != today) {
      final current = prefs.getInt(_daysWithPhotosKey) ?? 0;
      await prefs.setInt(_daysWithPhotosKey, current + 1);
      await prefs.setString(_daysWithPhotosLastDateKey, today);
    }
  }

  /// Returns the number of notes added.
  static Future<int> getNotesAdded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_notesAddedKey) ?? 0;
  }

  /// Increments the number of notes added by 1.
  static Future<void> incrementNotesAdded() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_notesAddedKey) ?? 0;
    await prefs.setInt(_notesAddedKey, current + 1);
  }

  /// Returns the number of unique days with notes added.
  static Future<int> getDaysWithNotes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_daysWithNotesKey) ?? 0;
  }

  /// Increments the number of unique days with notes added by 1 if today hasn't been counted yet.
  static Future<void> incrementDaysWithNotesIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = prefs.getString(_daysWithNotesLastDateKey);
    if (lastDate != today) {
      final current = prefs.getInt(_daysWithNotesKey) ?? 0;
      await prefs.setInt(_daysWithNotesKey, current + 1);
      await prefs.setString(_daysWithNotesLastDateKey, today);
    }
  }

  /// Returns the number of backups exported.
  static Future<int> getBackupsExported() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_backupsExportedKey) ?? 0;
  }

  /// Increments the number of backups exported by 1.
  static Future<void> incrementBackupsExported() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_backupsExportedKey) ?? 0;
    await prefs.setInt(_backupsExportedKey, current + 1);
  }

  /// Returns the number of photos shared.
  static Future<int> getPhotosShared() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_photosSharedKey) ?? 0;
  }

  /// Increments the number of photos shared by 1.
  static Future<void> incrementPhotosShared() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_photosSharedKey) ?? 0;
    await prefs.setInt(_photosSharedKey, current + 1);
  }

  /// Returns the number of calendars created.
  static Future<int> getCalendarsCreated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_calendarsCreatedKey) ?? 0;
  }

  /// Increments the number of calendars created by 1.
  static Future<void> incrementCalendarsCreated() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_calendarsCreatedKey) ?? 0;
    await prefs.setInt(_calendarsCreatedKey, current + 1);
  }

  /// Returns a map of all tracked stats for debugging or syncing.
  static Future<Map<String, int>> getAllStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      _photosTakenKey: prefs.getInt(_photosTakenKey) ?? 0,
      _daysWithPhotosKey: prefs.getInt(_daysWithPhotosKey) ?? 0,
      _notesAddedKey: prefs.getInt(_notesAddedKey) ?? 0,
      _daysWithNotesKey: prefs.getInt(_daysWithNotesKey) ?? 0,
      _backupsExportedKey: prefs.getInt(_backupsExportedKey) ?? 0,
      _photosSharedKey: prefs.getInt(_photosSharedKey) ?? 0,
      _calendarsCreatedKey: prefs.getInt(_calendarsCreatedKey) ?? 0,
    };
  }

  /// Resets all achievement progress to 0.
  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_photosTakenKey, 0);
    await prefs.setInt(_daysWithPhotosKey, 0);
    await prefs.setInt(_notesAddedKey, 0);
    await prefs.setInt(_daysWithNotesKey, 0);
    await prefs.setInt(_backupsExportedKey, 0);
    await prefs.setInt(_photosSharedKey, 0);
    await prefs.setInt(_calendarsCreatedKey, 0);
    await prefs.remove(_daysWithPhotosLastDateKey);
    await prefs.remove(_daysWithNotesLastDateKey);
  }

  /// Public method to record a photo taken, updating both photo count and unique days with photos.
  static Future<void> recordPhotoTaken() async {
    await incrementPhotosTaken();
    await incrementDaysWithPhotosIfNeeded();
  }

  /// Public method to record a note added, updating both note count and unique days with notes.
  static Future<void> recordNoteAdded() async {
    await incrementNotesAdded();
    await incrementDaysWithNotesIfNeeded();
  }
}