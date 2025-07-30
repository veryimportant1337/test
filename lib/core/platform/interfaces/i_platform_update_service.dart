import '../../../models/update_info.dart';

/// Abstract interface for platform-specific update service operations
abstract class IPlatformUpdateService {
  /// Gets the supported release channels for the current platform
  List<String> getSupportedChannels();

  /// Checks if a release channel is supported on the current platform
  bool isChannelSupported(String channel);

  /// Gets platform-specific installation metadata for a channel
  ///
  /// [channel] - Release channel (stable/nightly)
  ///
  /// Returns platform-specific metadata or null if not found
  Future<Map<String, String>?> getInstallationMetadata(String channel);

  /// Stores platform-specific installation metadata for a channel
  ///
  /// [channel] - Release channel (stable/nightly)
  /// [metadata] - Platform-specific metadata to store
  Future<void> storeInstallationMetadata(
    String channel,
    Map<String, String> metadata,
  );

  /// Clears platform-specific installation metadata for a channel
  ///
  /// [channel] - Release channel (stable/nightly)
  Future<void> clearInstallationMetadata(String channel);

  /// Gets platform information for debugging and logging
  Map<String, dynamic> getPlatformInfo();

  /// Performs platform-specific cleanup of temporary files
  ///
  /// [tempDir] - Temporary directory to clean up
  /// [downloadedFilePath] - Downloaded file path to clean up
  Future<void> cleanupTempFiles(String? tempDir, String? downloadedFilePath);
}
