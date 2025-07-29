import 'dart:io';
import 'package:path/path.dart' as path;
import '../../interfaces/i_platform_installer.dart';
import '../../../../models/update_info.dart';
import '../../../errors/app_exceptions.dart';
import '../../../services/logging_service.dart';
import '../../../utils/file_utils.dart';
import '../../../../services/extraction/extraction_service.dart';
import '../../../../services/installation/installation_service.dart';
import '../../../../services/storage/preferences_service.dart';
import '../../interfaces/i_platform_launcher.dart';
import '../windows/windows_launcher.dart';
import 'windows_file_handler.dart';

/// Windows-specific installer implementation
class WindowsInstaller implements IPlatformInstaller {
  final ExtractionService _extractionService;
  final InstallationService _installationService;
  final PreferencesService _preferencesService;
  final IPlatformLauncher _platformLauncher;

  WindowsInstaller(
    this._extractionService,
    this._installationService,
    this._preferencesService,
  ) : _platformLauncher = WindowsLauncher(
        _preferencesService,
        _installationService,
      );

  @override
  Future<bool> canHandle(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      // Windows installer handles archive files (zip, 7z, tar.gz, etc.)
      // but not APK or AppImage files
      final extension = path.extension(filePath).toLowerCase();

      // Supported archive formats for Windows
      final supportedExtensions = ['.zip', '.7z', '.tar', '.gz', '.rar'];

      // Check if it's a supported archive format
      if (supportedExtensions.any((ext) => extension.endsWith(ext))) {
        return true;
      }

      // Check for compound extensions like .tar.gz
      final fileName = path.basename(filePath).toLowerCase();
      if (fileName.endsWith('.tar.gz') || fileName.endsWith('.tar.bz2')) {
        return true;
      }

      // Reject APK and AppImage files
      if (extension == '.apk' || extension == '.appimage') {
        return false;
      }

      return false;
    } catch (e) {
      LoggingService.error(
        'Error checking if Windows installer can handle file',
        e,
      );
      return false;
    }
  }

  @override
  Future<void> install(
    String filePath,
    UpdateInfo updateInfo, {
    required bool createShortcuts,
    required bool portableMode,
    required Function(double) onProgress,
    required Function(String) onStatusUpdate,
  }) async {
    LoggingService.info('Starting Windows installation');
    LoggingService.info('File path: $filePath');
    LoggingService.info('Update version: ${updateInfo.version}');
    LoggingService.info('Create shortcuts: $createShortcuts');
    LoggingService.info('Portable mode: $portableMode');

    Directory? extractTempDir;

    try {
      // Verify file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw UpdateException('Installation file not found', filePath);
      }

      onStatusUpdate('Preparing installation...');
      onProgress(0.1);

      // Get install path and ensure it exists
      final installPath = await _installationService.getInstallPath();
      final installDir = Directory(installPath);
      if (!await installDir.exists()) {
        LoggingService.info('Creating install directory: $installPath');
        await installDir.create(recursive: true);
      }

      // Extract the archive to temp directory first
      onStatusUpdate('Extracting archive...');
      LoggingService.info('Creating extraction temp directory...');
      extractTempDir = await Directory.systemTemp.createTemp('eden_extract_');
      LoggingService.info('Extraction temp directory: ${extractTempDir.path}');

      LoggingService.info('Starting archive extraction...');
      await _extractionService.extractArchive(
        filePath,
        extractTempDir.path,
        onProgress: (progress) {
          onProgress(0.1 + (progress * 0.5));
          onStatusUpdate('Extracting... ${(progress * 100).toInt()}%');
        },
      );
      LoggingService.info('Archive extraction completed');

      // Move extracted files to final location
      onStatusUpdate('Installing files...');
      LoggingService.info('Moving extracted files to install location...');
      await _moveExtractedFiles(extractTempDir.path, installPath);
      LoggingService.info('Files moved successfully');
      onProgress(0.7);

      // Organize the installation
      onStatusUpdate('Organizing installation...');
      LoggingService.info('Organizing installation structure...');
      await _installationService.organizeInstallation(installPath);
      LoggingService.info('Installation organized');
      onProgress(0.8);

      // Update version info
      final channel = await _preferencesService.getReleaseChannel();
      await _preferencesService.setCurrentVersion(channel, updateInfo.version);
      LoggingService.info(
        'Updated version info for channel $channel to ${updateInfo.version}',
      );

      // Create user folder for portable mode in the channel-specific folder
      if (portableMode) {
        onStatusUpdate('Setting up portable mode...');
        LoggingService.info('Setting up portable mode...');
        final channelInstallPath = await _installationService
            .getChannelInstallPath();
        final userPath = path.join(channelInstallPath, 'user');
        await Directory(userPath).create(recursive: true);
        LoggingService.info('Portable mode user directory created: $userPath');
      }
      onProgress(0.9);

      // Create shortcut if requested
      if (createShortcuts) {
        onStatusUpdate('Creating desktop shortcut...');
        try {
          await _platformLauncher.createDesktopShortcut();
          LoggingService.info('Desktop shortcut created successfully');
        } catch (e) {
          LoggingService.warning('Failed to create desktop shortcut', e);
        }
      }

      onProgress(1.0);
      onStatusUpdate('Installation complete!');
      LoggingService.info('Windows installation completed successfully');
    } catch (e) {
      LoggingService.error('Windows installation failed', e);
      if (e is AppException) {
        rethrow;
      }
      throw UpdateException('Windows installation failed', e.toString());
    } finally {
      // Clean up extraction temp directory
      if (extractTempDir != null && await extractTempDir.exists()) {
        try {
          await extractTempDir.delete(recursive: true);
          LoggingService.info('Cleaned up extraction temp directory');
        } catch (e) {
          LoggingService.warning(
            'Failed to clean up extraction temp directory',
            e,
          );
        }
      }
    }
  }

  @override
  Future<void> postInstallSetup(
    String installPath,
    UpdateInfo updateInfo,
  ) async {
    LoggingService.info('Performing Windows post-install setup');

    try {
      // Find and verify the Eden executable exists
      final channel = await _preferencesService.getReleaseChannel();
      final fileHandler = WindowsFileHandler();
      final expectedExecutablePath = fileHandler.getEdenExecutablePath(
        installPath,
        channel,
      );

      if (await File(expectedExecutablePath).exists()) {
        // Store the executable path for future launches
        await _preferencesService.setEdenExecutablePath(
          channel,
          expectedExecutablePath,
        );
        LoggingService.info(
          'Stored Eden executable path: $expectedExecutablePath',
        );
      } else {
        LoggingService.warning(
          'Eden executable not found at expected path: $expectedExecutablePath',
        );

        // Try to find the executable in the installation directory
        final foundExecutable = await _findEdenExecutableInDirectory(
          installPath,
        );
        if (foundExecutable != null) {
          await _preferencesService.setEdenExecutablePath(
            channel,
            foundExecutable,
          );
          LoggingService.info(
            'Found and stored Eden executable path: $foundExecutable',
          );
        } else {
          LoggingService.error(
            'Could not find Eden executable in installation directory',
          );
        }
      }
    } catch (e) {
      LoggingService.error('Error during Windows post-install setup', e);
      // Don't throw here as the main installation was successful
    }
  }

  /// Move extracted files from temp directory to install directory
  Future<void> _moveExtractedFiles(
    String extractPath,
    String installPath,
  ) async {
    final extractDir = Directory(extractPath);

    await for (final entity in extractDir.list()) {
      final targetPath = path.join(installPath, path.basename(entity.path));

      if (entity is File) {
        await entity.copy(targetPath);
      } else if (entity is Directory) {
        await FileUtils.copyDirectory(entity.path, targetPath);
      }
    }
  }

  /// Find Eden executable in the installation directory
  Future<String?> _findEdenExecutableInDirectory(String installPath) async {
    try {
      final installDir = Directory(installPath);

      await for (final entity in installDir.list(recursive: true)) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          final fileHandler = WindowsFileHandler();
          if (fileHandler.isEdenExecutable(fileName)) {
            return entity.path;
          }
        }
      }

      return null;
    } catch (e) {
      LoggingService.error('Error searching for Eden executable', e);
      return null;
    }
  }
}
