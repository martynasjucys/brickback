// Catalog domain models. All fields are read straight from the read-only
// catalog project (whatabrick) — nothing here is ever written back.

enum CatalogKind { set, minifig }

/// A set's availability stage, recomputed daily in the catalog from community-sourced dates
/// (Brickset / BrickEconomy), so it's "best available" rather than official LEGO data. `null` for
/// recent, undated sets where the stage is genuinely unknown. Mirrors `sets.lifecycle_status`.
enum SetLifecycle {
  upcoming('upcoming'),
  available('available'),
  retiringSoon('retiring_soon'),
  retired('retired');

  const SetLifecycle(this.raw);
  final String raw;

  static SetLifecycle? fromRaw(String? value) {
    if (value == null) return null;
    for (final v in SetLifecycle.values) {
      if (v.raw == value) return v;
    }
    return null;
  }
}

/// A LEGO set as it appears in the catalog `sets` table.
class CatalogSet {
  const CatalogSet({
    required this.itemId,
    required this.setNum,
    required this.name,
    required this.year,
    required this.numParts,
    required this.imageUrl,
    this.themeName,
    this.lifecycle,
    this.launchDate,
    this.exitDate,
    this.retiringSoonDate,
  });

  final int itemId; // catalog items.id
  final String setNum;
  final String name;
  final int year;
  final int numParts;
  final String? imageUrl;
  final String? themeName; // resolved theme (items.theme_id → themes.name); null if the set has none
  final SetLifecycle? lifecycle; // availability stage; null when unknown
  final DateTime? launchDate; // official launch / release date (null for older or undated sets)
  final DateTime? exitDate; // official retirement date
  final DateTime? retiringSoonDate; // estimated upcoming retirement (retiring-soon sets)
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

/// Latest cached BrickLink "sold" value for a set — the quantity-weighted average of recent
/// completed sales, split by condition. Community market data; `null` sides mean no signal
/// (no recent sales or the set isn't price-mapped). Mirrors `bricklink_price_guides`.
class SetPrice {
  const SetPrice({required this.newValue, required this.used, required this.currency});

  final double? newValue;
  final double? used;
  final String currency;

  bool get hasAny => newValue != null || used != null;
}

/// Set-detail payload: the set row (incl. lifecycle dates) + resolved theme name + minifig count
/// + latest market value.
class SetDetail {
  const SetDetail({
    required this.set,
    this.themeName,
    this.minifigCount = 0,
    this.price,
  });

  final CatalogSet set;
  final String? themeName;
  final int minifigCount;
  final SetPrice? price;
}
