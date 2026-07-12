import SwiftUI
import BrickBackKit

/// App entry point. Builds the config → services → environment once, injects the environment,
/// and forwards the scene lifecycle to the sync controller — the native analog of the
/// `app.dart` `WidgetsBindingObserver` hooks. Sync only runs for signed-in premium users.
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
                // The branded palette is light-only for now; the full dark-mode pass (incl. a
                // proper per-screen status-bar style over the blue header) is the rest of S7.
                .preferredColorScheme(.light)
                .task { env.startSyncWiring() }
                // OAuth/OTP deep-link return (com.brickback://login-callback): supabase-swift
                // runs the PKCE exchange and emits on the auth-change stream.
                .onOpenURL { env.services.auth.handleOpenURL($0) }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background, .inactive:
                Task { await env.sync.pushNow() } // flush dirty on pause (gated on premium)
            case .active:
                Task { await env.sync.syncNow() } // full sync on resume (gated on premium)
            @unknown default:
                break
            }
        }
    }
}
