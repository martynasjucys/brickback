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
            // S9 offline mode: inject the Nuke-backed prefetcher, then point the shared image
            // pipeline at the durable store so every LazyImage reads/writes it (offline-capable).
            let services = try AppServices(config: config, imagePrefetcher: NukeImagePrefetcher())
            ImageOfflineCache.configure(store: services.imageStore)
            _env = State(initialValue: AppEnvironment(services: services))
        } catch {
            fatalError("Failed to open local store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootShell()
                .environment(env)
                .environment(env.locale)
                .environment(env.theme)
                // S7 i18n: drive SwiftUI date/number formatting off the chosen language, and key
                // the whole tree on it so an in-app Language switch re-renders every screen with
                // the new strings (routers live in `env`, so navigation survives the rebuild).
                .environment(\.locale, env.locale.locale)
                .id(env.locale.language)
                .tint(AppColors.ink)
                .background(AppColors.canvas)
                // S7 dark mode: follow the system (or the persisted Profile override). Every
                // `AppColors` token is dynamic, so pinning the scheme re-skins the whole app; in
                // dark the status bar goes light — correct over both the canvas and the blue/green
                // brand headers.
                .preferredColorScheme(env.theme.colorScheme)
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
