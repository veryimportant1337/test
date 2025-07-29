# Platform Implementation Developer Guide

This guide provides detailed instructions for implementing platform support in Eden Updater's platform abstraction layer.

## Overview

Eden Updater uses a platform abstraction layer that separates platform-specific code from business logic. To add support for a new platform, you need to implement four core interfaces and update the platform factory.

## Required Interfaces

### 1. IPlatformInstaller

Handles platform-specific installation operations.

```dart
abstract class IPlatformInstaller {
  /// Check if this installer can handle the given file
  Future<bool> canHandle(String filePath);
  
  /// Install the update file
  Future<void> install(
    String filePath,
    UpdateInfo updateInfo, {
    required bool createShortcuts,
    required bool portableMode,
    required Function(double) onProgress,
    required Function(String) onStatusUpdate,
  });
  
  /// Perform post-installation setup
  Future<void> postInstallSetup(String installPath, UpdateInfo updateInfo);
}
```

**Implementation Tips:**
- Check file extensions and signatures in `canHandle()`
- Handle platform-specific installation methods (APK intents, DMG mounting, etc.)
- Provide detailed progress updates
- Handle errors gracefully with platform-specific exceptions

### 2. IPlatformLauncher

Manages application launching and shortcut creation.

```dart
abstract class IPlatformLauncher {
  /// Launch the Eden application
  Future<void> launchEden();
  
  /// Create a desktop shortcut
  Future<void> createDesktopShortcut();
  
  /// Find the Eden executable in the installation
  Future<String?> findEdenExecutable(String installPath, String channel);
}
```

**Implementation Tips:**
- Handle different executable types (.exe, .app, .AppImage, APK packages)
- Create platform-appropriate shortcuts (.lnk, .desktop, etc.)
- Implement fallback mechanisms for finding executables
- Handle permission requirements for launching

### 3. IPlatformFileHandler

Provides platform-specific file operations.

```dart
abstract class IPlatformFileHandler {
  /// Check if filename is an Eden executable
  bool isEdenExecutable(String filename);
  
  /// Get expected executable path
  String getEdenExecutablePath(String installPath, String? channel);
  
  /// Make file executable (Unix-like systems)
  Future<void> makeExecutable(String filePath);
  
  /// Check if folder contains Eden files
  Future<bool> containsEdenFiles(String folderPath);
}
```

**Implementation Tips:**
- Define platform-specific executable patterns
- Handle file permissions appropriately
- Implement efficient file scanning
- Consider platform-specific file structures

### 4. IPlatformVersionDetector

Manages version detection and storage.

```dart
abstract class IPlatformVersionDetector {
  /// Get currently installed version
  Future<UpdateInfo?> getCurrentVersion(String channel);
  
  /// Update version information
  Future<void> updateVersionInfo(String channel, UpdateInfo updateInfo);
  
  /// Clear version information
  Future<void> clearVersionInfo(String channel);
}
```

**Implementation Tips:**
- Use platform-appropriate storage (Registry, plist files, SharedPreferences)
- Handle version migration between channels
- Implement robust error handling for storage operations
- Consider backup and recovery mechanisms

## Step-by-Step Implementation

### Step 1: Create Platform Directory

Create a new directory for your platform:
```
lib/core/platform/implementations/[platform]/
├── [platform]_installer.dart
├── [platform]_launcher.dart
├── [platform]_file_handler.dart
└── [platform]_version_detector.dart
```

### Step 2: Implement Interfaces

Start with the file handler as other components depend on it:

```dart
// macos_file_handler.dart
class MacOSFileHandler implements IPlatformFileHandler {
  @override
  bool isEdenExecutable(String filename) {
    return filename.toLowerCase() == 'eden.app' ||
           filename.toLowerCase().endsWith('.app');
  }
  
  @override
  String getEdenExecutablePath(String installPath, String? channel) {
    return path.join(installPath, 'Eden.app');
  }
  
  @override
  Future<void> makeExecutable(String filePath) async {
    // macOS .app bundles are executable by default
    // But we might need to set execute permissions on the binary inside
    final binaryPath = path.join(filePath, 'Contents', 'MacOS', 'Eden');
    if (await File(binaryPath).exists()) {
      await Process.run('chmod', ['+x', binaryPath]);
    }
  }
  
  @override
  Future<bool> containsEdenFiles(String folderPath) async {
    final dir = Directory(folderPath);
    await for (final entity in dir.list()) {
      if (entity is Directory && isEdenExecutable(path.basename(entity.path))) {
        return true;
      }
    }
    return false;
  }
}
```

### Step 3: Add Platform Configuration

Add your platform to `PlatformConfig`:

```dart
// In platform_config.dart
static const macos = PlatformConfig(
  name: 'macOS',
  supportedFileExtensions: ['.dmg', '.app', '.zip'],
  supportedChannels: ['stable', 'nightly'],
  supportsShortcuts: true,
  supportsPortableMode: false,
  requiresExecutablePermissions: true,
  defaultInstallationDir: '/Applications/Eden',
);
```

