import SwiftUI
import UIKit
import BrickBackKit

/// The Inventory Verification report / certificate (`.report(id)`). Renders the recorded
/// `Verification` as a shareable card, then exports it two ways off the **same** SwiftUI view via
/// `ImageRenderer`: a **@3× PNG** (`uiImage`) and a **printable A4 PDF** (`render` → a
/// `UIGraphicsPDFRenderer` page), so the printed certificate matches the shared image exactly.
/// Replaces Flutter's `RepaintBoundary → toImage` + `pdf`/`printing`. Port of `ReportScreen`.
struct ReportView: View {
    @Environment(AppEnvironment.self) private var env
    let rebuildSetId: String

    @State private var vm: ReportViewModel?
    @State private var shareItems: ShareItems?
    @State private var busy = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Pressable(onTap: { env.homeRouter.pop() }) {
                    Image(systemName: "arrow.left").foregroundStyle(AppColors.ink).padding(AppSpacing.s4)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.vertical, AppSpacing.s8)

            if let vm {
                switch vm.phase {
                case .loading:
                    Spacer(); ProgressView().tint(AppColors.primary); Spacer()
                case .failed(let message):
                    EmptyState(title: L.couldntLoad, message: message, icon: "exclamationmark.triangle")
                case .notVerified:
                    EmptyState(
                        title: L.notVerifiedYet,
                        message: L.notVerifiedMessage,
                        icon: "checkmark.seal"
                    )
                case .ready:
                    if let record = vm.record { ready(vm: vm, record: record) }
                }
            } else {
                Spacer(); ProgressView().tint(AppColors.primary); Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.canvas)
        .task {
            if vm == nil { vm = ReportViewModel(rebuildSetId: rebuildSetId, repo: env.services.rebuild, imageStore: env.services.imageStore) }
            await vm?.load()
        }
        .sheet(item: $shareItems) { ActivityView(items: $0.urls) }
    }

    private func ready(vm: ReportViewModel, record: Verification) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.s20) {
                // The certificate is a "paper" document (shared as PNG/PDF), so it always renders
                // light — even in dark mode — sitting on the themed report background.
                VerificationReportCard(record: record, setName: vm.setName, image: vm.image)
                    .environment(\.colorScheme, .light)
                VStack(spacing: AppSpacing.s12) {
                    AppButton(L.shareImage, variant: .secondary, icon: "photo", loading: busy, expand: true) {
                        share(vm: vm, record: record, asPDF: false)
                    }
                    AppButton(L.sharePdf, icon: "doc.richtext", loading: busy, expand: true) {
                        share(vm: vm, record: record, asPDF: true)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.bottom, AppSpacing.s24)
        }
    }

    /// Render the certificate to a file and hand it to the share sheet. The card is given a fixed
    /// width so its off-screen layout is deterministic (the `ImageRenderer` sizing risk).
    private func share(vm: ReportViewModel, record: Verification, asPDF: Bool) {
        guard !busy else { return }
        busy = true
        let card = VerificationReportCard(record: record, setName: vm.setName, image: vm.image)
            .frame(width: 360)
            .padding(AppSpacing.s20)
            .background(AppColors.canvas)
            .environment(\.colorScheme, .light) // export the certificate as light "paper", always
        let renderer = ImageRenderer(content: card)

        var url: URL?
        if asPDF {
            let data = renderer.renderedPDF()
            let u = FileManager.default.temporaryDirectory.appendingPathComponent("brickback-verification.pdf")
            if (try? data.write(to: u)) != nil { url = u }
        } else {
            renderer.scale = 3
            if let ui = renderer.uiImage, let data = ui.pngData() {
                let u = FileManager.default.temporaryDirectory.appendingPathComponent("verification.png")
                if (try? data.write(to: u)) != nil { url = u }
            }
        }
        busy = false
        if let url { shareItems = ShareItems(urls: [url]) }
    }
}

// MARK: - The certificate card

/// The certificate itself — a self-contained card so the captured PNG/PDF reads as a printable
/// certificate independent of the app chrome. Port of `VerificationReport`.
struct VerificationReportCard: View {
    let record: Verification
    let setName: String
    var image: UIImage? = nil

    /// Locale-aware verification date (S7): abbreviated month + day + year, formatted in the
    /// chosen app language (`I18n.locale`) so the shared PNG/PDF follow it — not the device.
    /// Replaces the Flutter app's hardcoded English month array.
    private var dateLabel: String {
        record.verifiedAt.formatted(Date.FormatStyle(date: .abbreviated).locale(I18n.locale))
    }

