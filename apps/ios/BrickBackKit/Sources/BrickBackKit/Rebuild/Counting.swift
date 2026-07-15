import Foundation

/// Pure counting-domain helpers for the S3 tap-to-count screen — no UI, no I/O, so they're
/// unit-tested directly (the SwiftUI `RebuildView` is a thin shell over these). Ports the
/// `_buildGroups` / `_PartGroup` / tap-cap logic from `rebuild_screen.dart`.
///
/// **Section identity, not display strings.** The fixed section titles (All parts / Unknown /
/// Other / Remaining / Complete / Extras) are exposed as a `titleKey` the UI localizes (S7),
/// keeping BrickBackKit string-free. `label` still carries a plain-English fallback so the
/// domain stays testable without a bundle; the UI renders `titleKey` when set, else `label`
/// (which for colour/category sections IS the real catalog name — never translated).

/// How the counting screen groups the parts list. Raw values persist via `@AppStorage`.
public enum PartGrouping: String, CaseIterable, Sendable {
    case color
    case category
    case status
    case none
}

/// Which fixed (non-data-derived) section a `PartSection` is, so the UI can localize its title.
/// `nil` on a section means `label` holds a real catalog name (a colour or category) that must
/// render verbatim.
public enum SectionTitle: Sendable {
    case allParts
    case remaining
    case complete
    case extras
    case unknownColor   // a colour section whose colour has no name
    case otherCategory  // the catch-all category bucket
}

/// Tile-tap increment: add `step`, never exceeding `needed`. Callers guard `current < needed`
/// (a completed part can't be pushed over). Pure so the cap is unit-tested directly.
public func tapIncrement(current: Int, step: Int, needed: Int) -> Int {
    min(current + step, needed)
}

/// One section of the counting list. Membership is derived per render (cheap); tiles carry
/// stable ids so only their `have` changes on a tap.
public struct PartSection: Sendable, Identifiable {
    public let id: String
    public let label: String
    /// Set for the fixed sections so the UI localizes them; `nil` when `label` is a real
    /// catalog colour/category name (rendered verbatim).
    public let titleKey: SectionTitle?
    public let colorRgb: String? // non-nil only for colour sections (renders a swatch)
    public let parts: [ExpandedPart]
    public let neededTotal: Int

    public init(id: String, label: String, colorRgb: String?, parts: [ExpandedPart], titleKey: SectionTitle? = nil) {
        self.id = id
        self.label = label
        self.titleKey = titleKey
        self.colorRgb = colorRgb
        self.parts = parts
        self.neededTotal = parts.reduce(0) { $0 + $1.neededQty }
    }

    /// Capped "have" across the section (`Σ min(have, needed)`).
    public func haveIn(_ have: [String: Int]) -> Int {
        parts.reduce(0) { $0 + min(have[$1.key] ?? 0, $1.neededQty) }
    }

    /// A section is hidden under "Remaining only" once every part in it is complete.
    public func visible(_ have: [String: Int], remainingOnly: Bool) -> Bool {
        if !remainingOnly { return true }
        return parts.contains { (have[$0.key] ?? 0) < $0.neededQty }
    }
}

/// Colour-then-name ordering (the `_byColorThenName` comparator).
func byColorThenName(_ a: ExpandedPart, _ b: ExpandedPart) -> Bool {
    let ca = a.colorName ?? "~", cb = b.colorName ?? "~"
    if ca != cb { return ca < cb }
    return a.partName < b.partName
}

/// Section the build parts by the chosen grouping. `color` shows a swatch per section; the
/// others use a plain label. `status` is dynamic (a part moves between "Remaining" and
/// "Complete" as it's counted), so that split reads the live `have`. Port of `_buildGroups`.
public func partSections(_ parts: [ExpandedPart], grouping: PartGrouping, have: [String: Int]) -> [PartSection] {
    switch grouping {
    case .none:
        return [PartSection(id: "all", label: "All parts", colorRgb: nil,
                            parts: parts.sorted(by: byColorThenName), titleKey: .allParts)]

    case .color:
        var byColor: [Int: [ExpandedPart]] = [:]
        for p in parts { byColor[p.colorId, default: []].append(p) }
        var sections = byColor.map { cid, group -> PartSection in
            let sorted = group.sorted { $0.partName < $1.partName }
            let name = sorted.first?.colorName
            return PartSection(
                id: "c\(cid)",
                label: name ?? "Unknown",
                colorRgb: sorted.first?.colorRgb ?? "808080",
                parts: sorted,
                titleKey: name == nil ? .unknownColor : nil
            )
        }
        sections.sort { $0.label < $1.label }
        return sections

    case .category:
        var byCat: [String: [ExpandedPart]] = [:]
        for p in parts { byCat[p.categoryName ?? "Other", default: []].append(p) }
        var sections = byCat.map { name, group in
            PartSection(id: "t\(name)", label: name, colorRgb: nil,
                        parts: group.sorted(by: byColorThenName),
                        titleKey: name == "Other" ? .otherCategory : nil)
        }
        sections.sort { $0.label < $1.label }
        return sections

    case .status:
        var remaining: [ExpandedPart] = []
        var complete: [ExpandedPart] = []
        for p in parts {
            if (have[p.key] ?? 0) >= p.neededQty { complete.append(p) } else { remaining.append(p) }
        }
        remaining.sort(by: byColorThenName)
        complete.sort(by: byColorThenName)
        var out: [PartSection] = []
        if !remaining.isEmpty { out.append(PartSection(id: "remaining", label: "Remaining", colorRgb: nil, parts: remaining, titleKey: .remaining)) }
        if !complete.isEmpty { out.append(PartSection(id: "complete", label: "Complete", colorRgb: nil, parts: complete, titleKey: .complete)) }
        return out
    }
}

/// The single "Extras" section (spare parts), rendered below the build parts.
public func extrasSection(_ extras: [ExpandedPart]) -> PartSection {
    PartSection(id: "extras", label: "Extras", colorRgb: nil,
                parts: extras.sorted(by: byColorThenName), titleKey: .extras)
}
