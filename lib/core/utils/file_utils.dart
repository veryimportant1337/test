import 'dart:io';
import 'package:path/path.dart' as path;
import '../platform/platform_factory.dart';
import '../platform/interfaces/i_platform_file_handler.dart';

/// Utility functions for file operations
///
/// This class provides both platform-agnostic utilities and backward-compatible
/// wrappers for platform-specific operations. For new code, prefer using
/// IPlatformFileHandler directly through PlatformFactory.createFileHandler().
class FileUtils {
  /// Cached platform file handler instance
  static IPlatformFileHandler? _platformFileHandler;

  /// Gets the platform-specific file handler instance
  static IPlatformFileHandler get _fileHandler {
    _platformFileHandler ??= PlatformFactory.createFileHandler();
    return _platformFileHandler!;
  }

  /// Check if a filename represents an Eden executable
  ///
  /// @deprecated Use IPlatformFileHandler.isEdenExecutable() instead
  /// This method is maintained for backward compatibility
  static bool isEdenExecutable(String filename) {
    return _fileHandler.isEdenExecutable(filename);
  }

  /// Get the expected Eden executable path for a given install directory
  ///
  /// @deprecated Use IPlatformFileHandler.getEdenExecutablePath() instead
  /// This method is maintained for backward compatibility
  static String getEdenExecutablePath(String installPath, [String? channel]) {
    return _fileHandler.getEdenExecutablePath(installPath, channel);
  }

  /// Format file size in human-readable format
  static String formatFileSize(int bytes) {
    if (bytes == 0) return 'Unknown size';

    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// Copy a directory recursively
  static Future<void> copyDirectory(
    String sourcePath,
    String targetPath,
  ) async {
    final sourceDir = Directory(sourcePath);
    final targetDir = Directory(targetPath);

    await targetDir.create(recursive: true);

    await for (final entity in sourceDir.list()) {
      final name = path.basename(entity.path);
      final targetEntityPath = path.join(targetPath, name);

      if (entity is File) {
        await entity.copy(targetEntityPath);
      } else if (entity is Directory) {
        await copyDirectory(entity.path, targetEntityPath);
      }
    }
  }

  /// Check if a directory contains Eden program files
  ///
  /// @deprecated Use IPlatformFileHandler.containsEdenFiles() instead
  /// This method is maintained for backward compatibility
  static Future<bool> containsEdenFiles(String folderPath) async {
    return await _fileHandler.containsEdenFiles(folderPath);
  }

  /// Resets the cached platform file handler (primarily for testing)
  static void resetCache() {
    _platformFileHandler = null;
  }
}
