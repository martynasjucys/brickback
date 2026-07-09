import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import '../rebuild/rebuild_models.dart';
import 'catalog_models.dart';

/// The subset of catalog reads the rebuild layer depends on. Extracted as an
/// interface so sync's "re-derive metadata from catalog on pull" path can be
/// exercised with a fake catalog in tests (no network). [CatalogRepository] is
/// the real implementation.
abstract interface class CatalogReader {
  Future<List<CatalogSet>> setsByIds(List<int> ids);
  Future<List<ExpandedPart>> expandSetParts(int setItemId);
  Future<List<CatalogMinifig>> setMinifigs(int setItemId);

  /// The set's **spare / extra** parts (the "just in case" pieces LEGO ships with).
  /// `expand_set_parts` deliberately excludes these (`is_spare = false`), so they
  /// are read separately from the set's own top-level inventory. One row per
  /// (part, colour); [ExpandedPart.neededQty] is the spare quantity. Empty when
  /// the set has no spares / no catalog inventory.
  Future<List<ExpandedPart>> getSetSpares(int setItemId);
}

/// Read-only access to the LEGO catalog (whatabrick project) via [catalogClient].
///
/// **Never writes.** Every call is a `select` or `rpc`. Set metadata, the
/// expanded part list, and minifigs are fetched here and snapshotted into Drift
/// at add-time so the rest of the app works fully offline.
class CatalogRepository implements CatalogReader {
  CatalogRepository(this._cdn);

  final String? _cdn;

  static const _setCols = 'item_id, set_num, name, year, num_parts, rebrickable_img_url';

  // Strip characters that would break PostgREST or-filter / ilike patterns.
  String _sanitize(String q) => q.replaceAll(RegExp(r'[,()%*]'), ' ').trim();

  /// Resolve item ids -> our R2/CDN image (item_images kind=webp), when mirrored.
  Future<Map<int, String>> _imageUrls(List<int> ids) async {
    final out = <int, String>{};
    if (ids.isEmpty || _cdn == null || _cdn.isEmpty) return out;
    final rows = await catalogClient
        .from('item_images')
        .select('item_id, storage_key')
        .inFilter('item_id', ids)
        .eq('kind', 'webp')
        .not('storage_key', 'is', null);
    for (final r in rows) {
      final id = r['item_id'] as int;
      final key = r['storage_key'] as String?;
      if (key != null && !out.containsKey(id)) out[id] = '$_cdn/$key';
    }
    return out;
  }

  CatalogSet _toSet(Map<String, dynamic> r, Map<int, String> imgs) {
    final id = r['item_id'] as int;
    return CatalogSet(
      itemId: id,
      setNum: r['set_num'] as String,
      name: r['name'] as String,
      year: r['year'] as int? ?? 0,
      numParts: r['num_parts'] as int? ?? 0,
      imageUrl: imgs[id] ?? r['rebrickable_img_url'] as String?,
    );
  }

  /// Catalog search over sets by name or number. Buildable sets only
  /// (`num_parts > 0` excludes books, bags, apparel). Debounced by the caller.
  Future<List<CatalogResult>> search(String query, {int limit = 25}) async {
    final q = _sanitize(query);
    if (q.isEmpty) return [];

    final rows = await catalogClient
        .from('sets')
        .select(_setCols)
        .or('name.ilike.%$q%,set_num.ilike.$q%')
        .gt('num_parts', 0)
        .limit(limit);
    final list = rows.cast<Map<String, dynamic>>();
    final imgs = await _imageUrls([for (final r in list) r['item_id'] as int]);
    return [
      for (final r in list)
        CatalogResult(
          itemId: r['item_id'] as int,
          kind: CatalogKind.set,
          ref: r['set_num'] as String,
          name: r['name'] as String,
          year: r['year'] as int?,
          numParts: r['num_parts'] as int?,
          imageUrl: imgs[r['item_id'] as int] ?? r['rebrickable_img_url'] as String?,
        ),
    ];
  }

