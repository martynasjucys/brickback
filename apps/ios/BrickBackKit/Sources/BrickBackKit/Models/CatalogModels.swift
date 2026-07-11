import Foundation

/// Catalog domain models. All fields are read straight from the read-only catalog project
/// (whatabrick) — nothing here is ever written back. Port of `catalog_models.dart`.

public enum CatalogKind: String, Sendable, Codable {
    case set
    case minifig
}

/// A LEGO set as it appears in the catalog `sets` table.
public struct CatalogSet: Sendable, Identifiable, Hashable {
    public let itemId: Int // catalog items.id
    public let setNum: String
    public let name: String
    public let year: Int
    public let numParts: Int
    public let imageUrl: String?

    public var id: Int { itemId }

    public init(itemId: Int, setNum: String, name: String, year: Int, numParts: Int, imageUrl: String?) {
        self.itemId = itemId
        self.setNum = setNum
        self.name = name
        self.year = year
        self.numParts = numParts
        self.imageUrl = imageUrl
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

/// Set-detail payload: the set row + resolved theme name + minifig count.
public struct SetDetail: Sendable, Hashable {
    public let set: CatalogSet
    public let themeName: String?
    public let minifigCount: Int

    public init(set: CatalogSet, themeName: String? = nil, minifigCount: Int = 0) {
        self.set = set
        self.themeName = themeName
        self.minifigCount = minifigCount
    }
}