### Step 4: Update Platform Factory

Add platform detection and factory methods:

```dart
// In platform_factory.dart

// Add to _detectPlatformConfig()
if (Platform.isMacOS) return PlatformConfig.macos;

// Add to createInstaller()
if (Platform.isMacOS) {
  return MacOSInstaller(
    ExtractionService(fileHandler),
    InstallationService(PreferencesService(), fileHandler),
    PreferencesService(),
  );
}

// Add similar blocks for other factory methods
```

### Step 5: Handle Platform-Specific Installation

Example macOS installer implementation:

```dart
class MacOSInstaller implements IPlatformInstaller {
  @override
  Future<bool> canHandle(String filePath) async {
    final extension = path.extension(filePath).toLowerCase();
    return extension == '.dmg' || extension == '.app' || extension == '.zip';
  }
  
  @override
  Future<void> install(String filePath, UpdateInfo updateInfo, {
    required bool createShortcuts,
    required bool portableMode,
    required Function(double) onProgress,
    required Function(String) onStatusUpdate,
  }) async {
    final extension = path.extension(filePath).toLowerCase();
    
    if (extension == '.dmg') {
      await _installFromDMG(filePath, onProgress, onStatusUpdate);
    } else if (extension == '.app') {
      await _installAppBundle(filePath, onProgress, onStatusUpdate);
    } else if (extension == '.zip') {
      await _installFromZip(filePath, onProgress, onStatusUpdate);
    }
  }
  
  Future<void> _installFromDMG(String dmgPath, Function(double) onProgress, Function(String) onStatusUpdate) async {
    // Mount DMG, copy app bundle, unmount
    onStatusUpdate('Mounting disk image...');
    final mountResult = await Process.run('hdiutil', ['attach', dmgPath]);
    // ... implementation details
  }
}
```

## Testing Your Implementation

### Unit Tests

Create comprehensive unit tests for each interface:

```dart
// test/core/platform/implementations/macos/macos_file_handler_test.dart
void main() {
  group('MacOSFileHandler', () {
    late MacOSFileHandler fileHandler;
    
    setUp(() {
      fileHandler = MacOSFileHandler();
    });
    
    test('should detect Eden.app as executable', () {
      expect(fileHandler.isEdenExecutable('Eden.app'), isTrue);
      expect(fileHandler.isEdenExecutable('SomeOther.app'), isFalse);
    });
    
    // More tests...
  });
}
```

### Integration Tests

Test the platform factory integration:

```dart
test('should create macOS implementations on macOS platform', () {
  // Mock Platform.isMacOS to return true
  final installer = PlatformFactory.createInstaller();
  expect(installer, isA<MacOSInstaller>());
});
```

## Best Practices

### Error Handling

Use platform-specific exceptions:

```dart
throw PlatformOperationException(
  'macOS',
  'install',
  'Failed to mount DMG file: $dmgPath',
);
```

### Logging

Use the centralized logging service:

```dart
LoggingService.info('Starting macOS installation from DMG');
LoggingService.error('DMG mounting failed', error);
```

### Async Operations

Handle long-running operations with proper progress reporting:

```dart
for (int i = 0; i < steps.length; i++) {
  await steps[i]();
  onProgress((i + 1) / steps.length);
  onStatusUpdate('Completed step ${i + 1} of ${steps.length}');
}
```

### Resource Cleanup

Always clean up temporary resources:

```dart
try {
  // Mount DMG
  // Copy files
} finally {
  // Unmount DMG
  await Process.run('hdiutil', ['detach', mountPoint]);
}
```

## Platform-Specific Considerations

### macOS
- Handle code signing and Gatekeeper
- Use proper app bundle structure
- Implement DMG mounting/unmounting
- Handle permission dialogs

### iOS (Future)
- Use iOS-specific installation methods
- Handle App Store vs. enterprise distribution
- Implement proper sandboxing

### Web (Future)
- Handle browser-specific download mechanisms
- Implement progressive web app installation
- Use browser storage APIs

## Common Pitfalls

1. **Forgetting to update all factory methods** - Make sure to add your platform to all four factory methods
2. **Not handling permissions** - Different platforms have different permission models
3. **Inadequate error handling** - Platform operations can fail in many ways
4. **Not testing edge cases** - Test with corrupted files, insufficient permissions, etc.
5. **Blocking the UI thread** - Use proper async/await patterns

## Getting Help

- Check existing implementations for patterns
- Review the platform abstraction interfaces
- Look at the test files for examples
- Consult the main architecture documentation

## Conclusion

The platform abstraction layer makes adding new platforms straightforward by providing clear interfaces and patterns. Follow this guide, implement the four core interfaces, and your platform will integrate seamlessly with the rest of Eden Updater.