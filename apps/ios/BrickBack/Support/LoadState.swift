import SwiftUI

/// A one-shot async load's UI state — the SwiftUI analog of Riverpod's `AsyncValue.when`
/// (loading / data / error). Screens hold one of these in `@State` and drive it from a
/// `.task`, so the load logic stays inline (no view model needed for a simple fetch).
enum LoadState<T> {
    case idle
    case loading
    case loaded(T)
    case failed(String)
}
