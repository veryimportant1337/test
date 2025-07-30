/// Configuration class that defines platform-specific capabilities and settings
class PlatformConfig {
  /// Human-readable name of the platform
  final String name;

  /// List of file extensions this platform can handle (e.g., ['.exe', '.zip'])
  final List<String> supportedFileExtensions;

  /// List of release channels supported by this platform
  final List<String> supportedChannels;

  /// Whether this platform supports creating desktop shortcuts
  final bool supportsShortcuts;

  /// Whether this platform supports portable mode installation
  final bool supportsPortableMode;

  /// Whether this platform requires executable permissions to be set
  final bool requiresExecutablePermissions;

  /// Default installation directory name for this platform
  final String defaultInstallationDir;

  const PlatformConfig({
    required this.name,
    required this.supportedFileExtensions,
    required this.supportedChannels,
    required this.supportsShortcuts,
    required this.supportsPortableMode,
    required this.requiresExecutablePermissions,
    required this.defaultInstallationDir,
  });

  /// Windows platform configuration
  static const windows = PlatformConfig(
    name: 'Windows',
    supportedFileExtensions: ['.exe', '.zip', '.7z'],
    supportedChannels: ['stable', 'nightly'],
    supportsShortcuts: true,
    supportsPortableMode: true,
    requiresExecutablePermissions: false,
    defaultInstallationDir: 'Eden',
  );

  /// Linux platform configuration
  static const linux = PlatformConfig(
    name: 'Linux',
    supportedFileExtensions: ['.AppImage', '.tar.gz', '.zip'],
    supportedChannels: ['stable', 'nightly'],
    supportsShortcuts: true,
    supportsPortableMode: true,
    requiresExecutablePermissions: true,
    defaultInstallationDir: 'Eden',
  );

  /// Android platform configuration
  static const android = PlatformConfig(
    name: 'Android',
    supportedFileExtensions: ['.apk'],
    supportedChannels: [
      'stable',
      'nightly',
    ], // Both channels supported, availability checked at runtime
    supportsShortcuts: false,
    supportsPortableMode: false,
    requiresExecutablePermissions: false,
    defaultInstallationDir: '', // Not applicable for Android
  );

  /// macOS platform configuration (future support)
  static const macos = PlatformConfig(
    name: 'macOS',
    supportedFileExtensions: ['.dmg', '.app', '.zip'],
    supportedChannels: ['stable', 'nightly'],
    supportsShortcuts: true,
    supportsPortableMode: true,
    requiresExecutablePermissions: true,
    defaultInstallationDir: 'Eden',
  );

  @override
  String toString() =>
      'PlatformConfig(name: $name, extensions: $supportedFileExtensions)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlatformConfig &&
        other.name == name &&
        other.supportedFileExtensions.length ==
            supportedFileExtensions.length &&
        other.supportedFileExtensions.every(
          (ext) => supportedFileExtensions.contains(ext),
        );
  }

  @override
  int get hashCode => Object.hash(name, supportedFileExtensions);
}
