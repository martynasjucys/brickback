import Foundation

/// Catalog domain models. All fields are read straight from the read-only catalog project
/// (whatabrick) — nothing here is ever written back. Port of `catalog_models.dart`.

public enum CatalogKind: String, Sendable, Codable {
    case set
    case minifig
}

/// A set's availability stage, recomputed daily in the catalog from community-sourced dates
/// (Brickset / BrickEconomy), so it's "best available" rather than official LEGO data. `nil` for
/// recent, undated sets where the stage is genuinely unknown. Mirrors `sets.lifecycle_status`.
public enum SetLifecycle: String, Sendable, Hashable {
    case upcoming
    case available
    case retiringSoon = "retiring_soon"
    case retired
}

/// A LEGO set as it appears in the catalog `sets` table.
public struct CatalogSet: Sendable, Identifiable, Hashable {
    public let itemId: Int // catalog items.id
    public let setNum: String
    public let name: String
    public let year: Int
    public let numParts: Int
    public let imageUrl: String?
    public let themeName: String? // resolved theme (items.theme_id → themes.name); nil if the set has none
    public let lifecycle: SetLifecycle? // availability stage; nil when unknown
    public let launchDate: Date? // official launch / release date (nil for older or undated sets)
    public let exitDate: Date? // official retirement date
    public let retiringSoonDate: Date? // estimated upcoming retirement (retiring-soon sets)

    public var id: Int { itemId }

    public init(itemId: Int, setNum: String, name: String, year: Int, numParts: Int, imageUrl: String?,
                themeName: String? = nil, lifecycle: SetLifecycle? = nil, launchDate: Date? = nil,
                exitDate: Date? = nil, retiringSoonDate: Date? = nil) {
        self.itemId = itemId
        self.setNum = setNum
        self.name = name
        self.year = year
        self.numParts = numParts
        self.imageUrl = imageUrl
        self.themeName = themeName
        self.lifecycle = lifecycle
        self.launchDate = launchDate
        self.exitDate = exitDate
        self.retiringSoonDate = retiringSoonDate
    }
}

/// A single catalog search hit (sets only in S2 — the app adds sets, not minifigs — but the
/// shape carries `kind` for later browse surfaces).
public struct CatalogResult: Sendable, Identifiable, Hashable {
    public let itemId: Int
    public let kind: CatalogKind
    public let ref: String // set_num / fig_num
    public let name: String
    public let year: Int?
    public let numParts: Int?
    public let imageUrl: String?

    public var id: Int { itemId }

    public init(itemId: Int, kind: CatalogKind, ref: String, name: String, year: Int?, numParts: Int?, imageUrl: String?) {
        self.itemId = itemId
        self.kind = kind
        self.ref = ref
        self.name = name
        self.year = year
        self.numParts = numParts
        self.imageUrl = imageUrl
    }
}

/// One minifig belonging to a set (latest inventory), with its needed quantity.
public struct CatalogMinifig: Sendable, Hashable {
    public let minifigItemId: Int // catalog minifigs.item_id
    public let quantity: Int
    public let figNum: String
    public let name: String
    public let imageUrl: String?

    public init(minifigItemId: Int, quantity: Int, figNum: String, name: String, imageUrl: String?) {
        self.minifigItemId = minifigItemId
        self.quantity = quantity
        self.figNum = figNum
        self.name = name
        self.imageUrl = imageUrl
    }
}

/// Latest cached BrickLink "sold" value for a set — the quantity-weighted average of recent
/// completed sales, split by condition. Community market data; `nil` sides mean no signal
/// (no recent sales or the set isn't price-mapped). Mirrors `bricklink_price_guides`.
public struct SetPrice: Sendable, Hashable {
    public let new: Double?
    public let used: Double?
    public let currency: String

    public var hasAny: Bool { new != nil || used != nil }

    public init(new: Double?, used: Double?, currency: String) {
        self.new = new
        self.used = used
        self.currency = currency
    }
}

/// Set-detail payload: the set row (incl. lifecycle dates) + resolved theme name + minifig count
/// + latest market value.
public struct SetDetail: Sendable, Hashable {
    public let set: CatalogSet
    public let themeName: String?
    public let minifigCount: Int
    public let price: SetPrice?

    public init(set: CatalogSet, themeName: String? = nil, minifigCount: Int = 0, price: SetPrice? = nil) {
        self.set = set
        self.themeName = themeName
        self.minifigCount = minifigCount
        self.price = price
    }
}
