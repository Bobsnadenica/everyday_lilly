import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class TimelapseService {
  static const _channel = MethodChannel('everyday_lilly/timelapse');

  /// Copies images to temp frames and asks native side to build an MP4.
  /// Returns the output video path or null on failure.
  Future<String?> generateFromFiles(List<File> orderedPhotos,
      {double fps = 1.0, int width = 1080, int height = 1920}) async {
    if (orderedPhotos.isEmpty) return null;

    // Prepare temp frames
    final tempRoot = await getTemporaryDirectory();
    final tempFrames = Directory('${tempRoot.path}/timelapse_frames');
    if (await tempFrames.exists()) await tempFrames.delete(recursive: true);
    await tempFrames.create(recursive: true);

    var i = 1;
    final framePaths = <String>[];
    for (final f in orderedPhotos) {
      final out = File('${tempFrames.path}/frame_${i.toString().padLeft(4, '0')}.jpg');
      if (await out.exists()) await out.delete();
      await f.copy(out.path);
      framePaths.add(out.path);
      i++;
    }

    final outputMp4 = '${tempRoot.path}/timelapse.mp4';
    try {
      final resultPath = await _channel.invokeMethod<String>('generateTimelapse', {
        'imagePaths': framePaths,
        'outputPath': outputMp4,
        'fps': fps,
        'width': width,
        'height': height,
      });
      return resultPath;
    } catch (_) {
      return null;
    }
  }
}