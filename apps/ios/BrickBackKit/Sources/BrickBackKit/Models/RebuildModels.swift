import Foundation

/// One (part, colour) line — the "needed" side of a rebuild. Sourced from the catalog
/// `expand_set_parts` RPC at add-time and then snapshotted into GRDB, so it round-trips from
/// either the catalog (add) or local storage (offline UI). Port of `rebuild_models.dart`.
public struct ExpandedPart: Sendable, Hashable, Identifiable {
    public let partItemId: Int // catalog parts.item_id
    public let colorId: Int // catalog colors.id
    public let neededQty: Int
    public let partName: String
    public let partNum: String?
    public let partCatId: Int?
    public let categoryName: String? // from the RPC only (not persisted); null offline
    public let colorName: String?
    public let colorRgb: String?
    public let imageUrl: String?
    public let blPartId: String?
    public let blColorId: Int?

    public init(
        partItemId: Int, colorId: Int, neededQty: Int, partName: String, partNum: String?,
        partCatId: Int?, categoryName: String?, colorName: String?, colorRgb: String?,
        imageUrl: String?, blPartId: String?, blColorId: Int?
    ) {
        self.partItemId = partItemId
        self.colorId = colorId
        self.neededQty = neededQty
        self.partName = partName
        self.partNum = partNum
        self.partCatId = partCatId
        self.categoryName = categoryName
        self.colorName = colorName
        self.colorRgb = colorRgb
        self.imageUrl = imageUrl
        self.blPartId = blPartId
        self.blColorId = blColorId
    }

    /// Part identity within a rebuild — the whatabrick convention (`partItemId:colorId`),
    /// reused verbatim so progress math and the wanted-list export line up. Also serves as the
    /// `Identifiable` id (unique among a set's parts).
    public var key: String { "\(partItemId):\(colorId)" }
    public var id: String { key }
}

/// One minifig line for a rebuild (verified separately from parts in S4).
public struct RebuildMinifigLine: Sendable, Hashable {
    public let minifigItemId: Int
    public let neededQty: Int
    public let haveQty: Int
    public let name: String
    public let imageUrl: String?

    public init(minifigItemId: Int, neededQty: Int, haveQty: Int, name: String, imageUrl: String?) {
        self.minifigItemId = minifigItemId
        self.neededQty = neededQty
        self.haveQty = haveQty
        self.name = name
        self.imageUrl = imageUrl
    }

    public var complete: Bool { haveQty >= neededQty }
}

/// A still-short `(part, colour)` for one rebuild — the shortfall side of the review screen
/// (S4) and the BrickLink wanted-list export. Computed locally off the snapshot;
/// `needed` is `max(0, neededQty − have)`.
public struct MissingPart: Sendable, Hashable {
    public let partItemId: Int
    public let colorId: Int
    public let needed: Int
    public let partName: String
    public let partNum: String?
    public let colorName: String?
    public let colorRgb: String?
    public let imageUrl: String?
    public let blPartId: String?
    public let blColorId: Int?

    public init(
        partItemId: Int, colorId: Int, needed: Int, partName: String, partNum: String?,
        colorName: String?, colorRgb: String?, imageUrl: String?, blPartId: String?, blColorId: Int?
    ) {
        self.partItemId = partItemId
        self.colorId = colorId
        self.needed = needed
        self.partName = partName
        self.partNum = partNum
        self.colorName = colorName
        self.colorRgb = colorRgb
        self.imageUrl = imageUrl
        self.blPartId = blPartId
        self.blColorId = blColorId
    }

    public var key: String { "\(partItemId):\(colorId)" }

    /// Whether this part can go on a BrickLink wanted list (needs a BL item id; the part
    /// number is a usable fallback). Parts with neither are surfaced in a footnote (S4).
    public var exportable: Bool {
        (blPartId?.isEmpty == false) || (partNum?.isEmpty == false)
    }
}

/// A tracked set rebuild (rebuild_sets row + progress), for the Home list.
public struct RebuildSummary: Sendable, Identifiable, Hashable {
    public let id: String // rebuild_sets.id (uuid)
    public let setItemId: Int
    public let name: String // auto-numbered "#N" when the set is added more than once
    public let imageUrl: String?
    public let totalParts: Int
    public let haveTotal: Int // capped sum of have (<= totalParts)
    public let verifiedAt: Date? // set once a verification is recorded (S4)

