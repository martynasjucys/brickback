import 'package:flutter/material.dart';

import 'tokens.dart';

// Re-export the token layer + motion/haptics so existing `import
// 'theme/app_theme.dart'` call sites keep resolving `AppColors`, `AppText`, etc.
export 'tokens.dart';
export 'motion.dart';
export 'haptics.dart';

/// The dark-aware semantic palette, resolved from the active [Theme]. This is the
/// Flutter analog of the Swift `Color(lightHex:darkHex:)` dynamic token: the
/// branded primitives + the design gallery read `BrickColors.of(context)` so they
/// render correctly in light **and** dark with no per-call-site branching.
///
/// (Legacy screens still reference the `const` [AppColors] light snapshot directly;
/// migrating them to `BrickColors.of(context)` is what unlocks full app-wide dark —
/// a bounded follow-up left to the phase that owns those screen files.)
@immutable
class BrickColors extends ThemeExtension<BrickColors> {
  const BrickColors({
    required this.canvas,
    required this.card,
    required this.cardEdge,
    required this.line,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.faint,
    required this.shadow,
    required this.brand,
    required this.brandDeep,
    required this.brandEdge,
    required this.party,
    required this.partyDeep,
    required this.partyEdge,
    required this.primary,
    required this.onPrimary,
    required this.primaryEdge,
    required this.accent,
    required this.onAccent,
    required this.accentEdge,
    required this.success,
    required this.successEdge,
    required this.warning,
    required this.danger,
    required this.info,
  });

  final Color canvas;
  final Color card;
  final Color cardEdge;
  final Color line;
  final Color ink;
  final Color inkSoft;
  final Color muted;
  final Color faint;
  final Color shadow;
  final Color brand;
  final Color brandDeep;
  final Color brandEdge;
  final Color party;
  final Color partyDeep;
  final Color partyEdge;
  final Color primary;
  final Color onPrimary;
  final Color primaryEdge;
  final Color accent;
  final Color onAccent;
  final Color accentEdge;
  final Color success;
  final Color successEdge;
  final Color warning;
  final Color danger;
  final Color info;

  static const light = BrickColors(
    canvas: AppColors.canvas,
    card: AppColors.card,
    cardEdge: AppColors.cardEdge,
    line: AppColors.line,
    ink: AppColors.ink,
    inkSoft: AppColors.inkSoft,
    muted: AppColors.muted,
    faint: AppColors.faint,
    shadow: AppColors.shadow,
    brand: AppColors.brand,
    brandDeep: AppColors.brandDeep,
    brandEdge: AppColors.brandEdge,
    party: AppColors.party,
    partyDeep: AppColors.partyDeep,
    partyEdge: AppColors.partyEdge,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryEdge: AppColors.primaryEdge,
    accent: AppColors.accent,
    onAccent: AppColors.onAccent,
    accentEdge: AppColors.accentEdge,
    success: AppColors.success,
    successEdge: AppColors.successEdge,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
  );

  static const dark = BrickColors(
    canvas: AppColorsDark.canvas,
    card: AppColorsDark.card,
    cardEdge: AppColorsDark.cardEdge,
    line: AppColorsDark.line,
    ink: AppColorsDark.ink,
    inkSoft: AppColorsDark.inkSoft,
    muted: AppColorsDark.muted,
    faint: AppColorsDark.faint,
    shadow: AppColorsDark.shadow,
    brand: AppColorsDark.brand,
    brandDeep: AppColorsDark.brandDeep,
    brandEdge: AppColorsDark.brandEdge,
    party: AppColorsDark.party,
    partyDeep: AppColorsDark.partyDeep,
    partyEdge: AppColorsDark.partyEdge,
    primary: AppColorsDark.primary,
    onPrimary: AppColorsDark.onPrimary,
    primaryEdge: AppColorsDark.primaryEdge,
    accent: AppColorsDark.accent,
    onAccent: AppColorsDark.onAccent,
    accentEdge: AppColorsDark.accentEdge,
    success: AppColorsDark.success,
    successEdge: AppColorsDark.successEdge,
    warning: AppColorsDark.warning,
    danger: AppColorsDark.danger,
    info: AppColorsDark.info,
  );

