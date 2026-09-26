import 'package:flutter/foundation.dart';

/// Environment configuration for the Agua app.
///
/// Detects the current platform and provides the correct API base URL.
/// In web, `localhost` is used since `10.0.2.2` (Android emulator) doesn't
/// exist in a browser context.
class EnvConfig {
  EnvConfig._();

  /// Backend API base URL, adapted per platform.
  static String get baseUrl {
    if (kIsWeb) {
      // Web: browser runs on the host machine, so localhost points to it.
      // The backend container exposes port 8000.
      return 'http://localhost:8000';
    }

    // Mobile (Android emulator): 10.0.2.2 maps to the host's localhost.
    return 'http://10.0.2.2:8000';
  }

  /// Whether the app is running in web mode.
  static bool get isWeb => kIsWeb;
}
