import 'dart:io';

/// Model representing a cached audio file
class AudioFileModel {
  final String filePath;
  final String fileName;
  final DateTime lastModified;
  final int fileSize;

  AudioFileModel({
    required this.filePath,
    required this.fileName,
    required this.lastModified,
    required this.fileSize,
  });

  /// Create from File
  factory AudioFileModel.fromFile(File file) {
    final stat = file.statSync();
    return AudioFileModel(
      filePath: file.path,
      fileName: file.path.split('/').last,
      lastModified: stat.modified,
      fileSize: stat.size,
    );
  }

  /// Format last modified date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(lastModified);

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
      return '${lastModified.day}/${lastModified.month}/${lastModified.year}';
    }
  }

  /// Format file size
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
