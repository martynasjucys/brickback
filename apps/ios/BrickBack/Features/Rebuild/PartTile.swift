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

    @GestureState private var pressing = false

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
        VStack(spacing: AppSpacing.s4) {
            ZStack(alignment: .topTrailing) {
                partImage
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                if complete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.success)
                        .padding(2)
                }
            }
            Text(part.partName)
                .font(.system(size: 11))
                .foregroundStyle(AppColors.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            if let num = part.partNum {
                Text(num).font(.system(size: 10)).foregroundStyle(AppColors.muted).lineLimit(1)
            }
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
        .scaleEffect(pressing ? 0.93 : 1)
        .animation(.easeOut(duration: 0.09), value: pressing)
        // Long-press wins if held ≥0.4 s (opens detail); otherwise it fails and the tap fires
        // (adds a step). `.exclusively` makes the two unambiguous — a plain onTap+onLongPress
        // pair lets a held press leak through as a tap.
        .gesture(
            LongPressGesture(minimumDuration: 0.4)
                .updating($pressing) { current, state, _ in state = current }
                .onEnded { _ in onLongPress?() }
                .exclusively(before: TapGesture().onEnded { onTap() })
        )
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
