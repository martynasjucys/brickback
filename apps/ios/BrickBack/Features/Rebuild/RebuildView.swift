import SwiftUI
import BrickBackKit

/// The core loop — interactive tap-to-count inventory (`.rebuild(id)`). Fully offline &
/// local-first: reads the snapshotted checklist from GRDB, the session `have` map is the live
/// source of truth, and writes are debounced (flushed on leave/background). Port of
/// `RebuildScreen`. The flag button flushes then opens the S4 review; the party (S6) action is
/// still stubbed.
struct RebuildView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.scenePhase) private var scenePhase
    let rebuildSetId: String

    @State private var vm: RebuildViewModel?
    @AppStorage("rebuild_grouping") private var groupingRaw = PartGrouping.color.rawValue
    @AppStorage("rebuild_show_extras") private var showExtras = false

    @State private var detailPart: ExpandedPart?
    @State private var showSearch = false
    @State private var showSettings = false
    @State private var startingParty = false
    @State private var partyError: String?
    /// The trailing action cluster: collapsed to a single "more" button by default; tapping it
    /// fans the four screen actions out with a spring.
    @State private var actionsExpanded = false

    private var grouping: PartGrouping { PartGrouping(rawValue: groupingRaw) ?? .color }

    var body: some View {
        ZStack {
            AppColors.canvas.ignoresSafeArea()
            if let vm {
                switch vm.phase {
                case .loading:
                    ProgressView().tint(AppColors.primary)
                case .failed(let message):
                    VStack(spacing: 0) {
                        header(vm: vm, inv: nil)
                        EmptyState(title: "Couldn't load", message: message, icon: "exclamationmark.triangle")
                    }
                case .ready:
                    if let inv = vm.inv { content(vm: vm, inv: inv) }
                }
            } else {
                ProgressView().tint(AppColors.primary)
            }
        }
        .task {
            if vm == nil {
                vm = RebuildViewModel(rebuildSetId: rebuildSetId, repo: env.services.rebuild, onNudge: { env.sync.nudge() })
            }
            await vm?.load()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background, let vm { Task { await vm.flush() } }
        }
        .onDisappear { if let vm { Task { await vm.flush() } } }
        .sheet(item: $detailPart) { part in
            if let vm { PartDetailSheet(part: part, vm: vm) }
        }
        .sheet(isPresented: $showSearch) {
            if let vm, let inv = vm.inv {
                PartSearchSheet(parts: inv.parts.sorted(by: byColorThenNameC), vm: vm, onOpenDetail: { part in
                    // Hand off from search → detail: close search first, then present detail
                    // (two sheets can't stack on the same anchor).
                    showSearch = false
                    Task { try? await Task.sleep(for: .milliseconds(350)); detailPart = part }
                })
            }
        }
        .sheet(isPresented: $showSettings) {
            if let vm {
                ViewSettingsSheet(
                    hasExtras: vm.inv?.hasExtras ?? false,
                    remainingOnly: Binding(get: { vm.remainingOnly }, set: { vm.remainingOnly = $0 })
                )
            }
        }
        .alert("Couldn't start party", isPresented: Binding(
            get: { partyError != nil },
            set: { if !$0 { partyError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(partyError ?? "")
        }
    }

    // MARK: - Content

    private func content(vm: RebuildViewModel, inv: RebuildInventory) -> some View {
        let sections = partSections(inv.parts, grouping: grouping, have: vm.have)
        let visible = sections.filter { $0.visible(vm.have, remainingOnly: vm.remainingOnly) }
        let extrasOn = showExtras && inv.hasExtras
        let extras = extrasOn ? extrasSection(inv.extras) : nil
        let extrasVisible = extras?.visible(vm.extraHave, remainingOnly: vm.remainingOnly) ?? false

        return VStack(spacing: 0) {
            header(vm: vm, inv: inv)
            if inv.parts.isEmpty {
                EmptyState(title: "No inventory data", message: "The catalog has no part list for this set yet.", icon: "info.circle")
            } else if visible.isEmpty && !extrasVisible {
                EmptyState(title: "All sorted!", message: "Every part for this set is accounted for.", icon: "party.popper")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(visible) { section in
                            sectionView(section, vm: vm, have: vm.have, onTap: vm.tap, onLongPress: { detailPart = $0 })
                        }
                        if let extras, extrasVisible {
                            sectionView(extras, vm: vm, have: vm.extraHave, leadingIcon: "sparkles", onTap: vm.tapExtra, onLongPress: nil)
                        }
                        Spacer().frame(height: AppSpacing.s40)
                    }
                }
            }
        }
    }

    // MARK: - Header (branded green field: nav row + progress summary)

    /// The branded green header: the back + expanding-actions nav row, and — once the inventory is
    /// loaded — the set's progress ring, title and part count riding on the same field (so it's
    /// taller than Home's, but keeps the same brick-plate background and border).
    private func header(vm: RebuildViewModel, inv: RebuildInventory?) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.s8) {
                BackButton { Task { await vm.flush(); env.homeRouter.pop() } }
                Spacer(minLength: AppSpacing.s8)
                actionCluster(vm: vm)
            }
            if let inv { progressSummary(vm: vm, inv: inv) }
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.top, AppSpacing.s8)
        .padding(.bottom, AppSpacing.s16)
        .frame(maxWidth: .infinity)
        .background(headerField)
    }

    /// Set title, part count and a slim progress bar — the same bar used elsewhere, styled white so
    /// it (and a completed fill) reads on the green field. Far shorter than the old progress ring.
    private func progressSummary(vm: RebuildViewModel, inv: RebuildInventory) -> some View {
        let total = inv.summary.totalParts
        let value = total == 0 ? 0 : Double(vm.haveTotal) / Double(total)
        return VStack(alignment: .leading, spacing: AppSpacing.s8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(inv.summary.name).font(AppText.h1).foregroundStyle(.white).lineLimit(2)
                Text("\(vm.haveTotal) of \(total) parts · \(inv.parts.count) types")
                    .font(AppText.caption).foregroundStyle(.white.opacity(0.85))
            }
            AppProgressBar(value: value, height: 8, track: .white.opacity(0.28), tint: .white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AppSpacing.s12)
    }

    /// The trailing actions. Collapsed, it's a single "more" button; expanded, the four screen
    /// actions spring out to its left. Tapping most actions collapses the cluster again; the party
    /// action stays open so its in-progress spinner is visible.
    @ViewBuilder
    private func actionCluster(vm: RebuildViewModel) -> some View {
        HStack(spacing: AppSpacing.s8) {
            if actionsExpanded {
                CircleIconButton(icon: "flag") {
                    collapseActions()
                    Task { await vm.flush(); env.homeRouter.push(.review(rebuildSetId)) }
                }
                .transition(actionReveal)

                Group {
                    if startingParty {
                        ProgressView().tint(AppColors.primary).frame(width: 40, height: 40)
                    } else {
                        CircleIconButton(icon: "person.2") { onParty(vm: vm) }
                    }
                }
                .transition(actionReveal)

                CircleIconButton(icon: "magnifyingglass") { collapseActions(); showSearch = true }
                    .transition(actionReveal)
                CircleIconButton(icon: "slider.horizontal.3") { collapseActions(); showSettings = true }
                    .transition(actionReveal)
            }

            Pressable(onTap: {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) { actionsExpanded.toggle() }
            }) {
                Image(systemName: actionsExpanded ? "xmark" : "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(AppColors.ink)
                    .frame(width: 40, height: 40)
                    .background(AppColors.card)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppColors.line, lineWidth: 1))
            }
            .accessibilityLabel(actionsExpanded ? "Close actions" : "More actions")
        }
    }

    /// Each revealed action scales up out of the "more" button (anchored trailing) as it fades in.
    private var actionReveal: AnyTransition {
        .scale(scale: 0.4, anchor: .trailing).combined(with: .opacity)
    }

    private func collapseActions() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) { actionsExpanded = false }
    }

    /// The branded green "brick plate" that backs the header — the counting-screen counterpart to
    /// Home's blue field: a gradient face raised on a darker bottom lip, bleeding into the status
    /// bar and curving off at the bottom.
    private var headerField: some View {
        let shape = UnevenRoundedRectangle(bottomLeadingRadius: AppRadius.xl,
                                           bottomTrailingRadius: AppRadius.xl, style: .continuous)
        return ZStack(alignment: .top) {
            shape.fill(AppColors.buildEdge)
            LinearGradient(colors: [AppColors.build, AppColors.buildDeep], startPoint: .top, endPoint: .bottom)
                .clipShape(shape)
                .padding(.bottom, AppDepth.brick + 1)
        }
        .ignoresSafeArea(edges: .top)
        .shadow(color: AppColors.ink.opacity(0.14), radius: 10, y: 4)
    }

    /// Host a realtime party on this rebuild. Premium + account only (the paywall / sign-in bounce
    /// mirrors the free-cap gate). `create_party` resolves the rebuild server-side, so flush + push
    /// this device's work to the cloud first, then open the party hub. Port of `_onParty`.
    private func onParty(vm: RebuildViewModel) {
        guard !startingParty else { return }
        if !env.isPremium { env.homeRouter.push(.paywall); return }
        if !env.isSignedIn { env.homeRouter.push(.signIn); return }
        startingParty = true
        Task {
            await vm.flush()
            do {
                await env.sync.pushNow()
                let name = vm.inv?.summary.name ?? "Sort party"
                let party = try await env.services.party.createParty(rebuildSetId, name: name)
                startingParty = false
                env.homeRouter.push(.party(party.id))
            } catch {
                startingParty = false
                partyError = "\(error)"
            }
        }
    }

    // MARK: - Section (header + tile grid)

    private func sectionView(
        _ section: PartSection,
        vm: RebuildViewModel,
        have: [String: Int],
        leadingIcon: String? = nil,
        onTap: @escaping (ExpandedPart) -> Void,
        onLongPress: ((ExpandedPart) -> Void)?
    ) -> some View {
        let tiles = section.parts.filter { !(vm.remainingOnly && (have[$0.key] ?? 0) >= $0.neededQty) }
        let haveN = section.haveIn(have)
        return VStack(alignment: .leading, spacing: AppSpacing.s8) {
            HStack(spacing: AppSpacing.s8) {
                if let rgb = section.colorRgb {
                    Circle().fill(swatchColor(rgb)).frame(width: 14, height: 14)
                        .overlay(Circle().stroke(AppColors.line, lineWidth: 1))
                } else if let leadingIcon {
                    Image(systemName: leadingIcon).font(.system(size: 15)).foregroundStyle(AppColors.inkSoft)
                }
                Text(section.label).font(AppText.label).foregroundStyle(AppColors.inkSoft).lineLimit(1)
                Spacer(minLength: AppSpacing.s8)
                Text("\(haveN)/\(section.neededTotal)")
                    .font(AppText.caption)
                    .foregroundStyle(haveN >= section.neededTotal ? AppColors.success : AppColors.muted)
            }
            .padding(.top, AppSpacing.s16)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 176), spacing: 12)], spacing: 12) {
                ForEach(tiles) { p in
                    PartTile(
                        part: p,
                        have: have[p.key] ?? 0,
                        onTap: { onTap(p) },
                        onLongPress: onLongPress.map { cb in { cb(p) } }
                    )
                    .id("\(section.id):\(p.key)")
                }
            }
        }
        .padding(.horizontal, AppSpacing.screen)
    }
}

/// A 40pt circular header action button (matches the Flutter `_CircleButton`).
struct CircleIconButton: View {
    let icon: String
    let onTap: () -> Void
    var body: some View {
        Pressable(onTap: onTap) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(AppColors.ink)
                .frame(width: 40, height: 40)
                .background(AppColors.card)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppColors.line, lineWidth: 1))
        }
    }
}

/// Colour-then-name ordering for the search sheet (mirrors the domain comparator, which is
/// internal to BrickBackKit).
func byColorThenNameC(_ a: ExpandedPart, _ b: ExpandedPart) -> Bool {
    let ca = a.colorName ?? "~", cb = b.colorName ?? "~"
    if ca != cb { return ca < cb }
    return a.partName < b.partName
}
