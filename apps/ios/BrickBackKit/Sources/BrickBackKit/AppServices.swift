import Foundation
import Supabase

/// The composition root for the domain/data layer — the "providers root" from
/// 00-architecture §4/§7. Builds both Supabase clients and every repository once, keeping
/// GRDB and supabase-swift **entirely inside this package**: the SwiftUI app holds an
/// `AppServices` and never imports either SDK.
///
/// Two clients, never conflated (00-architecture §7):
/// - `catalogClient` — anon, session-less, read-only LEGO catalog (whatabrick project).
/// - `userClient`    — auth-bearing; auth + premium cloud sync (BrickBack user project).
public final class AppServices: @unchecked Sendable {
    public let config: AppConfig
    public let db: AppDatabase

    private let userClient: SupabaseClient
    private let catalogClient: SupabaseClient
    private let catalogRepo: SupabaseCatalogRepository

    public var catalog: CatalogReader { catalogRepo }
    public let rebuild: RebuildRepository
    public let auth: AuthRepository
    public let entitlement: EntitlementService
    public let syncService: SyncService
    public let party: PartyRepository

    // S9 offline mode. The durable image store is SDK-free (built here); the prefetcher is the
    // Nuke-backed app implementation injected by `BrickBackApp` (a `NoopImagePrefetcher` in tests).
    // Not premium-gated — free users cache images for offline viewing too.
    public let imageStore: BrickImageStore
    public let offlineImages: OfflineImageService
    public let network = NetworkMonitor()

    public init(config: AppConfig, db: AppDatabase? = nil, imagePrefetcher: ImagePrefetching = NoopImagePrefetcher()) throws {
        self.config = config
        self.db = try db ?? AppDatabase.live()

        self.userClient = SupabaseClient(supabaseURL: config.userSupabaseURL, supabaseKey: config.userSupabaseAnonKey)
        self.catalogClient = SupabaseClient(supabaseURL: config.catalogSupabaseURL, supabaseKey: config.catalogSupabaseAnonKey)

        let images = ImageResolver(cdnURL: config.cdnURL)
        self.catalogRepo = SupabaseCatalogRepository(client: catalogClient, images: images)
        self.rebuild = RebuildRepository(catalog: catalogRepo, db: self.db)
        self.auth = AuthRepository(client: userClient)
        self.entitlement = EntitlementService(client: userClient)
        self.syncService = SyncService(db: self.db, rebuild: rebuild, remote: SupabaseSyncRemote(client: userClient))
        // Party mode (S6) — realtime collaborative counting on the user project. Reuses the anon
        // catalog reader (for the client-side picker) + the local rebuild store (for reconcile).
        self.party = PartyRepository(remote: SupabasePartyRemote(client: userClient), catalog: catalogRepo, rebuild: rebuild)

        self.imageStore = try BrickImageStore.live()
        self.offlineImages = OfflineImageService(db: self.db, store: imageStore, prefetcher: imagePrefetcher)
    }

    // MARK: - Catalog reads for the S2 UI (search + set detail; `catalog` covers the rest)

    /// Debounced catalog search (sets by name / number). See `SupabaseCatalogRepository.search`.
    public func searchCatalog(_ query: String) async throws -> [CatalogResult] {
        try await catalogRepo.search(query)
    }

    /// Set-detail payload (metadata + theme + minifig count). Backs the set detail screen.
    public func setDetail(_ itemId: Int) async throws -> SetDetail {
        try await catalogRepo.setDetail(itemId)
    }
}
