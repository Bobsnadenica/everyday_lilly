import 'dart:io';
import 'package:flutter/material.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  final Future<Directory> Function() getCalendarDirectory;
  BackupService({required this.getCalendarDirectory});

  Future<void> exportBackupZip(BuildContext context, String calendarName) async {
    ZipFileEncoder? encoder;
    try {
      final calendarDir = await getCalendarDirectory();

      if (!await calendarDir.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to backup.')),
        );
        return;
      }

      final files = calendarDir.listSync(recursive: true).whereType<File>().toList();
      if (files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No files found to backup.')),
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final zipPath = '${tempDir.path}/${calendarName}_backup.zip';

      encoder = ZipFileEncoder()..create(zipPath);
      for (final file in files) {
        encoder.addFile(file);
      }
      encoder.close();
      encoder = null;

      await Share.shareXFiles([XFile(zipPath)], text: 'Backup of $calendarName');

      try {
        final tempZip = File(zipPath);
        if (await tempZip.exists()) await tempZip.delete();
      } catch (_) {}
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    } finally {
      encoder?.close();
    }
  }
}