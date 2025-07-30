import 'dart:io';

import 'interfaces/i_platform_installer.dart';
import 'interfaces/i_platform_launcher.dart';
import 'interfaces/i_platform_file_handler.dart';
import 'interfaces/i_platform_version_detector.dart';
import 'models/platform_config.dart';
import 'models/installation_context.dart';
import 'exceptions/platform_exceptions.dart';

// Platform implementations
import 'implementations/windows/windows_installer.dart';
import 'implementations/windows/windows_launcher.dart';
import 'implementations/windows/windows_file_handler.dart';
import 'implementations/windows/windows_version_detector.dart';
import 'implementations/linux/linux_installer.dart';
import 'implementations/linux/linux_launcher.dart';
import 'implementations/linux/linux_file_handler.dart';
import 'implementations/linux/linux_version_detector.dart';
import 'implementations/android/android_installer.dart';
import 'implementations/android/android_launcher.dart';
import 'implementations/android/android_file_handler.dart';
import 'implementations/android/android_version_detector.dart';

// Services for dependency injection
import '../../services/extraction/extraction_service.dart';
import '../../services/installation/installation_service.dart';
import '../../services/storage/preferences_service.dart';

/// Factory class for creating platform-specific implementations
///
/// This factory provides runtime platform detection and creates appropriate
/// platform-specific implementations for installation, launching, file handling,
/// and version detection operations.
class PlatformFactory {
  // Private constructor to prevent instantiation
  PlatformFactory._();

  /// Cached platform configuration to avoid repeated detection
  static PlatformConfig? _cachedConfig;

  /// Cached platform name to avoid repeated detection
  static String? _cachedPlatformName;

  /// Gets the current platform configuration
  ///
  /// Uses caching to avoid repeated platform detection calls.
  /// Throws [PlatformNotSupportedException] if the current platform is not supported.
  static PlatformConfig getCurrentPlatformConfig() {
    _cachedConfig ??= _detectPlatformConfig();
    return _cachedConfig!;
  }

  /// Internal method to detect the current platform configuration
  static PlatformConfig _detectPlatformConfig() {
    if (Platform.isWindows) return PlatformConfig.windows;
    if (Platform.isLinux) return PlatformConfig.linux;
    if (Platform.isAndroid) return PlatformConfig.android;
    if (Platform.isMacOS) return PlatformConfig.macos;

    throw PlatformNotSupportedException(_getCurrentPlatformName());
  }

  /// Creates a platform-specific installer implementation
  static IPlatformInstaller createInstaller() {
    final fileHandler = createFileHandler();

    if (Platform.isWindows) {
      return WindowsInstaller(
        ExtractionService(fileHandler),
        InstallationService(PreferencesService(), fileHandler),
        PreferencesService(),
      );
    }
    if (Platform.isLinux) {
      return LinuxInstaller(
        ExtractionService(fileHandler),
        InstallationService(PreferencesService(), fileHandler),
        PreferencesService(),
      );
    }
    if (Platform.isAndroid) {
      return AndroidInstaller();
    }

    throw PlatformNotSupportedException(_getCurrentPlatformName());
  }

  /// Creates a platform-specific launcher implementation
  static IPlatformLauncher createLauncher() {
    final fileHandler = createFileHandler();

    if (Platform.isWindows) {
      return WindowsLauncher(
        PreferencesService(),
        InstallationService(PreferencesService(), fileHandler),
      );
    }
    if (Platform.isLinux) {
      return LinuxLauncher(
        PreferencesService(),
        InstallationService(PreferencesService(), fileHandler),
      );
    }
    if (Platform.isAndroid) {
      return AndroidLauncher(PreferencesService());
    }

    throw PlatformNotSupportedException(_getCurrentPlatformName());
  }

  /// Creates a platform-specific launcher implementation with provided services
  static IPlatformLauncher createLauncherWithServices(
    PreferencesService preferencesService,
    InstallationService installationService,
  ) {
    if (Platform.isWindows) {
      return WindowsLauncher(preferencesService, installationService);
    }
    if (Platform.isLinux) {
      return LinuxLauncher(preferencesService, installationService);
    }
    if (Platform.isAndroid) {
      return AndroidLauncher(preferencesService);
    }

    throw PlatformNotSupportedException(_getCurrentPlatformName());
  }

  /// Creates a platform-specific file handler implementation
  static IPlatformFileHandler createFileHandler() {
    if (Platform.isWindows) {
      return WindowsFileHandler();
    }
    if (Platform.isLinux) {
      return LinuxFileHandler();
    }
    if (Platform.isAndroid) {
      return AndroidFileHandler();
    }

    throw PlatformNotSupportedException(_getCurrentPlatformName());
  }

  /// Creates a platform-specific version detector implementation
  static IPlatformVersionDetector createVersionDetector() {
    final fileHandler = createFileHandler();

    if (Platform.isWindows) {
      return WindowsVersionDetector(
        PreferencesService(),
        InstallationService(PreferencesService(), fileHandler),
      );
    }
    if (Platform.isLinux) {
      return LinuxVersionDetector(
        PreferencesService(),
        InstallationService(PreferencesService(), fileHandler),
      );
    }
    if (Platform.isAndroid) {
      return AndroidVersionDetector(PreferencesService());
    }

    throw PlatformNotSupportedException(_getCurrentPlatformName());
  }

