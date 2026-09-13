import 'package:flutter/services.dart';

/// Bridges to a tiny bit of native Android code (see MainActivity.kt)
/// that sends the app to the background without killing its process or
/// clearing its task — the same effect as pressing the remote's Home
/// button, but available as an in-app button for TV boxes where Home
/// isn't always convenient to reach. The background service (see
/// background_service.dart) keeps the clock speaking normally afterwards.
class NativeWindow {
  static const _channel = MethodChannel('talking_clock/window');

  static Future<void> minimize() async {
    try {
      await _channel.invokeMethod('minimize');
    } catch (_) {
      // If the platform channel isn't available for any reason, just do
      // nothing rather than crash — minimizing is a convenience, not a
      // critical feature.
    }
  }
}
