import SwiftUI
import CoreImage.CIFilterBuiltins
import BrickBackKit

/// `.partyInvite(id)` — a scannable QR + the short code + a share sheet. The QR encodes
/// `brickback://party/<code>` (informational — joining is by code entry; there is no deep-link
/// handler yet, same as the Flutter app). QR is rendered with CoreImage's `CIQRCodeGenerator`, so
/// no `qr_flutter`-style dependency is needed. Port of `party_invite_screen.dart`.
struct PartyInviteView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.activeRouter) private var activeRouter
    let partyId: String

    @State private var state: LoadState<Party> = .loading
    @State private var showShare = false

    private var router: Router { activeRouter ?? env.homeRouter }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader("Invite", onBack: { router.pop() })
            switch state {
            case .idle, .loading:
                ProgressView().tint(AppColors.primary).frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                EmptyState(title: "Couldn't load party", message: message, icon: "exclamationmark.triangle")
            case .loaded(let party):
                invite(name: party.name, code: party.joinCode)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.canvas)
        .task(id: partyId) {
            state = .loading
            do {
                let party = try await env.services.party.getParty(partyId)
                if !Task.isCancelled { state = .loaded(party) }
            } catch {
                if !Task.isCancelled { state = .failed("\(error)") }
            }
        }
    }

    private func invite(name: String, code: String) -> some View {
        let link = "brickback://party/\(code)"
        return ScrollView {
            VStack(spacing: 0) {
                Text("Invite to \(name)").font(AppText.h1).foregroundStyle(AppColors.ink)
                    .multilineTextAlignment(.center)
                Spacer().frame(height: AppSpacing.s8)
                Text("Scan the code or share the link to join the sort.")
                    .font(AppText.body).foregroundStyle(AppColors.inkSoft).multilineTextAlignment(.center)

                Spacer().frame(height: AppSpacing.s24)
                AppCard(padding: AppSpacing.s20) {
                    Group {
                        if let qr = Self.qrImage(link) {
                            Image(uiImage: qr)
                                .interpolation(.none)
                                .resizable().scaledToFit()
                                .frame(width: 220, height: 220)
                        } else {
                            RoundedRectangle(cornerRadius: AppRadius.md).fill(AppColors.faint)
                                .frame(width: 220, height: 220)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                Spacer().frame(height: AppSpacing.s20)
                Text("Join code").font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                Spacer().frame(height: AppSpacing.s4)
                Text(code).font(AppText.display).tracking(4).foregroundStyle(AppColors.ink)

                Spacer().frame(height: AppSpacing.s24)
                AppButton("Share invite", icon: "square.and.arrow.up", expand: true) { showShare = true }
            }
            .padding(AppSpacing.s24)
        }
        .sheet(isPresented: $showShare) {
            ActivityView(items: ["Join my BrickBack sort party — code \(code)\n\(link)"])
        }
    }

    /// Render a string to a crisp QR `UIImage` via CoreImage (dark modules on transparent).
    private static func qrImage(_ string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
