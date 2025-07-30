import 'dart:io';

import 'interfaces/i_platform_installer.dart';
import 'interfaces/i_platform_launcher.dart';
import 'interfaces/i_platform_file_handler.dart';
import 'interfaces/i_platform_version_detector.dart';
import 'interfaces/i_platform_update_service.dart';
import 'interfaces/i_platform_installation_service.dart';
import 'models/platform_config.dart';
import 'models/installation_context.dart';
import 'exceptions/platform_exceptions.dart';
import '../services/logging_service.dart';

// Platform implementations
import 'implementations/windows/windows_installer.dart';
import 'implementations/windows/windows_launcher.dart';
import 'implementations/windows/windows_file_handler.dart';
import 'implementations/windows/windows_version_detector.dart';
import 'implementations/windows/windows_update_service.dart';
import 'implementations/windows/windows_installation_service.dart';
import 'implementations/linux/linux_installer.dart';
import 'implementations/linux/linux_launcher.dart';
import 'implementations/linux/linux_file_handler.dart';
import 'implementations/linux/linux_version_detector.dart';
import 'implementations/linux/linux_update_service.dart';
import 'implementations/linux/linux_installation_service.dart';
import 'implementations/android/android_installer.dart';
import 'implementations/android/android_launcher.dart';
import 'implementations/android/android_file_handler.dart';
import 'implementations/android/android_version_detector.dart';
import 'implementations/android/android_update_service.dart';
import 'implementations/android/android_installation_service.dart';

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
    if (_cachedConfig == null) {
      LoggingService.debug(
        '[PlatformFactory] Detecting platform configuration...',
      );
      _cachedConfig = _detectPlatformConfig();
      LoggingService.info(
        '[PlatformFactory] Platform detected: ${_cachedConfig!.name}',
      );
      LoggingService.debug(
        '[PlatformFactory] Platform capabilities: ${_cachedConfig!.supportedChannels}, shortcuts: ${_cachedConfig!.supportsShortcuts}, portable: ${_cachedConfig!.supportsPortableMode}',
      );
    }
    return _cachedConfig!;
  }

  /// Internal method to detect the current platform configuration
  static PlatformConfig _detectPlatformConfig() {
    LoggingService.debug(
      '[PlatformFactory] Running platform detection checks...',
    );
    LoggingService.debug(
      '[PlatformFactory] Platform.operatingSystem: ${Platform.operatingSystem}',
    );
    LoggingService.debug(
      '[PlatformFactory] Platform.operatingSystemVersion: ${Platform.operatingSystemVersion}',
    );

    if (Platform.isWindows) {
      LoggingService.debug('[PlatformFactory] Platform.isWindows: true');
      return PlatformConfig.windows;
    }
    if (Platform.isLinux) {
      LoggingService.debug('[PlatformFactory] Platform.isLinux: true');
      return PlatformConfig.linux;
    }
    if (Platform.isAndroid) {
      LoggingService.debug('[PlatformFactory] Platform.isAndroid: true');
      return PlatformConfig.android;
    }
    if (Platform.isMacOS) {
      LoggingService.debug(
        '[PlatformFactory] Platform.isMacOS: true (unsupported)',
      );
      return PlatformConfig.macos;
    }

    final platformName = _getCurrentPlatformName();
    LoggingService.error(
      '[PlatformFactory] Unsupported platform detected: $platformName',
    );
    throw PlatformNotSupportedException(platformName);
  }

  /// Creates a platform-specific installer implementation
  static IPlatformInstaller createInstaller() {
    final platformName = _getCurrentPlatformName();
    LoggingService.debug(
      '[PlatformFactory] Creating installer for platform: $platformName',
    );

    final fileHandler = createFileHandler();

    if (Platform.isWindows) {
      LoggingService.info('[PlatformFactory] Instantiating WindowsInstaller');
      return WindowsInstaller(
        ExtractionService(fileHandler),
        InstallationService(PreferencesService(), fileHandler),
        PreferencesService(),
      );
    }
    if (Platform.isLinux) {
      LoggingService.info('[PlatformFactory] Instantiating LinuxInstaller');
      return LinuxInstaller(
        ExtractionService(fileHandler),
        InstallationService(PreferencesService(), fileHandler),
        PreferencesService(),
      );
    }
    if (Platform.isAndroid) {
      LoggingService.info('[PlatformFactory] Instantiating AndroidInstaller');
      return AndroidInstaller();
    }

    LoggingService.error(
      '[PlatformFactory] No installer implementation available for platform: $platformName',
    );
    throw PlatformNotSupportedException(platformName);
  }

  /// Creates a platform-specific launcher implementation
  static IPlatformLauncher createLauncher() {
    final platformName = _getCurrentPlatformName();
    LoggingService.debug(
      '[PlatformFactory] Creating launcher for platform: $platformName',
    );

    final fileHandler = createFileHandler();

    if (Platform.isWindows) {
      LoggingService.info('[PlatformFactory] Instantiating WindowsLauncher');
      return WindowsLauncher(
        PreferencesService(),
        InstallationService(PreferencesService(), fileHandler),
      );
    }
    if (Platform.isLinux) {
      LoggingService.info('[PlatformFactory] Instantiating LinuxLauncher');
      return LinuxLauncher(
        PreferencesService(),
        InstallationService(PreferencesService(), fileHandler),
      );
    }
    if (Platform.isAndroid) {
      LoggingService.info('[PlatformFactory] Instantiating AndroidLauncher');
      return AndroidLauncher(PreferencesService());
    }

    LoggingService.error(
      '[PlatformFactory] No launcher implementation available for platform: $platformName',
    );
    throw PlatformNotSupportedException(platformName);
  }

  /// Creates a platform-specific launcher implementation with provided services
  static IPlatformLauncher createLauncherWithServices(
    PreferencesService preferencesService,
    InstallationService installationService,
  ) {
    final platformName = _getCurrentPlatformName();
    LoggingService.debug(
      '[PlatformFactory] Creating launcher with services for platform: $platformName',
    );

    if (Platform.isWindows) {
      LoggingService.info(
        '[PlatformFactory] Instantiating WindowsLauncher with provided services',
      );
      return WindowsLauncher(preferencesService, installationService);
    }
    if (Platform.isLinux) {
      LoggingService.info(
        '[PlatformFactory] Instantiating LinuxLauncher with provided services',
      );
      return LinuxLauncher(preferencesService, installationService);
    }
    if (Platform.isAndroid) {
      LoggingService.info(
        '[PlatformFactory] Instantiating AndroidLauncher with provided services',
      );
      return AndroidLauncher(preferencesService);
    }

    LoggingService.error(
      '[PlatformFactory] No launcher implementation available for platform: $platformName',
    );
    throw PlatformNotSupportedException(platformName);
  }

  /// Creates a platform-specific file handler implementation
  static IPlatformFileHandler createFileHandler() {
    final platformName = _getCurrentPlatformName();
    LoggingService.debug(
      '[PlatformFactory] Creating file handler for platform: $platformName',
    );

    if (Platform.isWindows) {
      LoggingService.info('[PlatformFactory] Instantiating WindowsFileHandler');
      return WindowsFileHandler();
    }
    if (Platform.isLinux) {
      LoggingService.info('[PlatformFactory] Instantiating LinuxFileHandler');
      return LinuxFileHandler();
    }
    if (Platform.isAndroid) {
      LoggingService.info('[PlatformFactory] Instantiating AndroidFileHandler');
      return AndroidFileHandler();
    }

    LoggingService.error(
      '[PlatformFactory] No file handler implementation available for platform: $platformName',
    );
    throw PlatformNotSupportedException(platformName);
  }

  /// Creates a platform-specific version detector implementation
  static IPlatformVersionDetector createVersionDetector() {
    final platformName = _getCurrentPlatformName();
    LoggingService.debug(
      '[PlatformFactory] Creating version detector for platform: $platformName',
    );

    final fileHandler = createFileHandler();

    if (Platform.isWindows) {
      LoggingService.info(
        '[PlatformFactory] Instantiating WindowsVersionDetector',
      );
      return WindowsVersionDetector(
        PreferencesService(),
        InstallationService(PreferencesService(), fileHandler),
      );
    }
    if (Platform.isLinux) {
      LoggingService.info(
        '[PlatformFactory] Instantiating LinuxVersionDetector',
      );
      return LinuxVersionDetector(
        PreferencesService(),
        InstallationService(PreferencesService(), fileHandler),
      );
    }
    if (Platform.isAndroid) {
      LoggingService.info(
        '[PlatformFactory] Instantiating AndroidVersionDetector',
      );
      return AndroidVersionDetector(PreferencesService());
    }

    LoggingService.error(
      '[PlatformFactory] No version detector implementation available for platform: $platformName',
    );
    throw PlatformNotSupportedException(platformName);
  }

  /// Creates a platform-specific update service implementation
  static IPlatformUpdateService createUpdateService() {
    final platformName = _getCurrentPlatformName();
    LoggingService.debug(
      '[PlatformFactory] Creating update service for platform: $platformName',
    );

    if (Platform.isWindows) {
      LoggingService.info(
        '[PlatformFactory] Instantiating WindowsUpdateService',
      );
      return WindowsUpdateService(PreferencesService());
    }
    if (Platform.isLinux) {
      LoggingService.info('[PlatformFactory] Instantiating LinuxUpdateService');
      return LinuxUpdateService(PreferencesService());
    }
    if (Platform.isAndroid) {
      LoggingService.info(
        '[PlatformFactory] Instantiating AndroidUpdateService',
      );
      return AndroidUpdateService(PreferencesService());
    }

    LoggingService.error(
      '[PlatformFactory] No update service implementation available for platform: $platformName',
    );
    throw PlatformNotSupportedException(platformName);
  }

  /// Creates a platform-specific update service implementation with provided services
  static IPlatformUpdateService createUpdateServiceWithServices(
    PreferencesService preferencesService,
  ) {
    final platformName = _getCurrentPlatformName();
    LoggingService.debug(
      '[PlatformFactory] Creating update service with services for platform: $platformName',
    );

    if (Platform.isWindows) {
      LoggingService.info(
        '[PlatformFactory] Instantiating WindowsUpdateService with provided services',
      );
      return WindowsUpdateService(preferencesService);
    }
    if (Platform.isLinux) {
      LoggingService.info(
        '[PlatformFactory] Instantiating LinuxUpdateService with provided services',
      );
      return LinuxUpdateService(preferencesService);
    }
    if (Platform.isAndroid) {
      LoggingService.info(
        '[PlatformFactory] Instantiating AndroidUpdateService with provided services',
      );
      return AndroidUpdateService(preferencesService);
    }

    LoggingService.error(
      '[PlatformFactory] No update service implementation available for platform: $platformName',
    );
    throw PlatformNotSupportedException(platformName);
  }

  /// Creates a platform-specific installation service implementation
  static IPlatformInstallationService createInstallationService() {
    final platformName = _getCurrentPlatformName();
    LoggingService.debug(
      '[PlatformFactory] Creating installation service for platform: $platformName',
    );

    final fileHandler = createFileHandler();

    if (Platform.isWindows) {
      LoggingService.info(
        '[PlatformFactory] Instantiating WindowsInstallationService',
      );
      return WindowsInstallationService(fileHandler, PreferencesService());
    }
    if (Platform.isLinux) {
      LoggingService.info(
        '[PlatformFactory] Instantiating LinuxInstallationService',
      );
      return LinuxInstallationService(fileHandler, PreferencesService());
    }
    if (Platform.isAndroid) {
      LoggingService.info(
        '[PlatformFactory] Instantiating AndroidInstallationService',
      );
      return AndroidInstallationService(fileHandler, PreferencesService());
    }

    LoggingService.error(
      '[PlatformFactory] No installation service implementation available for platform: $platformName',
    );
    throw PlatformNotSupportedException(platformName);
  }

  /// Creates a platform-specific installation service implementation with provided services
  static IPlatformInstallationService createInstallationServiceWithServices(
    IPlatformFileHandler fileHandler,
    PreferencesService preferencesService,
  ) {
    final platformName = _getCurrentPlatformName();
    LoggingService.debug(
      '[PlatformFactory] Creating installation service with services for platform: $platformName',
    );

    if (Platform.isWindows) {
      LoggingService.info(
        '[PlatformFactory] Instantiating WindowsInstallationService with provided services',
      );
      return WindowsInstallationService(fileHandler, preferencesService);
    }
    if (Platform.isLinux) {
      LoggingService.info(
        '[PlatformFactory] Instantiating LinuxInstallationService with provided services',
      );
      return LinuxInstallationService(fileHandler, preferencesService);
    }
    if (Platform.isAndroid) {
      LoggingService.info(
        '[PlatformFactory] Instantiating AndroidInstallationService with provided services',
      );
      return AndroidInstallationService(fileHandler, preferencesService);
    }

    LoggingService.error(
      '[PlatformFactory] No installation service implementation available for platform: $platformName',
    );
    throw PlatformNotSupportedException(platformName);
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
