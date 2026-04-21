import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Centralized haptic feedback service.
///
/// Maps UI interactions to platform-appropriate tactile feedback.
/// Respects system haptic settings automatically.
abstract class HapticService {
  /// Light impact — keypad digits, category select, switch toggle.
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact — button press, keypad operator, long press start.
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact — error states, over-budget warning.
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection click — small discrete changes, scroll snap.
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Success notification — expense saved, milestone reached.
  static Future<void> success() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Error notification — invalid input, biometric fail.
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.heavyImpact();
  }

  /// Warning notification — delete action, budget at 100%.
  static Future<void> warning() async {
    await HapticFeedback.mediumImpact();
  }

  /// Double heavy warning — over budget.
  static Future<void> doubleWarning() async {
    await heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await heavyImpact();
  }

  /// Milestone celebration pattern.
  static Future<void> milestone() async {
    await mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await success();
  }

  /// Vibrate for devices without haptic engines.
  static Future<void> vibrate({int durationMs = 50}) async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      await Vibration.vibrate(duration: durationMs);
    }
  }
}
