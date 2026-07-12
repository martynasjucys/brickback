import SwiftUI
import BrickBackKit

/// A stable seeded colour per member (wireframe palette — recoloured in S7). Ports
/// `party_avatar.dart`. Uses a deterministic string hash so a member keeps the same colour across
/// launches (Swift's `hashValue` is per-run randomized, so it can't seed this).
private let partyPalette: [Color] = [
    AppColors.info,
    AppColors.success,
    AppColors.warning,
    AppColors.danger,
    Color(hex: 0x6D28D9),
    Color(hex: 0x0E7490),
]

/// FNV-1a over the UTF-8 bytes — small, stable, good enough to spread seeds across the palette.
private func stableHash(_ s: String) -> Int {
    var h: UInt64 = 1469598103934665603
    for byte in s.utf8 {
        h ^= UInt64(byte)
        h = h &* 1099511628211
    }
    return Int(h % UInt64(Int.max))
}

struct PartyAvatar: View {
    let member: PartyMember
    var size: CGFloat = 36

    private var seed: String { member.displayName ?? member.userId }
    private var initial: String {
        let trimmed = member.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "?" : String(trimmed.prefix(1)).uppercased()
    }
    private var color: Color { partyPalette[stableHash(seed) % partyPalette.count] }

    var body: some View {
        Text(initial)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundStyle(AppColors.onPrimary)
            .frame(width: size, height: size)
            .background(color)
            .clipShape(Circle())
            // A host is ringed in ink; members in the card colour so they read flat.
            .overlay(Circle().stroke(member.isHost ? AppColors.ink : AppColors.card, lineWidth: 2))
    }
}

/// Overlapping avatar row with a `+N` overflow chip. Port of `AvatarStack`.
struct AvatarStack: View {
    let members: [PartyMember]
    var max: Int = 5
    var size: CGFloat = 36

    var body: some View {
        let shown = Array(members.prefix(max))
        let overflow = members.count - shown.count
        let overlap = size * 0.35
        let step = size - overlap
        let width = shown.isEmpty
            ? 0
            : size + CGFloat(shown.count - 1) * step + (overflow > 0 ? step : 0)

        ZStack(alignment: .leading) {
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, member in
                PartyAvatar(member: member, size: size)
                    .offset(x: CGFloat(index) * step)
            }
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundStyle(AppColors.inkSoft)
                    .frame(width: size, height: size)
                    .background(AppColors.faint)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppColors.card, lineWidth: 2))
                    .offset(x: CGFloat(shown.count) * step)
            }
        }
        .frame(width: width, height: size, alignment: .leading)
    }
}
