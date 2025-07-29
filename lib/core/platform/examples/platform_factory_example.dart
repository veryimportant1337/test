// Example usage of PlatformFactory
// This file demonstrates how to use the platform factory for runtime platform detection

import '../platform_factory.dart';
import '../models/installation_context.dart';
import '../../../models/update_info.dart';

/// Example class showing how to use PlatformFactory in practice
class PlatformFactoryExample {
  /// Demonstrates basic platform detection
  static void demonstratePlatformDetection() {
    print('=== Platform Detection Example ===');

    // Get current platform configuration
    final config = PlatformFactory.getCurrentPlatformConfig();
    print('Current platform: ${config.name}');
    print('Supported file extensions: ${config.supportedFileExtensions}');
    print('Supported channels: ${config.supportedChannels}');
    print('Supports shortcuts: ${config.supportsShortcuts}');
    print('Supports portable mode: ${config.supportsPortableMode}');
    print('');
  }

  /// Demonstrates platform capability checking
  static void demonstrateCapabilityChecking() {
    print('=== Platform Capability Checking ===');

    // Check if current platform is supported
    final isSupported = PlatformFactory.isCurrentPlatformSupported();
    print('Current platform supported: $isSupported');

    // Check file extension support
    final extensions = ['.exe', '.apk', '.AppImage', '.zip', '.dmg'];
    for (final ext in extensions) {
      final supported = PlatformFactory.isFileExtensionSupported(ext);
      print('$ext supported: $supported');
    }

    // Check channel support
    final channels = ['stable', 'nightly', 'beta'];
    for (final channel in channels) {
      final supported = PlatformFactory.isChannelSupported(channel);
      print('$channel channel supported: $supported');
    }
    print('');
  }

  /// Demonstrates platform information gathering
  static void demonstratePlatformInfo() {
    print('=== Platform Information ===');

    final info = PlatformFactory.getPlatformInfo();
    info.forEach((key, value) {
      print('$key: $value');
    });
    print('');
  }

  /// Demonstrates installation context validation
  static void demonstrateContextValidation() {
    print('=== Installation Context Validation ===');

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
      print('Installation context is valid for current platform');
    } catch (e) {
      print('Installation context validation failed: $e');
    }
    print('');
  }

  /// Demonstrates factory method usage (will show expected exceptions)
  static void demonstrateFactoryMethods() {
    print('=== Factory Method Usage ===');

    try {
      final installer = PlatformFactory.createInstaller();
      print('Installer created: $installer');
    } catch (e) {
      print('Expected: Installer not yet implemented - $e');
    }

    try {
      final launcher = PlatformFactory.createLauncher();
      print('Launcher created: $launcher');
    } catch (e) {
      print('Expected: Launcher not yet implemented - $e');
    }

    try {
      final fileHandler = PlatformFactory.createFileHandler();
      print('File handler created: $fileHandler');
    } catch (e) {
      print('Expected: File handler not yet implemented - $e');
    }

    try {
      final versionDetector = PlatformFactory.createVersionDetector();
      print('Version detector created: $versionDetector');
    } catch (e) {
      print('Expected: Version detector not yet implemented - $e');
    }
    print('');
  }

  /// Runs all examples
  static void runAllExamples() {
    print('Platform Factory Usage Examples\n');

    demonstratePlatformDetection();
    demonstrateCapabilityChecking();
    demonstratePlatformInfo();
    demonstrateContextValidation();
    demonstrateFactoryMethods();

    print('Examples completed!');
  }
}
