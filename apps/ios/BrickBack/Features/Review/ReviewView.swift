import SwiftUI
import BrickBackKit

/// Review & verification (`.review(id)`) — S4's signature payoff. Reads the same local snapshot the
/// counting screen wrote (via `RebuildRepository.detail`) and shows parts completion, the exact
/// missing-parts list (with a BrickLink wanted-list export), separate minifig verification, and a
/// "Mark as verified" action that records a verification and opens the report. All math is local —
/// completion % here is `inv.progress`, so it matches the counting ring exactly. Port of
/// `ReviewScreen`.
struct ReviewView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.openURL) private var openURL
    let rebuildSetId: String

    @State private var vm: ReviewViewModel?
    @State private var showMarkSheet = false
    @State private var shareItems: ShareItems?

    var body: some View {
        ZStack {
            AppColors.canvas.ignoresSafeArea()
            if let vm {
                switch vm.phase {
                case .loading:
                    ProgressView().tint(AppColors.primary)
                case .failed(let message):
                    VStack(spacing: 0) {
                        header(inv: nil)
                        EmptyState(title: L.couldntLoad, message: message, icon: "exclamationmark.triangle")
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
                vm = ReviewViewModel(rebuildSetId: rebuildSetId, repo: env.services.rebuild, onNudge: { env.sync.nudge() })
            }
            await vm?.load()
        }
        .sheet(isPresented: $showMarkSheet) {
            if let vm, let inv = vm.inv {
                MarkVerifiedSheet(
                    pct: Int((inv.progress * 100).rounded()),
                    partsComplete: inv.complete,
                    minifigsComplete: vm.minifigsComplete,
                    hasMinifigs: inv.hasMinifigs
                ) { box, instructions, stickers, notes in
                    showMarkSheet = false
                    Task {
                        if await vm.markVerified(box: box, instructions: instructions, stickers: stickers, notes: notes) {
                            env.homeRouter.push(.report(rebuildSetId))
                        }
                    }
                }
            }
        }
        .sheet(item: $shareItems) { ActivityView(items: $0.urls) }
    }

    // MARK: - Content

    private func content(vm: ReviewViewModel, inv: RebuildInventory) -> some View {
        let missing = inv.missingParts
        let notExportable = missing.filter { !$0.exportable }.count

        return VStack(spacing: 0) {
            header(inv: inv)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    summaryCard(inv)
                    if inv.hasMinifigs { minifigSection(vm: vm, inv: inv) }
                    sectionLabel(L.missingParts, trailing: missing.isEmpty ? nil : typeCount(missing.count))
                    if missing.isEmpty {
                        EmptyState(
                            title: L.reviewNothingMissing,
                            message: L.everyPartAccountedFor,
                            icon: "party.popper"
                        )
                        .frame(minHeight: 180)
                    } else {
                        ForEach(missing, id: \.key) { part in
                            MissingRow(part: part) { openBrickLink(part) }
                        }
                        if notExportable > 0 { notExportableFootnote(notExportable) }
                    }
                    Spacer().frame(height: AppSpacing.s24)
                }
            }
            bottomBar(vm: vm, inv: inv)
        }
    }

    // MARK: - Header

    private func header(inv: RebuildInventory?) -> some View {
        let hasMissing = !(inv?.missingParts.isEmpty ?? true)
        return HStack(spacing: AppSpacing.s8) {
            // The shared brick-plate back control — matches the share button beside it and gives a
            // 44pt target + a "Back" VoiceOver label (the old bare arrow had neither).
            BackButton { env.homeRouter.pop() }
            Spacer()
            if hasMissing, let inv {
                BrickIconButton(icon: "square.and.arrow.up") { shareMissing(inv) }
            }
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.vertical, AppSpacing.s8)
    }

    private func summaryCard(_ inv: RebuildInventory) -> some View {
        AppCard {
            HStack(spacing: AppSpacing.s16) {
                ProgressRing(value: inv.progress, size: 72, stroke: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(inv.summary.name).font(AppText.h2).foregroundStyle(AppColors.ink).lineLimit(2)
                    Text(L.reviewPartsFound(found: inv.partsFound, needed: inv.neededTotal))
                        .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                    Text(inv.complete ? L.allPartsAccountedFor : typesStillMissing(inv.remainingPartTypes))
                        .font(AppText.caption)
                        .foregroundStyle(inv.complete ? AppColors.success : AppColors.warning)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.bottom, AppSpacing.s16)
    }

    private func minifigSection(vm: ReviewViewModel, inv: RebuildInventory) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppSpacing.s8) {
                Text(L.minifiguresSection).font(AppText.label).foregroundStyle(AppColors.inkSoft)
                Text("\(vm.minifigsFound)/\(inv.minifigsNeeded)")
                    .font(AppText.caption)
                    .foregroundStyle(vm.minifigsComplete ? AppColors.success : AppColors.muted)
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.bottom, AppSpacing.s8)
            ForEach(inv.minifigs, id: \.minifigItemId) { m in
                MinifigRow(fig: m, have: vm.figHave[m.minifigItemId] ?? 0) { q in vm.setFig(m, q) }
            }
            Spacer().frame(height: AppSpacing.s20)
        }
    }

    private func sectionLabel(_ title: String, trailing: String?) -> some View {
        HStack(spacing: AppSpacing.s8) {
            Text(title).font(AppText.label).foregroundStyle(AppColors.inkSoft)
            if let trailing {
                Text(trailing).font(AppText.caption).foregroundStyle(AppColors.muted)
            }
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.bottom, AppSpacing.s8)
    }

    private func notExportableFootnote(_ n: Int) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.s8) {
            Image(systemName: "info.circle").font(.system(size: 14)).foregroundStyle(AppColors.muted)
            Text(notExportableText(n)).font(AppText.caption).foregroundStyle(AppColors.muted)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.top, AppSpacing.s12)
    }

    private func bottomBar(vm: ReviewViewModel, inv: RebuildInventory) -> some View {
        VStack(spacing: AppSpacing.s12) {
            if inv.summary.verified {
                AppButton(L.viewReport, variant: .secondary, icon: "rosette", expand: true) {
                    env.homeRouter.push(.report(rebuildSetId))
                }
            }
            AppButton(
                inv.summary.verified ? L.reverify : L.markAsVerified,
                icon: "checkmark.seal", expand: true
            ) { showMarkSheet = true }
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.vertical, AppSpacing.s12)
        .background(
            AppColors.card.overlay(Rectangle().fill(AppColors.line).frame(height: 1), alignment: .top)
        )
    }

    // MARK: - Actions

    private func shareMissing(_ inv: RebuildInventory) {
        guard let xml = vm?.wantedListXml(), let data = xml.data(using: .utf8) else { return }
        let filename = safeFileStem(inv.summary.name) + "-missing.xml"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            shareItems = ShareItems(urls: [url])
        } catch {}
    }

    private func openBrickLink(_ p: MissingPart) {
        if let url = BrickLink.url(blPartId: p.blPartId, blColorId: p.blColorId, partNum: p.partNum) {
            openURL(url)
        }
    }

    // MARK: - Wireframe copy (moves to the String Catalog in S7)

    private func typesStillMissing(_ n: Int) -> String { L.typesStillMissing(n) }
    private func typeCount(_ n: Int) -> String { L.typeCount(n) }
    private func notExportableText(_ n: Int) -> String { L.notExportableText(n) }
}

