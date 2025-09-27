import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class TimelapseService {
  static const _channel = MethodChannel('everyday_lilly/timelapse');

  /// Copies images to temp frames and asks native side to build an MP4.
  /// Returns the output video path or an error message on failure.
  Future<String?> generateFromFiles(
    List<File> orderedPhotos, {
    double fps = 1.0,
    int width = 1080,
    int height = 1920,
    bool applyFade = false,
    String? watermarkText,
    bool reversePlayback = false,
    // NEW options (all optional, backwards compatible)
    int crossfadeDurationMs = 150,
    int holdFirstLastMs = 300,
    bool kenBurns = false,
    double kenBurnsIntensity = 0.08, // 0..1
    String? colorFilter, // e.g. 'bw', 'sepia', 'vivid'
    bool stabilize = false,
    String? overlayAudioPath,
    String qualityPreset = 'medium', // 'low'|'medium'|'high'
    int? bitrateKbps,
    String outputFileName = 'timelapse.mp4',
    int? maxFrames, // evenly sample if provided
    bool skipDuplicateConsecutive = true,
    bool safeMode = true,
    int loopCount = 1,
    String transitionEffect = 'crossfade',
    String? backgroundMusicPath,
    double musicVolume = 1.0,
  }) async {
    // Basic validation
    if (orderedPhotos.isEmpty) {
      debugPrint('No photos provided for timelapse generation.');
      return 'No photos provided.';
    }

    // Filter to existing, readable files
    final initialCount = orderedPhotos.length;
    orderedPhotos = orderedPhotos.where((f) => f.existsSync() && f.lengthSync() > 0).toList();
    if (orderedPhotos.isEmpty) {
      debugPrint('All input photos were missing or empty ($initialCount).');
      return 'All input photos were missing or empty.';
    }

    try {
      debugPrint('Starting timelapse generation with ${orderedPhotos.length} valid photos.');

      // Sort photos by last modified timestamp to ensure correct sequence
      orderedPhotos.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
      debugPrint('Photos sorted by last modified timestamp.');

      // Reverse playback if requested
      if (reversePlayback) {
        orderedPhotos = orderedPhotos.reversed.toList();
        debugPrint('Frames reversed for reverse playback.');
      }

      // Remove consecutive duplicates (by size + name) to avoid stutter
      if (skipDuplicateConsecutive && orderedPhotos.length > 1) {
        final deduped = <File>[];
        File? prev;
        int removed = 0;
        for (final f in orderedPhotos) {
          final keep = prev == null || (f.lengthSync() != prev!.lengthSync() || f.path != prev!.path);
          if (keep) {
            deduped.add(f);
            prev = f;
          } else {
            removed++;
          }
        }
        orderedPhotos = deduped;
        if (removed > 0) debugPrint('Removed $removed consecutive duplicate frames.');
      }

      // Evenly sample to maxFrames if requested
      if (maxFrames != null && maxFrames > 0 && orderedPhotos.length > maxFrames) {
        final sampled = <File>[];
        final step = orderedPhotos.length / maxFrames;
        for (int i = 0; i < maxFrames; i++) {
          final idx = min(orderedPhotos.length - 1, (i * step).floor());
          sampled.add(orderedPhotos[idx]);
        }
        orderedPhotos = sampled;
        debugPrint('Sampled frames down to $maxFrames.');
      }

      // Safety check for maximum resolution to avoid OOM errors
      const maxPixels = 1920 * 1080; // limit
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

      // Prepare temp frames in a unique directory
      final tempRoot = await getTemporaryDirectory();
      final tempFrames = Directory('${tempRoot.path}/timelapse_frames_${DateTime.now().millisecondsSinceEpoch}');
      if (await tempFrames.exists()) {
        await tempFrames.delete(recursive: true);
      }
      await tempFrames.create(recursive: true);
      debugPrint('Created temp frames directory at ${tempFrames.path}.');

      // Copy frames (with safety)
      var i = 1;
      final framePaths = <String>[];
      for (final f in orderedPhotos) {
        try {
          final out = File('${tempFrames.path}/frame_${i.toString().padLeft(4, '0')}.jpg');
          if (await out.exists()) await out.delete();
          await f.copy(out.path);
          framePaths.add(out.path);
          i++;
        } catch (e) {
          if (!safeMode) rethrow;
          debugPrint('Skipping frame due to copy error: $e');
        }
      }
      if (framePaths.isEmpty) {
        await tempFrames.delete(recursive: true);
        return 'Failed to prepare frames.';
      }
      debugPrint('Prepared ${framePaths.length} frames.');

      // Timing / transitions
      final frameDelay = (1.0 / fps) * 1000; // ms
      debugPrint('Frame delay set to ${frameDelay.toStringAsFixed(2)} ms (fps=$fps).');

      // Select transition effect if 'random' or empty
      final supportedEffects = ['crossfade', 'fade', 'slide', 'zoom', 'spin', 'wipe'];
      if (transitionEffect.trim().isEmpty || transitionEffect == 'random') {
        final random = Random();
        transitionEffect = supportedEffects[random.nextInt(supportedEffects.length)];
      }
      debugPrint('Using transition effect: $transitionEffect.');

      if (backgroundMusicPath != null && backgroundMusicPath.isNotEmpty) {
        debugPrint('Background music path set: $backgroundMusicPath with volume $musicVolume.');
      } else {
        debugPrint('No background music set.');
      }

      // Output path
      final sanitizedName = outputFileName.trim().isEmpty ? 'timelapse.mp4' : outputFileName.trim();
      final outputPath = '${tempRoot.path}/$sanitizedName';

      // Parameters for native call (unknown keys are safe to ignore on native side)
      final Map<String, dynamic> params = {
        'imagePaths': framePaths,
        'outputPath': outputPath,
        'fps': fps,
        'width': width,
        'height': height,
        'frameDelay': frameDelay,
        'smoothTransitions': true,
        'transitionEffect': transitionEffect,
        'crossfadeDurationMs': crossfadeDurationMs,
        'holdFirstLastMs': holdFirstLastMs,
        'kenBurns': kenBurns,
        'kenBurnsIntensity': kenBurnsIntensity,
        'colorFilter': colorFilter, // null -> no filter
        'stabilize': stabilize,
        'overlayAudioPath': overlayAudioPath,
        'qualityPreset': qualityPreset,
        'bitrateKbps': bitrateKbps,
        'loopCount': max(1, loopCount),
        'backgroundMusicPath': backgroundMusicPath,
        'musicVolume': musicVolume,
      };

      if (applyFade) {
        params['applyFade'] = true;
        debugPrint('Fade-in/out effect enabled.');
      }

      if (watermarkText != null && watermarkText.isNotEmpty) {
        final watermarkFile = File('${tempRoot.path}/watermark.txt');
        await watermarkFile.writeAsString(watermarkText);
        params['watermarkPath'] = watermarkFile.path;
        debugPrint('Watermark text saved to ${watermarkFile.path}.');
      }

      debugPrint('Invoking native method with parameters: $params');
      final resultPath = await _channel.invokeMethod<String>('generateTimelapse', params);

      // Clean up temp frames after generation
      try {
        if (await tempFrames.exists()) {
          await tempFrames.delete(recursive: true);
          debugPrint('Cleaned up temp frames directory.');
        }
      } catch (e) {
        debugPrint('Failed to clean temp frames: $e');
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