// Catalog domain models. All fields are read straight from the read-only
// catalog project (whatabrick) — nothing here is ever written back.

enum CatalogKind { set, minifig }

/// A LEGO set as it appears in the catalog `sets` table.
class CatalogSet {
  const CatalogSet({
    required this.itemId,
    required this.setNum,
    required this.name,
    required this.year,
    required this.numParts,
    required this.imageUrl,
  });

  final int itemId; // catalog items.id
  final String setNum;
  final String name;
  final int year;
  final int numParts;
  final String? imageUrl;
}

/// A single catalog search hit (sets only in Phase 2 — the app adds sets, not
/// minifigs — but the shape carries [kind] for later browse surfaces).
class CatalogResult {
  const CatalogResult({
    required this.itemId,
    required this.kind,
    required this.ref,
    required this.name,
    this.year,
    this.numParts,
    required this.imageUrl,
  });

  final int itemId;
  final CatalogKind kind;
  final String ref; // set_num / fig_num
  final String name;
  final int? year;
  final int? numParts;
  final String? imageUrl;
}

/// One minifig belonging to a set (latest inventory), with its needed quantity.
class CatalogMinifig {
  const CatalogMinifig({
    required this.minifigItemId,
    required this.quantity,
    required this.figNum,
    required this.name,
    required this.imageUrl,
  });

  final int minifigItemId; // catalog minifigs.item_id
  final int quantity;
  final String figNum;
  final String name;
  final String? imageUrl;
}

/// Set-detail payload: the set row + resolved theme name + minifig count.
/// Deliberately lean — no price / rarity / 3D (whatabrick extras, out of MVP).
class SetDetail {
  const SetDetail({
    required this.set,
    this.themeName,
    this.minifigCount = 0,
  });

  final CatalogSet set;
  final String? themeName;
  final int minifigCount;
}
