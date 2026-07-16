import SwiftUI
import NukeUI

/// Branded primitive views (S7). Token-driven, no default chrome. The public API is unchanged
/// from the S1 wireframe versions — this pass swaps their internals for the LEGO-toy identity:
/// every interactive surface is a **brick plate** (`BrickSurface`) that sits raised on a darker
/// bottom lip and clicks down when pressed.

// MARK: - BrickSurface (the signature)

/// A raised "brick plate": a rounded, continuous-corner face sitting `depth` points above a
/// darker `edge` lip — the app's core surface treatment. When `pressed`, the face travels down
/// onto its lip (the satisfying "click into place"), while the overall height stays constant so
/// layout never shifts. Drive `pressed` from a `ButtonStyle` for tappable surfaces.
struct BrickSurface<Content: View>: View {
    var fill: Color
    var edge: Color
    var radius: CGFloat = AppRadius.lg
    var depth: CGFloat = AppDepth.brick
    var pressed: Bool = false
    var stroke: Color? = nil // optional hairline around the face (defines white plates on cream)
    @ViewBuilder var content: () -> Content

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: radius, style: .continuous) }

    var body: some View {
        content()
            .background(shape.fill(fill))
            .overlay { if let stroke { shape.strokeBorder(stroke, lineWidth: 1).offset(y: pressed ? depth : 0) } }
            .offset(y: pressed ? depth : 0)
            .padding(.bottom, depth)
            .background(shape.fill(edge)) // the lip: full height, stays put
    }
}

// MARK: - Pressable

/// Scale-on-press button style (kept for content that isn't a brick — thumbnails, icon taps).
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.easeOut(duration: 0.09), value: configuration.isPressed)
    }
}

/// Tappable wrapper that scales on press. No-op (plain content) when `onTap` is nil.
struct Pressable<Content: View>: View {
    var onTap: (() -> Void)?
    var scale: CGFloat = 0.97
    @ViewBuilder var content: () -> Content

    var body: some View {
        if let onTap {
            Button(action: onTap, label: content)
                .buttonStyle(PressableStyle(scale: scale))
        } else {
            content()
        }
    }
}

// MARK: - BrickButtonStyle

/// Presents a button's label on a `BrickSurface` that clicks down when pressed. `ghost` skips the
/// plate and just dims. Springy so the press reads as physical.
struct BrickButtonStyle: ButtonStyle {
    var fill: Color
    var edge: Color
    var radius: CGFloat = AppRadius.md
    var depth: CGFloat = AppDepth.tile
    var stroke: Color? = nil
    var ghost: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        Group {
            if ghost {
                configuration.label.opacity(configuration.isPressed ? 0.55 : 1)
            } else {
                BrickSurface(fill: fill, edge: edge, radius: radius, depth: depth,
                             pressed: configuration.isPressed, stroke: stroke) {
                    configuration.label
                }
            }
        }
        .animation(.spring(response: 0.16, dampingFraction: 0.62), value: configuration.isPressed)
    }
}

// MARK: - BrickIconButton

/// Square brick-plate icon button — the app's signature raised plate (the same treatment as the
/// Home filter button: a `card` face on a darker `cardEdge` lip with a hairline `line` stroke that
/// clicks down when pressed). This is the round-plate replacement so every icon tap — back, the
/// counting step controls, the rebuild action cluster — reads as the same physical brick.
struct BrickIconButton: View {
    let icon: String
    var size: CGFloat = 44                 // square face (the app-wide icon-button size); lip adds `depth` below
    var iconSize: CGFloat = 18
    var iconWeight: Font.Weight = .semibold
    var tint: Color = AppColors.ink
    var fill: Color = AppColors.card
    var edge: Color = AppColors.cardEdge
    var stroke: Color? = AppColors.line
    var enabled: Bool = true
    var symbolReplace: Bool = false        // animate icon swaps (e.g. ellipsis ↔ xmark)
    var accessibilityLabel: String? = nil
    let onTap: () -> Void

