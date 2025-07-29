# Platform Abstraction Layer

This directory contains the platform abstraction layer for Eden Updater, which provides a clean separation between platform-specific code and the rest of the application.

## Overview

The platform abstraction layer uses the **Strategy Pattern** combined with **Factory Pattern** to handle platform-specific operations. This design makes it easy to:

- Add support for new platforms
- Test platform-specific functionality
- Maintain clean separation of concerns
- Ensure consistent behavior across platforms

## Architecture

```
Platform Abstraction Layer
├── Core Interfaces (Abstract contracts)
├── Platform Implementations (Concrete strategies) - [To be implemented in tasks 3-5]
├── Platform Factory (Runtime selection)
├── Data Models (Configuration and context)
├── Exceptions (Platform-specific errors)
└── Examples (Usage demonstrations)
```

## Components

### Core Interfaces

Located in `interfaces/`:

- **`IPlatformInstaller`**: Handles platform-specific installation operations
- **`IPlatformLauncher`**: Manages application launching and shortcut creation
- **`IPlatformFileHandler`**: Provides platform-specific file operations
- **`IPlatformVersionDetector`**: Manages version detection and storage

### Platform Factory

The `PlatformFactory` class provides:

- **Runtime platform detection** with caching for performance
- **Factory methods** for creating platform-specific implementations
- **Capability checking** for file extensions and release channels
- **Validation methods** for installation contexts
- **Utility methods** for platform information and debugging

### Data Models

Located in `models/`:

- **`PlatformConfig`**: Defines platform capabilities and settings
- **`InstallationContext`**: Provides context for installation operations

### Exceptions

Located in `exceptions/`:

- **`PlatformNotSupportedException`**: Thrown for unsupported platforms
- **`PlatformOperationException`**: Thrown for failed platform operations
- **`UnsupportedFileTypeException`**: Thrown for unsupported file types
- **`PlatformInstallationException`**: Thrown for installation failures
- **`PlatformLauncherException`**: Thrown for launcher operation failures
- **`PlatformFileException`**: Thrown for file operation failures
- **`PlatformVersionException`**: Thrown for version detection failures

## Usage

### Basic Platform Detection

```dart
import 'package:eden_updater/core/platform/platform.dart';

// Get current platform configuration
final config = PlatformFactory.getCurrentPlatformConfig();
print('Platform: ${config.name}');
print('Supported extensions: ${config.supportedFileExtensions}');

// Check platform support
if (PlatformFactory.isCurrentPlatformSupported()) {
  print('Platform is supported');
}
```

### Capability Checking

```dart
// Check if a file extension is supported
if (PlatformFactory.isFileExtensionSupported('.exe')) {
  print('Windows executables are supported');
}

// Check if a release channel is supported
if (PlatformFactory.isChannelSupported('nightly')) {
  print('Nightly channel is supported');
}
```

### Installation Context Validation

```dart
final context = InstallationContext(
  filePath: '/path/to/update.zip',
  installPath: '/path/to/install',
  updateInfo: updateInfo,
  createShortcuts: true,
  portableMode: false,
  channel: 'stable',
  onProgress: (progress) => print('Progress: $progress'),
  onStatusUpdate: (status) => print('Status: $status'),
);

try {
  PlatformFactory.validateInstallationContext(context);
  // Context is valid, proceed with installation
} catch (PlatformOperationException e) {
  // Handle validation error
  print('Invalid context: ${e.details}');
}
```

### Creating Platform Implementations (Future)

```dart
// These will be available after tasks 3-5 are completed
final installer = PlatformFactory.createInstaller();
final launcher = PlatformFactory.createLauncher();
final fileHandler = PlatformFactory.createFileHandler();
final versionDetector = PlatformFactory.createVersionDetector();
```

## Platform Support

### Currently Supported Platforms

- **Windows**: `.exe`, `.zip`, `.7z` files with shortcut and portable mode support
- **Linux**: `.AppImage`, `.tar.gz`, `.zip` files with shortcut and portable mode support
- **Android**: `.apk` files with limited channel support (stable only by default)

### Future Platform Support

- **macOS**: `.dmg`, `.app`, `.zip` files (configuration ready, implementation pending)

## Implementation Status

### ✅ Completed (Task 2)

- Platform factory with runtime detection
- Platform configuration constants
- Factory registration and selection logic
- Comprehensive error handling
- Utility methods for capability checking
- Installation context validation
- Caching for performance optimization
- Detailed platform information gathering
- Unit tests and examples

### 🔄 Pending (Tasks 3-5)

- Windows platform implementations
- Linux platform implementations  
- Android platform implementations
- Service integration and refactoring

## Testing

Run the platform factory tests:

```bash
flutter test test/core/platform/platform_factory_test.dart
```

## Examples

See `examples/platform_factory_example.dart` for comprehensive usage examples.

## Adding New Platforms

To add support for a new platform:

1. **Add platform configuration** to `PlatformConfig` class
2. **Update platform detection** in `PlatformFactory._detectPlatformConfig()`
3. **Implement platform interfaces** in `implementations/[platform]/`
4. **Update factory methods** to create new implementations
5. **Add platform-specific tests**
6. **Update documentation**

## Design Principles

- **Single Responsibility**: Each interface handles one specific concern
- **Open/Closed Principle**: Easy to extend with new platforms without modifying existing code
- **Dependency Inversion**: Services depend on abstractions, not concrete implementations
- **Factory Pattern**: Centralized creation of platform-specific implementations
- **Strategy Pattern**: Platform-specific behavior encapsulated in separate classes