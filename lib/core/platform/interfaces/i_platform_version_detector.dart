import '../../../models/update_info.dart';

/// Abstract interface for platform-specific version detection and storage
abstract class IPlatformVersionDetector {
  /// Gets the currently installed version information for the given channel
  ///
  /// [channel] - Release channel (stable/nightly)
  ///
  /// Returns the current version info or null if not found
  Future<UpdateInfo?> getCurrentVersion(String channel);

  /// Stores version information for the given channel
  ///
  /// [updateInfo] - Version information to store
  /// [channel] - Release channel (stable/nightly)
  Future<void> storeVersionInfo(UpdateInfo updateInfo, String channel);

  /// Clears stored version information for the given channel
  ///
  /// [channel] - Release channel (stable/nightly)
  Future<void> clearVersionInfo(String channel);
}
