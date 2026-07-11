import Foundation

/// One line of a BrickLink wanted list — a shortfall `(item, colour)` to re-buy.
public struct WantedItem: Sendable, Hashable {
    public let blItemId: String // BL part id, or the part number as a usable fallback
    public let blColorId: Int? // omitted from the XML when unknown
    public let minQty: Int // shortfall (needed − have)

    public init(blItemId: String, blColorId: Int?, minQty: Int) {
        self.blItemId = blItemId
        self.blColorId = blColorId
        self.minQty = minQty
    }
}

/// BrickLink Wanted List XML — verbatim port of `wanted_list.dart` (which ports the web
/// `wanted-list.ts`). Imports cleanly into BrickLink's Wanted List uploader.
///
///   `<ITEMID>` = BrickLink part id (falls back to the part number),
///   `<COLOR>`  = BL colour id (omitted when unknown — BrickLink then treats it as "any colour",
///                which is better than dropping the line),
///   `<MINQTY>` = shortfall (needed − have).
public enum WantedList {
    public static func buildWantedListXML(_ items: [WantedItem]) -> String {
        let body = items
            .filter { $0.minQty > 0 && !$0.blItemId.isEmpty }
            .map { i -> String in
                let color = i.blColorId != nil ? "\n    <COLOR>\(i.blColorId!)</COLOR>" : ""
                return "  <ITEM>\n"
                    + "    <ITEMTYPE>P</ITEMTYPE>\n"
                    + "    <ITEMID>\(escapeXML(i.blItemId))</ITEMID>\(color)\n"
                    + "    <MINQTY>\(i.minQty)</MINQTY>\n"
                    + "  </ITEM>"
            }
            .joined(separator: "\n")
        return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<INVENTORY>\n\(body)\n</INVENTORY>\n"
    }

    private static func escapeXML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