    var body: some View {
        let button = Button(action: { if enabled { onTap() } }) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: iconWeight))
                .contentTransition(symbolReplace ? .symbolEffect(.replace) : .identity)
                .foregroundStyle(enabled ? tint : AppColors.faint)
                .frame(width: size, height: size)
        }
        .buttonStyle(BrickButtonStyle(fill: fill, edge: edge, radius: AppRadius.lg, stroke: stroke))
        .disabled(!enabled)

        if let accessibilityLabel {
            button.accessibilityLabel(accessibilityLabel)
        } else {
            button
        }
    }
}

// MARK: - BrickBackWordmark

/// The app wordmark — chunky rounded white lettering (only the two B's capitalised), sized to
/// sit on the brand-blue header.
struct BrickBackWordmark: View {
    var size: CGFloat = 30

    var body: some View {
        Text("BrickBack")
            .font(.system(size: size, weight: .black, design: .rounded))
            .tracking(0.5)
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.6) // hold one line on the header at large Dynamic Type
            .shadow(color: AppColors.brandEdge.opacity(0.6), radius: 0, y: 1.5) // subtle brick emboss
            .accessibilityLabel("BrickBack")
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - AppButton

enum AppButtonVariant { case primary, secondary, ghost }

struct AppButton: View {
    let label: String
    var variant: AppButtonVariant = .primary
    var icon: String? = nil // SF Symbol
    var loading: Bool = false
    var expand: Bool = false
    var onTap: (() -> Void)?

    init(_ label: String, variant: AppButtonVariant = .primary, icon: String? = nil, loading: Bool = false, expand: Bool = false, onTap: (() -> Void)? = nil) {
        self.label = label
        self.variant = variant
        self.icon = icon
        self.loading = loading
        self.expand = expand
        self.onTap = onTap
    }

    private var isPrimary: Bool { variant == .primary }
    private var isGhost: Bool { variant == .ghost }
    private var bg: Color { isPrimary ? AppColors.primary : AppColors.card }
    private var edge: Color { isPrimary ? AppColors.primaryEdge : AppColors.cardEdge }
    private var stroke: Color? { (isPrimary || isGhost) ? nil : AppColors.line }
    private var fg: Color { isPrimary ? AppColors.onPrimary : AppColors.ink }

    var body: some View {
        Button(action: { if !loading { onTap?() } }) {
            HStack(spacing: 8) {
                if loading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                        .tint(fg)
                        .frame(width: 16, height: 16)
                } else {
                    if let icon {
                        Image(systemName: icon).font(.system(size: 18, weight: .bold)).foregroundStyle(fg)
                    }
                    Text(label).font(AppText.label).foregroundStyle(fg)
                }
            }
            .frame(maxWidth: expand ? .infinity : nil)
            .padding(.horizontal, AppSpacing.s20)
            .padding(.vertical, AppSpacing.s12)
        }
        .buttonStyle(BrickButtonStyle(fill: bg, edge: edge, radius: AppRadius.md, stroke: stroke, ghost: isGhost))
        .disabled(loading)
    }
}

// MARK: - AppCard

struct AppCard<Content: View>: View {
    var padding: CGFloat = AppSpacing.s16
    var onTap: (() -> Void)?
    @ViewBuilder var content: () -> Content

    private var body_: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        if let onTap {
            Button(action: onTap) { body_ }
                .buttonStyle(BrickButtonStyle(fill: AppColors.card, edge: AppColors.cardEdge,
                                              radius: AppRadius.lg, depth: AppDepth.brick, stroke: AppColors.line))
        } else {
            BrickSurface(fill: AppColors.card, edge: AppColors.cardEdge, radius: AppRadius.lg,
                         depth: AppDepth.brick, stroke: AppColors.line) { body_ }
        }
    }
}

// MARK: - AppBadge

struct AppBadge: View {
    let text: String
    var color: Color = AppColors.inkSoft

    init(_ text: String, color: Color = AppColors.inkSoft) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.30), lineWidth: 1))
    }
}

