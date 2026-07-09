// BrickLink Wanted List XML — ported from whatabrick (which ports the web
// `wanted-list.ts`). Imports cleanly into BrickLink's Wanted List uploader.
//
//   <ITEMID> = BrickLink part id (falls back to the part number),
//   <COLOR>  = BL colour id (omitted when unknown — BrickLink then treats it as
//              "any colour", which is better than dropping the line),
//   <MINQTY> = shortfall (needed − have).

class WantedItem {
  const WantedItem({required this.blItemId, required this.blColorId, required this.minQty});
  final String blItemId;
  final int? blColorId;
  final int minQty;
}

String buildWantedListXml(List<WantedItem> items) {
  final body = items
      .where((i) => i.minQty > 0 && i.blItemId.isNotEmpty)
      .map((i) {
        final color = i.blColorId != null ? '\n    <COLOR>${i.blColorId}</COLOR>' : '';
        return '  <ITEM>\n'
            '    <ITEMTYPE>P</ITEMTYPE>\n'
            '    <ITEMID>${_escapeXml(i.blItemId)}</ITEMID>$color\n'
            '    <MINQTY>${i.minQty}</MINQTY>\n'
            '  </ITEM>';
      })
      .join('\n');
  return '<?xml version="1.0" encoding="UTF-8"?>\n<INVENTORY>\n$body\n</INVENTORY>\n';
}

String _escapeXml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
