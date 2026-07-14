import SwiftUI

/// Runtime localization override (S7 i18n). Holds the `.lproj` bundle + `Locale` that every
/// imperative `L.*` lookup resolves against, so the in-app **Language** switch is live (no
/// relaunch). Plain statics because all access is main-actor (SwiftUI `body` / view models);
/// `LocaleController` keeps them in lock-step with the SwiftUI `\.locale` environment.
enum I18n {
    /// Bundle that `String(localized:)` resolves against. `.main` = follow the device (System).
    static var bundle: Bundle = .main
    /// Locale used for number/date formatting inside interpolated + plural strings.
    static var locale: Locale = .autoupdatingCurrent
}

/// The three language choices surfaced in Profile → Language. `system` follows the device
/// locale (the first-launch default — auto-detect); `en` / `lt` force one.
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case en
    case lt

    var id: String { rawValue }

    /// Localized label for this choice — the Profile row value and the Language picker rows.
    var label: String {
        switch self {
        case .system: return L.languageSystem
        case .en: return L.languageEnglish
        case .lt: return L.languageLithuanian
        }
    }
}

/// Owns the chosen `AppLanguage`, persists it to `UserDefaults`, and mirrors it into `I18n`
/// (for imperative `L.*`) + publishes a `locale` for the SwiftUI `\.locale` environment. The app
/// root also keys its view tree on `language`, so a switch rebuilds every screen with the new
/// strings while the routers (owned by `AppEnvironment`) preserve navigation. Mirrors the Flutter
/// `localeController`, plus first-launch device auto-detect the Flutter app deferred.
@MainActor
@Observable
final class LocaleController {
    private static let defaultsKey = "app_language"

    private(set) var language: AppLanguage

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let raw = defaults.string(forKey: Self.defaultsKey)
        // No stored choice → System (device-locale auto-detect on first launch).
        self.language = raw.flatMap(AppLanguage.init(rawValue:)) ?? .system
        apply()
    }

    private let defaults: UserDefaults

    /// Change the language: persist, then mirror into `I18n` so imperative lookups switch live.
    func set(_ lang: AppLanguage) {
        guard lang != language else { return }
        language = lang
        if lang == .system {
            defaults.removeObject(forKey: Self.defaultsKey)
        } else {
            defaults.set(lang.rawValue, forKey: Self.defaultsKey)
        }
        apply()
    }

    /// Locale to inject into `\.environment(\.locale, …)` — drives SwiftUI date/number formatting
    /// and any remaining `Text(LocalizedStringKey)` lookups.
    var locale: Locale {
        switch language {
        case .system: return .autoupdatingCurrent
        case .en: return Locale(identifier: "en")
        case .lt: return Locale(identifier: "lt")
        }
    }

    /// Human label for the current choice (shown as the Profile row's value).
    var currentLabel: String { language.label }

    private func apply() {
        I18n.locale = locale
        switch language {
        case .system:
            I18n.bundle = .main
        case .en, .lt:
            if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
               let lproj = Bundle(path: path) {
                I18n.bundle = lproj
            } else {
                // The compiled catalog is missing this .lproj — fall back to the device bundle so
                // strings still resolve (English source) rather than showing raw keys.
                I18n.bundle = .main
            }
        }
    }
}
