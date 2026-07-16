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
    @Environment(\.horizontalSizeClass) private var widthClass
    let rebuildSetId: String

    @State private var vm: RebuildViewModel?
    @AppStorage("rebuild_grouping") private var groupingRaw = PartGrouping.color.rawValue
    @AppStorage("rebuild_show_extras") private var showExtras = false

    @State private var detailPart: ExpandedPart?
    @State private var showSearch = false
    @State private var showSettings = false
    @State private var startingParty = false
    @State private var partyError: String?

    private var grouping: PartGrouping { PartGrouping(rawValue: groupingRaw) ?? .color }

    /// Tile-width bounds for the counting grid, widened on iPad so the tiles grow into fewer, more
    /// tappable columns instead of the grid packing ~7 phone-sized ones (see `AppLayout.tileMin`).
    private var tileMin: CGFloat { widthClass == .regular ? AppLayout.tileMinRegular : AppLayout.tileMin }
    private var tileMax: CGFloat { widthClass == .regular ? AppLayout.tileMaxRegular : AppLayout.tileMax }

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
                        EmptyState(title: L.couldntLoad, message: message, icon: "exclamationmark.triangle")
                    }
                case .ready:
                    if let inv = vm.inv { content(vm: vm, inv: inv) }
                }
            } else {
                ProgressView().tint(AppColors.primary)
            }
        }
        .overlay { if startingParty { partyStartingOverlay } }
        // The green nav bar hosts the back button, the set title + count, and the ••• actions menu.
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let vm, let inv = vm.inv { navTitle(vm: vm, inv: inv) }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if let vm, vm.inv != nil { actionsMenu(vm: vm) }
            }
        }
        .brandBar(AppColors.build)
        .task {
            if vm == nil {
                vm = RebuildViewModel(rebuildSetId: rebuildSetId, repo: env.services.rebuild, onNudge: { env.sync.nudge() })
            }
            await vm?.load()
            // S9: make sure this set's images are cached for offline (no-op once complete). Covers
            // cloud-imported sets and any add whose prefetch didn't finish.
            Task { await env.services.offlineImages.ensureCached(rebuildSetId) }
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
        .alert(L.couldntStartParty, isPresented: Binding(
            get: { partyError != nil },
            set: { if !$0 { partyError = nil } }
        )) {
            Button(L.ok, role: .cancel) {}
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
                EmptyState(title: L.countNoInventoryTitle, message: L.countNoInventoryMessage, icon: "info.circle")
            } else if visible.isEmpty && !extrasVisible {
                EmptyState(title: L.countAllSortedTitle, message: L.everyPartAccountedFor, icon: "party.popper")
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

    // MARK: - Header (green nav bar + a progress strip pinned below it)

    /// The set title + part count, shown as the native nav bar's centred title — riding between the
    /// back button and the ••• menu. White on the green bar (see `brandBar`).
    private func navTitle(vm: RebuildViewModel, inv: RebuildInventory) -> some View {
        VStack(spacing: 1) {
            Text(inv.summary.name).font(AppText.title).foregroundStyle(.white).lineLimit(1)
            Text(L.countHaveOfPartsTypes(have: vm.haveTotal, total: inv.summary.totalParts, types: inv.parts.count))
                .font(AppText.caption).foregroundStyle(.white.opacity(0.85)).lineLimit(1)
        }
    }

    /// The progress strip: a slim bar pinned under the nav bar, above the scrolling grid, so
    /// progress stays visible while counting. It sat on the green plate until S10 step 4 — now it
    /// sits on the canvas below a green *bar*, with a hairline to divide the two.
    private func header(vm: RebuildViewModel, inv: RebuildInventory?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let inv { progressBar(vm: vm, inv: inv) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screen)
        .padding(.top, AppSpacing.s12)
        .padding(.bottom, AppSpacing.s12)
        .background(AppColors.canvas)
        .overlay(alignment: .bottom) { Rectangle().fill(AppColors.line).frame(height: 1) }
    }

    /// A slim progress bar. It was white-on-green for the plate; on the canvas white would be an
    /// invisible bar on an invisible track, so it takes the build green and the standard track.
    private func progressBar(vm: RebuildViewModel, inv: RebuildInventory) -> some View {
        let total = inv.summary.totalParts
        let value = total == 0 ? 0 : Double(vm.haveTotal) / Double(total)
        return AppProgressBar(value: value, height: 8, tint: AppColors.build)
    }

    /// The trailing ••• actions, as a native `Menu` — the system's own expand/collapse dropdown:
    /// review & verify, start party, search parts, view settings. On iOS 26 the toolbar renders it
    /// as a glass circular button; on older versions it falls back to a plain glyph — same menu.
    private func actionsMenu(vm: RebuildViewModel) -> some View {
        Menu {
            Button {
                Task { await vm.flush(); env.homeRouter.push(.review(rebuildSetId)) }
            } label: { Label(L.menuReview, systemImage: "flag") }

            Button { onParty(vm: vm) } label: { Label(L.menuStartParty, systemImage: "person.2") }

            Button { showSearch = true } label: { Label(L.menuSearchParts, systemImage: "magnifyingglass") }

            Button {
                if let itemId = vm.inv?.summary.setItemId { env.homeRouter.push(.setDetail(itemId)) }
            } label: { Label(L.menuSetDetails, systemImage: "info.circle") }

            Button { showSettings = true } label: { Label(L.viewSettings, systemImage: "slider.horizontal.3") }
        } label: {
            Image(systemName: "ellipsis")
        }
        .accessibilityLabel(L.moreActions)
    }

    /// A lightweight blocking spinner while a party is being created (the async flush → push →
    /// create round-trip). The old inline cluster spinner has no home now the actions are a menu.
    private var partyStartingOverlay: some View {
        ZStack {
            Color.black.opacity(0.12).ignoresSafeArea()
            ProgressView().tint(AppColors.primary)
                .padding(AppSpacing.s24)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        }
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
                let name = vm.inv?.summary.name ?? L.sortParty
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
                Text(L.sectionTitle(section)).font(AppText.label).foregroundStyle(AppColors.inkSoft).lineLimit(1)
                Spacer(minLength: AppSpacing.s8)
                Text("\(haveN)/\(section.neededTotal)")
                    .font(AppText.caption)
                    .foregroundStyle(haveN >= section.neededTotal ? AppColors.success : AppColors.muted)
            }
            .padding(.top, AppSpacing.s16)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: tileMin, maximum: tileMax), spacing: 12)], spacing: 12) {
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

/// Colour-then-name ordering for the search sheet (mirrors the domain comparator, which is
/// internal to BrickBackKit).
func byColorThenNameC(_ a: ExpandedPart, _ b: ExpandedPart) -> Bool {
    let ca = a.colorName ?? "~", cb = b.colorName ?? "~"
    if ca != cb { return ca < cb }
    return a.partName < b.partName
}
