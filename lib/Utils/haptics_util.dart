import 'package:flutter/services.dart';

import 'app_provider.dart';

/// Haptic feedback routed through the user's haptics toggle. The method set
/// mirrors [HapticFeedback]; when the setting is off every call is a no-op,
/// when it is on these are pass-throughs.
class LoftifyHaptics {
  static bool get _enabled => appProvider.hapticsEnabled;

  static Future<void> lightImpact() =>
      _enabled ? HapticFeedback.lightImpact() : Future<void>.value();

  static Future<void> mediumImpact() =>
      _enabled ? HapticFeedback.mediumImpact() : Future<void>.value();

  static Future<void> heavyImpact() =>
      _enabled ? HapticFeedback.heavyImpact() : Future<void>.value();

  static Future<void> selectionClick() =>
      _enabled ? HapticFeedback.selectionClick() : Future<void>.value();

  static Future<void> vibrate() =>
      _enabled ? HapticFeedback.vibrate() : Future<void>.value();
}
