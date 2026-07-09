/// BrickLink catalog deep-link for a part. Uses the BrickLink part id from
/// `expand_set_parts` when present (the v2 catalog page shows a colour selector);
/// otherwise falls back to a catalog search by part number.
///
/// Note: the v2 `catalogitem.page` rejects an `idColor` query param ("General
/// Error"), so colour is intentionally not deep-linked — the part page lets the
/// user pick the colour. `blColorId` is accepted for forward-compatibility.
String brickLinkUrl({String? blPartId, int? blColorId, String? partNum}) {
  if (blPartId != null && blPartId.isNotEmpty) {
    return 'https://www.bricklink.com/v2/catalog/catalogitem.page?P=$blPartId';
  }
  return 'https://www.bricklink.com/v2/search.page?q=${Uri.encodeComponent(partNum ?? '')}';
}

/// Whether we have enough identity to open a useful BrickLink page for a part.
bool hasBrickLink({String? blPartId, String? partNum}) =>
    (blPartId != null && blPartId.isNotEmpty) || (partNum != null && partNum.isNotEmpty);
