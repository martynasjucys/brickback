import Foundation
import GRDB

/// GRDB record structs — a direct port of the Drift v3 schema (minus `step_qty`; see
/// 00-architecture §5). Columns use the snake_case cloud names so the sync mapping in
/// `SyncService` is a straight pass-through. Every synced row carries `updated_at`,
/// `dirty` (needs push), `deleted` (tombstone).

// MARK: - rebuild_sets  (PK: id)

public struct RebuildSetRecord: Codable, FetchableRecord, MutablePersistableRecord, Sendable, Hashable {
    public static let databaseTableName = "rebuild_sets"

    public var id: String // client-generated uuid (== cloud id)
    public var setItemId: Int
    public var name: String
    public var theme: String?
    public var year: Int?
    public var imageUrl: String?
    public var totalParts: Int
    public var verifiedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date
    public var dirty: Bool
    public var deleted: Bool
    /// S9 offline mode — stamped once every image URL for this set is cached on disk. Device-local
    /// (not synced); NULL means the prefetch hasn't completed yet, so a resume will retry it.
    public var imagesCachedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case setItemId = "set_item_id"
        case name
        case theme
        case year
        case imageUrl = "image_url"
        case totalParts = "total_parts"
        case verifiedAt = "verified_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case dirty
        case deleted
        case imagesCachedAt = "images_cached_at"
    }

    public init(
        id: String, setItemId: Int, name: String = "", theme: String? = nil, year: Int? = nil,
        imageUrl: String? = nil, totalParts: Int = 0, verifiedAt: Date? = nil,
        createdAt: Date, updatedAt: Date, dirty: Bool = true, deleted: Bool = false,
        imagesCachedAt: Date? = nil
    ) {
        self.id = id
        self.setItemId = setItemId
        self.name = name
        self.theme = theme
        self.year = year
        self.imageUrl = imageUrl
        self.totalParts = totalParts
        self.verifiedAt = verifiedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.dirty = dirty
        self.deleted = deleted
        self.imagesCachedAt = imagesCachedAt
    }
}

// MARK: - rebuild_parts  (PK: rebuild_set_id, part_item_id, color_id)

public struct RebuildPartRecord: Codable, FetchableRecord, MutablePersistableRecord, Sendable, Hashable {
    public static let databaseTableName = "rebuild_parts"

    public var rebuildSetId: String
    public var partItemId: Int
    public var colorId: Int
    public var neededQty: Int
    public var haveQty: Int
    public var partName: String
    public var partNum: String?
    public var partCatId: Int?
    public var categoryName: String? // v2
    public var colorName: String?
    public var colorRgb: String?
    public var imageUrl: String?
    public var blPartId: String?
    public var blColorId: Int?
    public var updatedAt: Date
    public var dirty: Bool
    public var deleted: Bool

    enum CodingKeys: String, CodingKey {
        case rebuildSetId = "rebuild_set_id"
        case partItemId = "part_item_id"
        case colorId = "color_id"
        case neededQty = "needed_qty"
        case haveQty = "have_qty"
        case partName = "part_name"
        case partNum = "part_num"
        case partCatId = "part_cat_id"
        case categoryName = "category_name"
        case colorName = "color_name"
        case colorRgb = "color_rgb"
        case imageUrl = "image_url"
        case blPartId = "bl_part_id"
        case blColorId = "bl_color_id"
        case updatedAt = "updated_at"
        case dirty
        case deleted
    }

    public init(
        rebuildSetId: String, partItemId: Int, colorId: Int, neededQty: Int = 0, haveQty: Int = 0,
        partName: String = "", partNum: String? = nil, partCatId: Int? = nil, categoryName: String? = nil,
        colorName: String? = nil, colorRgb: String? = nil, imageUrl: String? = nil,
        blPartId: String? = nil, blColorId: Int? = nil, updatedAt: Date, dirty: Bool = true, deleted: Bool = false
    ) {
        self.rebuildSetId = rebuildSetId
        self.partItemId = partItemId
        self.colorId = colorId
        self.neededQty = neededQty
        self.haveQty = haveQty
        self.partName = partName
        self.partNum = partNum
        self.partCatId = partCatId
        self.categoryName = categoryName
        self.colorName = colorName
        self.colorRgb = colorRgb
        self.imageUrl = imageUrl
        self.blPartId = blPartId
        self.blColorId = blColorId
        self.updatedAt = updatedAt
        self.dirty = dirty
        self.deleted = deleted
    }
}

// MARK: - rebuild_minifigs  (PK: rebuild_set_id, minifig_item_id)

public struct RebuildMinifigRecord: Codable, FetchableRecord, MutablePersistableRecord, Sendable, Hashable {
    public static let databaseTableName = "rebuild_minifigs"

