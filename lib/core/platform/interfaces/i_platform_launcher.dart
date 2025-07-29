/// Abstract interface for platform-specific launching operations
abstract class IPlatformLauncher {
  /// Launches the Eden emulator application
  Future<void> launchEden();

  /// Creates a desktop shortcut for the Eden emulator
  Future<void> createDesktopShortcut();

  /// Finds the Eden executable in the given installation path
  ///
  /// [installPath] - Path to the Eden installation directory
  /// [channel] - Release channel (stable/nightly)
  ///
  /// Returns the path to the executable or null if not found
  Future<String?> findEdenExecutable(String installPath, String channel);
}
