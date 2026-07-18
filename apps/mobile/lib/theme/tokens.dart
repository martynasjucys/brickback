import 'package:flutter/material.dart';

/// BrickBack design tokens — **LEGO "Build Together" clone** identity (Redesign
/// V1). This layer is a faithful reskin toward the reference screens in
/// `docs/design`: a **pale sky-blue page**, crisp **white cards** floating on a
/// soft blue shadow, big **rounded, chunky** type, and a strict accent language —
///
/// - **blue** owns the brand headers + the primary confirm action + info/progress,
/// - **yellow** is the hero/"go" accent (Start Building, Join party, search FAB,
///   the selected filter chip) — a raised brick that clicks down when pressed,
/// - **purple** is the party field,
/// - **green** is owned/complete, **red** is retired/destructive.
///
/// **Names are stable.** The S1–F5 screens reference these token *names* directly
/// (several as compile-time `const`s); this pass swaps the *values* and adds the
/// new `accent`/`onAccent`/`accentEdge` trio without renaming anything.
///
/// **Dark mode:** [AppColors] is the light snapshot, [AppColorsDark] the dark one;
/// the `BrickColors` ThemeExtension (see `app_theme.dart`) resolves the dark-aware
/// set for the primitives, the Flutter analog of the Swift dynamic token.

/// Clone **light** palette.
class AppColors {
  AppColors._();

  // Neutrals — pale sky-blue page, white cards.
  static const canvas = Color(0xFFDCEAF7); // page background (home / body)
  static const card = Color(0xFFFFFFFF); // card + button top face
  static const cardEdge = Color(0xFFDBE4F0); // 3D bottom lip on white controls
  static const line = Color(0xFFE4EAF2); // hairline borders
  static const ink = Color(0xFF1B2436); // primary text / headings (near-black navy)
  static const inkSoft = Color(0xFF5B6675); // secondary text
  static const muted = Color(0xFF98A2B3); // tertiary / placeholders
  static const faint = Color(0xFFEDF3F9); // fills, skeletons, tracks

  /// Ambient drop-shadow tint — a soft blue-black (cards float, not glow).
  static const shadow = Color(0xFF14223E);

  // Brand — the header field. A deep blue plate that owns the collapsing headers.
  static const brand = Color(0xFF1E51D4);
  static const brandDeep = Color(0xFF123A9E); // header gradient deep end
  static const brandEdge = Color(0xFF0E2C77); // blue plate's raised lip

  // Counting / "Rebuild" field — a green brick plate (legacy; kept for parity).
  static const build = Color(0xFF2E9E4F);
  static const buildDeep = Color(0xFF238B43);
  static const buildEdge = Color(0xFF155F2D);

  // Party field — a purple brick plate.
  static const party = Color(0xFF6D28D9);
  static const partyDeep = Color(0xFF4C1D95);
  static const partyEdge = Color(0xFF38156F);

  // Profile field — legacy warm orange (kept; the header now rides `brand`).
  static const profile = Color(0xFFF0730C);
  static const profileDeep = Color(0xFFD35F08);
  static const profileEdge = Color(0xFF854005);

  // Primary action — the bright LEGO blue confirm button ("Show N sets").
  static const primary = Color(0xFF2F6BF0);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryEdge = Color(0xFF1D4FC4);

  // Accent — LEGO yellow. The hero/"go" action + selected state. Raised brick.
  static const accent = Color(0xFFFFD21E);
  static const onAccent = Color(0xFF1B2436); // black text on yellow
  static const accentEdge = Color(0xFFE6B400); // yellow plate's raised lip

  // Semantic.
  static const success = Color(0xFF3FA34D); // owned / complete (green)
  static const successEdge = Color(0xFF2E7D32);
  static const warning = Color(0xFFF2A20C);
  static const danger = Color(0xFFE23B37); // retired / destructive (red)
  static const info = Color(0xFF2F6BF0); // progress-in-motion (== primary blue)

  // LEGO-primary accent set — party avatars cycle these.
  static const legoRed = Color(0xFFE4000F);
  static const legoBlue = Color(0xFF0F62D6);
  static const legoGreen = Color(0xFF009B48);
  static const legoOrange = Color(0xFFF5720B);
  static const legoPurple = Color(0xFF8A3FD1);
}

