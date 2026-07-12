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
            ViewSettingsSheet(hasExtras: vm?.inv?.hasExtras ?? false)
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
            progressBlock(vm: vm, inv: inv)
            Divider().overlay(AppColors.line)
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

    // MARK: - Header (back + circle actions)

    private func header(vm: RebuildViewModel, inv: RebuildInventory?) -> some View {
        HStack(spacing: AppSpacing.s8) {
            Pressable(onTap: { Task { await vm.flush(); env.homeRouter.pop() } }) {
                Image(systemName: "arrow.left").foregroundStyle(AppColors.ink).padding(AppSpacing.s4)
            }
            Spacer()
            CircleIconButton(icon: "flag") { Task { await vm.flush(); env.homeRouter.push(.review(rebuildSetId)) } }
            if startingParty {
                ProgressView().tint(AppColors.primary).frame(width: 40, height: 40)
            } else {
                CircleIconButton(icon: "person.2") { onParty(vm: vm) }
            }
            CircleIconButton(icon: "magnifyingglass") { showSearch = true }
            CircleIconButton(icon: "slider.horizontal.3") { showSettings = true }
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.vertical, AppSpacing.s8)
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

    private func progressBlock(vm: RebuildViewModel, inv: RebuildInventory) -> some View {
        let total = inv.summary.totalParts
        let value = total == 0 ? 0 : Double(vm.haveTotal) / Double(total)
        return HStack(spacing: AppSpacing.s16) {
            ProgressRing(value: value, size: 72, stroke: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(inv.summary.name).font(AppText.h1).foregroundStyle(AppColors.ink).lineLimit(2)
                Text("\(vm.haveTotal) of \(total) parts · \(inv.parts.count) types")
                    .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                Spacer().frame(height: AppSpacing.s4)
                Pressable(onTap: { vm.remainingOnly.toggle() }) {
                    HStack(spacing: AppSpacing.s4) {
                        Image(systemName: vm.remainingOnly ? "checkmark.square.fill" : "square")
                            .font(.system(size: 18))
                            .foregroundStyle(vm.remainingOnly ? AppColors.primary : AppColors.muted)
                        Text("Remaining only").font(AppText.label).foregroundStyle(AppColors.muted)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.bottom, AppSpacing.s12)
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
