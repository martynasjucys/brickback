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

    var body: some View {
        ZStack {
            AppColors.canvas.ignoresSafeArea()
            if let vm {
                switch vm.phase {
                case .loading:
                    ProgressView().tint(AppColors.primary)
                case .failed(let message):
                    VStack(spacing: 0) {
                        headerBar(showInvite: false)
                        EmptyState(title: "Couldn't load party", message: message, icon: "exclamationmark.triangle")
                    }
                case .ready:
                    content(vm: vm)
                }
            } else {
                ProgressView().tint(AppColors.primary)
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
        .alert("End this party?", isPresented: $confirmEnd) {
            Button("End party", role: .destructive) { end() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Members won't be able to add parts anymore.")
        }
    }

    // MARK: - Content

    private func content(vm: PartyViewModel) -> some View {
        let party = vm.party!
        let active = party.isActive
        return VStack(alignment: .leading, spacing: 0) {
            headerBar(showInvite: active)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(party.name).font(AppText.display).foregroundStyle(AppColors.ink)
                        Spacer(minLength: AppSpacing.s8)
                        if !active {
                            AppBadge(party.status == "ended" ? "Ended" : "Paused", color: AppColors.warning)
                        }
                    }
                    Text("Party · code \(party.joinCode)").font(AppText.caption).foregroundStyle(AppColors.inkSoft)

                    Spacer().frame(height: AppSpacing.s20)
                    VStack(spacing: AppSpacing.s8) {
                        ProgressRing(value: vm.progress.value, size: 132, stroke: 10)
                        Text("\(vm.progress.have) of \(vm.progress.total) parts")
                            .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer().frame(height: AppSpacing.s16)
                    HStack(spacing: AppSpacing.s8) {
                        AvatarStack(members: vm.members)
                        Text(memberCount(vm.members.count)).font(AppText.label).foregroundStyle(AppColors.muted)
                    }

                    Spacer().frame(height: AppSpacing.s16)
                    AppButton("Add found parts", icon: "plus.circle", expand: true,
                              onTap: active ? { router.push(.partyAddParts(party.id)) } : nil)

                    Spacer().frame(height: AppSpacing.s24)
                    Text("Activity").font(AppText.h2).foregroundStyle(AppColors.ink)
                    Spacer().frame(height: AppSpacing.s8)
                    if vm.feed.isEmpty {
                        Text("No parts added yet.").font(AppText.caption).foregroundStyle(AppColors.muted)
                    } else {
                        ForEach(vm.feed) { c in
                            ActivityItem(who: vm.memberName(c.memberId), contribution: c)
                        }
                    }

                    if vm.isHost && active {
                        Spacer().frame(height: AppSpacing.s24)
                        AppButton("End party", variant: .ghost, icon: "stop.circle",
                                  loading: vm.ending, expand: true,
                                  onTap: vm.ending ? nil : { confirmEnd = true })
                    }
                }
                .padding(.horizontal, AppSpacing.screen)
                .padding(.bottom, AppSpacing.s24)
            }
        }
    }

    // MARK: - Header

    private func headerBar(showInvite: Bool) -> some View {
        HStack {
            Pressable(onTap: { back() }) {
                Image(systemName: "arrow.left").foregroundStyle(AppColors.ink).padding(AppSpacing.s4)
            }
            Spacer()
            if showInvite {
                Pressable(onTap: { router.push(.partyInvite(partyId)) }) {
                    HStack(spacing: AppSpacing.s4) {
                        Image(systemName: "person.badge.plus").font(.system(size: 18)).foregroundStyle(AppColors.info)
                        Text("Invite").font(AppText.label).foregroundStyle(AppColors.info)
                    }
                    .padding(AppSpacing.s8)
                }
            }
        }
        .padding(.horizontal, AppSpacing.s12)
        .padding(.vertical, AppSpacing.s8)
    }

    private func back() {
        guard let vm else { router.pop(); return }
        Task { await vm.reconcile(); router.pop() }
    }

    private func end() {
        guard let vm else { return }
        Task {
            if await vm.endParty() { router.pop() }
        }
    }

    private func memberCount(_ n: Int) -> String { n == 1 ? "1 member" : "\(n) members" }
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
                Text("\(who) added \(what)").font(AppText.body).foregroundStyle(AppColors.ink)
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
