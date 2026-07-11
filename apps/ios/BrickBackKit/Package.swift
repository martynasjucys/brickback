// swift-tools-version: 6.0
import PackageDescription

// BrickBackKit — the UI-independent domain/data layer (see docs/ios-swift/00-architecture.md §4).
// Pure Swift, no SwiftUI, so it unit-tests in milliseconds against an in-memory GRDB DB —
// exactly how the Flutter repos are tested today.
let package = Package(
    name: "BrickBackKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "BrickBackKit", targets: ["BrickBackKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "BrickBackKit",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            swiftSettings: [
                // Start in language mode 5 (concurrency warnings, not errors) per S0; the
                // sync engine is already actor-isolated so a Swift-6 bump is a later step.
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "BrickBackKitTests",
            dependencies: [
                "BrickBackKit",
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
    ]
)
