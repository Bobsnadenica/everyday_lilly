import 'dart:io';
import 'package:flutter/material.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  final Future<Directory> Function() getCalendarDirectory;
  BackupService({required this.getCalendarDirectory});

  Future<void> exportBackupZip(BuildContext context, String calendarName) async {
    try {
      final calendarDir = await getCalendarDirectory();
      final tempDir = await getTemporaryDirectory();
      final zipPath = '${tempDir.path}/${calendarName}_backup.zip';

      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      for (final entity in calendarDir.listSync(recursive: true)) {
        if (entity is File) encoder.addFile(entity);
      }
      encoder.close();

      await Share.shareXFiles([XFile(zipPath)], text: 'Backup of $calendarName');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create backup.')),
      );
    }
  }
}