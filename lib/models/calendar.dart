import 'dart:io';

class Calendar {
  final String id;
  final String name;
  final Map<String, File> photos;

  Calendar({
    required this.id,
    required this.name,
    Map<String, File>? photos,
  }) : photos = photos ?? {};

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Calendar.fromJson(Map<String, dynamic> json) => Calendar(
        id: json['id'],
        name: json['name'],
      );
}