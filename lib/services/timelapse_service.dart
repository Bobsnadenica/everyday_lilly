import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class TimelapseService {
  static const _channel = MethodChannel('everyday_lilly/timelapse');

  /// Copies images to temp frames and asks native side to build an MP4.
  /// Returns the output video path or an error message on failure.
  Future<String?> generateFromFiles(List<File> orderedPhotos,
      {double fps = 1.0, int width = 1080, int height = 1920}) async {
    if (orderedPhotos.isEmpty) {
      debugPrint('No photos provided for timelapse generation.');
      return 'No photos provided.';
    }

    try {
      debugPrint('Starting timelapse generation with ${orderedPhotos.length} photos.');

      // Sort photos by last modified timestamp to ensure correct sequence
      orderedPhotos.sort((a, b) {
        final aTime = a.lastModifiedSync();
        final bTime = b.lastModifiedSync();
        return aTime.compareTo(bTime);
      });
      debugPrint('Photos sorted by last modified timestamp.');

      // Safety check for maximum resolution to avoid OOM errors
      const maxPixels = 1920 * 1080; // example max pixels limit
      if (width * height > maxPixels) {
        final aspectRatio = width / height;
        if (aspectRatio >= 1) {
          width = 1080;
          height = (1080 / aspectRatio).round();
        } else {
          height = 1080;
          width = (1080 * aspectRatio).round();
        }
        debugPrint('Resolution adjusted to $width x $height to avoid OOM.');
      } else {
        debugPrint('Using resolution $width x $height.');
      }

      // Prepare temp frames
      final tempRoot = await getTemporaryDirectory();
      final tempFrames = Directory('${tempRoot.path}/timelapse_frames');
      if (await tempFrames.exists()) {
        await tempFrames.delete(recursive: true);
        debugPrint('Deleted existing temp frames directory.');
      }
      await tempFrames.create(recursive: true);
      debugPrint('Created temp frames directory at ${tempFrames.path}.');

      var i = 1;
      final framePaths = <String>[];
      for (final f in orderedPhotos) {
        final out = File('${tempFrames.path}/frame_${i.toString().padLeft(4, '0')}.jpg');
        if (await out.exists()) await out.delete();
        await f.copy(out.path);
        framePaths.add(out.path);
        i++;
      }
      debugPrint('Copied ${framePaths.length} frames to temp directory.');

      // Add frame delay and smoother transitions parameters
      // Note: Assuming native side can handle 'frameDelay' and 'smoothTransitions' params
      final frameDelay = (1.0 / fps) * 1000; // in milliseconds
      debugPrint('Frame delay set to ${frameDelay.toStringAsFixed(2)} ms based on fps $fps.');

      final outputMp4 = '${tempRoot.path}/timelapse.mp4';
      final resultPath = await _channel.invokeMethod<String>('generateTimelapse', {
        'imagePaths': framePaths,
        'outputPath': outputMp4,
        'fps': fps,
        'width': width,
        'height': height,
        'frameDelay': frameDelay,
        'smoothTransitions': true,
      });

      // Clean up temp frames after generation
      if (await tempFrames.exists()) {
        await tempFrames.delete(recursive: true);
        debugPrint('Cleaned up temp frames directory.');
      }

      if (resultPath == null || resultPath.isEmpty) {
        debugPrint('Timelapse generation failed: empty result path.');
        return 'Timelapse generation failed: no output path returned.';
      }

      debugPrint('Timelapse generated successfully at $resultPath.');
      return resultPath;
    } catch (e, stacktrace) {
      debugPrint('Error during timelapse generation: $e');
      debugPrint('$stacktrace');
      return 'Error during timelapse generation: $e';
    }
  }
}