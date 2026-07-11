import Foundation
@testable import BrickBackKit

/// In-memory catalog for tests — no network. Mirrors the Dart fake used to exercise the
/// "re-derive metadata from catalog on pull" path.
final class FakeCatalog: CatalogReader, @unchecked Sendable {
    var sets: [Int: CatalogSet] = [:]
    var partsBySet: [Int: [ExpandedPart]] = [:]
    var minifigsBySet: [Int: [CatalogMinifig]] = [:]
    var sparesBySet: [Int: [ExpandedPart]] = [:]

    func setsByIds(_ ids: [Int]) async throws -> [CatalogSet] { ids.compactMap { sets[$0] } }
    func expandSetParts(_ setItemId: Int) async throws -> [ExpandedPart] { partsBySet[setItemId] ?? [] }
    func setMinifigs(_ setItemId: Int) async throws -> [CatalogMinifig] { minifigsBySet[setItemId] ?? [] }
    func getSetSpares(_ setItemId: Int) async throws -> [ExpandedPart] { sparesBySet[setItemId] ?? [] }
}

/// In-memory cloud shared by two "devices" in the sync tests. Upserts merge on the natural key
/// (== local id), fetches return everything — exactly the contract `SyncService` relies on.
final class FakeSyncRemote: SyncRemote, @unchecked Sendable {
    var uid: String?
    private var sets: [String: CloudSet] = [:]
    private var parts: [String: CloudPart] = [:]
    private var minifigs: [String: CloudMinifig] = [:]
    private var verifications: [String: CloudVerification] = [:]

    init(uid: String? = "user-1") { self.uid = uid }

    private func partKey(_ setId: String, _ part: Int, _ color: Int) -> String { "\(setId):\(part):\(color)" }
    private func minifigKey(_ setId: String, _ fig: Int) -> String { "\(setId):\(fig)" }

    func upsertSets(_ rows: [SyncSetPayload]) async throws {
        for r in rows {
            sets[r.id] = CloudSet(id: r.id, setItemId: r.setItemId, totalParts: r.totalParts, verifiedAt: r.verifiedAt, updatedAt: r.updatedAt, deleted: r.deleted)
        }
    }
    func upsertParts(_ rows: [SyncPartPayload]) async throws {
        for r in rows {
            parts[partKey(r.rebuildSetId, r.partItemId, r.colorId)] = CloudPart(rebuildSetId: r.rebuildSetId, partItemId: r.partItemId, colorId: r.colorId, haveQty: r.haveQty, deleted: r.deleted)
        }
    }
    func upsertMinifigs(_ rows: [SyncMinifigPayload]) async throws {
        for r in rows {
            minifigs[minifigKey(r.rebuildSetId, r.minifigItemId)] = CloudMinifig(rebuildSetId: r.rebuildSetId, minifigItemId: r.minifigItemId, haveQty: r.haveQty, deleted: r.deleted)
        }
    }
    func upsertVerifications(_ rows: [SyncVerificationPayload]) async throws {
        for r in rows {
            verifications[r.id] = CloudVerification(id: r.id, rebuildSetId: r.rebuildSetId, setItemId: r.setItemId, completionPct: r.completionPct, partsNeeded: r.partsNeeded, partsFound: r.partsFound, minifigsNeeded: r.minifigsNeeded, minifigsFound: r.minifigsFound, flags: r.flags, notes: r.notes, verifiedAt: r.verifiedAt, updatedAt: r.updatedAt, deleted: r.deleted)
        }
    }

    func fetchSets() async throws -> [CloudSet] { Array(sets.values) }
    func fetchParts(_ rebuildSetIds: [String]) async throws -> [CloudPart] {
        parts.values.filter { rebuildSetIds.contains($0.rebuildSetId) }
    }
    func fetchMinifigs(_ rebuildSetIds: [String]) async throws -> [CloudMinifig] {
        minifigs.values.filter { rebuildSetIds.contains($0.rebuildSetId) }
    }
    func fetchVerifications() async throws -> [CloudVerification] { Array(verifications.values) }
}

/// Convenience part builder for tests.
func makePart(_ partItemId: Int, _ colorId: Int, needed: Int, name: String = "Brick", category: String? = "Bricks") -> ExpandedPart {
    ExpandedPart(
        partItemId: partItemId, colorId: colorId, neededQty: needed, partName: name, partNum: "\(partItemId)",
        partCatId: nil, categoryName: category, colorName: "Red", colorRgb: "FF0000", imageUrl: nil,
        blPartId: nil, blColorId: nil
    )
}
