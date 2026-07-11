import SwiftUI

/// BrickBack design tokens — **WIREFRAME fidelity** (S1–S4). Deliberately low-fidelity:
/// grayscale, boxy, hairline borders. The S7 polish pass swaps this one file for the branded
/// palette + typography — **keep these token NAMES stable** so screens don't change.
/// Port of `app_theme.dart`.
enum AppColors {
    // Neutrals (the whole wireframe lives here)
    static let canvas = Color(hex: 0xF4F4F5) // page background
    static let card = Color(hex: 0xFFFFFF) // surfaces
    static let line = Color(hex: 0xD4D4D8) // hairline borders
    static let ink = Color(hex: 0x18181B) // primary text / headings
    static let inkSoft = Color(hex: 0x52525B) // secondary text
    static let muted = Color(hex: 0x9CA3AF) // tertiary / placeholders
    static let faint = Color(hex: 0xE4E4E7) // fills, skeletons

    // Single interactive accent (grayscale-ink in wireframe; brand color in S7)
    static let primary = Color(hex: 0x18181B)
    static let onPrimary = Color(hex: 0xFFFFFF)

    // Semantic (kept muted so it still reads as a wireframe; recolored in S7)
    static let success = Color(hex: 0x3F6212)
    static let warning = Color(hex: 0x92600A)
    static let danger = Color(hex: 0x991B1B)
    static let info = Color(hex: 0x334155)
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
    // Boxy on purpose for the wireframe stage.
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let pill: CGFloat = 999
}

/// Typographic scale (system font in wireframe; branded in S7). Fonts only — apply the ink
/// colour at the call site (SwiftUI keeps font and colour separate).
enum AppText {
    static let display = Font.system(size: 30, weight: .bold)
    static let h1 = Font.system(size: 24, weight: .bold)
    static let h2 = Font.system(size: 20, weight: .bold)
    static let title = Font.system(size: 16, weight: .semibold)
    static let body = Font.system(size: 15, weight: .regular)
    static let label = Font.system(size: 13, weight: .semibold)
    static let caption = Font.system(size: 12, weight: .regular)
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
