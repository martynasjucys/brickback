import SwiftUI

/// BrickBack design tokens — **branded** (S7). The S1–S6 screens were built against these token
/// *names* while the values were a deliberately low-fidelity grayscale wireframe; S7 swaps the
/// values (and a few primitive internals) for the real LEGO-toy identity without touching feature
/// code. **Keep the names stable.**
///
/// Identity: a warm cream page, white "brick plate" surfaces that sit *raised* on a darker bottom
/// lip (see `BrickSurface`), LEGO-primary accents, and a rounded, chunky display type. Brand
/// yellow owns the header + wordmark; **red** is the primary action (high-contrast, and it keeps
/// every existing `AppColors.primary` tint — spinners, toggles, chips — reading crisply); **blue**
/// is progress-in-motion; **green** is done/verified.
enum AppColors {
    // Neutrals — warm, cream-based.
    static let canvas = Color(hex: 0xF6F3E7) // page background (warm cream)
    static let card = Color(hex: 0xFFFFFF) // surface — the top face of a brick plate
    static let cardEdge = Color(hex: 0xE6E1D0) // white plate's bottom lip (the raised "3D" edge)
    static let line = Color(hex: 0xEAE5D6) // hairline borders on warm surfaces
    static let ink = Color(hex: 0x1C1C21) // primary text / headings
    static let inkSoft = Color(hex: 0x6B6A72) // secondary text
    static let muted = Color(hex: 0xACA89B) // tertiary / placeholders (warm)
    static let faint = Color(hex: 0xEDE9DC) // fills, skeletons (warm)

    // Brand — LEGO blue. Owns the header field + wordmark, not the CTAs.
    static let brand = Color(hex: 0x0253C4)
    static let brandDeep = Color(hex: 0x0349B0) // header gradient bottom / deeper brand blue
    static let brandEdge = Color(hex: 0x012E73) // blue plate's raised bottom lip (the 3D edge)

    // Counting / "Rebuild" header field — a green brick plate, distinct from the blue home header.
    static let build = Color(hex: 0x2E9E4F)
    static let buildDeep = Color(hex: 0x238B43) // header gradient bottom / deeper green
    static let buildEdge = Color(hex: 0x155F2D) // green plate's raised bottom lip (the 3D edge)

    // Primary action — a LEGO-red brick. onPrimary is white; primaryEdge is the pressed lip.
    static let primary = Color(hex: 0xE4000F)
    static let onPrimary = Color(hex: 0xFFFFFF)
    static let primaryEdge = Color(hex: 0xB00009)

    // Semantic.
    static let success = Color(hex: 0x2E9E4F) // complete / verified (green)
    static let successEdge = Color(hex: 0x217A3C)
    static let warning = Color(hex: 0xE39A00)
    static let danger = Color(hex: 0xC62828)
    static let info = Color(hex: 0x1B74E4) // progress-in-motion (blue)

    // LEGO-primary accent set — the rainbow wordmark cycles these (yellow omitted: it vanishes on
    // the brand header).
    static let legoRed = Color(hex: 0xE4000F)
    static let legoBlue = Color(hex: 0x0F62D6)
    static let legoGreen = Color(hex: 0x009B48)
    static let legoOrange = Color(hex: 0xF5720B)
    static let legoPurple = Color(hex: 0x8A3FD1)
}

enum AppSpacing {
    static let s4: CGFloat = 4
    static let s8: CGFloat = 8
    static let s12: CGFloat = 12
    static let s16: CGFloat = 16
    static let s20: CGFloat = 20
    static let s24: CGFloat = 24
    static let s32: CGFloat = 32
    static let s40: CGFloat = 40
    static let screen: CGFloat = 20 // page gutter
}

enum AppRadius {
    // Softer + rounder than the wireframe — friendly, toy-like. Primitives pair these with
    // `.continuous` corners for the squircle "moulded plastic" feel.
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 18
    static let xl: CGFloat = 24
    static let pill: CGFloat = 999
}

/// The depth of a brick plate's bottom lip — how far a surface sits above its shadow edge, and
/// how far it travels when pressed. See `BrickSurface`.
enum AppDepth {
    static let brick: CGFloat = 5 // panels / cards
    static let tile: CGFloat = 4 // buttons / small controls
}

/// Typographic scale. Display + headings + labels use **SF Rounded** (`design: .rounded`) — the
/// native, Dynamic-Type-ready face that reads playful and "LEGO-toy" without a bundled font.
/// Body + caption stay SF Pro for dense-text legibility (a deliberate display/body pairing).
/// Fonts only — apply the ink colour at the call site.
enum AppText {
    static let display = Font.system(size: 30, weight: .heavy, design: .rounded)
    static let h1 = Font.system(size: 25, weight: .bold, design: .rounded)
    static let h2 = Font.system(size: 20, weight: .bold, design: .rounded)
    static let title = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 15, weight: .regular)
    static let label = Font.system(size: 13, weight: .bold, design: .rounded)
    static let caption = Font.system(size: 12, weight: .medium)
}

extension Color {
    /// Build a Color from a 0xRRGGBB literal (design tokens are authored as hex).
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
