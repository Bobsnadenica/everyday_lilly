import 'dart:io';

class Calendar {
  /// Unique identifier for the calendar (e.g., a UUID)
  final String id;

  /// Human-readable name (e.g., "Everyday Lilly")
  final String name;

  /// The target year this calendar tracks
  final int year;

  /// Photos stored as a map of date keys (YYYY-MM-DD) -> absolute file path
  /// Using String paths instead of File objects makes the model JSON-serializable
  /// and avoids platform-specific issues during (de)serialization.
  final Map<String, String> photos;

  /// Optional notes per date: date key (YYYY-MM-DD) -> text
  final Map<String, String> notes;

  Calendar({
    required this.id,
    required String name,
    required this.year,
    Map<String, String>? photos,
    Map<String, String>? notes,
  })  : name = name.trim(),
        photos = Map.unmodifiable({...?photos}),
        notes = Map.unmodifiable({...?notes}) {
    assert(this.name.isNotEmpty, 'Calendar name cannot be empty');
    assert(year >= 1970 && year <= 2100, 'Year must be in a reasonable range (1970–2100)');
  }

  /// Create a copy with selective overrides
  Calendar copyWith({
    String? id,
    String? name,
    int? year,
    Map<String, String>? photos,
    Map<String, String>? notes,
  }) {
    return Calendar(
      id: id ?? this.id,
      name: (name ?? this.name).trim(),
      year: year ?? this.year,
      photos: photos ?? this.photos,
      notes: notes ?? this.notes,
    );
  }

  /// Serialize to JSON (fully serializable)
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'year': year,
        'photos': photos,
        'notes': notes,
      };

  /// Deserialize from JSON safely
  factory Calendar.fromJson(Map<String, dynamic> json) {
    final rawPhotos = (json['photos'] as Map?) ?? const {};
    final rawNotes = (json['notes'] as Map?) ?? const {};

    // Normalize dynamic maps to Map<String, String>
    final normalizedPhotos = <String, String>{};
    rawPhotos.forEach((k, v) {
      if (k != null && v != null) {
        normalizedPhotos[k.toString()] = v.toString();
      }
    });

    final normalizedNotes = <String, String>{};
    rawNotes.forEach((k, v) {
      if (k != null && v != null) {
        normalizedNotes[k.toString()] = v.toString();
      }
    });

    return Calendar(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      year: (json['year'] as int?) ?? DateTime.now().year,
      photos: normalizedPhotos,
      notes: normalizedNotes,
    );
  }

  // ---------- Convenience helpers ----------

  /// Standard date key used across the app (YYYY-MM-DD)
  static String dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final da = d.day.toString().padLeft(2, '0');
    return '$y-$m-$da';
  }

  /// Read helpers
  String? getPhotoPath(String key) => photos[key];
  String? getNote(String key) => notes[key];

  /// Mutating helpers return a new instance (immutability-friendly)
  Calendar setPhoto(String key, String absolutePath) {
    final updated = Map<String, String>.from(photos)..[key] = absolutePath;
    return copyWith(photos: updated);
  }

  Calendar removePhoto(String key) {
    if (!photos.containsKey(key)) return this;
    final updated = Map<String, String>.from(photos)..remove(key);
    return copyWith(photos: updated);
  }

  Calendar setNote(String key, String text) {
    final updated = Map<String, String>.from(notes)..[key] = text;
    return copyWith(notes: updated);
  }

  Calendar removeNote(String key) {
    if (!notes.containsKey(key)) return this;
    final updated = Map<String, String>.from(notes)..remove(key);
    return copyWith(notes: updated);
  }

  @override
  String toString() => 'Calendar(id: $id, name: $name, year: $year, photos: ${photos.length}, notes: ${notes.length})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Calendar &&
        other.id == id &&
        other.name == name &&
        other.year == year &&
        _mapEquals(other.photos, photos) &&
        _mapEquals(other.notes, notes);
  }

  @override
  int get hashCode => Object.hash(id, name, year, _deepMapHash(photos), _deepMapHash(notes));

  static bool _mapEquals(Map a, Map b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static int _deepMapHash(Map<String, String> m) {
    var h = 0;
    m.forEach((k, v) {
      h = h ^ Object.hash(k, v);
    });
    return h;
  }
}