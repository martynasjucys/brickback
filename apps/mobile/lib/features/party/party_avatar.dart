import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import 'party_models.dart';

/// A stable seeded colour per member (wireframe palette — recoloured in Phase 9).
const _palette = [
  AppColors.info,
  AppColors.success,
  AppColors.warning,
  AppColors.danger,
  Color(0xFF6D28D9),
  Color(0xFF0E7490),
];

class PartyAvatar extends StatelessWidget {
  const PartyAvatar({super.key, required this.member, this.size = 36});
  final PartyMember member;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final seed = member.displayName ?? member.userId;
    final initial = (member.displayName?.trim().isNotEmpty ?? false)
        ? member.displayName!.trim()[0].toUpperCase()
        : '?';
    final color = _palette[seed.hashCode.abs() % _palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        // A host is ringed in ink; members in the canvas colour so they read flat.
        border: Border.all(
          color: member.isHost ? c.ink : c.card,
          width: 2,
        ),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: c.onPrimary,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
          height: 1.0,
        ),
      ),
    );
  }
}

/// Overlapping avatar row with a `+N` overflow chip.
class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.members, this.max = 5, this.size = 36});
  final List<PartyMember> members;
  final int max;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final shown = members.take(max).toList();
    final overflow = members.length - shown.length;
    final overlap = size * 0.35;
    return SizedBox(
      height: size,
      width: shown.isEmpty
          ? 0
          : size + (shown.length - 1) * (size - overlap) + (overflow > 0 ? size - overlap : 0),
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(left: i * (size - overlap), child: PartyAvatar(member: shown[i], size: size)),
          if (overflow > 0)
            Positioned(
              left: shown.length * (size - overlap),
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.faint,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.card, width: 2),
                ),
                child: Text('+$overflow',
                    style: TextStyle(
                        color: c.inkSoft,
                        fontWeight: FontWeight.w700,
                        fontSize: size * 0.34)),
              ),
            ),
        ],
      ),
    );
  }
}
