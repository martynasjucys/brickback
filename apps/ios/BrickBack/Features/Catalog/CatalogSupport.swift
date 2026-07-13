import SwiftUI

/// Parse a catalog `color_rgb` hex (e.g. `F2CD37`) into a swatch colour. Mirrors the Dart
/// `swatchColor`: a missing value falls back to mid-grey, an unparseable one to the faint fill.
func swatchColor(_ rgb: String?) -> Color {
    let hex = rgb ?? "808080"
    guard let value = UInt32(hex, radix: 16) else { return AppColors.faint }
    return Color(hex: value)
}

/// "no parts" / "1 part" / "N parts" — the Dart `partsCount` plural. (English-only in the
/// wireframe; the S7 i18n pass moves this into the String Catalog.)
func partsCountLabel(_ count: Int) -> String {
    return L.partsCount(count)
}
