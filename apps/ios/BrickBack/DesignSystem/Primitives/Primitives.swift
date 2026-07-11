import SwiftUI

/// Wireframe primitive views. Token-driven, no default chrome. Re-skinned to the brand in S7
/// without changing their public API. Ports of `widgets/primitives.dart`.

// MARK: - Pressable

/// Scale-on-press button style (replaces InkWell; no splash).
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
    private var bg: Color { isPrimary ? AppColors.primary : (isGhost ? .clear : AppColors.card) }
    private var fg: Color { isPrimary ? AppColors.onPrimary : AppColors.ink }

    var body: some View {
        Pressable(onTap: loading ? nil : onTap) {
            HStack(spacing: 8) {
                if loading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                        .tint(fg)
                        .frame(width: 16, height: 16)
                } else {
                    if let icon {
                        Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(fg)
                    }
                    Text(label).font(AppText.label).foregroundStyle(fg)
                }
            }
            .frame(maxWidth: expand ? .infinity : nil)
            .padding(.horizontal, AppSpacing.s20)
            .padding(.vertical, AppSpacing.s12)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(isPrimary ? AppColors.primary : AppColors.line, lineWidth: isGhost ? 0 : 1)
            )
        }
    }
}

// MARK: - AppCard

struct AppCard<Content: View>: View {
    var padding: CGFloat = AppSpacing.s16
    var onTap: (() -> Void)?
    @ViewBuilder var content: () -> Content

    var body: some View {
        let card = content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(AppColors.line, lineWidth: 1))
        if let onTap {
            Pressable(onTap: onTap) { card }
        } else {
            card
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
            .font(AppText.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.10))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 1))
    }
}

// MARK: - ScreenHeader

struct ScreenHeader<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    var onBack: (() -> Void)? = nil
    @ViewBuilder var trailing: () -> Trailing

    init(_ title: String, subtitle: String? = nil, onBack: (() -> Void)? = nil, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.subtitle = subtitle
        self.onBack = onBack
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.s8) {
            if let onBack {
                Pressable(onTap: onBack) {
                    Image(systemName: "arrow.left").foregroundStyle(AppColors.ink)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppText.h1).foregroundStyle(AppColors.ink)
                if let subtitle {
                    Text(subtitle).font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                }
            }
            Spacer(minLength: 0)
            trailing()
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.top, AppSpacing.s8)
        .padding(.bottom, AppSpacing.s16)
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
            Image(systemName: icon).font(.system(size: 40)).foregroundStyle(AppColors.muted)
            Spacer().frame(height: AppSpacing.s16)
            Text(title).font(AppText.title).foregroundStyle(AppColors.ink).multilineTextAlignment(.center)
            if let message {
                Spacer().frame(height: AppSpacing.s8)
                Text(message).font(AppText.caption).foregroundStyle(AppColors.inkSoft).multilineTextAlignment(.center)
            }
            let a = action()
            if !(a is EmptyView) {
                Spacer().frame(height: AppSpacing.s20)
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

    var body: some View {
        let v = min(max(value, 0), 1)
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(AppColors.faint)
                Capsule()
                    .fill(v >= 1 ? AppColors.success : AppColors.primary)
                    .frame(width: max(geo.size.width * v, v == 0 ? 0 : 2))
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
    }
}

// MARK: - ProgressRing

struct ProgressRing: View {
    let value: Double // 0..1
    var size: CGFloat = 44
    var stroke: CGFloat = 5

    var body: some View {
        let v = min(max(value, 0), 1)
        ZStack {
            Circle().stroke(AppColors.faint, lineWidth: stroke)
            Circle()
                .trim(from: 0, to: v)
                .stroke(v >= 1 ? AppColors.success : AppColors.primary, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((v * 100).rounded()))%")
                .font(AppText.caption.weight(.bold))
                .foregroundStyle(AppColors.ink)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - SetThumb

/// Square catalog thumbnail. Renders the real image (via AsyncImage) when `imageUrl` is set,
/// falling back to a wireframe placeholder box on nil or load failure.
/// S2: swap AsyncImage → NukeUI `LazyImage` for disk caching.
struct SetThumb: View {
    var imageUrl: String? = nil
    var size: CGFloat = 56
    var label: String? = nil
    var radius: CGFloat = AppRadius.md

    private var placeholder: some View {
        ZStack {
            AppColors.faint
            Text(label ?? "[img]").font(AppText.caption).foregroundStyle(AppColors.muted)
        }
        .frame(width: size, height: size)
    }

    var body: some View {
        Group {
            if let imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit().background(AppColors.card)
                    case .failure:
                        placeholder
                    case .empty:
                        ZStack { AppColors.card; ProgressView().controlSize(.small) }
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

// MARK: - SearchField

struct SearchField: View {
    var hint: String = "Search…"
    @Binding var text: String
    var autofocus: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.system(size: 18)).foregroundStyle(AppColors.muted)
            TextField(hint, text: $text)
                .font(AppText.body)
                .foregroundStyle(AppColors.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .tint(AppColors.ink)
        }
        .padding(.horizontal, AppSpacing.s12)
        .padding(.vertical, AppSpacing.s12)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.line, lineWidth: 1))
    }
}