  /// Fetch set metadata by item id (batched).
  @override
  Future<List<CatalogSet>> setsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final rows = await catalogClient.from('sets').select(_setCols).inFilter('item_id', ids);
    final list = rows.cast<Map<String, dynamic>>();
    final imgs = await _imageUrls([for (final r in list) r['item_id'] as int]);
    return [for (final r in list) _toSet(r, imgs)];
  }

  /// Latest (highest-version) inventory id for a set, or null if the catalog has
  /// no inventory for it.
  Future<int?> _latestInventoryId(int setItemId) async {
    final inv = await catalogClient
        .from('inventories')
        .select('id')
        .eq('item_id', setItemId)
        .order('version', ascending: false)
        .limit(1)
        .maybeSingle();
    return inv == null ? null : inv['id'] as int;
  }

  /// Expanded (part, colour) lines needed to build a set. Spares are excluded and
  /// minifig sub-parts are included by the catalog RPC. One row per (part, colour).
  @override
  Future<List<ExpandedPart>> expandSetParts(int setItemId) async {
    final rows = await catalogClient.rpc('expand_set_parts', params: {'p_set_item_id': setItemId});
    return [for (final r in (rows as List)) ExpandedPart.fromCatalogRow(r as Map<String, dynamic>)];
  }

  /// The minifigs belonging to a set's latest inventory (for minifig verification
  /// in Phase 4). Empty when the set has no minifigs / no catalog inventory.
  @override
  Future<List<CatalogMinifig>> setMinifigs(int setItemId) async {
    final invId = await _latestInventoryId(setItemId);
    if (invId == null) return [];
    final rows = await catalogClient
        .from('inventory_minifigs')
        .select('minifig_item_id, quantity, minifigs(fig_num, name, rebrickable_img_url)')
        .eq('inventory_id', invId);
    final list = rows.cast<Map<String, dynamic>>();
    final imgs = await _imageUrls([for (final r in list) r['minifig_item_id'] as int]);
    return [
      for (final r in list)
        () {
          final id = r['minifig_item_id'] as int;
          final fig = r['minifigs'];
          final m = fig is Map ? fig : const {};
          return CatalogMinifig(
            minifigItemId: id,
            quantity: r['quantity'] as int? ?? 1,
            figNum: m['fig_num'] as String? ?? '',
            name: m['name'] as String? ?? 'Minifig',
            imageUrl: imgs[id] ?? m['rebrickable_img_url'] as String?,
          );
        }(),
    ];
  }

  /// Spare / extra parts for a set — read directly from the set's top-level
  /// inventory (spares only live there, not in sub-sets/minifigs, so no recursion).
  /// Metadata (part / category / colour) comes via nested embeds; the per part+
  /// colour photo is `inventory_parts.img_url`, same source the checklist uses.
  @override
  Future<List<ExpandedPart>> getSetSpares(int setItemId) async {
    final invId = await _latestInventoryId(setItemId);
    if (invId == null) return const [];
    final rows = await catalogClient
        .from('inventory_parts')
        .select('part_item_id, color_id, quantity, img_url, '
            'parts(part_num, name, part_cat_id, part_categories(name)), '
            'colors(name, rgb)')
        .eq('inventory_id', invId)
        .eq('is_spare', true);
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        () {
          final part = r['parts'] is Map ? r['parts'] as Map : const {};
          final cat = part['part_categories'] is Map ? part['part_categories'] as Map : const {};
          final color = r['colors'] is Map ? r['colors'] as Map : const {};
          return ExpandedPart(
            partItemId: r['part_item_id'] as int,
            colorId: r['color_id'] as int,
            neededQty: r['quantity'] as int? ?? 1,
            partName: part['name'] as String? ?? 'Part',
            partNum: part['part_num'] as String?,
            partCatId: part['part_cat_id'] as int?,
            categoryName: cat['name'] as String?,
            colorName: color['name'] as String?,
            colorRgb: color['rgb'] as String?,
            imageUrl: r['img_url'] as String?,
            blPartId: null,
            blColorId: null,
          );
        }(),
    ];
  }

  /// Set detail: set row + theme name + minifig count (sum of figure quantities).
  Future<SetDetail> setDetail(int setItemId) async {
    final setRow =
        await catalogClient.from('sets').select(_setCols).eq('item_id', setItemId).single();
    final imgs = await _imageUrls([setItemId]);
    final set = _toSet(setRow.cast<String, dynamic>(), imgs);

    // Theme name via items.theme_id -> themes.name.
    String? themeName;
    final itemRow = await catalogClient
        .from('items')
        .select('theme_id, themes(name)')
        .eq('id', setItemId)
        .maybeSingle();
    if (itemRow != null) {
      final theme = itemRow['themes'];
      if (theme is Map) themeName = theme['name'] as String?;
    }

    final figs = await setMinifigs(setItemId);
    final minifigCount = figs.fold<int>(0, (a, m) => a + m.quantity);

    return SetDetail(set: set, themeName: themeName, minifigCount: minifigCount);
  }
}

final catalogRepositoryProvider =
    Provider<CatalogRepository>((ref) => CatalogRepository(Env.cdnUrl));

final setDetailProvider =
    FutureProvider.autoDispose.family<SetDetail, int>((ref, itemId) {
  return ref.read(catalogRepositoryProvider).setDetail(itemId);
});

final searchProvider =
    FutureProvider.autoDispose.family<List<CatalogResult>, String>((ref, query) {
  return ref.read(catalogRepositoryProvider).search(query);
});

/// The set's expanded (part, colour) lines — one per unique part. Backs the
/// "unique parts" count on the set detail and the unique-parts list screen.
final setPartsProvider = FutureProvider.autoDispose.family<List<ExpandedPart>, int>(
    (ref, itemId) => ref.read(catalogRepositoryProvider).expandSetParts(itemId));

/// The set's minifigs — backs the minifig list screen.
final setMinifigsProvider = FutureProvider.autoDispose.family<List<CatalogMinifig>, int>(
    (ref, itemId) => ref.read(catalogRepositoryProvider).setMinifigs(itemId));
