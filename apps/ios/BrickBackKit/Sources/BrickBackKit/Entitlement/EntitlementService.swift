import Foundation
import Supabase

/// Free tier keeps up to this many concurrent rebuilds on-device; beyond it, the add-a-set
/// flow shows the paywall instead of creating another (D7 default).
public let kFreeRebuildCap = 3

/// Premium entitlement — the source of truth for the sync gate + the free project cap (S5).
///
/// Backed by `profiles.is_premium` on the user project. That flag is set server-side by a
/// billing webhook / service role (RevenueCat is the intended integration; deferred). The app
/// only READS its own row. Everything stays fully usable when this is false — premium only adds
/// cross-device sync and lifts the free cap. Port of `EntitlementService`.
public final class EntitlementService: @unchecked Sendable {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    /// Read the signed-in user's premium flag. Returns false when signed out or on any transient
    /// error — the app is local-first, so "unknown" degrades to free.
    public func fetchIsPremium() async -> Bool {
        guard let uid = client.auth.currentUser?.id else { return false }
        do {
            let rows: [ProfileRow] = try await client
                .from("profiles")
                .select("is_premium")
                .eq("id", value: uid)
                .limit(1)
                .execute()
                .value
            return rows.first?.isPremium ?? false
        } catch {
            return false
        }
    }

    private struct ProfileRow: Decodable {
        let isPremium: Bool?
        enum CodingKeys: String, CodingKey { case isPremium = "is_premium" }
    }
}
