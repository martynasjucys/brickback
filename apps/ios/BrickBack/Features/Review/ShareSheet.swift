import SwiftUI
import UIKit

/// Identifiable payload of file URLs to hand to the system share sheet. Presented via
/// `.sheet(item:)` rather than a bare `UIActivityViewController` so it stays correct on iPad,
/// where a raw activity controller needs an explicit popover anchor.
struct ShareItems: Identifiable {
    let id = UUID()
    let urls: [URL]
}

/// UIKit share sheet bridged into SwiftUI — shares file URLs (the wanted-list XML, the report
/// PNG / PDF). The Flutter app used `SharePlus`; this is the native equivalent.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// A safe filename stem from a set name (mirrors the Dart `RegExp(r'[^\w.-]')` scrub).
func safeFileStem(_ name: String, fallback: String = "set") -> String {
    let scrubbed = name.replacingOccurrences(of: "[^A-Za-z0-9._-]", with: "_", options: .regularExpression)
    return scrubbed.isEmpty ? fallback : scrubbed
}
