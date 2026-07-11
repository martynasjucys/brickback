import Foundation

/// Builds catalog image URLs. Our R2/CDN mirror (`item_images` kind=webp) is preferred;
/// the caller falls back to the row's `rebrickable_img_url` when a set/part isn't mirrored.
/// The app builds URLs as `${cdnURL}/${item_images.storage_key}`. Used from S2 on.
public struct ImageResolver: Sendable {
    public let cdnURL: URL?

    public init(cdnURL: URL?) {
        self.cdnURL = cdnURL
    }

    /// Full URL for a mirrored image, or nil if there's no CDN base / no key.
    public func url(forStorageKey key: String?) -> String? {
        guard let cdnURL, let key, !key.isEmpty else { return nil }
        // Trim any trailing slash on the base, then join.
        let base = cdnURL.absoluteString.hasSuffix("/")
            ? String(cdnURL.absoluteString.dropLast())
            : cdnURL.absoluteString
        return "\(base)/\(key)"
    }
}