  /// The active brick palette, or the light snapshot when no theme carries it.
  static BrickColors of(BuildContext context) =>
      Theme.of(context).extension<BrickColors>() ?? light;

  @override
  BrickColors copyWith({
    Color? canvas,
    Color? card,
    Color? cardEdge,
    Color? line,
    Color? ink,
    Color? inkSoft,
    Color? muted,
    Color? faint,
    Color? shadow,
    Color? brand,
    Color? brandDeep,
    Color? brandEdge,
    Color? party,
    Color? partyDeep,
    Color? partyEdge,
    Color? primary,
    Color? onPrimary,
    Color? primaryEdge,
    Color? accent,
    Color? onAccent,
    Color? accentEdge,
    Color? success,
    Color? successEdge,
    Color? warning,
    Color? danger,
    Color? info,
  }) {
    return BrickColors(
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      cardEdge: cardEdge ?? this.cardEdge,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      shadow: shadow ?? this.shadow,
      brand: brand ?? this.brand,
      brandDeep: brandDeep ?? this.brandDeep,
      brandEdge: brandEdge ?? this.brandEdge,
      party: party ?? this.party,
      partyDeep: partyDeep ?? this.partyDeep,
      partyEdge: partyEdge ?? this.partyEdge,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryEdge: primaryEdge ?? this.primaryEdge,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentEdge: accentEdge ?? this.accentEdge,
      success: success ?? this.success,
      successEdge: successEdge ?? this.successEdge,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
    );
  }

  @override
  BrickColors lerp(ThemeExtension<BrickColors>? other, double t) {
    if (other is! BrickColors) return this;
    return BrickColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardEdge: Color.lerp(cardEdge, other.cardEdge, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandDeep: Color.lerp(brandDeep, other.brandDeep, t)!,
      brandEdge: Color.lerp(brandEdge, other.brandEdge, t)!,
      party: Color.lerp(party, other.party, t)!,
      partyDeep: Color.lerp(partyDeep, other.partyDeep, t)!,
      partyEdge: Color.lerp(partyEdge, other.partyEdge, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryEdge: Color.lerp(primaryEdge, other.primaryEdge, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentEdge: Color.lerp(accentEdge, other.accentEdge, t)!,
      success: Color.lerp(success, other.success, t)!,
      successEdge: Color.lerp(successEdge, other.successEdge, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

/// Branded light theme.
final ThemeData appLightTheme = _buildTheme(Brightness.light);

/// Branded dark theme.
final ThemeData appDarkTheme = _buildTheme(Brightness.dark);

/// Framework host theme. Material is used only as a scaffold — all splash/hover
/// chrome is stripped so the branded primitives fully own the look. Both schemes
/// are built from the token layer so dark mode is `ThemeMode` + a dark
/// `ColorScheme`, with no per-widget branching.
ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final c = isDark ? BrickColors.dark : BrickColors.light;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.primary, // LEGO-red CTA
    onPrimary: c.onPrimary,
    secondary: c.brand, // brand blue
    onSecondary: Colors.white,
    surface: c.card,
    onSurface: c.ink,
    surfaceContainerHighest: c.faint,
    outline: c.line,
    error: c.danger,
    onError: Colors.white,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.canvas,
    canvasColor: c.canvas,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    splashColor: Colors.transparent,
    fontFamily: null, // platform system font (see AppText deviation note)
    extensions: [c],
    dividerColor: c.line,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.primary,
      selectionColor: c.primary.withValues(alpha: 0.25),
      selectionHandleColor: c.primary,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : c.card,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.primary : c.faint,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.primary : c.line,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: c.card,
      showDragHandle: false,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.ink,
      contentTextStyle: TextStyle(color: c.canvas),
      behavior: SnackBarBehavior.floating,
    ),
    iconTheme: IconThemeData(color: c.ink),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink),
  );
}
