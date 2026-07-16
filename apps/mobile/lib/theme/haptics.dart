import 'package:flutter/services.dart';

/// The app's haptic vocabulary — a Flutter port of the Swift oracle
/// `apps/ios/BrickBack/DesignSystem/Haptics.swift`. The counting loop's map:
/// a **selection** tick per count, a **medium** thud when a tap finishes a single
/// part, a **light** tap when touching an already-complete part, and a richer
/// **celebration** when the whole set reaches 100%.
///
/// Swift plays the set-complete flourish through CoreHaptics (three rising
/// transient taps + a soft swell). Flutter has no CoreHaptics binding, so the
/// celebration is approximated with a short rising impact sequence
/// (light → medium → heavy). Every call degrades silently to a no-op on hardware
/// (or a Simulator) without a Taptic engine.
class Haptics {
  Haptics._();

  /// A light selection tick — one per count.
  static void selection() => HapticFeedback.selectionClick();

  /// A medium impact — a tap just finished a single part.
  static void impactMedium() => HapticFeedback.mediumImpact();

  /// A light impact — touching a part that's already complete.
  static void light() => HapticFeedback.lightImpact();

  /// The whole set just reached 100% — a rising light→medium→heavy flourish.
  static Future<void> celebrate() async {
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.heavyImpact();
  }
}
