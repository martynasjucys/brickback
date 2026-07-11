import SwiftUI
import BrickBackKit

/// App entry point. Builds the config → services → environment once, injects the environment,
/// and forwards the scene lifecycle to the (inert until S5) sync controller — the native
/// analog of the `app.dart` `WidgetsBindingObserver` hooks.
@main
struct BrickBackApp: App {
    @State private var env: AppEnvironment
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // AppConfig.fromBundle traps with a clear message if a publishable value is missing
        // (the S0 "missing secret fails launch clearly" acceptance).
        let config = AppConfig.fromBundle()
        do {
            let services = try AppServices(config: config)
            _env = State(initialValue: AppEnvironment(services: services))
        } catch {
            fatalError("Failed to open local store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(env)
                .tint(AppColors.ink)
                .background(AppColors.canvas)
                .task { env.startSyncWiring() }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background, .inactive:
                Task { await env.sync.pushNow() } // flush dirty on pause (no-op until S5)
            case .active:
                Task { await env.sync.syncNow() } // full sync on resume (no-op until S5)
            @unknown default:
                break
            }
        }
    }
}