    public var rebuildSetId: String
    public var minifigItemId: Int
    public var neededQty: Int
    public var haveQty: Int
    public var name: String
    public var imageUrl: String?
    public var updatedAt: Date
    public var dirty: Bool
    public var deleted: Bool

    enum CodingKeys: String, CodingKey {
        case rebuildSetId = "rebuild_set_id"
        case minifigItemId = "minifig_item_id"
        case neededQty = "needed_qty"
        case haveQty = "have_qty"
        case name
        case imageUrl = "image_url"
        case updatedAt = "updated_at"
        case dirty
        case deleted
    }

    public init(
        rebuildSetId: String, minifigItemId: Int, neededQty: Int = 0, haveQty: Int = 0,
        name: String = "", imageUrl: String? = nil, updatedAt: Date, dirty: Bool = true, deleted: Bool = false
    ) {
        self.rebuildSetId = rebuildSetId
        self.minifigItemId = minifigItemId
        self.neededQty = neededQty
        self.haveQty = haveQty
        self.name = name
        self.imageUrl = imageUrl
        self.updatedAt = updatedAt
        self.dirty = dirty
        self.deleted = deleted
    }
}

// MARK: - rebuild_extra_parts  (device-local, NOT synced)  (PK: rebuild_set_id, part_item_id, color_id)

public struct RebuildExtraPartRecord: Codable, FetchableRecord, MutablePersistableRecord, Sendable, Hashable {
    public static let databaseTableName = "rebuild_extra_parts"

    public var rebuildSetId: String
    public var partItemId: Int
    public var colorId: Int
    public var neededQty: Int // spare quantity
    public var haveQty: Int
    public var partName: String
    public var partNum: String?
    public var partCatId: Int?
    public var categoryName: String?
    public var colorName: String?
    public var colorRgb: String?
    public var imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case rebuildSetId = "rebuild_set_id"
        case partItemId = "part_item_id"
        case colorId = "color_id"
        case neededQty = "needed_qty"
        case haveQty = "have_qty"
        case partName = "part_name"
        case partNum = "part_num"
        case partCatId = "part_cat_id"
        case categoryName = "category_name"
        case colorName = "color_name"
        case colorRgb = "color_rgb"
        case imageUrl = "image_url"
    }

    public init(
        rebuildSetId: String, partItemId: Int, colorId: Int, neededQty: Int = 0, haveQty: Int = 0,
        partName: String = "", partNum: String? = nil, partCatId: Int? = nil, categoryName: String? = nil,
        colorName: String? = nil, colorRgb: String? = nil, imageUrl: String? = nil
    ) {
        self.rebuildSetId = rebuildSetId
        self.partItemId = partItemId
        self.colorId = colorId
        self.neededQty = neededQty
        self.haveQty = haveQty
        self.partName = partName
        self.partNum = partNum
        self.partCatId = partCatId
        self.categoryName = categoryName
        self.colorName = colorName
        self.colorRgb = colorRgb
        self.imageUrl = imageUrl
    }
}

// MARK: - verifications  (PK: id)

public struct VerificationRecord: Codable, FetchableRecord, MutablePersistableRecord, Sendable, Hashable {
    public static let databaseTableName = "verifications"

    public var id: String
    public var rebuildSetId: String
    public var setItemId: Int
    public var completionPct: Double
    public var partsNeeded: Int?
    public var partsFound: Int?
    public var minifigsNeeded: Int?
    public var minifigsFound: Int?
    public var flags: String // json
    public var notes: String?
    public var verifiedAt: Date
    public var updatedAt: Date
    public var dirty: Bool
    public var deleted: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case rebuildSetId = "rebuild_set_id"
        case setItemId = "set_item_id"
        case completionPct = "completion_pct"
        case partsNeeded = "parts_needed"
        case partsFound = "parts_found"
        case minifigsNeeded = "minifigs_needed"
        case minifigsFound = "minifigs_found"
        case flags
        case notes
        case verifiedAt = "verified_at"
        case updatedAt = "updated_at"
        case dirty
        case deleted
    }

    public init(
        id: String, rebuildSetId: String, setItemId: Int, completionPct: Double = 0,
        partsNeeded: Int? = nil, partsFound: Int? = nil, minifigsNeeded: Int? = nil, minifigsFound: Int? = nil,
        flags: String = "{}", notes: String? = nil, verifiedAt: Date, updatedAt: Date,
        dirty: Bool = true, deleted: Bool = false
    ) {
        self.id = id
        self.rebuildSetId = rebuildSetId
        self.setItemId = setItemId
        self.completionPct = completionPct
        self.partsNeeded = partsNeeded
        self.partsFound = partsFound
        self.minifigsNeeded = minifigsNeeded
        self.minifigsFound = minifigsFound
        self.flags = flags
        self.notes = notes
        self.verifiedAt = verifiedAt
        self.updatedAt = updatedAt
        self.dirty = dirty
        self.deleted = deleted
    }
}
