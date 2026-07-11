import Foundation

/// The certificate flags for an Inventory Verification — the three manual checks a builder ticks
/// plus the two derived from the counts. Serialised as the JSON `flags` blob on a `verifications`
/// row (see `VerificationRecord`) so the report renders offline and the S5 cloud mirror passes the
/// same string through unchanged. Port of `VerificationFlags` (verification_models.dart); the JSON
/// keys (`box` / `instructions` / `stickers` / `all_parts` / `minifigs`) match the cloud schema.
public struct VerificationFlags: Codable, Sendable, Hashable {
    public var boxIncluded: Bool // user-toggled
    public var instructionsIncluded: Bool // user-toggled
    public var stickersApplied: Bool // user-toggled
    public var allParts: Bool // derived: parts 100%
    public var minifigsIncluded: Bool // derived: minifigs complete (or none)

    public init(
        boxIncluded: Bool = false, instructionsIncluded: Bool = false, stickersApplied: Bool = false,
        allParts: Bool = false, minifigsIncluded: Bool = false
    ) {
        self.boxIncluded = boxIncluded
        self.instructionsIncluded = instructionsIncluded
        self.stickersApplied = stickersApplied
        self.allParts = allParts
        self.minifigsIncluded = minifigsIncluded
    }

    enum CodingKeys: String, CodingKey {
        case boxIncluded = "box"
        case instructionsIncluded = "instructions"
        case stickersApplied = "stickers"
        case allParts = "all_parts"
        case minifigsIncluded = "minifigs"
    }

    public func copyWith(allParts: Bool? = nil, minifigsIncluded: Bool? = nil) -> VerificationFlags {
        VerificationFlags(
            boxIncluded: boxIncluded, instructionsIncluded: instructionsIncluded, stickersApplied: stickersApplied,
            allParts: allParts ?? self.allParts, minifigsIncluded: minifigsIncluded ?? self.minifigsIncluded
        )
    }

    /// Encode to the JSON string stored in `verifications.flags`. Deterministic key order so
    /// snapshots/tests are stable.
    public func encode() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(self), let s = String(data: data, encoding: .utf8) else { return "{}" }
        return s
    }

    /// Tolerant decode of a stored `flags` blob — any malformed value falls back to all-false
    /// (mirrors the Dart `try/catch` decode), so a bad row never crashes the report.
    public static func decode(_ raw: String) -> VerificationFlags {
        guard let data = raw.data(using: .utf8),
              let flags = try? JSONDecoder().decode(VerificationFlags.self, from: data)
        else { return VerificationFlags() }
        return flags
    }
}

/// A recorded Inventory Verification — the payoff of the review flow, rendered by the report /
/// certificate. The domain view of a `verifications` row (with the `flags` blob decoded); the
/// repository returns this, keeping the SwiftUI layer clear of GRDB. Port of `VerificationRecord`
/// (verification_models.dart), renamed here so it doesn't collide with the GRDB storage record of
/// the same Dart name.
public struct Verification: Sendable, Hashable, Identifiable {
    public let id: String
    public let rebuildSetId: String
    public let setItemId: Int
    public let completionPct: Double // parts, 0..1
    public let partsNeeded: Int
    public let partsFound: Int
    public let minifigsNeeded: Int
    public let minifigsFound: Int
    public let flags: VerificationFlags
    public let notes: String?
    public let verifiedAt: Date

    public init(
        id: String, rebuildSetId: String, setItemId: Int, completionPct: Double,
        partsNeeded: Int, partsFound: Int, minifigsNeeded: Int, minifigsFound: Int,
        flags: VerificationFlags, notes: String?, verifiedAt: Date
    ) {
        self.id = id
        self.rebuildSetId = rebuildSetId
        self.setItemId = setItemId
        self.completionPct = completionPct
        self.partsNeeded = partsNeeded
        self.partsFound = partsFound
        self.minifigsNeeded = minifigsNeeded
        self.minifigsFound = minifigsFound
        self.flags = flags
        self.notes = notes
        self.verifiedAt = verifiedAt
    }

    public var partsMissing: Int { max(0, partsNeeded - partsFound) }
    public var partsComplete: Bool { partsNeeded > 0 && partsFound >= partsNeeded }
    public var minifigsComplete: Bool { minifigsFound >= minifigsNeeded }
    public var pctLabel: Int { Int((completionPct * 100).rounded()) }
}