// MARK: - WrapLayout

/// A minimal flow layout (CSS flex-wrap): lays subviews left→right, wrapping to a new line when
/// the next one won't fit. Shared by the Home theme pills and the set-detail metadata chips.
struct WrapLayout: Layout {
    var spacing: CGFloat = AppSpacing.s8
    var lineSpacing: CGFloat = AppSpacing.s8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0, widest: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                widest = max(widest, x - spacing)
                x = 0; y += lineHeight + lineSpacing; lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        widest = max(widest, x - spacing)
        let width = maxWidth.isFinite ? maxWidth : max(widest, 0)
        return CGSize(width: width, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > bounds.width {
                x = 0; y += lineHeight + lineSpacing; lineHeight = 0
            }
            sub.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - BrandHeader

/// A raised "brick plate" header field — a gradient face over a darker bottom lip that bleeds into
/// the status bar and curves off at the bottom, matching the Home tab's blue wordmark panel and the
/// counting screen's green plate. The tab roots pass their own hue (Party = indigo, Profile =
/// orange) and lay arbitrary content over it. Only the plate bleeds up behind the status bar; the
/// content stays within the safe area.
struct BrandHeader<Content: View>: View {
    let face: Color
    let deep: Color
    let edge: Color
    @ViewBuilder var content: () -> Content

    init(face: Color, deep: Color, edge: Color, @ViewBuilder content: @escaping () -> Content) {
        self.face = face
        self.deep = deep
        self.edge = edge
        self.content = content
    }

    var body: some View {
        content()
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.s8)
            .padding(.bottom, AppSpacing.s20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(field)
    }

    private var field: some View {
        let shape = UnevenRoundedRectangle(bottomLeadingRadius: AppRadius.xl,
                                           bottomTrailingRadius: AppRadius.xl, style: .continuous)
        return ZStack(alignment: .top) {
            shape.fill(edge)
            LinearGradient(colors: [face, deep], startPoint: .top, endPoint: .bottom)
                .clipShape(shape)
                .padding(.bottom, AppDepth.brick + 1)
        }
        .ignoresSafeArea(edges: .top)
        .shadow(color: AppColors.shadow.opacity(0.14), radius: 10, y: 4)
    }
}

// MARK: - EmptyState

struct EmptyState<Action: View>: View {
    let title: String
    var message: String? = nil
    var icon: String = "tray"
    @ViewBuilder var action: () -> Action

    init(title: String, message: String? = nil, icon: String = "tray", @ViewBuilder action: @escaping () -> Action = { EmptyView() }) {
        self.title = title
        self.message = message
        self.icon = icon
        self.action = action
    }

    var body: some View {
        VStack(spacing: 0) {
            // Icon on a soft brand-yellow round plate — the empty state's one spot of colour.
            Image(systemName: icon)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AppColors.brandDeep)
                .frame(width: 84, height: 84)
                .background(Circle().fill(AppColors.brand.opacity(0.18)))
            Spacer().frame(height: AppSpacing.s20)
            Text(title).font(AppText.h2).foregroundStyle(AppColors.ink).multilineTextAlignment(.center)
            if let message {
                Spacer().frame(height: AppSpacing.s8)
                Text(message).font(AppText.body).foregroundStyle(AppColors.inkSoft).multilineTextAlignment(.center)
            }
            let a = action()
            if !(a is EmptyView) {
                Spacer().frame(height: AppSpacing.s24)
                a
            }
        }
        .padding(AppSpacing.s32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - AppProgressBar

struct AppProgressBar: View {
    let value: Double // 0..1
    var height: CGFloat = 8
    /// The unfilled track. Defaults to the warm skeleton fill (for cream surfaces).
    var track: Color = AppColors.faint
    /// The filled portion. `nil` auto-picks green when complete, else blue-in-motion. Override with
    /// a fixed colour (e.g. white) on a coloured field where those would vanish.
    var tint: Color? = nil

    var body: some View {
        let v = min(max(value, 0), 1)
        let fill = tint ?? (v >= 1 ? AppColors.success : AppColors.info)
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(fill)
                    .frame(width: max(geo.size.width * v, v == 0 ? 0 : height))
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
        // Sweep the fill as the count changes (instant under Reduce Motion).
        .brickAnimation(Motion.progress, value: v)
    }
}

// MARK: - ProgressRing

struct ProgressRing: View {
    let value: Double // 0..1
    var size: CGFloat = 44
    var stroke: CGFloat = 5
    /// The unfilled track. Defaults to the warm skeleton fill (for cream surfaces).
    var track: Color = AppColors.faint
    /// The filled arc. `nil` auto-picks green when complete, else blue-in-motion. Override with a
    /// fixed colour (e.g. white) when the ring sits on a coloured field where those would vanish.
    var tint: Color? = nil
    /// The centre percentage label.
    var textColor: Color = AppColors.ink

    var body: some View {
        let v = min(max(value, 0), 1)
        let arc = tint ?? (v >= 1 ? AppColors.success : AppColors.info)
        ZStack {
            Circle().stroke(track, lineWidth: stroke)
            Circle()
                .trim(from: 0, to: v)
                .stroke(arc, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((v * 100).rounded()))%")
                .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                .foregroundStyle(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5) // the ring is a fixed-size graphic — shrink to fit
                .contentTransition(.numericText()) // roll the percentage as the arc sweeps
        }
        .frame(width: size, height: size)
        // Sweep the arc + roll the label as progress changes (instant under Reduce Motion).
        .brickAnimation(Motion.progress, value: v)
        // VoiceOver reads the ring as "Progress, 50%" rather than a bare "50%".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L.a11yProgress)
        .accessibilityValue("\(Int((v * 100).rounded()))%")
    }
}

// MARK: - SetThumb

/// Square catalog thumbnail. Renders the real image via NukeUI's `LazyImage` (memory + disk
/// cached) when `imageUrl` is set, falling back to a wireframe placeholder box on nil or load
/// failure. Same public API as the S1 `AsyncImage` version.
struct SetThumb: View {
    var imageUrl: String? = nil
    var size: CGFloat = 56
    var label: String? = nil
    var radius: CGFloat = AppRadius.md

    private var placeholder: some View {
        ZStack {
            AppColors.faint
            Image(systemName: "cube.box")
                .font(.system(size: size * 0.34))
                .foregroundStyle(AppColors.muted)
        }
        .frame(width: size, height: size)
    }

    var body: some View {
        Group {
            if let imageUrl, let url = URL(string: imageUrl) {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image.resizable().scaledToFit().background(AppColors.card)
                    } else if state.error != nil {
                        placeholder
                    } else {
                        ZStack { AppColors.card; ProgressView().controlSize(.small) }
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(AppColors.line, lineWidth: 1))
        // A decorative thumbnail — every row/card that uses it carries the name as text alongside,
        // so hiding it from VoiceOver removes "image" noise without losing information.
        .accessibilityHidden(true)
    }
}

// MARK: - SearchField

struct SearchField: View {
    var hint: String = "Search…"
    @Binding var text: String
    var autofocus: Bool = false
    @FocusState private var focused: Bool

    var body: some View {
        BrickSurface(fill: AppColors.card, edge: AppColors.cardEdge, radius: AppRadius.md,
                     depth: AppDepth.tile, stroke: AppColors.line) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 18, weight: .semibold)).foregroundStyle(AppColors.muted)
                TextField(hint, text: $text)
                    .font(AppText.body)
                    .foregroundStyle(AppColors.ink)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .tint(AppColors.primary)
                    .focused($focused)
                if !text.isEmpty {
                    Pressable(onTap: { text = "" }) {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 16)).foregroundStyle(AppColors.muted)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.s12)
            .padding(.vertical, AppSpacing.s12)
        }
        .onAppear {
            // Raise the keyboard on first appear when requested (the Dart `autofocus: true`).
            guard autofocus else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(350))
                focused = true
            }
        }
    }
}
