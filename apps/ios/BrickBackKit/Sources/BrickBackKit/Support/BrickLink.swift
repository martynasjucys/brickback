import Foundation

/// BrickLink catalog deep-link for a part. Port of `bricklink.dart`.
///
/// Uses the BrickLink part id from `expand_set_parts` when present (the v2 catalog page shows a
/// colour selector); otherwise falls back to a catalog search by part number. The v2
/// `catalogitem.page` rejects an `idColor` query param, so colour is intentionally not
/// deep-linked — `blColorId` is accepted for forward-compatibility only.
public enum BrickLink {
    public static func url(blPartId: String?, blColorId: Int? = nil, partNum: String?) -> URL? {
        if let id = blPartId, !id.isEmpty {
            return URL(string: "https://www.bricklink.com/v2/catalog/catalogitem.page?P=\(id)")
        }
        let q = (partNum ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
        return URL(string: "https://www.bricklink.com/v2/search.page?q=\(q)")
    }

    /// Whether we have enough identity to open a useful BrickLink page for a part.
    public static func hasLink(blPartId: String?, partNum: String?) -> Bool {
        (blPartId?.isEmpty == false) || (partNum?.isEmpty == false)
    }
}

private extension CharacterSet {
    /// Query-value safe set (drops `&`, `=`, `?`, `+`, `/`, etc. that `.urlQueryAllowed` keeps).
    static let urlQueryValueAllowed: CharacterSet = {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "&=?+/#")
        return set
    }()
}
