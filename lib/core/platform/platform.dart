// Platform Abstraction Layer
// This file provides a single import point for all platform abstraction components

// Core interfaces
export 'interfaces/i_platform_installer.dart';
export 'interfaces/i_platform_launcher.dart';
export 'interfaces/i_platform_file_handler.dart';
export 'interfaces/i_platform_version_detector.dart';

// Data models
export 'models/platform_config.dart';
export 'models/installation_context.dart';

// Exceptions
export 'exceptions/platform_exceptions.dart';

// Factory
export 'platform_factory.dart';

// Examples (for development and documentation)
export 'examples/platform_factory_example.dart';
