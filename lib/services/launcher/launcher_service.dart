import '../../core/services/logging_service.dart';
import '../../core/platform/platform_factory.dart';
import '../../core/platform/interfaces/i_platform_launcher.dart';
import '../storage/preferences_service.dart';
import '../installation/installation_service.dart';

/// Service for launching Eden emulator
///
/// This service has been refactored to use platform abstractions instead of
/// embedded platform-specific logic. All platform-specific operations are
/// now delegated to platform-specific implementations through the IPlatformLauncher interface.
class LauncherService {
  final IPlatformLauncher _platformLauncher;

  LauncherService(
    PreferencesService preferencesService,
    InstallationService installationService,
  ) : _platformLauncher = PlatformFactory.createLauncherWithServices(
        preferencesService,
        installationService,
      );

  /// Launch the Eden emulator
  ///
  /// Delegates to the platform-specific launcher implementation.
  /// All platform-specific logic has been moved to the platform implementations.
  Future<void> launchEden() async {
    try {
      LoggingService.info('Launching Eden using platform abstraction');
      await _platformLauncher.launchEden();
      LoggingService.info('Eden launched successfully');
    } catch (e) {
      LoggingService.error('Failed to launch Eden', e);
      rethrow;
    }
  }

  /// Create a desktop shortcut for Eden
  ///
  /// Delegates to the platform-specific launcher implementation.
  /// All platform-specific logic has been moved to the platform implementations.
  Future<void> createDesktopShortcut() async {
    try {
      LoggingService.info(
        'Creating desktop shortcut using platform abstraction',
      );
      await _platformLauncher.createDesktopShortcut();
      LoggingService.info('Desktop shortcut created successfully');
    } catch (e) {
      LoggingService.error('Failed to create desktop shortcut', e);
      rethrow;
    }
  }

  /// Finds the Eden executable in the given installation path
  ///
  /// This method delegates to the platform-specific implementation
  /// for finding the Eden executable.
  Future<String?> findEdenExecutable(String installPath, String channel) async {
    try {
      LoggingService.info('Finding Eden executable using platform abstraction');
      final result = await _platformLauncher.findEdenExecutable(
        installPath,
        channel,
      );
      if (result != null) {
        LoggingService.info('Eden executable found: $result');
      } else {
        LoggingService.warning('Eden executable not found');
      }
      return result;
    } catch (e) {
      LoggingService.error('Error finding Eden executable', e);
      return null;
    }
  }
}
