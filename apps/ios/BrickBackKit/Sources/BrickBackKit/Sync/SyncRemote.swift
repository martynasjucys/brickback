import Foundation

/// The cloud side of sync, behind a protocol so the push/pull engine (`SyncService`) can be
/// driven by an in-memory fake in tests — no network, no authenticated Supabase session.
/// `SupabaseSyncRemote` is the real implementation against the BrickBack **user** project.
///
/// Payloads are SDK-independent value types (SyncService never imports Supabase). Timestamps
/// are ISO-8601 UTC strings and `flags` is a raw JSON string — the SDK boundary
/// (`SupabaseSyncRemote`) converts them to timestamptz / jsonb. Port of `sync_remote.dart`.
public protocol SyncRemote: Sendable {
    /// The signed-in user id, or nil when signed out (sync is a no-op).
    var uid: String? { get }

    func upsertSets(_ rows: [SyncSetPayload]) async throws
    func upsertParts(_ rows: [SyncPartPayload]) async throws
    func upsertMinifigs(_ rows: [SyncMinifigPayload]) async throws
    func upsertVerifications(_ rows: [SyncVerificationPayload]) async throws

    /// All of the user's `rebuild_sets` (owner-scoped by RLS).
    func fetchSets() async throws -> [CloudSet]

    /// Part / minifig rows for the given owned set ids.
    func fetchParts(_ rebuildSetIds: [String]) async throws -> [CloudPart]
    func fetchMinifigs(_ rebuildSetIds: [String]) async throws -> [CloudMinifig]

    /// All of the user's verification records.
    func fetchVerifications() async throws -> [CloudVerification]
}

// MARK: - Push payloads (local → cloud)

public struct SyncSetPayload: Sendable, Equatable {
    public var id: String
    public var userId: String
    public var setItemId: Int
    public var totalParts: Int
    public var verifiedAt: String?
    public var updatedAt: String
    public var deleted: Bool
    public init(id: String, userId: String, setItemId: Int, totalParts: Int, verifiedAt: String?, updatedAt: String, deleted: Bool) {
        self.id = id; self.userId = userId; self.setItemId = setItemId; self.totalParts = totalParts
        self.verifiedAt = verifiedAt; self.updatedAt = updatedAt; self.deleted = deleted
    }
}

public struct SyncPartPayload: Sendable, Equatable {
    public var rebuildSetId: String
    public var partItemId: Int
    public var colorId: Int
    public var haveQty: Int
    public var updatedAt: String
    public var deleted: Bool
    public init(rebuildSetId: String, partItemId: Int, colorId: Int, haveQty: Int, updatedAt: String, deleted: Bool) {
        self.rebuildSetId = rebuildSetId; self.partItemId = partItemId; self.colorId = colorId
        self.haveQty = haveQty; self.updatedAt = updatedAt; self.deleted = deleted
    }
}

public struct SyncMinifigPayload: Sendable, Equatable {
    public var rebuildSetId: String
    public var minifigItemId: Int
    public var haveQty: Int
    public var updatedAt: String
    public var deleted: Bool
    public init(rebuildSetId: String, minifigItemId: Int, haveQty: Int, updatedAt: String, deleted: Bool) {
        self.rebuildSetId = rebuildSetId; self.minifigItemId = minifigItemId
        self.haveQty = haveQty; self.updatedAt = updatedAt; self.deleted = deleted
    }
}

public struct SyncVerificationPayload: Sendable, Equatable {
    public var id: String
    public var userId: String
    public var rebuildSetId: String
    public var setItemId: Int
    public var completionPct: Double
    public var partsNeeded: Int?
    public var partsFound: Int?
    public var minifigsNeeded: Int?
    public var minifigsFound: Int?
    public var flags: String // raw JSON text
    public var notes: String?
    public var verifiedAt: String
    public var updatedAt: String
    public var deleted: Bool
    public init(id: String, userId: String, rebuildSetId: String, setItemId: Int, completionPct: Double, partsNeeded: Int?, partsFound: Int?, minifigsNeeded: Int?, minifigsFound: Int?, flags: String, notes: String?, verifiedAt: String, updatedAt: String, deleted: Bool) {
        self.id = id; self.userId = userId; self.rebuildSetId = rebuildSetId; self.setItemId = setItemId
        self.completionPct = completionPct; self.partsNeeded = partsNeeded; self.partsFound = partsFound
        self.minifigsNeeded = minifigsNeeded; self.minifigsFound = minifigsFound; self.flags = flags
        self.notes = notes; self.verifiedAt = verifiedAt; self.updatedAt = updatedAt; self.deleted = deleted
    }
}

// MARK: - Pull rows (cloud → local)

public struct CloudSet: Sendable, Equatable {
    public var id: String
    public var setItemId: Int
    public var totalParts: Int
    public var verifiedAt: String?
    public var updatedAt: String
    public var deleted: Bool
    public init(id: String, setItemId: Int, totalParts: Int, verifiedAt: String?, updatedAt: String, deleted: Bool) {
        self.id = id; self.setItemId = setItemId; self.totalParts = totalParts
        self.verifiedAt = verifiedAt; self.updatedAt = updatedAt; self.deleted = deleted
    }
}

public struct CloudPart: Sendable, Equatable {
    public var rebuildSetId: String
    public var partItemId: Int
    public var colorId: Int
    public var haveQty: Int
    public var deleted: Bool
    public init(rebuildSetId: String, partItemId: Int, colorId: Int, haveQty: Int, deleted: Bool) {
        self.rebuildSetId = rebuildSetId; self.partItemId = partItemId; self.colorId = colorId
        self.haveQty = haveQty; self.deleted = deleted
    }
}

public struct CloudMinifig: Sendable, Equatable {
    public var rebuildSetId: String
    public var minifigItemId: Int
    public var haveQty: Int
    public var deleted: Bool
    public init(rebuildSetId: String, minifigItemId: Int, haveQty: Int, deleted: Bool) {
        self.rebuildSetId = rebuildSetId; self.minifigItemId = minifigItemId
        self.haveQty = haveQty; self.deleted = deleted
    }
}

public struct CloudVerification: Sendable, Equatable {
    public var id: String
    public var rebuildSetId: String
    public var setItemId: Int
    public var completionPct: Double
    public var partsNeeded: Int?
    public var partsFound: Int?
    public var minifigsNeeded: Int?
    public var minifigsFound: Int?
    public var flags: String // raw JSON text
    public var notes: String?
    public var verifiedAt: String
    public var updatedAt: String
    public var deleted: Bool
    public init(id: String, rebuildSetId: String, setItemId: Int, completionPct: Double, partsNeeded: Int?, partsFound: Int?, minifigsNeeded: Int?, minifigsFound: Int?, flags: String, notes: String?, verifiedAt: String, updatedAt: String, deleted: Bool) {
        self.id = id; self.rebuildSetId = rebuildSetId; self.setItemId = setItemId
        self.completionPct = completionPct; self.partsNeeded = partsNeeded; self.partsFound = partsFound
        self.minifigsNeeded = minifigsNeeded; self.minifigsFound = minifigsFound; self.flags = flags
        self.notes = notes; self.verifiedAt = verifiedAt; self.updatedAt = updatedAt; self.deleted = deleted
    }
}
