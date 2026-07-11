import Foundation

/// The subset of catalog reads the rebuild layer depends on. Extracted as a protocol so
/// sync's "re-derive metadata from catalog on pull" path can be exercised with a fake
/// catalog in tests (no network). `SupabaseCatalogRepository` is the real implementation.
/// Port of the `CatalogReader` interface in `catalog_repository.dart`.
public protocol CatalogReader: Sendable {
    func setsByIds(_ ids: [Int]) async throws -> [CatalogSet]
    func expandSetParts(_ setItemId: Int) async throws -> [ExpandedPart]
    func setMinifigs(_ setItemId: Int) async throws -> [CatalogMinifig]

    /// The set's **spare / extra** parts (the "just in case" pieces LEGO ships with).
    /// `expand_set_parts` deliberately excludes these (`is_spare = false`), so they are read
    /// separately from the set's own top-level inventory. One row per (part, colour);
    /// `ExpandedPart.neededQty` is the spare quantity. Empty when the set has no spares.
    func getSetSpares(_ setItemId: Int) async throws -> [ExpandedPart]
}
