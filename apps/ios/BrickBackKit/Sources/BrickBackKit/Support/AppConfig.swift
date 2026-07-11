import Foundation

/// Typed accessor over the publishable config injected via the `.xcconfig` → Info.plist
/// chain (client-safe keys only — see docs/ios-swift/01-foundation.md S0). Never a server
/// secret. Port of [`env.dart`](../../../../apps/mobile/lib/core/env.dart), including its
/// `_req` fail-fast guard on a missing/empty value.
public struct AppConfig: Sendable {
    public let userSupabaseURL: URL
    public let userSupabaseAnonKey: String
    public let catalogSupabaseURL: URL
    public let catalogSupabaseAnonKey: String
    public let cdnURL: URL

    public init(
        userSupabaseURL: URL,
        userSupabaseAnonKey: String,
        catalogSupabaseURL: URL,
        catalogSupabaseAnonKey: String,
        cdnURL: URL
    ) {
        self.userSupabaseURL = userSupabaseURL
        self.userSupabaseAnonKey = userSupabaseAnonKey
        self.catalogSupabaseURL = catalogSupabaseURL
        self.catalogSupabaseAnonKey = catalogSupabaseAnonKey
        self.cdnURL = cdnURL
    }

    /// Build from the app bundle's `BrickBackConfig` dictionary (populated by the
    /// `.xcconfig` values). Traps with a clear message on any missing/empty/malformed
    /// value — the native analog of `StateError('Missing env var: …')`.
    public static func fromBundle(_ bundle: Bundle = .main) -> AppConfig {
        let dict = bundle.object(forInfoDictionaryKey: "BrickBackConfig") as? [String: Any] ?? [:]

        func req(_ key: String) -> String {
            guard let v = dict[key] as? String, !v.isEmpty else {
                fatalError("Missing config value: \(key) — set it in apps/ios/BrickBack/Config/Secrets.xcconfig (run apps/ios/gen-secrets.sh)")
            }
            return v
        }
        func reqURL(_ key: String) -> URL {
            let raw = req(key)
            guard let url = URL(string: raw) else {
                fatalError("Malformed URL for config value: \(key)")
            }
            return url
        }

        return AppConfig(
            userSupabaseURL: reqURL("USER_SUPABASE_URL"),
            userSupabaseAnonKey: req("USER_SUPABASE_ANON_KEY"),
            catalogSupabaseURL: reqURL("CATALOG_SUPABASE_URL"),
            catalogSupabaseAnonKey: req("CATALOG_SUPABASE_ANON_KEY"),
            cdnURL: reqURL("CDN_URL")
        )
    }
}
