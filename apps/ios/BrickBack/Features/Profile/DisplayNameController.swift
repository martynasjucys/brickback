import SwiftUI

/// A small brick-themed random name generator. Seeds a friendly display name for anyone who never
/// sets one, so the party roster/feed reads "Sunny Brick" instead of the server's fallback
/// "Builder". Pure value logic — `Int.random` is fine here (this is app code, not a workflow).
enum NameGenerator {
    private static let adjectives = [
        "Brave", "Sunny", "Clever", "Golden", "Mighty", "Swift", "Jolly", "Cosmic",
        "Turbo", "Nimble", "Sparky", "Lucky", "Bold", "Zippy", "Cheery", "Snappy",
    ]
    private static let nouns = [
        "Brick", "Stud", "Minifig", "Baseplate", "Builder", "Plate", "Tile", "Sorter",
        "Block", "Wrench", "Cog", "Piece", "Bricklayer", "Gearhead", "Tinker",
    ]

    static func random() -> String {
        let a = adjectives.randomElement() ?? "Brave"
        let n = nouns.randomElement() ?? "Brick"
        return "\(a) \(n)"
    }
}

/// Owns the user's display name — the label shown to others in party mode (`party_members`). Persisted
/// to `UserDefaults`, mirrors `LocaleController` / `ThemeController` (S7). **Never blank:** if the user
/// hasn't chosen one, a random brick-themed name is generated on first launch and kept, so a guest who
/// joins a party always shows something friendlier than the server's "Builder" fallback. The chosen
/// name rides into the anonymous guest session's metadata (see `AuthRepository.ensureGuestSession`).
@MainActor
@Observable
final class DisplayNameController {
    private static let defaultsKey = "display_name"
    /// Guard against an over-long name reaching the shared roster.
    private static let maxLength = 24

    private(set) var name: String
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.string(forKey: Self.defaultsKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let stored, !stored.isEmpty {
            self.name = stored
        } else {
            // First launch (or a cleared name) → seed a random one and persist it.
            let generated = NameGenerator.random()
            self.name = generated
            defaults.set(generated, forKey: Self.defaultsKey)
        }
    }

    /// Set a user-entered name. Blank input falls back to a freshly generated random name so the
    /// field is never empty; anything longer than `maxLength` is trimmed.
    func set(_ newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = trimmed.isEmpty ? NameGenerator.random() : String(trimmed.prefix(Self.maxLength))
        name = value
        defaults.set(value, forKey: Self.defaultsKey)
    }
}
