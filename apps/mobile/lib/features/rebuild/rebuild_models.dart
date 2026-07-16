import 'dart:math' as math;

/// One (part, colour) line — the "needed" side of a rebuild. Sourced from the
/// catalog `expand_set_parts` RPC at add-time and then snapshotted into Drift, so
/// it round-trips from either the catalog (add) or local storage (offline UI).
class ExpandedPart {
  const ExpandedPart({
    required this.partItemId,
    required this.colorId,
    required this.neededQty,
    required this.partName,
    required this.partNum,
    required this.partCatId,
    required this.categoryName,
    required this.colorName,
    required this.colorRgb,
    required this.imageUrl,
    required this.blPartId,
    required this.blColorId,
  });

  final int partItemId; // catalog parts.item_id
  final int colorId; // catalog colors.id
  final int neededQty;
  final String partName;
  final String? partNum;
  final int? partCatId;
  final String? categoryName; // from the RPC only (not persisted); null offline
  final String? colorName;
  final String? colorRgb;
  final String? imageUrl;
  final String? blPartId;
  final int? blColorId;

  /// Part identity within a rebuild — the whatabrick convention, reused verbatim
  /// so progress math and future wanted-list export line up.
  String get key => '$partItemId:$colorId';

  static ExpandedPart fromCatalogRow(Map<String, dynamic> r) => ExpandedPart(
        partItemId: r['part_item_id'] as int,
        colorId: r['color_id'] as int,
        neededQty: r['quantity'] as int,
        partNum: r['part_num'] as String?,
        partName: r['part_name'] as String? ?? 'Part',
        partCatId: r['part_cat_id'] as int?,
        categoryName: r['category_name'] as String?,
        colorName: r['color_name'] as String?,
        colorRgb: r['color_rgb'] as String?,
        imageUrl: r['img_url'] as String?,
        blPartId: r['bl_part_id'] as String?,
        blColorId: r['bl_color_id'] as int?,
      );
}

/// One minifig line for a rebuild (verified separately from parts in Phase 4).
class RebuildMinifigLine {
  const RebuildMinifigLine({
    required this.minifigItemId,
    required this.neededQty,
    required this.haveQty,
    required this.name,
    required this.imageUrl,
  });

  final int minifigItemId;
  final int neededQty;
  final int haveQty;
  final String name;
  final String? imageUrl;

  bool get complete => haveQty >= neededQty;
}

/// A still-short `(part, colour)` for one rebuild — the shortfall side of the
/// review screen and the BrickLink wanted-list export. Computed locally off the
/// Drift snapshot; [needed] is `max(0, neededQty - have)`.
class MissingPart {
  const MissingPart({
    required this.partItemId,
    required this.colorId,
    required this.needed,
    required this.partName,
    required this.partNum,
    required this.colorName,
    required this.colorRgb,
    required this.imageUrl,
    required this.blPartId,
    required this.blColorId,
  });

  final int partItemId;
  final int colorId;
  final int needed; // shortfall (needed − have)
  final String partName;
  final String? partNum;
  final String? colorName;
  final String? colorRgb;
  final String? imageUrl;
  final String? blPartId;
  final int? blColorId;

  String get key => '$partItemId:$colorId';

  /// Whether this part can be put on a BrickLink wanted list (needs a BL item id;
  /// the part number is a usable fallback). Parts with neither are surfaced in a
  /// "not exportable" footnote rather than silently dropped.
  bool get exportable =>
      (blPartId != null && blPartId!.isNotEmpty) ||
      (partNum != null && partNum!.isNotEmpty);
}

/// A tracked set rebuild (rebuild_sets row + progress), for the Home list.
class RebuildSummary {
  const RebuildSummary({
    required this.id,
    required this.setItemId,
    required this.name,
    required this.imageUrl,
    required this.totalParts,
    required this.haveTotal,
    this.theme,
    this.verifiedAt,
  });

  final String id; // rebuild_sets.id (uuid)
  final int setItemId;
  final String name; // auto-numbered "#N" when the set is added more than once
  final String? imageUrl;
  final int totalParts;
  final int haveTotal; // capped sum of have (<= totalParts)
  final String? theme; // local, catalog-derived LEGO theme (non-synced); drives the Home filter
  final DateTime? verifiedAt; // set once a verification is recorded (Phase 4)

  double get progress => totalParts == 0 ? 0 : (haveTotal / totalParts).clamp(0, 1);
  bool get complete => totalParts > 0 && haveTotal >= totalParts;
  bool get verified => verifiedAt != null;
}

/// Full checklist for one rebuild — read entirely from the local snapshot.
class RebuildInventory {
  const RebuildInventory({
    required this.summary,
    required this.parts,
    required this.have,
    required this.minifigs,
    this.step = const {},
    this.extras = const [],
    this.extraHave = const {},
  });

  final RebuildSummary summary;
  final List<ExpandedPart> parts;
  final Map<String, int> have; // key -> have_qty

  /// Per-part tap increment ("step"), keyed by [ExpandedPart.key]. Each part
  /// carries its own step so bulk pieces (e.g. Technic pins) count 10/20 at a
  /// tap while a one-off brick counts by 1. Missing key ⇒ default step of 1.
  final Map<String, int> step;

  final List<RebuildMinifigLine> minifigs;

  /// The set's spare / extra parts (needed side). A countable bonus that is
  /// deliberately **excluded** from [haveTotal] / [progress] / [complete] — it's
  /// not part of the build target. Empty unless the set ships spares.
  final List<ExpandedPart> extras;
  final Map<String, int> extraHave; // key -> extras found

  int haveFor(ExpandedPart p) => have[p.key] ?? 0;
  int extraHaveFor(ExpandedPart p) => extraHave[p.key] ?? 0;
  bool get hasExtras => extras.isNotEmpty;

  int get neededTotal => summary.totalParts;
  int get haveTotal =>
      parts.fold(0, (s, p) => s + math.min(have[p.key] ?? 0, p.neededQty));
  double get progress => neededTotal == 0 ? 0 : (haveTotal / neededTotal).clamp(0, 1);
  bool get complete => parts.isNotEmpty && parts.every((p) => (have[p.key] ?? 0) >= p.neededQty);
  int get remainingPartTypes => parts.where((p) => (have[p.key] ?? 0) < p.neededQty).length;

  // --- Phase 4 review math (all local, off the snapshot) ----------------------

  int get partsFound => haveTotal;

  /// Every still-short `(part, colour)`, biggest shortfall first. Empty when the
  /// rebuild is 100% — so an empty list is the "nothing missing" signal.
  List<MissingPart> get missingParts {
    final out = <MissingPart>[];
    for (final p in parts) {
      final short = p.neededQty - (have[p.key] ?? 0);
      if (short <= 0) continue;
      out.add(MissingPart(
        partItemId: p.partItemId,
        colorId: p.colorId,
        needed: short,
        partName: p.partName,
        partNum: p.partNum,
        colorName: p.colorName,
        colorRgb: p.colorRgb,
        imageUrl: p.imageUrl,
        blPartId: p.blPartId,
        blColorId: p.blColorId,
      ));
    }
    out.sort((a, b) => b.needed.compareTo(a.needed));
    return out;
  }

  int get minifigsNeeded => minifigs.fold(0, (s, m) => s + m.neededQty);
  int get minifigsFound =>
      minifigs.fold(0, (s, m) => s + math.min(m.haveQty, m.neededQty));
  bool get hasMinifigs => minifigs.isNotEmpty;
  bool get minifigsComplete =>
      minifigs.isEmpty || minifigs.every((m) => m.haveQty >= m.neededQty);
}
