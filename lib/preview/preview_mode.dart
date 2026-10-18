import 'package:flutter/foundation.dart';

/// Enabled only by the separate debug entry point, never by normal startup.
class PreviewMode {
  static bool _requested = false;
  static bool get enabled => kDebugMode && _requested;
  static void enable() {
    if (!kDebugMode) throw UnsupportedError('Önizleme yalnızca debug içindir.');
    _requested = true;
  }

  static const userId = 'preview-user';
}