/// Clone **dark** palette. Field names mirror [AppColors].
class AppColorsDark {
  AppColorsDark._();

  // Neutrals — deep navy page, raised slate cards.
  static const canvas = Color(0xFF0F1826);
  static const card = Color(0xFF1A2436);
  static const cardEdge = Color(0xFF0C1420);
  static const line = Color(0xFF2A374B);
  static const ink = Color(0xFFEAF0F8);
  static const inkSoft = Color(0xFFA7B2C2);
  static const muted = Color(0xFF6E7B8E);
  static const faint = Color(0xFF232F42);

  static const shadow = Color(0xFF000000);

  static const brand = Color(0xFF2A5EE0);
  static const brandDeep = Color(0xFF173B9C);
  static const brandEdge = Color(0xFF0B2154);

  static const build = Color(0xFF2C9A4C);
  static const buildDeep = Color(0xFF1E7C3A);
  static const buildEdge = Color(0xFF0D4620);

  static const party = Color(0xFF7C3AED);
  static const partyDeep = Color(0xFF5B21B6);
  static const partyEdge = Color(0xFF3A1470);

  static const profile = Color(0xFFF5810A);
  static const profileDeep = Color(0xFFDE760C);
  static const profileEdge = Color(0xFF5A2E08);

  static const primary = Color(0xFF3E7BF5);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryEdge = Color(0xFF2154C4);

  static const accent = Color(0xFFFFD84D);
  static const onAccent = Color(0xFF14203A);
  static const accentEdge = Color(0xFFD9A800);

  static const success = Color(0xFF43B054);
  static const successEdge = Color(0xFF2E8B3D);
  static const warning = Color(0xFFF5B43C);
  static const danger = Color(0xFFF0524E);
  static const info = Color(0xFF4C8DF6);

  static const legoRed = Color(0xFFFF3B45);
  static const legoBlue = Color(0xFF3E86F0);
  static const legoGreen = Color(0xFF24B56E);
  static const legoOrange = Color(0xFFFF8C33);
  static const legoPurple = Color(0xFFA96BE0);
}

/// Spacing scale.
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

/// Layout bounds. (tile-width bounds wire the adaptive counting grid, F3.)
class AppLayout {
  AppLayout._();
  static const readableWidth = 620.0;
  static const tileMin = 104.0;
  static const tileMinRegular = 150.0;
  static const tileMax = 176.0;
  static const tileMaxRegular = 200.0;
}

/// Corner radii — the clone is rounder/chunkier than the wireframe. `button` is
/// the rounded-square (squircle-ish) radius of the top action buttons + FAB;
/// `card`/`xl` round the big surfaces.
class AppRadius {
  AppRadius._();
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 28.0;
  static const button = 20.0; // action buttons / FAB (rounded square)
  static const card = 26.0; // list + hero cards
  static const pill = 999.0;
}

/// Depth of a brick plate's bottom lip — how far a raised surface sits above its
/// shadow edge, and how far it travels when pressed.
class AppDepth {
  AppDepth._();
  static const brick = 6.0; // panels / cards
  static const tile = 5.0; // buttons / small controls
  static const cta = 6.0; // hero yellow/blue CTAs (chunkier click)
}

/// Typographic scale — heavier, rounder, LEGO-toy weights.
///
/// **Deviation:** the reference uses a bespoke rounded face; Flutter has no
/// bundled rounded font here, so every style uses the platform system font at the
/// matched size/weight (headings pushed to w800/w900 to read as chunky). Bundling
/// a rounded face (e.g. Nunito) later is the one note that gets closer still.
class AppText {
  AppText._();
  // No baked colour: styles inherit the ambient `DefaultTextStyle`, set to the
  // brightness-correct `BrickColors.ink` by the Material theme.
  static const _base = TextStyle(height: 1.2);

  static final display = _base.copyWith(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5);
  static final h1 = _base.copyWith(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3);
  static final h2 = _base.copyWith(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.2);
  static final title = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w700);
  static final body = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w500, height: 1.35);
  static final label = _base.copyWith(fontSize: 13, fontWeight: FontWeight.w700);
  static final caption = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w600);
}
