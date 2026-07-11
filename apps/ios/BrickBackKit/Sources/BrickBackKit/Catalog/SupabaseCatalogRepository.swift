import Foundation
import Supabase

/// Read-only access to the LEGO catalog (whatabrick project) via the anon `catalogClient`.
/// **Never writes.** Every call is a `select` or `rpc`. Set metadata, the expanded part
/// list, minifigs and spares are fetched here and snapshotted into GRDB at add-time so the
/// rest of the app works fully offline. Port of `CatalogRepository`.
///
/// S1 ships the reads the sync/rebuild layer needs (`CatalogReader`) plus a `smokeReadSetName`
/// probe for the Home banner. Search + set detail are S2.
public final class SupabaseCatalogRepository: CatalogReader, @unchecked Sendable {
    private let client: SupabaseClient
    private let images: ImageResolver

    private static let setCols = "item_id, set_num, name, year, num_parts, rebrickable_img_url"

    public init(client: SupabaseClient, images: ImageResolver) {
        self.client = client
        self.images = images
    }

    // MARK: - Smoke read (S1)

    /// Fetch a single set's name to prove the anon catalog client works end-to-end on device
    /// — the same check the Flutter Phase 1 "Catalog OK · …" banner used.
    public func smokeReadSetName() async throws -> String? {
        struct NameRow: Decodable { let name: String }
        let rows: [NameRow] = try await client
            .from("sets")
            .select("name")
            .gt("num_parts", value: 0)
            .limit(1)
            .execute()
            .value
        return rows.first?.name
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