    private var badgeColor: Color { record.partsComplete ? AppColors.success : AppColors.warning }
    private var badgeText: String {
        record.partsComplete
            ? L.reportPctComplete(record.pctLabel)
            : L.reportPctPartsMissing(pct: record.pctLabel, count: record.partsMissing)
    }
    private var figLine: String {
        record.minifigsNeeded == 0 ? L.noneInSet : "\(record.minifigsFound) / \(record.minifigsNeeded)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L.inventoryVerification)
                    .font(AppText.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(AppColors.muted)
                Spacer(minLength: 0)
                Image(systemName: "checkmark.seal.fill").font(.system(size: 20)).foregroundStyle(AppColors.success)
            }
            Spacer().frame(height: AppSpacing.s16)

            ReportThumb(image: image, size: 104)
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer().frame(height: AppSpacing.s12)
            Text(setName)
                .font(AppText.h2).foregroundStyle(AppColors.ink)
                .multilineTextAlignment(.center).lineLimit(2)
                .frame(maxWidth: .infinity)
            Spacer().frame(height: AppSpacing.s12)

            Text(badgeText)
                .font(AppText.label).tracking(0.5).foregroundStyle(badgeColor)
                .padding(.horizontal, AppSpacing.s16).padding(.vertical, AppSpacing.s8)
                .background(badgeColor.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(badgeColor.opacity(0.4), lineWidth: 1))
                .frame(maxWidth: .infinity)
            Spacer().frame(height: AppSpacing.s20)

            StatRow(label: L.reportPartsFound, value: "\(record.partsFound) / \(record.partsNeeded)")
            StatRow(label: L.minifiguresSection, value: figLine)
            Spacer().frame(height: AppSpacing.s12)
            Rectangle().fill(AppColors.line).frame(height: 1)
            Spacer().frame(height: AppSpacing.s12)

            CheckLine(label: L.allPartsPresent, value: record.flags.allParts)
            if record.minifigsNeeded > 0 {
                CheckLine(label: L.minifiguresIncluded, value: record.flags.minifigsIncluded)
            }
            CheckLine(label: L.boxIncluded, value: record.flags.boxIncluded)
            CheckLine(label: L.instructionsIncluded, value: record.flags.instructionsIncluded)
            CheckLine(label: L.stickersApplied, value: record.flags.stickersApplied)

            if let notes = record.notes, !notes.isEmpty {
                Spacer().frame(height: AppSpacing.s12)
                Text("“\(notes)”")
                    .font(AppText.caption.italic()).foregroundStyle(AppColors.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.s12)
                    .background(AppColors.canvas)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }
            Spacer().frame(height: AppSpacing.s16)

            HStack {
                Text(L.verifiedDate(dateLabel)).font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                Spacer(minLength: 0)
                HStack(spacing: AppSpacing.s4) {
                    Image(systemName: "square.grid.2x2").font(.system(size: 13)).foregroundStyle(AppColors.ink)
                    Text(L.verifiedWithBrickback)
                        .font(AppText.caption.weight(.semibold)).foregroundStyle(AppColors.ink)
                }
            }
        }
        .padding(AppSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(AppColors.line, lineWidth: 1))
    }
}

/// Square set thumbnail that renders a concrete `UIImage` (so `ImageRenderer` bakes it into the
/// export), falling back to a wireframe placeholder. Not `LazyImage` — that loads async and would
/// be blank off-screen.
private struct ReportThumb: View {
    let image: UIImage?
    var size: CGFloat = 104
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFit().background(AppColors.card)
            } else {
                ZStack {
                    AppColors.faint
                    Text("[img]").font(AppText.caption).foregroundStyle(AppColors.muted)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(AppText.body).foregroundStyle(AppColors.inkSoft)
            Spacer(minLength: 0)
            Text(value).font(AppText.label).foregroundStyle(AppColors.ink)
        }
        .padding(.vertical, AppSpacing.s4)
    }
}

private struct CheckLine: View {
    let label: String
    let value: Bool
    var body: some View {
        let color = value ? AppColors.success : AppColors.muted
        return HStack(spacing: AppSpacing.s8) {
            Image(systemName: value ? "checkmark.circle.fill" : "xmark.circle")
                .font(.system(size: 18)).foregroundStyle(color)
            Text(label).font(AppText.body).foregroundStyle(value ? AppColors.ink : AppColors.muted)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - ImageRenderer → A4 PDF

extension ImageRenderer {
    /// Render the content into a single A4 page (595×842 pt @72dpi), scaled to fit within the
    /// margins, top-aligned and horizontally centred. Drawn at rasterization scale 1 so text stays
    /// crisp vector output when printed. One-page certificate → no pagination.
    @MainActor
    func renderedPDF(pageSize: CGSize = CGSize(width: 595, height: 842), margin: CGFloat = 28) -> Data {
        var data = Data()
        render(rasterizationScale: 1) { size, renderInContext in
            let bounds = CGRect(origin: .zero, size: pageSize)
            let pdfRenderer = UIGraphicsPDFRenderer(bounds: bounds)
            data = pdfRenderer.pdfData { ctx in
                ctx.beginPage()
                let cg = ctx.cgContext
                let available = CGSize(width: pageSize.width - margin * 2, height: pageSize.height - margin * 2)
                let scale = min(available.width / max(size.width, 1), available.height / max(size.height, 1))
                let scaledWidth = size.width * scale
                let offsetX = (pageSize.width - scaledWidth) / 2
                cg.translateBy(x: offsetX, y: margin)
                cg.scaleBy(x: scale, y: scale)
                renderInContext(cg)
            }
        }
        return data
    }
}
