import Foundation
import Supabase

/// Read-only access to the LEGO catalog (whatabrick project) via the anon `catalogClient`.
/// **Never writes.** Every call is a `select` or `rpc`. Set metadata, the expanded part
/// list, minifigs and spares are fetched here and snapshotted into GRDB at add-time so the
/// rest of the app works fully offline. Port of `CatalogRepository`.
///
/// S1 ships the reads the sync/rebuild layer needs (`CatalogReader`). Search + set detail are S2.
public final class SupabaseCatalogRepository: CatalogReader, @unchecked Sendable {
    private let client: SupabaseClient
    private let images: ImageResolver

    private static let setCols = "item_id, set_num, name, year, num_parts, rebrickable_img_url"

    public init(client: SupabaseClient, images: ImageResolver) {
        self.client = client
        self.images = images
    }

    /// Strip characters that would break the PostgREST or-filter / ilike pattern.
    private func sanitize(_ q: String) -> String {
        q.replacingOccurrences(of: "[,()%*]", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Image resolution

    /// Resolve item ids -> our R2/CDN image (item_images kind=webp), when mirrored.
    private func imageUrls(_ ids: [Int]) async throws -> [Int: String] {
        var out: [Int: String] = [:]
        guard !ids.isEmpty, images.cdnURL != nil else { return out }
        let rows: [ImageRow] = try await client
            .from("item_images")
            .select("item_id, storage_key")
            .in("item_id", values: ids)
            .eq("kind", value: "webp")
            .not("storage_key", operator: .is, value: "null")
            .execute()
            .value
        for r in rows {
            if let url = images.url(forStorageKey: r.storageKey), out[r.itemId] == nil {
                out[r.itemId] = url
            }
        }
        return out
    }

    private func toSet(_ r: SetRow, _ imgs: [Int: String]) -> CatalogSet {
        CatalogSet(
            itemId: r.itemId,
            setNum: r.setNum ?? "",
            name: r.name,
            year: r.year ?? 0,
            numParts: r.numParts ?? 0,
            imageUrl: imgs[r.itemId] ?? r.rebrickableImgUrl
        )
    }

    // MARK: - Search & set detail (S2)

    /// Catalog search over sets by name or number. Buildable sets only
    /// (`num_parts > 0` excludes books, bags, apparel). Debounced by the caller. Port of the
    /// Dart `search` — same `or` filter, `_sanitize`, and CDN image join.
    public func search(_ query: String, limit: Int = 25) async throws -> [CatalogResult] {
        let q = sanitize(query)
        guard !q.isEmpty else { return [] }
        let rows: [SetRow] = try await client
            .from("sets")
            .select(Self.setCols)
            .or("name.ilike.%\(q)%,set_num.ilike.\(q)%")
            .gt("num_parts", value: 0)
            .limit(limit)
            .execute()
            .value
        let imgs = try await imageUrls(rows.map(\.itemId))
        return rows.map { r in
            CatalogResult(
                itemId: r.itemId,
                kind: .set,
                ref: r.setNum ?? "",
                name: r.name,
                year: r.year,
                numParts: r.numParts,
                imageUrl: imgs[r.itemId] ?? r.rebrickableImgUrl
            )
        }
    }

    /// Set detail: set row + theme name (`items.theme_id → themes.name`) + minifig count
    /// (sum of figure quantities). Port of the Dart `setDetail`.
    public func setDetail(_ setItemId: Int) async throws -> SetDetail {
        let rows: [SetRow] = try await client
            .from("sets")
            .select(Self.setCols)
            .eq("item_id", value: setItemId)
            .limit(1)
            .execute()
            .value
        guard let row = rows.first else {
            throw CatalogError.setNotFound(setItemId)
        }
        let imgs = try await imageUrls([setItemId])
        let set = toSet(row, imgs)

        // Theme name via items.theme_id -> themes.name (nullable; the set may have no theme).
        var themeName: String?
        let itemRows: [ItemThemeRow] = try await client
            .from("items")
            .select("theme_id, themes(name)")
            .eq("id", value: setItemId)
            .limit(1)
            .execute()
            .value
        if let theme = itemRows.first?.themes { themeName = theme.name }

        let figs = try await setMinifigs(setItemId)
        let minifigCount = figs.reduce(0) { $0 + $1.quantity }

        return SetDetail(set: set, themeName: themeName, minifigCount: minifigCount)
    }

    // MARK: - CatalogReader

    public func setsByIds(_ ids: [Int]) async throws -> [CatalogSet] {
        guard !ids.isEmpty else { return [] }
        let rows: [SetRow] = try await client
            .from("sets")
            .select(Self.setCols)
            .in("item_id", values: ids)
            .execute()
            .value
        let imgs = try await imageUrls(rows.map(\.itemId))
        return rows.map { toSet($0, imgs) }
    }

    public func expandSetParts(_ setItemId: Int) async throws -> [ExpandedPart] {
        let rows: [PartRow] = try await client
            .rpc("expand_set_parts", params: ["p_set_item_id": setItemId])
            .execute()
            .value
        return rows.map { r in
            ExpandedPart(
                partItemId: r.partItemId,
                colorId: r.colorId,
                neededQty: r.quantity ?? 0,
                partName: r.partName ?? "Part",
                partNum: r.partNum,
                partCatId: r.partCatId,
                categoryName: r.categoryName,
                colorName: r.colorName,
                colorRgb: r.colorRgb,
                imageUrl: r.imgUrl,
                blPartId: r.blPartId,
                blColorId: r.blColorId
            )
        }
    }

    public func setMinifigs(_ setItemId: Int) async throws -> [CatalogMinifig] {
        guard let invId = try await latestInventoryId(setItemId) else { return [] }
        let rows: [MinifigInvRow] = try await client
            .from("inventory_minifigs")
            .select("minifig_item_id, quantity, minifigs(fig_num, name, rebrickable_img_url)")
            .eq("inventory_id", value: invId)
            .execute()
            .value
        let imgs = try await imageUrls(rows.map(\.minifigItemId))
        return rows.map { r in
            CatalogMinifig(
                minifigItemId: r.minifigItemId,
                quantity: r.quantity ?? 1,
                figNum: r.minifigs?.figNum ?? "",
                name: r.minifigs?.name ?? "Minifig",
                imageUrl: imgs[r.minifigItemId] ?? r.minifigs?.rebrickableImgUrl
            )
        }
    }

    public func getSetSpares(_ setItemId: Int) async throws -> [ExpandedPart] {
        guard let invId = try await latestInventoryId(setItemId) else { return [] }
        let rows: [SpareRow] = try await client
            .from("inventory_parts")
            .select("part_item_id, color_id, quantity, img_url, "
                + "parts(part_num, name, part_cat_id, part_categories(name)), "
                + "colors(name, rgb)")
            .eq("inventory_id", value: invId)
            .eq("is_spare", value: true)
            .execute()
            .value
        return rows.map { r in
            ExpandedPart(
                partItemId: r.partItemId,
                colorId: r.colorId,
                neededQty: r.quantity ?? 1,
                partName: r.parts?.name ?? "Part",
                partNum: r.parts?.partNum,
                partCatId: r.parts?.partCatId,
                categoryName: r.parts?.partCategories?.name,
                colorName: r.colors?.name,
                colorRgb: r.colors?.rgb,
                imageUrl: r.imgUrl,
                blPartId: nil,
                blColorId: nil
            )
        }
    }

    /// Latest (highest-version) inventory id for a set, or nil if the catalog has none.
    private func latestInventoryId(_ setItemId: Int) async throws -> Int? {
        let rows: [InventoryRow] = try await client
            .from("inventories")
            .select("id")
            .eq("item_id", value: setItemId)
            .order("version", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first?.id
    }
}

/// Errors surfaced by the read-only catalog path.
public enum CatalogError: Error, LocalizedError {
    case setNotFound(Int)

    public var errorDescription: String? {
        switch self {
        case .setNotFound(let id): return "Set #\(id) not found in the catalog."
        }
    }
}

// MARK: - Decodable DTOs (snake_case JSON via explicit CodingKeys; the PostgREST decoder
// does not convert keys). Kept private to the repo.

private struct SetRow: Decodable {
    let itemId: Int
    let setNum: String?
    let name: String
    let year: Int?
    let numParts: Int?
    let rebrickableImgUrl: String?
    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case setNum = "set_num"
        case name
        case year
        case numParts = "num_parts"
        case rebrickableImgUrl = "rebrickable_img_url"
    }
}

private struct ImageRow: Decodable {
    let itemId: Int
    let storageKey: String?
    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case storageKey = "storage_key"
    }
}

private struct InventoryRow: Decodable {
    let id: Int
}

private struct ItemThemeRow: Decodable {
    let themes: ThemeEmbed?
    struct ThemeEmbed: Decodable { let name: String? }
}

private struct PartRow: Decodable {
    let partItemId: Int
    let colorId: Int
    let quantity: Int?
    let partNum: String?
    let partName: String?
    let partCatId: Int?
    let categoryName: String?
    let colorName: String?
    let colorRgb: String?
    let imgUrl: String?
    let blPartId: String?
    let blColorId: Int?
    enum CodingKeys: String, CodingKey {
        case partItemId = "part_item_id"
        case colorId = "color_id"
        case quantity
        case partNum = "part_num"
        case partName = "part_name"
        case partCatId = "part_cat_id"
        case categoryName = "category_name"
        case colorName = "color_name"
        case colorRgb = "color_rgb"
        case imgUrl = "img_url"
        case blPartId = "bl_part_id"
        case blColorId = "bl_color_id"
    }
}

private struct MinifigInvRow: Decodable {
    let minifigItemId: Int
    let quantity: Int?
    let minifigs: MinifigEmbed?
    enum CodingKeys: String, CodingKey {
        case minifigItemId = "minifig_item_id"
        case quantity
        case minifigs
    }
    struct MinifigEmbed: Decodable {
        let figNum: String?
        let name: String?
        let rebrickableImgUrl: String?
        enum CodingKeys: String, CodingKey {
            case figNum = "fig_num"
            case name
            case rebrickableImgUrl = "rebrickable_img_url"
        }
    }
}

private struct SpareRow: Decodable {
    let partItemId: Int
    let colorId: Int
    let quantity: Int?
    let imgUrl: String?
    let parts: PartEmbed?
    let colors: ColorEmbed?
    enum CodingKeys: String, CodingKey {
        case partItemId = "part_item_id"
        case colorId = "color_id"
        case quantity
        case imgUrl = "img_url"
        case parts
        case colors
    }
    struct PartEmbed: Decodable {
        let partNum: String?
        let name: String?
        let partCatId: Int?
        let partCategories: CategoryEmbed?
        enum CodingKeys: String, CodingKey {
            case partNum = "part_num"
            case name
            case partCatId = "part_cat_id"
            case partCategories = "part_categories"
        }
    }
    struct CategoryEmbed: Decodable {
        let name: String?
    }
    struct ColorEmbed: Decodable {
        let name: String?
        let rgb: String?
    }
}
