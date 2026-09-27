import 'package:flutter/foundation.dart';

/// Environment configuration for the Agua app.
///
/// The API base URL is declared, not guessed. Platform sniffing is unreliable
/// here: `flutter run -d web-server` and the Android emulator both answer
/// `kIsWeb == false` in some builds, and the emulator address
/// (`10.0.2.2`) is unreachable from a normal browser or desktop, which shows
/// up only as an opaque `ClientFailed to fetch`.
///
/// Pass an explicit value instead:
///   flutter run -d web-server --dart-define=API_BASE_URL=http://localhost:8000
class EnvConfig {
  EnvConfig._();

  /// Compile-time override, e.g. `--dart-define=API_BASE_URL=http://host:8000`.
  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Backend API base URL, without a trailing slash.
  ///
  /// Order: explicit override, then a platform default. The default keeps the
  /// Android emulator mapping working for a real device build.
  static String get baseUrl {
    final configured = _override.trim();
    if (configured.isNotEmpty) {
      return _stripTrailingSlash(configured);
    }
    // Web: the browser runs on the host, so localhost is the host itself.
    // Mobile: 10.0.2.2 is the host as seen from the Android emulator.
    return _stripTrailingSlash(kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000');
  }

  /// Whether the app is running in web mode.
  static bool get isWeb => kIsWeb;

  static String _stripTrailingSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
