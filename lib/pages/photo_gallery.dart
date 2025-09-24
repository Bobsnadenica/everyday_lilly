import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

class PhotoGallery extends StatefulWidget {
  final Map<String, File> photos;
  final String initialPhotoKey;
  final Function(String) onDelete;

  const PhotoGallery({
    super.key,
    required this.photos,
    required this.initialPhotoKey,
    required this.onDelete,
  });

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  late final PageController _controller;
  late final List<String> keys;

  @override
  void initState() {
    super.initState();
    keys = widget.photos.keys.toList()..sort();
    final initialIndex = keys.indexOf(widget.initialPhotoKey);
    _controller = PageController(initialPage: initialIndex);
  }

  void _deletePhoto(int index) {
    final key = keys[index];
    widget.onDelete(key);
    setState(() {
      keys.removeAt(index);
    });
    if (keys.isEmpty) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lilly Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final key = keys[_controller.page!.round()];
              final file = widget.photos[key];
              if (file != null) {
                Share.shareXFiles([XFile(file.path)]);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              final index = _controller.page!.round();
              _deletePhoto(index);
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final photo = widget.photos[keys[index]];
          if (photo == null) {
            return const Center(child: Text('Photo missing'));
          }
          return Center(
            child: Image.file(photo, fit: BoxFit.contain),
          );
        },
      ),
    );
  }
}