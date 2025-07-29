/// Abstract interface for platform-specific file operations
abstract class IPlatformFileHandler {
  /// Checks if the given filename is an Eden executable for this platform
  ///
  /// [filename] - Name of the file to check
  ///
  /// Returns true if the file is an Eden executable
  bool isEdenExecutable(String filename);

  /// Gets the expected path to the Eden executable within an installation
  ///
  /// [installPath] - Path to the installation directory
  /// [channel] - Release channel (stable/nightly), can be null
  ///
  /// Returns the expected path to the executable
  String getEdenExecutablePath(String installPath, String? channel);

  /// Makes a file executable (relevant for Unix-like systems)
  ///
  /// [filePath] - Path to the file to make executable
  Future<void> makeExecutable(String filePath);

  /// Checks if a folder contains Eden application files
  ///
  /// [folderPath] - Path to the folder to check
  ///
  /// Returns true if the folder contains Eden files
  Future<bool> containsEdenFiles(String folderPath);
}