    public init(id: String, setItemId: Int, name: String, imageUrl: String?, totalParts: Int, haveTotal: Int, verifiedAt: Date? = nil) {
        self.id = id
        self.setItemId = setItemId
        self.name = name
        self.imageUrl = imageUrl
        self.totalParts = totalParts
        self.haveTotal = haveTotal
        self.verifiedAt = verifiedAt
    }

    public var progress: Double {
        totalParts == 0 ? 0 : min(1, max(0, Double(haveTotal) / Double(totalParts)))
    }
    public var complete: Bool { totalParts > 0 && haveTotal >= totalParts }
    public var verified: Bool { verifiedAt != nil }
}

/// Full checklist for one rebuild — read entirely from the local snapshot.
///
/// Divergence from Flutter: **no per-part `step`** here. The counting step is in-memory
/// session state held by the S3 counting view model (see 00-architecture §5), not a
/// persisted/model field.
public struct RebuildInventory: Sendable {
    public let summary: RebuildSummary
    public let parts: [ExpandedPart]
    public let have: [String: Int] // key -> have_qty
    public let minifigs: [RebuildMinifigLine]

    /// The set's spare / extra parts (needed side). A countable bonus deliberately
    /// **excluded** from `haveTotal` / `progress` / `complete`. Empty unless the set ships spares.
    public let extras: [ExpandedPart]
    public let extraHave: [String: Int] // key -> extras found

    public init(
        summary: RebuildSummary, parts: [ExpandedPart], have: [String: Int],
        minifigs: [RebuildMinifigLine], extras: [ExpandedPart] = [], extraHave: [String: Int] = [:]
    ) {
        self.summary = summary
        self.parts = parts
        self.have = have
        self.minifigs = minifigs
        self.extras = extras
        self.extraHave = extraHave
    }

    public func haveFor(_ p: ExpandedPart) -> Int { have[p.key] ?? 0 }
    public func extraHaveFor(_ p: ExpandedPart) -> Int { extraHave[p.key] ?? 0 }
    public var hasExtras: Bool { !extras.isEmpty }

    public var neededTotal: Int { summary.totalParts }
    public var haveTotal: Int { parts.reduce(0) { $0 + min(have[$1.key] ?? 0, $1.neededQty) } }
    public var progress: Double {
        neededTotal == 0 ? 0 : min(1, max(0, Double(haveTotal) / Double(neededTotal)))
    }
    public var complete: Bool { !parts.isEmpty && parts.allSatisfy { (have[$0.key] ?? 0) >= $0.neededQty } }
    public var remainingPartTypes: Int { parts.filter { (have[$0.key] ?? 0) < $0.neededQty }.count }

    // --- S4 review math (all local, off the snapshot) ---------------------------

    public var partsFound: Int { haveTotal }

    /// Every still-short `(part, colour)`, biggest shortfall first. Empty when the rebuild
    /// is 100% — so an empty list is the "nothing missing" signal.
    public var missingParts: [MissingPart] {
        var out: [MissingPart] = []
        for p in parts {
            let short = p.neededQty - (have[p.key] ?? 0)
            if short <= 0 { continue }
            out.append(MissingPart(
                partItemId: p.partItemId, colorId: p.colorId, needed: short,
                partName: p.partName, partNum: p.partNum, colorName: p.colorName,
                colorRgb: p.colorRgb, imageUrl: p.imageUrl, blPartId: p.blPartId, blColorId: p.blColorId
            ))
        }
        out.sort { $0.needed > $1.needed }
        return out
    }

    public var minifigsNeeded: Int { minifigs.reduce(0) { $0 + $1.neededQty } }
    public var minifigsFound: Int { minifigs.reduce(0) { $0 + min($1.haveQty, $1.neededQty) } }
    public var hasMinifigs: Bool { !minifigs.isEmpty }
    public var minifigsComplete: Bool { minifigs.isEmpty || minifigs.allSatisfy { $0.haveQty >= $0.neededQty } }
}
