import SwiftUI
import UIKit

/// BrickBack design tokens — **branded** (S7). The S1–S6 screens were built against these token
/// *names* while the values were a deliberately low-fidelity grayscale wireframe; S7 swaps the
/// values (and a few primitive internals) for the real LEGO-toy identity without touching feature
/// code. **Keep the names stable.**
///
/// Identity: a warm cream page (dark: a warm near-black), white "brick plate" surfaces that sit
/// *raised* on a darker bottom lip (see `BrickSurface`), LEGO-primary accents, and a rounded,
/// chunky display type. Brand blue owns the header + wordmark; **red** is the primary action
/// (high-contrast, and it keeps every existing `AppColors.primary` tint — spinners, toggles,
/// chips — reading crisply); **blue** is progress-in-motion; **green** is done/verified.
///
/// **Dark mode (S7):** every token carries a light + dark value via `Color(lightHex:darkHex:)`
/// (a `UIColor(dynamicProvider:)` under the hood), so it resolves to the active appearance with
/// **no call-site change** — the same "swap the values, keep the names" seam. The branded hues
/// (blue/green headers, red CTA) stay vivid in dark; neutral text/icon/semantic tones are lifted
/// for contrast on the dark canvas. The raised-plate identity is preserved: the plate face is a
/// lifted charcoal over an even-darker lip.
enum AppColors {
    // Neutrals — warm cream in light; warm near-black in dark.
    static let canvas = Color(lightHex: 0xF6F3E7, darkHex: 0x161619) // page background
    static let card = Color(lightHex: 0xFFFFFF, darkHex: 0x232228) // brick-plate top face
    static let cardEdge = Color(lightHex: 0xE6E1D0, darkHex: 0x100F13) // plate's bottom lip (3D edge)
    static let line = Color(lightHex: 0xEAE5D6, darkHex: 0x37363E) // hairline borders on surfaces
    static let ink = Color(lightHex: 0x1C1C21, darkHex: 0xF1EFE8) // primary text / headings
    static let inkSoft = Color(lightHex: 0x6B6A72, darkHex: 0xA6A5AD) // secondary text
    static let muted = Color(lightHex: 0xACA89B, darkHex: 0x706F78) // tertiary / placeholders
    static let faint = Color(lightHex: 0xEDE9DC, darkHex: 0x2C2B32) // fills, skeletons, tracks

    /// Ambient drop-shadow tint — dark in both modes (a light shadow would glow on the dark canvas).
    static let shadow = Color(lightHex: 0x1C1C21, darkHex: 0x000000)

    // Brand — LEGO blue. Owns the header field + wordmark, not the CTAs.
    static let brand = Color(lightHex: 0x0253C4, darkHex: 0x0B54C0)
    static let brandDeep = Color(lightHex: 0x0349B0, darkHex: 0x08408F) // header gradient bottom
    static let brandEdge = Color(lightHex: 0x012E73, darkHex: 0x03203C) // blue plate's raised lip

    // Counting / "Rebuild" header field — a green brick plate, distinct from the blue home header.
    static let build = Color(lightHex: 0x2E9E4F, darkHex: 0x2C9A4C)
    static let buildDeep = Color(lightHex: 0x238B43, darkHex: 0x1E7C3A) // header gradient bottom
    static let buildEdge = Color(lightHex: 0x155F2D, darkHex: 0x0D4620) // green plate's raised lip

    // Party header field — an indigo brick plate (joining a party is open to everyone).
    static let party = Color(lightHex: 0x4F46E5, darkHex: 0x5A52EA)
    static let partyDeep = Color(lightHex: 0x4034C4, darkHex: 0x4238C0) // header gradient bottom
    static let partyEdge = Color(lightHex: 0x272183, darkHex: 0x1B1856) // indigo plate's raised lip

    // Profile header field — a warm orange brick plate.
    static let profile = Color(lightHex: 0xF0730C, darkHex: 0xF5810A)
    static let profileDeep = Color(lightHex: 0xD35F08, darkHex: 0xDE760C) // header gradient bottom
    static let profileEdge = Color(lightHex: 0x854005, darkHex: 0x5A2E08) // orange plate's raised lip

    // Primary action — a LEGO-red brick. onPrimary is white; primaryEdge is the pressed lip.
    static let primary = Color(lightHex: 0xE4000F, darkHex: 0xEC2029)
    static let onPrimary = Color(lightHex: 0xFFFFFF, darkHex: 0xFFFFFF)
    static let primaryEdge = Color(lightHex: 0xB00009, darkHex: 0x8F0710)

    // Semantic — lifted in dark so text/icons/progress keep contrast on the dark canvas.
    static let success = Color(lightHex: 0x2E9E4F, darkHex: 0x37B85E) // complete / verified (green)
    static let successEdge = Color(lightHex: 0x217A3C, darkHex: 0x2A8F49)
    static let warning = Color(lightHex: 0xE39A00, darkHex: 0xF2AC1E)
    static let danger = Color(lightHex: 0xC62828, darkHex: 0xE5484D)
    static let info = Color(lightHex: 0x1B74E4, darkHex: 0x4C93F2) // progress-in-motion (blue)

    // LEGO-primary accent set — party avatars cycle these (brighter in dark for white initials).
    static let legoRed = Color(lightHex: 0xE4000F, darkHex: 0xFF3B45)
    static let legoBlue = Color(lightHex: 0x0F62D6, darkHex: 0x3E86F0)
    static let legoGreen = Color(lightHex: 0x009B48, darkHex: 0x24B56E)
    static let legoOrange = Color(lightHex: 0xF5720B, darkHex: 0xFF8C33)
    static let legoPurple = Color(lightHex: 0x8A3FD1, darkHex: 0xA96BE0)
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

    /// A **dynamic** token that resolves to `lightHex` or `darkHex` for the active appearance
    /// (S7 dark mode). Backed by `UIColor(dynamicProvider:)` so it also resolves correctly inside
    /// `ImageRenderer` and any subtree that pins `\.colorScheme` — no call-site change needed.
    init(lightHex: UInt32, darkHex: UInt32, alpha: Double = 1) {
        self.init(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? darkHex : lightHex, alpha: alpha)
        })
    }
}

private extension UIColor {
    convenience init(rgb: UInt32, alpha: Double) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: CGFloat(alpha)
        )
    }
}
