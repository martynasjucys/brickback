import SwiftUI
import BrickBackKit

/// `.party(id)` — the realtime hub. Live shared progress, the member roster, and an activity feed;
/// "Add found parts" logs contributions that roll up server-side into the shared have-count.
/// Port of `party_screen.dart`.
struct PartyView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.activeRouter) private var activeRouter
    let partyId: String

    @State private var vm: PartyViewModel?
    @State private var confirmEnd = false

    private var router: Router { activeRouter ?? env.homeRouter }

    /// The native bar's inline title: the party's own name once loaded (the big content heading in a
    /// compact form the bar keeps as you scroll), falling back to the generic label while it loads.
    private var navTitle: String { vm?.party?.name ?? L.partyModeTitle }

    /// Invite is only offered on a live, loaded party — an ended/paused one has nothing to invite
    /// into, and a failed load has no party to invite to at all.
    private var showInvite: Bool {
        guard let vm, case .ready = vm.phase, let party = vm.party else { return false }
        return party.isActive
    }

    var body: some View {
        ZStack {
            AppColors.canvas.ignoresSafeArea()
            if let vm {
                switch vm.phase {
                case .loading:
                    ProgressView().tint(AppColors.primary)
                case .failed(let message):
                    EmptyState(title: L.couldntLoadParty, message: message, icon: "exclamationmark.triangle")
                case .ready:
                    content(vm: vm)
                }
            } else {
                ProgressView().tint(AppColors.primary)
            }
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showInvite {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { router.push(.partyInvite(partyId)) } label: {
                        Label(L.invite, systemImage: "person.badge.plus")
                    }
                }
            }
        }
        .task {
            if vm == nil {
                vm = PartyViewModel(partyId: partyId, repo: env.services.party, onNudge: { env.sync.nudge() })
            }
            await vm?.load()
        }
        .onDisappear {
            if let vm { Task { await vm.reconcile(); vm.teardown() } }
        }
        .alert(L.endThisParty, isPresented: $confirmEnd) {
            Button(L.endParty, role: .destructive) { end() }
            Button(L.cancel, role: .cancel) {}
        } message: {
            Text(L.endPartyBody)
        }
    }

    // MARK: - Content

    private func content(vm: PartyViewModel) -> some View {
        let party = vm.party!
        let active = party.isActive
        return VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(party.name).font(AppText.display).foregroundStyle(AppColors.ink)
                        Spacer(minLength: AppSpacing.s8)
                        if !active {
                            AppBadge(party.status == "ended" ? L.statusEnded : L.statusPaused, color: AppColors.warning)
                        }
                    }
                    Text(L.partyCodeCaption(party.joinCode)).font(AppText.caption).foregroundStyle(AppColors.inkSoft)

                    Spacer().frame(height: AppSpacing.s20)
                    VStack(spacing: AppSpacing.s8) {
                        ProgressRing(value: vm.progress.value, size: 132, stroke: 10)
                        Text(L.partyProgress(have: vm.progress.have, total: vm.progress.total))
                            .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer().frame(height: AppSpacing.s16)
                    HStack(spacing: AppSpacing.s8) {
                        AvatarStack(members: vm.members)
                        Text(L.memberCount(vm.members.count)).font(AppText.label).foregroundStyle(AppColors.muted)
                    }

                    Spacer().frame(height: AppSpacing.s16)
                    AppButton(L.addFoundParts, icon: "plus.circle", expand: true,
                              onTap: active ? { router.push(.partyAddParts(party.id)) } : nil)

                    Spacer().frame(height: AppSpacing.s24)
                    Text(L.activity).font(AppText.h2).foregroundStyle(AppColors.ink)
                    Spacer().frame(height: AppSpacing.s8)
                    if vm.feed.isEmpty {
                        Text(L.noActivity).font(AppText.caption).foregroundStyle(AppColors.muted)
                    } else {
                        ForEach(vm.feed) { c in
                            ActivityItem(who: vm.memberName(c.memberId), contribution: c)
                        }
                    }

                    if vm.isHost && active {
                        Spacer().frame(height: AppSpacing.s24)
                        AppButton(L.endParty, variant: .ghost, icon: "stop.circle",
                                  loading: vm.ending, expand: true,
                                  onTap: vm.ending ? nil : { confirmEnd = true })
                    }
                }
                .padding(.horizontal, AppSpacing.screen)
                .padding(.bottom, AppSpacing.s24)
            }
        }
    }

    private func end() {
        guard let vm else { return }
        Task {
            if await vm.endParty() { router.pop() }
        }
    }
}

/// One activity-feed row: "{who} added {what}" + a +qty pill.
private struct ActivityItem: View {
    let who: String
    let contribution: PartyContribution

    private var what: String {
        contribution.colorName.map { "\($0) \(contribution.partName)" } ?? contribution.partName
    }

    var body: some View {
        AppCard(padding: AppSpacing.s12) {
            HStack(spacing: AppSpacing.s8) {
                Text(L.activityLine(who: who, what: what)).font(AppText.body).foregroundStyle(AppColors.ink)
                Spacer(minLength: AppSpacing.s8)
                Text("+\(contribution.qty)")
                    .font(AppText.label).foregroundStyle(AppColors.success)
                    .padding(.horizontal, AppSpacing.s8).padding(.vertical, AppSpacing.s4)
                    .background(AppColors.success.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.bottom, AppSpacing.s8)
    }
}
