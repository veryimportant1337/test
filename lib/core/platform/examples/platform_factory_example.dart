// Example usage of PlatformFactory
// This file demonstrates how to use the platform factory for runtime platform detection

import '../platform_factory.dart';
import '../models/installation_context.dart';
import '../../../models/update_info.dart';

/// Example class showing how to use PlatformFactory in practice
class PlatformFactoryExample {
  /// Demonstrates basic platform detection
  static void demonstratePlatformDetection() {
    // Get current platform configuration
    final config = PlatformFactory.getCurrentPlatformConfig();
  }

  /// Demonstrates platform capability checking
  static void demonstrateCapabilityChecking() {
    // Check if current platform is supported
    final isSupported = PlatformFactory.isCurrentPlatformSupported();

    // Check file extension support
    final extensions = ['.exe', '.apk', '.AppImage', '.zip', '.dmg'];
    for (final ext in extensions) {
      final supported = PlatformFactory.isFileExtensionSupported(ext);
    }

    // Check channel support
    final channels = ['stable', 'nightly', 'beta'];
    for (final channel in channels) {
      final supported = PlatformFactory.isChannelSupported(channel);
    }
  }

  /// Demonstrates platform information gathering
  static void demonstratePlatformInfo() {
    final info = PlatformFactory.getPlatformInfo();
    info.forEach((key, value) {});
  }

  /// Demonstrates installation context validation
  static void demonstrateContextValidation() {
    try {
      // Create a sample installation context
      final context = InstallationContext(
        filePath: '/path/to/update.zip',
        installPath: '/path/to/install',
        updateInfo: UpdateInfo(
          version: '1.0.0',
          downloadUrl: 'https://example.com/update.zip',
          releaseDate: DateTime.now(),
          releaseNotes: 'Sample update',
          releaseUrl: 'https://example.com/release',
          fileSize: 1024,
        ),
        createShortcuts: true,
        portableMode: false,
        channel: 'stable',
        onProgress: (progress) =>
            print('Progress: ${(progress * 100).toInt()}%'),
        onStatusUpdate: (status) => print('Status: $status'),
      );

      // Validate the context
      PlatformFactory.validateInstallationContext(context);
    } catch (e) {}
  }

  /// Demonstrates factory method usage (will show expected exceptions)
  static void demonstrateFactoryMethods() {
    try {
      final installer = PlatformFactory.createInstaller();
    } catch (e) {}

    try {
      final launcher = PlatformFactory.createLauncher();
    } catch (e) {}

    try {
      final fileHandler = PlatformFactory.createFileHandler();
    } catch (e) {}

    try {
      final versionDetector = PlatformFactory.createVersionDetector();
    } catch (e) {}
  }

  /// Runs all examples
  static void runAllExamples() {
    demonstratePlatformDetection();
    demonstrateCapabilityChecking();
    demonstratePlatformInfo();
    demonstrateContextValidation();
    demonstrateFactoryMethods();
  }
}
