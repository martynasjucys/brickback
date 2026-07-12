import Foundation

/// Party-mode domain models. Port of `party_models.dart`. All values are read from the
/// **user** project (the `party_*` tables + RPCs); the catalog client is never touched here.
///
/// BrickBack's two-project split (00-architecture §7) forces two things onto the client that
/// whatabrick did server-side, both reflected below: `Party.setItemId` is denormalized onto the
/// session row so any member can derive the picker + reconcile without reading the host's
/// owner-scoped `rebuild_sets`, and `PartyPart` is built on-device by joining the catalog-derived
/// needed line with the shared rolled-up `have`.

/// A realtime party (a `party_sessions` row). Carries `set_item_id` so any member can derive the
/// catalog-side picker on-device.
public struct Party: Sendable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let joinCode: String
    /// The **host's** rebuild id (owner-scoped; not readable by members).
    public let rebuildSetId: String?
    /// Catalog set id — drives the on-device picker + local reconcile.
    public let setItemId: Int
    public let hostUserId: String
    public let status: String // active | paused | ended

    public init(id: String, name: String, joinCode: String, rebuildSetId: String?, setItemId: Int, hostUserId: String, status: String) {
        self.id = id
        self.name = name
        self.joinCode = joinCode
        self.rebuildSetId = rebuildSetId
        self.setItemId = setItemId
        self.hostUserId = hostUserId
        self.status = status
    }

    public var isActive: Bool { status == "active" }
}

/// One roster member (a `party_members` row).
public struct PartyMember: Sendable, Identifiable, Hashable {
    public let id: String
    public let userId: String
    public let role: String
    public let displayName: String?
    public let joinedAt: Date

    public init(id: String, userId: String, role: String, displayName: String?, joinedAt: Date) {
        self.id = id
        self.userId = userId
        self.role = role
        self.displayName = displayName
        self.joinedAt = joinedAt
    }

    public var isHost: Bool { role == "host" }
}

/// One logged "found parts" event, for the activity feed. `partName` / `colorName` are
/// denormalized on the row (BrickBack's user project can't join the catalog), so the feed renders
/// with no catalog lookup. An empty/blank `part_name` degrades to a generic "part".
public struct PartyContribution: Sendable, Identifiable, Hashable {
    public let id: String
    public let memberId: String?
    public let qty: Int
    public let partName: String
    public let colorName: String?
    public let createdAt: Date

    public init(id: String, memberId: String?, qty: Int, partName: String, colorName: String?, createdAt: Date) {
        self.id = id
        self.memberId = memberId
        self.qty = qty
        self.partName = partName
        self.colorName = colorName
        self.createdAt = createdAt
    }
}

/// Shared party progress ({total, have}) from the `party_progress` RPC.
public struct PartyProgress: Sendable, Equatable {
    public let total: Int
    public let have: Int

    public init(total: Int, have: Int) {
        self.total = total
        self.have = have
    }

    public var value: Double { total == 0 ? 0 : min(1, max(0, Double(have) / Double(total))) }
}

/// A part the party still needs. Built ON-DEVICE by joining the catalog-derived "needed" line
/// (`ExpandedPart`, from the catalog client) with the shared rolled-up `have` (from
/// `party_have_counts`). Replaces whatabrick's server-side `party_parts`, which relied on a
/// catalog that BrickBack's user project lacks.
public struct PartyPart: Sendable, Identifiable, Hashable {
    public let needed: ExpandedPart
    public let have: Int

    public init(needed: ExpandedPart, have: Int) {
        self.needed = needed
        self.have = have
    }

    public var partItemId: Int { needed.partItemId }
    public var colorId: Int { needed.colorId }
    public var key: String { needed.key } // "partItemId:colorId"
    public var id: String { key }
    public var name: String { needed.partName }
    public var colorName: String? { needed.colorName }
    public var colorRgb: String? { needed.colorRgb }
    public var imageUrl: String? { needed.imageUrl }

    /// How many of this (part, colour) the party still needs, never below zero.
    public var remaining: Int { max(0, needed.neededQty - have) }

    public static func fromNeeded(_ p: ExpandedPart, have: [String: Int]) -> PartyPart {
        PartyPart(needed: p, have: have[p.key] ?? 0)
    }
}
