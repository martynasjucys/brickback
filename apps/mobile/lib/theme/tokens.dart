import 'package:flutter/material.dart';

/// BrickBack design tokens — **branded** (F2), a 1:1 port of the Swift oracle
/// `apps/ios/BrickBack/DesignSystem/Tokens.swift`. The S1–F1 screens were built
/// against these token *names* while the values were a low-fidelity grayscale
/// wireframe; F2 swaps the values (and a few primitive internals) for the real
/// LEGO-toy identity without touching feature code. **Keep the names stable.**
///
/// Identity: a warm cream page (dark: a warm near-black), white "brick plate"
/// surfaces that sit *raised* on a darker bottom lip (see `BrickSurface`),
/// LEGO-primary accents, and a rounded, chunky display type. Brand blue owns the
/// header + wordmark; **red** is the primary action; **blue** is progress-in-motion;
/// **green** is done/verified.
///
/// **Dark mode:** Flutter `Color` cannot resolve per-appearance the way Swift's
/// `Color(lightHex:darkHex:)` does, and the app's screens reference these tokens
/// as compile-time `const`s (several in forbidden files), so `AppColors` is the
/// **light** snapshot and [AppColorsDark] carries the matching dark values. The
/// `BrickColors` ThemeExtension (see `app_theme.dart`) resolves the dark-aware set
/// for context-aware widgets (the primitives + the design gallery), which is the
/// Flutter analog of the Swift "dynamic token, no call-site change" seam.

/// Branded **light** palette. Field names + values mirror `AppColors` in
/// `Tokens.swift` (the `lightHex` of each dynamic token).
class AppColors {
  AppColors._();

  // Neutrals — warm cream in light.
  static const canvas = Color(0xFFF6F3E7); // page background
  static const card = Color(0xFFFFFFFF); // brick-plate top face
  static const cardEdge = Color(0xFFE6E1D0); // plate's bottom lip (3D edge)
  static const line = Color(0xFFEAE5D6); // hairline borders on surfaces
  static const ink = Color(0xFF1C1C21); // primary text / headings
  static const inkSoft = Color(0xFF6B6A72); // secondary text
  static const muted = Color(0xFFACA89B); // tertiary / placeholders
  static const faint = Color(0xFFEDE9DC); // fills, skeletons, tracks

  /// Ambient drop-shadow tint — dark in both modes (a light shadow would glow).
  static const shadow = Color(0xFF1C1C21);

  // Brand — LEGO blue. Owns the header field + wordmark, not the CTAs.
  static const brand = Color(0xFF0253C4);
  static const brandDeep = Color(0xFF0349B0); // header gradient bottom
  static const brandEdge = Color(0xFF012E73); // blue plate's raised lip

  // Counting / "Rebuild" header field — a green brick plate.
  static const build = Color(0xFF2E9E4F);
  static const buildDeep = Color(0xFF238B43);
  static const buildEdge = Color(0xFF155F2D);

  // Party header field — an indigo brick plate.
  static const party = Color(0xFF4F46E5);
  static const partyDeep = Color(0xFF4034C4);
  static const partyEdge = Color(0xFF272183);

  // Profile header field — a warm orange brick plate.
  static const profile = Color(0xFFF0730C);
  static const profileDeep = Color(0xFFD35F08);
  static const profileEdge = Color(0xFF854005);

  // Primary action — a LEGO-red brick.
  static const primary = Color(0xFFE4000F);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryEdge = Color(0xFFB00009);

  // Semantic.
  static const success = Color(0xFF2E9E4F); // complete / verified (green)
  static const successEdge = Color(0xFF217A3C);
  static const warning = Color(0xFFE39A00);
  static const danger = Color(0xFFC62828);
  static const info = Color(0xFF1B74E4); // progress-in-motion (blue)

  // LEGO-primary accent set — party avatars cycle these.
  static const legoRed = Color(0xFFE4000F);
  static const legoBlue = Color(0xFF0F62D6);
  static const legoGreen = Color(0xFF009B48);
  static const legoOrange = Color(0xFFF5720B);
  static const legoPurple = Color(0xFF8A3FD1);
}

