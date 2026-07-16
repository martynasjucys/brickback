import 'package:flutter/widgets.dart';

/// Motion tokens + **Reduce Motion** gating — a Flutter port of the Swift oracle
/// `apps/ios/BrickBack/DesignSystem/Motion.swift`. One place for the app's
/// animation curves/durations so every screen's motion reads as one system, and
/// one gate so all of it collapses to an instant change when the user turns on
/// *Settings ▸ Accessibility ▸ Motion ▸ Reduce Motion* (surfaced to Flutter as
/// `MediaQuery.disableAnimations`).
///
/// Swift expresses these as SwiftUI springs; Flutter implicit animations take a
/// duration + curve, so each spring is mapped to the nearest duration/curve pair:
/// - `reveal`  spring(0.34, 0.82) → 340ms easeOutBack (gentle overshoot)
/// - `state`   spring(0.30, 0.72) → 300ms easeOutBack (bouncier fill)
/// - `progress` easeInOut 0.32    → 320ms easeInOut (no overshoot on a value bar)
class Motion {
  Motion._();

  /// Interactive-reveal — expand/collapse moments (action clusters, sheets).
  static const revealDuration = Duration(milliseconds: 340);
  static const revealCurve = Curves.easeOutBack;

  /// State-change fill for count tiles / completion (neutral → started → complete).
  static const stateDuration = Duration(milliseconds: 300);
  static const stateCurve = Curves.easeOutBack;

  /// Progress sweep (ring trim, bar width) — eased, no overshoot.
  static const progressDuration = Duration(milliseconds: 320);
  static const progressCurve = Curves.easeInOut;

  /// Scale-on-press (mirrors Swift `PressableStyle`'s 0.09s ease-out).
  static const pressDuration = Duration(milliseconds: 90);
  static const pressCurve = Curves.easeOut;

  /// Whether the user has asked for reduced motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// [base] unless Reduce Motion is on, in which case [Duration.zero] (instant).
  /// Feed straight into `AnimatedFoo(duration: Motion.gate(context, ...))`.
  static Duration gate(BuildContext context, Duration base) =>
      reduced(context) ? Duration.zero : base;
}
