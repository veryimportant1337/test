import '../../services/update_service.dart';
import '../../services/network/github_api_service.dart';
import '../../services/storage/preferences_service.dart';
import '../../services/download/download_service.dart';
import '../../services/extraction/extraction_service.dart';
import '../../services/installation/installation_service.dart';
import '../../services/launcher/launcher_service.dart';
import '../platform/platform_factory.dart';

/// Simple service locator for dependency injection
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};

  /// Register a service
  void register<T>(T service) {
    _services[T] = service;
  }

  /// Get a service
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T not registered');
    }
    return service as T;
  }

  /// Initialize all services
  static void initialize() {
    final locator = ServiceLocator();

    // Register core services as singletons
    final preferencesService = PreferencesService();
    final fileHandler = PlatformFactory.createFileHandler();

    locator.register<PreferencesService>(preferencesService);
    locator.register<GitHubApiService>(GitHubApiService());
    locator.register<DownloadService>(DownloadService());
    locator.register<ExtractionService>(ExtractionService(fileHandler));

    // Register services that depend on others
    final installationService = InstallationService(
      preferencesService,
      fileHandler,
    );
    locator.register<InstallationService>(installationService);

    locator.register<LauncherService>(
      LauncherService(preferencesService, installationService),
    );

    // Register platform-specific services as singletons
    final platformInstaller = PlatformFactory.createInstaller();
    final platformVersionDetector = PlatformFactory.createVersionDetector();
    final platformUpdateService =
        PlatformFactory.createUpdateServiceWithServices(preferencesService);

    // Register the main update service
    locator.register<UpdateService>(
      UpdateService.withServices(
        locator.get<GitHubApiService>(),
        preferencesService,
        locator.get<DownloadService>(),
        locator.get<LauncherService>(),
        platformInstaller,
        platformVersionDetector,
        platformUpdateService,
      ),
    );
  }
}
