import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/platform/interfaces/i_platform_file_handler.dart';
import '../../core/platform/platform_factory.dart';
import '../storage/preferences_service.dart';

/// Service for managing Eden installation
class InstallationService {
  final PreferencesService _preferencesService;
  final IPlatformFileHandler _fileHandler;

  InstallationService(
    this._preferencesService, [
    IPlatformFileHandler? fileHandler,
  ]) : _fileHandler = fileHandler ?? PlatformFactory.createFileHandler();

  /// Get the installation path, creating it if necessary
  Future<String> getInstallPath() async {
    String? installPath = await _preferencesService.getInstallPath();

    if (installPath == null) {
      final appDir = await getApplicationDocumentsDirectory();
      installPath = path.join(appDir.path, 'Eden');
      await _preferencesService.setInstallPath(installPath);
    }

    await Directory(installPath).create(recursive: true);
    return installPath;
  }

  /// Get the channel-specific installation path
  Future<String> getChannelInstallPath() async {
    final installPath = await getInstallPath();
    final channel = await _preferencesService.getReleaseChannel();
    final channelFolderName = channel == AppConstants.nightlyChannel
        ? 'Eden-Nightly'
        : 'Eden-Release';
    return path.join(installPath, channelFolderName);
  }

  /// Organize extracted files into proper channel folder
  Future<void> organizeInstallation(String installPath) async {
    final channel = await _preferencesService.getReleaseChannel();
    final targetFolderName = channel == AppConstants.nightlyChannel
        ? 'Eden-Nightly'
        : 'Eden-Release';
    final targetPath = path.join(installPath, targetFolderName);

    final targetDir = Directory(targetPath);
    if (await targetDir.exists()) {
      await _cleanEdenFolder(targetPath);
    }

    final installDir = Directory(installPath);
    await for (final entity in installDir.list()) {
      if (entity is Directory) {
        final folderName = path.basename(entity.path);

        if (folderName == 'Eden-Release' || folderName == 'Eden-Nightly') {
          continue;
        }

        if (await _fileHandler.containsEdenFiles(entity.path)) {
          await _mergeEdenFolder(entity.path, targetPath);
          await entity.delete(recursive: true);
          await _scanAndStoreEdenExecutable(targetPath);
          return;
        }
      }
    }
  }

  /// Scan for Eden executable and store its path
  Future<void> _scanAndStoreEdenExecutable(String installPath) async {
    List<String> foundExecutables = [];

    await for (final entity in Directory(installPath).list(recursive: true)) {
      if (entity is File) {
        final filename = path.basename(entity.path);
        if (_fileHandler.isEdenExecutable(filename)) {
          foundExecutables.add(entity.path);
        }
      }
    }

    if (foundExecutables.isEmpty) {
      return;
    }

    // Prioritize GUI versions over command-line versions
    String? selectedExecutable;

    // First priority: use platform-specific preferred executable
    final preferredExecutable = _fileHandler.getEdenExecutablePath(
      installPath,
      null,
    );
    final preferredName = path.basename(preferredExecutable).toLowerCase();

    for (final exe in foundExecutables) {
      final name = path.basename(exe).toLowerCase();
      if (name == preferredName) {
        selectedExecutable = exe;
        break;
      }
    }

    // Second priority: avoid command-line versions
    if (selectedExecutable == null) {
      for (final exe in foundExecutables) {
        final name = path.basename(exe).toLowerCase();
        if (!name.contains('cmd') && !name.contains('cli')) {
          selectedExecutable = exe;
          break;
        }
      }
    }

    // Fallback: use first found
    selectedExecutable ??= foundExecutables.first;

    final channel = await _preferencesService.getReleaseChannel();
    await _preferencesService.setEdenExecutablePath(
      channel,
      selectedExecutable,
    );

    // Make the executable file executable (relevant for Unix-like systems)
    await _fileHandler.makeExecutable(selectedExecutable);
  }

  /// Clean existing Eden folder while preserving user data
  Future<void> _cleanEdenFolder(String edenPath) async {
    final edenDir = Directory(edenPath);
    if (!await edenDir.exists()) return;

    await for (final entity in edenDir.list()) {
      final name = path.basename(entity.path).toLowerCase();

      if (name == 'user') {
        continue; // Preserve user data
      }

      try {
        await entity.delete(recursive: true);
      } catch (e) {
        // Continue if we can't delete some files
      }
    }
  }

  /// Merge Eden folder contents
  Future<void> _mergeEdenFolder(String sourcePath, String targetPath) async {
    final sourceDir = Directory(sourcePath);
    final targetDir = Directory(targetPath);

    await targetDir.create(recursive: true);

    await for (final entity in sourceDir.list()) {
      final name = path.basename(entity.path);
      final targetEntityPath = path.join(targetPath, name);

      try {
        if (entity is File) {
          await entity.copy(targetEntityPath);
        } else if (entity is Directory) {
          await _copyDirectory(entity.path, targetEntityPath);
        }
      } catch (e) {
        // Continue if we can't copy some files
      }
    }
  }

  /// Copy a directory recursively using platform-agnostic operations
  Future<void> _copyDirectory(String sourcePath, String targetPath) async {
    final sourceDir = Directory(sourcePath);
    final targetDir = Directory(targetPath);

    await targetDir.create(recursive: true);

    await for (final entity in sourceDir.list()) {
      final name = path.basename(entity.path);
      final targetEntityPath = path.join(targetPath, name);

      if (entity is File) {
        await entity.copy(targetEntityPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity.path, targetEntityPath);
      }
    }
  }
}
