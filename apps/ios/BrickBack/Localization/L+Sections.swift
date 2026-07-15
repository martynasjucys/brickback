import BrickBackKit

extension L {
    /// Localized title for a counting-screen section. The fixed sections carry a `titleKey` and
    /// resolve through the String Catalog; colour/category sections have `titleKey == nil` and
    /// render their real catalog name (`label`) verbatim. Keeps BrickBackKit string-free (S7).
    static func sectionTitle(_ section: PartSection) -> String {
        switch section.titleKey {
        case .allParts: return sectionAllParts
        case .remaining: return sectionRemaining
        case .complete: return sectionComplete
        case .extras: return sectionExtras
        case .unknownColor: return unknownColor
        case .otherCategory: return sectionOther
        case nil: return section.label
        }
    }
}
