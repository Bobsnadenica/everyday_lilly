import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

class PhotoGallery extends StatefulWidget {
  final Map<String, File> photos;
  final String initialPhotoKey;
  final Function(String) onDelete;
  final Map<String, String> notes;
  final Function(String, String?) onNoteChanged;

  const PhotoGallery({
    super.key,
    required this.photos,
    required this.initialPhotoKey,
    required this.onDelete,
    required this.notes,
    required this.onNoteChanged,
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

  Future<void> _editNoteDialog(String photoKey) async {
    final currentNote = widget.notes[photoKey] ?? '';
    final TextEditingController controller = TextEditingController(text: currentNote);
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Note'),
          content: TextField(
            controller: controller,
            maxLines: null,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter note here',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim().isEmpty ? null : controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      widget.onNoteChanged(photoKey, result);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lilly Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share this photo',
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
            tooltip: 'Delete this photo',
            onPressed: () {
              final index = _controller.page!.round();
              _deletePhoto(index);
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final photoKey = keys[index];
          final photo = widget.photos[photoKey];
          final note = widget.notes[photoKey];
          if (photo == null) {
            return const Center(child: Text('Photo missing'));
          }
          return Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Image.file(
                    photo,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              if (note != null && note.isNotEmpty)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        note,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final index = _controller.page!.round();
          final photoKey = keys[index];
          _editNoteDialog(photoKey);
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}