import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing audio file storage in Downloads folder
/// with MediaStore indexing for visibility in system file managers
class AudioStorageService {
  static final AudioStorageService _instance = AudioStorageService._internal();

  factory AudioStorageService() => _instance;

  AudioStorageService._internal();

  static const String _audioMetadataKey = 'aura_audio_files';
  static const String _audioCounterKey = 'aura_audio_counter';
  static const String _auraFolderName = 'Aura';

  /// Get the Downloads/Aura directory path
  Future<Directory> getDownloadsAuraDirectory() async {
    if (Platform.isAndroid) {
      // Use app-specific external storage to avoid permission issues on modern Android
      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        // Fallback to internal if external is null
        return await getApplicationDocumentsDirectory();
      }

      final auraPath = path.join(externalDir.path, _auraFolderName);
      final dir = Directory(auraPath);

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      return dir;
    } else if (Platform.isIOS) {
      // On iOS, use Documents directory (visible in Files app)
      final appDocDir = await getApplicationDocumentsDirectory();
      final auraDir = Directory(path.join(appDocDir.path, _auraFolderName));

      if (!await auraDir.exists()) {
        await auraDir.create(recursive: true);
      }

      return auraDir;
    }

    // Fallback
    final tempDir = await getTemporaryDirectory();
    return tempDir;
  }

  /// Get the next sequential audio file number
  Future<int> _getNextAudioNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_audioCounterKey) ?? 0;
    final nextCount = currentCount + 1;
    await prefs.setInt(_audioCounterKey, nextCount);
    return nextCount;
  }

  /// Generate a unique audio filename with sequential numbering
  Future<String> generateAudioFilename() async {
    final number = await _getNextAudioNumber();
    return 'Aura Audio $number.wav';
  }

  /// Get the full path for a new audio file
  Future<String> getNewAudioFilePath() async {
    final dir = await getDownloadsAuraDirectory();
    final filename = await generateAudioFilename();
    return path.join(dir.path, filename);
  }

  /// Save audio file metadata to SharedPreferences
  Future<void> _saveAudioMetadata(AudioMetadata metadata) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getStringList(_audioMetadataKey) ?? [];

    // Add new metadata at the beginning (newest first)
    existingJson.insert(0, jsonEncode(metadata.toJson()));

    await prefs.setStringList(_audioMetadataKey, existingJson);
  }

  /// Get all saved audio metadata from SharedPreferences
  Future<List<AudioMetadata>> getSavedAudioMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_audioMetadataKey) ?? [];

    final List<AudioMetadata> result = [];
    final List<String> validJsonList = [];

    for (final jsonStr in jsonList) {
      try {
        final metadata = AudioMetadata.fromJson(jsonDecode(jsonStr));
        // Verify file still exists
        final file = File(metadata.filePath);
        if (await file.exists()) {
          result.add(metadata);
          validJsonList.add(jsonStr);
        }
      } catch (e) {
        // Skip invalid entries
      }
    }

    // Update storage to remove references to deleted files
    if (validJsonList.length != jsonList.length) {
      await prefs.setStringList(_audioMetadataKey, validJsonList);
    }

    return result;
  }

  /// Save audio file to Downloads/Aura and register in metadata
  /// Returns the saved file path
  Future<String> saveAudioFile(
    File sourceFile, {
    String? customFilename,
  }) async {
    final dir = await getDownloadsAuraDirectory();

    String filename;
    if (customFilename != null && customFilename.isNotEmpty) {
      filename = customFilename;
    } else {
      filename = await generateAudioFilename();
    }

    final destPath = path.join(dir.path, filename);

    // Copy file to destination
    final savedFile = await sourceFile.copy(destPath);

    // Delete source file (temp file)
    try {
      if (await sourceFile.exists()) {
        await sourceFile.delete();
      }
    } catch (e) {
      // Ignore cleanup errors
    }

    // Get file info
    final stat = await savedFile.stat();

    // Save metadata
    final metadata = AudioMetadata(
      filePath: savedFile.path,
      fileName: filename,
      createdAt: DateTime.now(),
      fileSize: stat.size,
    );
    await _saveAudioMetadata(metadata);

    // Trigger media scan so file appears in gallery/file managers
    await _triggerMediaScan(savedFile.path);

    return savedFile.path;
  }

  /// Export an audio file to the public Downloads folder
  Future<bool> exportToPublicDownloads(
    String sourcePath,
    String fileName,
  ) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return false;

      String destPath;
      if (Platform.isAndroid) {
        destPath = '/storage/emulated/0/Download/$fileName';
      } else {
        // iOS doesn't have a public Downloads folder like Android,
        // using the Documents directory which is usually enough.
        final dir = await getApplicationDocumentsDirectory();
        destPath = path.join(dir.path, fileName);
      }

      final destFile = File(destPath);

      // Copy the file
      await sourceFile.copy(destFile.path);

      // Notify the system to scan the new file
      await _triggerMediaScan(destFile.path);

      return true;
    } catch (e) {
      print('Export failed: $e');
      return false;
    }
  }

  /// Trigger media scanner to index the file
  Future<void> _triggerMediaScan(String filePath) async {
    if (Platform.isAndroid) {
      try {
        // Use Process to call media scanner via am broadcast
        await Process.run('am', [
          'broadcast',
          '-a',
          'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
          '-d',
          'file://$filePath',
        ]);
      } catch (e) {
        // Fallback: Try alternative method
        // The file will still be visible, just may take longer to appear in media apps
        print('Media scan failed: $e');
      }
    }
  }

  /// Delete an audio file
  Future<bool> deleteAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from metadata
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_audioMetadataKey) ?? [];
      final updatedList = jsonList.where((jsonStr) {
        try {
          final metadata = AudioMetadata.fromJson(jsonDecode(jsonStr));
          return metadata.filePath != filePath;
        } catch (e) {
          return true;
        }
      }).toList();

      await prefs.setStringList(_audioMetadataKey, updatedList);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete multiple audio files at once
  Future<bool> deleteMultipleAudioFiles(List<String> filePaths) async {
    try {
      final Set<String> pathsToDelete = filePaths.toSet();
      
      for (final filePath in pathsToDelete) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Remove from metadata in one go
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_audioMetadataKey) ?? [];
      final updatedList = jsonList.where((jsonStr) {
        try {
          final metadata = AudioMetadata.fromJson(jsonDecode(jsonStr));
          return !pathsToDelete.contains(metadata.filePath);
        } catch (e) {
          return true;
        }
      }).toList();

      await prefs.setStringList(_audioMetadataKey, updatedList);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get the most recent audio file
  Future<AudioMetadata?> getLastAudioFile() async {
    final files = await getSavedAudioMetadata();
    return files.isNotEmpty ? files.first : null;
  }

  /// Clear all audio files and metadata
  Future<void> clearAllAudio() async {
    final files = await getSavedAudioMetadata();

    for (final metadata in files) {
      try {
        final file = File(metadata.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Continue with other files
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_audioMetadataKey);
  }

  /// Get total count of saved audio files
  Future<int> getAudioCount() async {
    final files = await getSavedAudioMetadata();
    return files.length;
  }
}

/// Model for audio file metadata stored in SharedPreferences
class AudioMetadata {
  final String filePath;
  final String fileName;
  final DateTime createdAt;
  final int fileSize;

  AudioMetadata({
    required this.filePath,
    required this.fileName,
    required this.createdAt,
    required this.fileSize,
  });

  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'fileName': fileName,
    'createdAt': createdAt.toIso8601String(),
    'fileSize': fileSize,
  };

  factory AudioMetadata.fromJson(Map<String, dynamic> json) => AudioMetadata(
    filePath: json['filePath'] as String,
    fileName: json['fileName'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    fileSize: json['fileSize'] as int,
  );

  /// Format file size for display
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Format creation date for display
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