/// Branded **dark** palette. Field names mirror [AppColors]; values are the
/// `darkHex` of each dynamic token in `Tokens.swift`. Consumed by the
/// `BrickColors` ThemeExtension to build the dark scheme.
class AppColorsDark {
  AppColorsDark._();

  // Neutrals — warm near-black in dark.
  static const canvas = Color(0xFF161619);
  static const card = Color(0xFF232228);
  static const cardEdge = Color(0xFF100F13);
  static const line = Color(0xFF37363E);
  static const ink = Color(0xFFF1EFE8);
  static const inkSoft = Color(0xFFA6A5AD);
  static const muted = Color(0xFF706F78);
  static const faint = Color(0xFF2C2B32);

  static const shadow = Color(0xFF000000);

  static const brand = Color(0xFF0B54C0);
  static const brandDeep = Color(0xFF08408F);
  static const brandEdge = Color(0xFF03203C);

  static const build = Color(0xFF2C9A4C);
  static const buildDeep = Color(0xFF1E7C3A);
  static const buildEdge = Color(0xFF0D4620);

  static const party = Color(0xFF5A52EA);
  static const partyDeep = Color(0xFF4238C0);
  static const partyEdge = Color(0xFF1B1856);

  static const profile = Color(0xFFF5810A);
  static const profileDeep = Color(0xFFDE760C);
  static const profileEdge = Color(0xFF5A2E08);

  static const primary = Color(0xFFEC2029);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryEdge = Color(0xFF8F0710);

  static const success = Color(0xFF37B85E);
  static const successEdge = Color(0xFF2A8F49);
  static const warning = Color(0xFFF2AC1E);
  static const danger = Color(0xFFE5484D);
  static const info = Color(0xFF4C93F2);

  static const legoRed = Color(0xFFFF3B45);
  static const legoBlue = Color(0xFF3E86F0);
  static const legoGreen = Color(0xFF24B56E);
  static const legoOrange = Color(0xFFFF8C33);
  static const legoPurple = Color(0xFFA96BE0);
}

/// Spacing scale — identical to `AppSpacing` in `Tokens.swift`.
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

/// Layout bounds — mirrors `AppLayout` in `Tokens.swift`. The tile-width bounds
/// are wired by F3 (adaptive layout); defined here so the token layer is complete.
class AppLayout {
  AppLayout._();
  static const readableWidth = 620.0; // widest comfortable form/card column
  static const tileMin = 104.0; // compact (iPhone)
  static const tileMinRegular = 150.0; // regular (iPad)
  static const tileMax = 176.0;
  static const tileMaxRegular = 200.0;
}

/// Corner radii — softer + rounder than the wireframe. Mirrors `AppRadius` in
/// `Tokens.swift`. (Swift pairs these with `.continuous` squircle corners; Flutter
/// uses circular corners — a small, within-tolerance deviation, see F2-results.)
class AppRadius {
  AppRadius._();
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

/// The depth of a brick plate's bottom lip — how far a surface sits above its
/// shadow edge, and how far it travels when pressed. Mirrors `AppDepth` in
/// `Tokens.swift`.
class AppDepth {
  AppDepth._();
  static const brick = 5.0; // panels / cards
  static const tile = 4.0; // buttons / small controls
}

/// Typographic scale — sizes + weights mirror `AppText` in `Tokens.swift`.
///
/// **Deviation:** Swift uses SF Rounded (`design: .rounded`) for display/heads/
/// labels and SF Pro for body/caption. Flutter has no bundled rounded face and
/// F2 avoids adding a font dependency, so every style uses the platform system
/// font at the matched size/weight. The "rounded, LEGO-toy" quality is the one
/// visual note that can't be reproduced without a bundled font (see F2-results).
class AppText {
  AppText._();
  static const _base = TextStyle(color: AppColors.ink, height: 1.25);

  static final display = _base.copyWith(fontSize: 30, fontWeight: FontWeight.w800);
  static final h1 = _base.copyWith(fontSize: 25, fontWeight: FontWeight.w700);
  static final h2 = _base.copyWith(fontSize: 20, fontWeight: FontWeight.w700);
  static final title = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
  static final body = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w400);
  static final label = _base.copyWith(fontSize: 13, fontWeight: FontWeight.w700);
  static final caption =
      _base.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.inkSoft);
}
