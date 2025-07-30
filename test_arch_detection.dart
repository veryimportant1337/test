import 'lib/core/platform/models/platform_config.dart';

void main() {
  // Test the Linux asset patterns
  final linuxConfig = PlatformConfig.linux;

  // Test asset pattern matching
  final testAssets = [
    'Eden-Linux-v0.0.3-rc2-aarch64.AppImage',
    'Eden-Linux-v0.0.3-rc2-amd64.AppImage',
    'Eden-Linux-v0.0.3-rc2-armv9.AppImage',
    'Eden-Windows-v0.0.3-rc2-x86_64.7z',
  ];

  for (final asset in testAssets) {
    bool matches = false;
    for (int i = 0; i < linuxConfig.assetSearchPatterns.length; i++) {
      if (linuxConfig.assetSearchPatterns[i](asset.toLowerCase())) {
        matches = true;
        break;
      }
    }
    if (!matches) {}
  }
}
