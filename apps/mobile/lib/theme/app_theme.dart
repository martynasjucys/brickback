import 'package:flutter/material.dart';

/// BrickBack design tokens — **WIREFRAME fidelity** (Phase 1–4).
///
/// Deliberately low-fidelity: grayscale, boxy, hairline borders. The goal is to
/// validate the flow, not the visuals. The polish pass (Phase 9) swaps this one
/// file for the branded palette + typography — **keep these token NAMES stable**
/// so screens don't need to change.
class AppColors {
  AppColors._();

  // Neutrals (the whole wireframe lives here)
  static const canvas = Color(0xFFF4F4F5); // page background
  static const card = Color(0xFFFFFFFF); // surfaces
  static const line = Color(0xFFD4D4D8); // hairline borders
  static const ink = Color(0xFF18181B); // primary text / headings
  static const inkSoft = Color(0xFF52525B); // secondary text
  static const muted = Color(0xFF9CA3AF); // tertiary / placeholders
  static const faint = Color(0xFFE4E4E7); // fills, skeletons

  // Single interactive accent (grayscale-ink in wireframe; brand color in Phase 9)
  static const primary = Color(0xFF18181B);
  static const onPrimary = Color(0xFFFFFFFF);

  // Semantic (kept muted so it still reads as a wireframe; recolored in Phase 9)
  static const success = Color(0xFF3F6212);
  static const warning = Color(0xFF92600A);
  static const danger = Color(0xFF991B1B);
  static const info = Color(0xFF334155);
}

class AppSpacing {
  AppSpacing._();
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s40 = 40.0;
  static const screen = 20.0; // page gutter
}

class AppRadius {
  AppRadius._();
  // Boxy on purpose for the wireframe stage.
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 16.0;
  static const pill = 999.0;
}

class AppText {
  AppText._();
  // System font in wireframe (no google_fonts branding yet — Phase 9).
  static const _base = TextStyle(color: AppColors.ink, height: 1.25);

  static final display = _base.copyWith(fontSize: 30, fontWeight: FontWeight.w700);
  static final h1 = _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700);
  static final h2 = _base.copyWith(fontSize: 20, fontWeight: FontWeight.w700);
  static final title = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
  static final body = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w400);
  static final label = _base.copyWith(fontSize: 13, fontWeight: FontWeight.w600);
  static final caption =
      _base.copyWith(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.inkSoft);
}

/// Framework host theme. Material is used only as a scaffold — all splash/hover
/// chrome is stripped so custom widgets fully own the look (whatabrick pattern).
ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.canvas,
    ),
    scaffoldBackgroundColor: AppColors.canvas,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    splashColor: Colors.transparent,
    fontFamily: null,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}