// MARK: - Missing part row

/// A missing (part, colour) row — tap to open its BrickLink page.
private struct MissingRow: View {
    let part: MissingPart
    let onTap: () -> Void

    private var sub: String {
        [part.colorName ?? L.unknownColor, part.partNum].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    var body: some View {
        Pressable(onTap: onTap) {
            HStack(spacing: AppSpacing.s12) {
                SetThumb(imageUrl: part.imageUrl, size: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(part.partName).font(AppText.body).foregroundStyle(AppColors.ink).lineLimit(1)
                    HStack(spacing: AppSpacing.s4) {
                        Circle().fill(swatchColor(part.colorRgb)).frame(width: 12, height: 12)
                            .overlay(Circle().stroke(AppColors.line, lineWidth: 1))
                        Text(sub).font(AppText.caption).foregroundStyle(AppColors.inkSoft).lineLimit(1)
                    }
                }
                Spacer(minLength: AppSpacing.s8)
                Text(L.needQty(part.needed)).font(AppText.label).foregroundStyle(AppColors.warning)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.vertical, AppSpacing.s8)
            .contentShape(Rectangle())
        }
        // VoiceOver: the row is a `Button`; label/value/hint override its auto-combined label so it
        // reads "<part>, <colour> · <num>", value "need N", hint "opens BrickLink".
        .accessibilityLabel("\(part.partName), \(sub)")
        .accessibilityValue(L.needQty(part.needed))
        .accessibilityHint(L.a11yOpensBrickLink)
    }
}

// MARK: - Minifig verification row

/// One minifig verification row: image + name + a present/absent toggle (needed == 1) or a small
/// +/- stepper (needed > 1), writing straight to GRDB via the view model.
private struct MinifigRow: View {
    let fig: RebuildMinifigLine
    let have: Int
    let onChanged: (Int) -> Void

    private var complete: Bool { have >= fig.neededQty }

    var body: some View {
        let row = HStack(spacing: AppSpacing.s12) {
            SetThumb(imageUrl: fig.imageUrl, size: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(fig.name).font(AppText.body).foregroundStyle(AppColors.ink).lineLimit(2)
                Text(fig.neededQty > 1 ? L.minifigPresent(have: have, needed: fig.neededQty) : L.neededOne)
                    .font(AppText.caption)
                    .foregroundStyle(complete ? AppColors.success : AppColors.muted)
            }
            Spacer(minLength: AppSpacing.s8)
            if fig.neededQty > 1 {
                HStack(spacing: AppSpacing.s8) {
                    MiniStepBtn(icon: "minus", label: L.remove, enabled: have > 0) { onChanged(have - 1) }
                    Text("\(have)/\(fig.neededQty)")
                        .font(AppText.label)
                        .foregroundStyle(complete ? AppColors.success : AppColors.ink)
                        .frame(minWidth: 34)
                        .accessibilityLabel(L.a11yCount(have: have, needed: fig.neededQty))
                    MiniStepBtn(icon: "plus", label: L.a11yAdd, enabled: have < fig.neededQty) { onChanged(have + 1) }
                }
            } else {
                Pressable(onTap: { onChanged(complete ? 0 : fig.neededQty) }) {
                    Image(systemName: complete ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28))
                        .foregroundStyle(complete ? AppColors.success : AppColors.muted)
                        .frame(width: 44, height: 44) // 44pt tap target around the 28pt glyph
                        .contentShape(Circle())
                }
            }
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.vertical, AppSpacing.s8)