  /// Gets the current platform name as a string
  ///
  /// Uses caching to avoid repeated platform detection calls.
  static String _getCurrentPlatformName() {
    _cachedPlatformName ??= _detectPlatformName();
    return _cachedPlatformName!;
  }

  /// Internal method to detect the current platform name
  static String _detectPlatformName() {
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isMacOS) return 'macOS';
    return 'Unknown (${Platform.operatingSystem})';
  }

  /// Checks if the current platform is supported
  ///
  /// Returns true if the current platform has an implementation available.
  /// Note: macOS is detected but not yet fully supported.
  static bool isCurrentPlatformSupported() {
    return Platform.isWindows || Platform.isLinux || Platform.isAndroid;
  }

  /// Gets a list of all supported platforms
  static List<String> getSupportedPlatforms() {
    return ['Windows', 'Linux', 'Android'];
  }

  /// Gets a list of all platforms that can be detected (including future support)
  static List<String> getDetectablePlatforms() {
    return ['Windows', 'Linux', 'Android', 'macOS'];
  }

  /// Checks if a file extension is supported on the current platform
  ///
  /// [extension] - File extension to check (with or without leading dot)
  ///
  /// Returns true if the extension is supported on the current platform.
  static bool isFileExtensionSupported(String extension) {
    try {
      final config = getCurrentPlatformConfig();
      final normalizedExtension = extension.startsWith('.')
          ? extension.toLowerCase()
          : '.${extension.toLowerCase()}';
      return config.supportedFileExtensions.contains(normalizedExtension);
    } catch (e) {
      return false;
    }
  }

  /// Checks if a release channel is supported on the current platform
  ///
  /// [channel] - Release channel to check (stable/nightly)
  ///
  /// Returns true if the channel is supported on the current platform.
  static bool isChannelSupported(String channel) {
    try {
      final config = getCurrentPlatformConfig();
      return config.supportedChannels.contains(channel.toLowerCase());
    } catch (e) {
      return false;
    }
  }

  /// Gets the supported file extensions for the current platform
  ///
  /// Returns a list of supported file extensions, or empty list if platform is unsupported.
  static List<String> getSupportedFileExtensions() {
    try {
      final config = getCurrentPlatformConfig();
      return List.unmodifiable(config.supportedFileExtensions);
    } catch (e) {
      return [];
    }
  }

  /// Gets the supported release channels for the current platform
  ///
  /// Returns a list of supported channels, or empty list if platform is unsupported.
  static List<String> getSupportedChannels() {
    try {
      final config = getCurrentPlatformConfig();
      return List.unmodifiable(config.supportedChannels);
    } catch (e) {
      return [];
    }
  }

  /// Validates an installation context for the current platform
  ///
  /// [context] - Installation context to validate
  ///
  /// Throws appropriate exceptions if the context is invalid for the current platform.
  static void validateInstallationContext(InstallationContext context) {
    final config = getCurrentPlatformConfig();

    // Check if the channel is supported
    if (!config.supportedChannels.contains(context.channel.toLowerCase())) {
      throw PlatformOperationException(
        config.name,
        'validateInstallationContext',
        'Channel "${context.channel}" is not supported on ${config.name}. '
            'Supported channels: ${config.supportedChannels.join(', ')}',
      );
    }

    // Check if shortcuts are requested but not supported
    if (context.createShortcuts && !config.supportsShortcuts) {
      throw PlatformOperationException(
        config.name,
        'validateInstallationContext',
        'Desktop shortcuts are not supported on ${config.name}',
      );
    }

    // Check if portable mode is requested but not supported
    if (context.portableMode && !config.supportsPortableMode) {
      throw PlatformOperationException(
        config.name,
        'validateInstallationContext',
        'Portable mode is not supported on ${config.name}',
      );
    }
  }

  /// Resets the cached platform detection results
  ///
  /// This method is primarily for testing purposes to allow platform detection
  /// to be re-run with different conditions.
  static void resetCache() {
    _cachedConfig = null;
    _cachedPlatformName = null;
  }

  /// Gets detailed platform information for debugging
  ///
  /// Returns a map containing detailed information about the current platform.
  static Map<String, dynamic> getPlatformInfo() {
    try {
      final config = getCurrentPlatformConfig();
      return {
        'platformName': _getCurrentPlatformName(),
        'isSupported': isCurrentPlatformSupported(),
        'operatingSystem': Platform.operatingSystem,
        'operatingSystemVersion': Platform.operatingSystemVersion,
        'supportedExtensions': config.supportedFileExtensions,
        'supportedChannels': config.supportedChannels,
        'supportsShortcuts': config.supportsShortcuts,
        'supportsPortableMode': config.supportsPortableMode,
        'requiresExecutablePermissions': config.requiresExecutablePermissions,
        'defaultInstallationDir': config.defaultInstallationDir,
      };
    } catch (e) {
      return {
        'platformName': _getCurrentPlatformName(),
        'isSupported': false,
        'operatingSystem': Platform.operatingSystem,
        'operatingSystemVersion': Platform.operatingSystemVersion,
        'error': e.toString(),
      };
    }
  }
}
