import SwiftUI

/// The three appearance choices surfaced in Profile → Appearance. `system` follows the device
/// (the default); `light` / `dark` force one. Mirrors `AppLanguage` / `LocaleController` (S7).
enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    /// The value handed to `.preferredColorScheme(_:)` — `nil` = follow the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// Localized label for this choice — the Profile row value and the Appearance picker rows.
    var label: String {
        switch self {
        case .system: return L.themeSystem
        case .light: return L.themeLight
        case .dark: return L.themeDark
        }
    }
}

/// Owns the chosen `AppTheme`, persists it to `UserDefaults`, and exposes the `ColorScheme?` the
/// app root pins via `.preferredColorScheme`. Because `AppColors` tokens are dynamic
/// (`Color(lightHex:darkHex:)`), pinning the scheme is all it takes — every surface re-resolves.
@MainActor
@Observable
final class ThemeController {
    private static let defaultsKey = "app_theme"

    private(set) var theme: AppTheme
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let raw = defaults.string(forKey: Self.defaultsKey)
        // No stored choice → System (follow the device appearance).
        self.theme = raw.flatMap(AppTheme.init(rawValue:)) ?? .system
    }

    func set(_ theme: AppTheme) {
        guard theme != self.theme else { return }
        self.theme = theme
        if theme == .system {
            defaults.removeObject(forKey: Self.defaultsKey)
        } else {
            defaults.set(theme.rawValue, forKey: Self.defaultsKey)
        }
    }

    var colorScheme: ColorScheme? { theme.colorScheme }

    /// Human label for the current choice (shown as the Profile row's value).
    var currentLabel: String { theme.label }
}
