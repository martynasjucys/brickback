import 'dart:convert';

/// The certificate flags for an Inventory Verification — the manual checks a
/// builder ticks plus the two derived from the counts. Persisted as the JSON
/// `flags` blob on a `verifications` row so the report can render them offline.
class VerificationFlags {
  const VerificationFlags({
    this.boxIncluded = false,
    this.instructionsIncluded = false,
    this.stickersApplied = false,
    this.allParts = false,
    this.minifigsIncluded = false,
  });

  final bool boxIncluded; // user-toggled
  final bool instructionsIncluded; // user-toggled
  final bool stickersApplied; // user-toggled
  final bool allParts; // derived: parts 100%
  final bool minifigsIncluded; // derived: minifigs complete (or none)

  VerificationFlags copyWith({
    bool? boxIncluded,
    bool? instructionsIncluded,
    bool? stickersApplied,
    bool? allParts,
    bool? minifigsIncluded,
  }) =>
      VerificationFlags(
        boxIncluded: boxIncluded ?? this.boxIncluded,
        instructionsIncluded: instructionsIncluded ?? this.instructionsIncluded,
        stickersApplied: stickersApplied ?? this.stickersApplied,
        allParts: allParts ?? this.allParts,
        minifigsIncluded: minifigsIncluded ?? this.minifigsIncluded,
      );

  Map<String, dynamic> toJson() => {
        'box': boxIncluded,
        'instructions': instructionsIncluded,
        'stickers': stickersApplied,
        'all_parts': allParts,
        'minifigs': minifigsIncluded,
      };

  String encode() => jsonEncode(toJson());

  factory VerificationFlags.fromJson(Map<String, dynamic> j) => VerificationFlags(
        boxIncluded: j['box'] == true,
        instructionsIncluded: j['instructions'] == true,
        stickersApplied: j['stickers'] == true,
        allParts: j['all_parts'] == true,
        minifigsIncluded: j['minifigs'] == true,
      );

  factory VerificationFlags.decode(String raw) {
    try {
      final j = jsonDecode(raw);
      return j is Map<String, dynamic>
          ? VerificationFlags.fromJson(j)
          : const VerificationFlags();
    } catch (_) {
      return const VerificationFlags();
    }
  }
}

/// A recorded Inventory Verification (one `verifications` row) — the payoff of
/// the review flow. Rendered by the report/certificate. Local-first; mirrored to
/// the cloud in Phase 5.
class VerificationRecord {
  const VerificationRecord({
    required this.id,
    required this.rebuildSetId,
    required this.setItemId,
    required this.completionPct,
    required this.partsNeeded,
    required this.partsFound,
    required this.minifigsNeeded,
    required this.minifigsFound,
    required this.flags,
    required this.notes,
    required this.verifiedAt,
  });

  final String id;
  final String rebuildSetId;
  final int setItemId;
  final double completionPct; // parts, 0..1
  final int partsNeeded;
  final int partsFound;
  final int minifigsNeeded;
  final int minifigsFound;
  final VerificationFlags flags;
  final String? notes;
  final DateTime verifiedAt;

  int get partsMissing => (partsNeeded - partsFound) > 0 ? partsNeeded - partsFound : 0;
  bool get partsComplete => partsNeeded > 0 && partsFound >= partsNeeded;
  bool get minifigsComplete => minifigsFound >= minifigsNeeded;
  int get pctLabel => (completionPct * 100).round();
}
