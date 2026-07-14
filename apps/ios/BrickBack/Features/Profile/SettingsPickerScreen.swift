import SwiftUI

/// A native single-select settings sub-screen — the standard iOS "tap a row, it checks, then the
/// view pops back" pattern used for Profile → Appearance / Language (S7). Replaces the old
/// `.confirmationDialog` action sheets, which on iPad rendered as a stray, centre-anchored popover.
///
/// A plain inset-grouped `List` so it reads as a system Settings pane (native row highlight +
/// separators); the current choice carries a trailing checkmark. Pushed onto the Profile stack with
/// the native nav bar (back chevron + inline title), matching the paywall / sign-in screens it
/// shares that stack with — so the stack never toggles nav-bar visibility (see `Route.hidesNavBar`).
struct SettingsPickerScreen<Option: Identifiable & Equatable>: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.activeRouter) private var activeRouter

    let title: String
    let options: [Option]
    /// The currently-selected option — drives which row shows the checkmark.
    let selection: Option
    let label: (Option) -> String
    let onSelect: (Option) -> Void

    // Reachable only from Profile today, but resolve the active stack (like the paywall does) so a
    // future second entry point pops the stack the user is actually on.
    private var router: Router { activeRouter ?? env.profileRouter }

    var body: some View {
        List {
            ForEach(options) { option in
                Button {
                    onSelect(option)
                    // Pop via the router, not `@Environment(\.dismiss)`: choosing a Language re-ids
                    // the whole view tree (BrickBackApp keys on `locale.language`), and the
                    // router-owned path is what survives that rebuild — so popping it is reliable.
                    router.pop()
                } label: {
                    HStack(spacing: AppSpacing.s12) {
                        Text(label(option))
                            .font(AppText.body)
                            .foregroundStyle(AppColors.ink)
                        Spacer(minLength: AppSpacing.s8)
                        if option == selection {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppColors.primary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .listRowBackground(AppColors.card)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppColors.canvas)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
