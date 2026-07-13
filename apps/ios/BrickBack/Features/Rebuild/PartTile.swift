import SwiftUI
import NukeUI
import BrickBackKit

/// Square part tile: image-forward, colour-coded by state (neutral → amber once started →
/// green when complete). Tap adds the step; long-press opens details. Port of `_PartTile`.
struct PartTile: View {
    let part: ExpandedPart
    let have: Int
    var onTap: () -> Void
    var onLongPress: (() -> Void)? = nil

    /// Set by the long-press so the tap that follows on finger-up (a `Button` still fires on
    /// release even after a long-press) doesn't also increment the count.
    @State private var longPressed = false

    private var complete: Bool { have >= part.neededQty }
    private var started: Bool { have > 0 && !complete }
    private var bg: Color {
        complete ? AppColors.success.opacity(0.14) : (started ? AppColors.warning.opacity(0.16) : AppColors.card)
    }
    private var borderColor: Color {
        complete ? AppColors.success : (started ? AppColors.warning : AppColors.line)
    }
    private var countColor: Color {
        complete ? AppColors.success : (started ? AppColors.warning : AppColors.muted)
    }

    var body: some View {
        // A `Button` (not a raw `.gesture`) so the tile cooperates with the enclosing
        // `ScrollView`: the button defers to the scroll pan instead of swallowing finger-down.
        // Press-scale comes from the button style; the long-press is a *simultaneous* gesture so
        // it never blocks scrolling (a drag cancels it) — with `longPressed` guarding the trailing
        // tap so a held press opens detail without also incrementing.
        Button(action: handleTap) {
            VStack(spacing: AppSpacing.s4) {
                // Fixed square image area — `Color.clear` holds the square regardless of the
                // image's own aspect or a loading/error placeholder, so every tile's image
                // region is identical; the part image just fits within it.
                ZStack(alignment: .topTrailing) {
                    Color.clear
                    partImage
                    if complete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppColors.success)
                            .padding(2)
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                // Reserve space for two name lines + one number line so a 1-line name or a part
                // with no number doesn't shrink the tile — every tile ends up the same height.
                Text(part.partName)
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.ink)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Text(part.partNum ?? "")
                    .font(.system(size: 10)).foregroundStyle(AppColors.muted)
                    .lineLimit(1, reservesSpace: true)
                Text("\(have)/\(part.neededQty)").font(AppText.label).foregroundStyle(countColor)
            }
            .padding(AppSpacing.s8)
            .frame(maxWidth: .infinity)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(borderColor, lineWidth: (complete || started) ? 1.5 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .buttonStyle(TilePressStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                guard let onLongPress else { return } // extras tiles pass nil → long-hold still taps
                longPressed = true
                onLongPress()
            }
        )
    }

    private func handleTap() {
        if longPressed { longPressed = false; return } // consumed by the long-press
        onTap()
    }

    @ViewBuilder private var partImage: some View {
        if let urlString = part.imageUrl, let url = URL(string: urlString) {
            LazyImage(url: url) { state in
                if let image = state.image {
                    image.resizable().scaledToFit()
                } else if state.error != nil {
                    Image(systemName: "photo").foregroundStyle(AppColors.faint)
                } else {
                    Color.clear
                }
            }
        } else {
            Image(systemName: "photo").foregroundStyle(AppColors.faint)
        }
    }
}

/// Scale-on-press for the tile. Mirrors `PressableStyle` (no splash/tint) but with the tile's
/// slightly deeper 0.93 press scale, and — crucially — leaves the button free to defer to the
/// enclosing `ScrollView`'s pan so the grid still scrolls.
private struct TilePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.easeOut(duration: 0.09), value: configuration.isPressed)
    }
}
