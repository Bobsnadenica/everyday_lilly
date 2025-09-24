import 'dart:io';

class Calendar {
  final String id;
  final String name;
  final int year;
  final Map<String, File> photos;

  Calendar({
    required this.id,
    required this.name,
    required this.year,
    Map<String, File>? photos,
  }) : photos = photos ?? {};

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'year': year};

  factory Calendar.fromJson(Map<String, dynamic> json) => Calendar(
        id: json['id'],
        name: json['name'],
        year: json['year'] ?? DateTime.now().year,
      );
}