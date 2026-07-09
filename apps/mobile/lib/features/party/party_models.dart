import '../rebuild/rebuild_models.dart';

/// A realtime party (server row from `party_sessions`). Unlike whatabrick, the
/// row carries `set_item_id` so any member can derive the catalog-side picker
/// on-device (the user project has no catalog, and members can't read the host's
/// owner-scoped `rebuild_sets`).
class Party {
  const Party({
    required this.id,
    required this.name,
    required this.joinCode,
    required this.rebuildSetId,
    required this.setItemId,
    required this.hostUserId,
    required this.status,
  });

  final String id;
  final String name;
  final String joinCode;
  final String? rebuildSetId; // the HOST's rebuild id (owner-scoped; not readable by members)
  final int setItemId; // catalog set id — drives on-device picker + local reconcile
  final String hostUserId;
  final String status; // active | paused | ended

  bool get isActive => status == 'active';

  static Party fromRow(Map<String, dynamic> r) => Party(
        id: r['id'] as String,
        name: r['name'] as String,
        joinCode: r['join_code'] as String,
        rebuildSetId: r['rebuild_set_id'] as String?,
        setItemId: (r['set_item_id'] as num).toInt(),
        hostUserId: r['host_user_id'] as String,
        status: r['status'] as String,
      );
}

class PartyMember {
  const PartyMember({
    required this.id,
    required this.userId,
    required this.role,
    this.displayName,
    required this.joinedAt,
  });

  final String id;
  final String userId;
  final String role;
  final String? displayName;
  final DateTime joinedAt;

  bool get isHost => role == 'host';

  static PartyMember fromRow(Map<String, dynamic> r) => PartyMember(
        id: r['id'] as String,
        userId: r['user_id'] as String,
        role: r['role'] as String,
        displayName: r['display_name'] as String?,
        joinedAt: DateTime.parse(r['joined_at'] as String),
      );
}

/// One logged "found parts" event, for the activity feed. `partName`/`colorName`
/// are denormalized on the row (BrickBack's user project can't join the catalog),
/// so the feed renders without any catalog lookup.
class PartyContribution {
  const PartyContribution({
    required this.id,
    required this.memberId,
    required this.qty,
    required this.partName,
    required this.colorName,
    required this.createdAt,
  });

  final String id;
  final String? memberId;
  final int qty;
  final String partName;
  final String? colorName;
  final DateTime createdAt;

  static PartyContribution fromRow(Map<String, dynamic> r) => PartyContribution(
        id: r['id'] as String,
        memberId: r['member_id'] as String?,
        qty: (r['qty'] as num).toInt(),
        partName: (r['part_name'] as String?)?.trim().isNotEmpty == true
            ? r['part_name'] as String
            : 'part',
        colorName: r['color_name'] as String?,
        createdAt: DateTime.parse(r['created_at'] as String),
      );
}

/// Shared party progress ({total, have}) from the `party_progress` RPC.
class PartyProgress {
  const PartyProgress({required this.total, required this.have});
  final int total;
  final int have;
  double get value => total == 0 ? 0 : (have / total).clamp(0, 1);
}

/// A part the party still needs. Built ON-DEVICE by joining the catalog-derived
/// "needed" line ([ExpandedPart], from the catalog client) with the shared
/// rolled-up `have` (from `party_have_counts`). Replaces whatabrick's server-side
/// `party_parts`, which relied on a catalog that BrickBack's user project lacks.
class PartyPart {
  const PartyPart({required this.needed, required this.have});

  final ExpandedPart needed;
  final int have;

  int get partItemId => needed.partItemId;
  int get colorId => needed.colorId;
  String get key => needed.key; // '$partItemId:$colorId'
  String get name => needed.partName;
  String? get colorName => needed.colorName;
  String? get colorRgb => needed.colorRgb;
  String? get imageUrl => needed.imageUrl;

  int get remaining {
    final r = needed.neededQty - have;
    return r > 0 ? r : 0;
  }

  static PartyPart fromNeeded(ExpandedPart p, Map<String, int> have) =>
      PartyPart(needed: p, have: have[p.key] ?? 0);
}