        // The single-needed row is a present/absent toggle: read it as one element carrying the
        // state (the on-screen "Needed" caption never changes, so VoiceOver needs it in the value).
        if fig.neededQty == 1 {
            row.accessibilityElement(children: .ignore)
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel(fig.name)
                .accessibilityValue(complete ? L.a11yPresent : L.a11yAbsent)
                .accessibilityAction { onChanged(complete ? 0 : fig.neededQty) }
        } else {
            row
        }
    }
}

private struct MiniStepBtn: View {
    let icon: String
    let label: String
    let enabled: Bool
    let onTap: () -> Void
    var body: some View {
        Pressable(onTap: enabled ? onTap : nil) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(enabled ? AppColors.ink : AppColors.faint)
                .frame(width: 32, height: 32)
                .background(AppColors.card)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppColors.line, lineWidth: 1))
                .frame(width: 44, height: 44) // 44pt tap target around the 32pt visual
                .contentShape(Circle())
        }
        .accessibilityLabel(label)
    }
}

// MARK: - Mark-as-verified sheet

/// The "Mark as verified" sheet: a completion summary line + the three certificate flags a builder
/// ticks (box / instructions / stickers) + optional notes. The two derived flags (all parts /
/// minifigs) are filled in by the view model. Port of `_MarkVerifiedSheet`.
private struct MarkVerifiedSheet: View {
    let pct: Int
    let partsComplete: Bool
    let minifigsComplete: Bool
    let hasMinifigs: Bool
    let onSave: (_ box: Bool, _ instructions: Bool, _ stickers: Bool, _ notes: String) -> Void

    @State private var box = false
    @State private var instructions = false
    @State private var stickers = false
    @State private var notes = ""

    private var partsLine: String { partsComplete ? L.pctAllParts(pct) : L.pctOfParts(pct) }
    private var figLine: String {
        !hasMinifigs ? L.noMinifigures : (minifigsComplete ? L.minifiguresIncluded : L.minifiguresIncomplete)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(L.markAsVerified).font(AppText.h2).foregroundStyle(AppColors.ink)
                Spacer().frame(height: AppSpacing.s4)
                Text("\(partsLine) · \(figLine)").font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                Spacer().frame(height: AppSpacing.s20)

                Text(L.whatElseInBox).font(AppText.label).foregroundStyle(AppColors.inkSoft)
                Spacer().frame(height: AppSpacing.s8)
                FlagToggle(label: L.boxIncluded, value: $box)
                FlagToggle(label: L.instructionsIncluded, value: $instructions)
                FlagToggle(label: L.stickersApplied, value: $stickers)

                Spacer().frame(height: AppSpacing.s16)
                Text(L.notesOptional).font(AppText.label).foregroundStyle(AppColors.inkSoft)
                Spacer().frame(height: AppSpacing.s8)
                TextField(L.notesHint, text: $notes, axis: .vertical)
                    .font(AppText.body)
                    .foregroundStyle(AppColors.ink)
                    .tint(AppColors.primary)
                    .lineLimit(2...4)
                    .padding(AppSpacing.s12)
                    .background(AppColors.canvas)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.line, lineWidth: 1))

                Spacer().frame(height: AppSpacing.s20)
                AppButton(L.saveVerification, icon: "checkmark.seal", expand: true) {
                    onSave(box, instructions, stickers, notes)
                }
            }
            .padding(.horizontal, AppSpacing.s20)
            .padding(.top, AppSpacing.s20)
            .padding(.bottom, AppSpacing.s24)
        }
        .background(AppColors.card)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct FlagToggle: View {
    let label: String
    @Binding var value: Bool
    var body: some View {
        Pressable(onTap: { value.toggle() }) {
            HStack(spacing: AppSpacing.s12) {
                Image(systemName: value ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundStyle(value ? AppColors.primary : AppColors.muted)
                Text(label).font(AppText.body).foregroundStyle(AppColors.ink)
                Spacer(minLength: 0)
            }
            .padding(.vertical, AppSpacing.s8)
            .contentShape(Rectangle())
        }
        // Read as a checkbox: "<label>, selected/—, button". The row is a `Button`, so labelling it
        // directly (rather than wrapping with `.accessibilityElement`) keeps its tap action.
        .accessibilityLabel(label)
        .accessibilityAddTraits(value ? [.isButton, .isSelected] : .isButton)
    }
}
