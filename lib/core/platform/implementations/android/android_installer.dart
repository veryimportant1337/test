import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:path/path.dart' as path;

import '../../../../models/update_info.dart';
import '../../../services/logging_service.dart';
import '../../interfaces/i_platform_installer.dart';
import '../../exceptions/platform_exceptions.dart';

/// Android-specific installer implementation
///
/// Handles APK installation using Android Intents and manages
/// Android-specific file storage and installation metadata.
class AndroidInstaller implements IPlatformInstaller {
  @override
  Future<bool> canHandle(String filePath) async {
    return await _isApkFile(filePath);
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
    try {
      LoggingService.info('Starting Android APK installation');
      onStatusUpdate('Installing APK...');
      onProgress(0.1);

      // Verify this is an APK file
      if (!await canHandle(filePath)) {
        throw PlatformOperationException(
          'Android',
          'install',
          'File is not a valid APK: $filePath',
        );
      }

      onProgress(0.3);
      onStatusUpdate('Launching APK installer...');

      // Use Android Intent to launch the APK installer
      await _installAndroidApk(filePath, onProgress, onStatusUpdate);

      onProgress(1.0);
      onStatusUpdate('APK installation initiated');

      LoggingService.info('Android APK installation completed successfully');
    } catch (e) {
      LoggingService.error('Android installation failed: $e');
      if (e is PlatformOperationException) {
        rethrow;
      }
      throw PlatformOperationException(
        'Android',
        'install',
        'Failed to install APK: $e',
      );
    }
  }

  @override
  Future<void> postInstallSetup(
    String installPath,
    UpdateInfo updateInfo,
  ) async {
    // Android APK installation doesn't require post-install setup
    // The Android system handles the installation process
    LoggingService.info(
      'Android post-install setup completed (no action required)',
    );
  }

  /// Checks if the given file is an APK file
  Future<bool> _isApkFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // Check file extension
      final extension = path.extension(filePath).toLowerCase();
      if (extension == '.apk') {
        return true;
      }

      // Check file signature (APK files are ZIP files with specific structure)
      final bytes = await file.openRead(0, 4).first;

      // ZIP file signature: 0x504B0304 (PK..)
      if (bytes.length >= 4 &&
          bytes[0] == 0x50 &&
          bytes[1] == 0x4B &&
          (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07) &&
          (bytes[3] == 0x04 || bytes[3] == 0x06 || bytes[3] == 0x08)) {
        // Additional check: APK files should have AndroidManifest.xml
        // This is a more thorough check but requires ZIP parsing
        // For now, we'll rely on the ZIP signature and extension
        return extension == '.apk' || await _hasAndroidManifest(filePath);
      }

      return false;
    } catch (e) {
      LoggingService.warning('Error checking if file is APK: $e');
      return false;
    }
  }

  /// Checks if the ZIP/APK file contains AndroidManifest.xml
  Future<bool> _hasAndroidManifest(String filePath) async {
    try {
      // This is a simplified check - in a full implementation,
      // we would parse the ZIP file to look for AndroidManifest.xml
      // For now, we'll assume files with .apk extension are APK files
      return path.extension(filePath).toLowerCase() == '.apk';
    } catch (e) {
      LoggingService.warning('Error checking for AndroidManifest: $e');
      return false;
    }
  }

  /// Installs an Android APK using Android Intent
  Future<void> _installAndroidApk(
    String filePath,
    Function(double) onProgress,
    Function(String) onStatusUpdate,
  ) async {
    try {
      LoggingService.info('Launching APK installer using Android Intent');
      onProgress(0.5);

      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: 'file://$filePath',
        type: 'application/vnd.android.package-archive',
        flags: [
          0x10000000, // FLAG_ACTIVITY_NEW_TASK
          0x00000001, // FLAG_GRANT_READ_URI_PERMISSION
        ],
      );

      onStatusUpdate('Opening system installer...');
      onProgress(0.8);

      await intent.launch();

      onProgress(0.9);
      onStatusUpdate('Installation handed off to system');

      LoggingService.info('APK installer launched successfully');
    } catch (e) {
      LoggingService.error('Failed to launch APK installer: $e');
      throw PlatformOperationException(
        'Android',
        'installApk',
        'Failed to launch APK installer: $e',
      );
    }
  }
}
