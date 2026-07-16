# F0 baseline screenshots

The "before" set for the migration. Captured 2026-07-16 (see [`../F0-results.md`](../F0-results.md)).

- **`flutter/`** — the frozen `apps/mobile` app on **iPhone 16 Pro**, light-only (the app has no
  dark theme yet — that's F2). Visuals are deliberately **wireframe fidelity** (grayscale, boxy).
  Regenerate with the harness:
  `flutter drive --driver=test_driver/screenshot_driver.dart --target=integration_test/screenshot_capture.dart -d <sim>`
- **`swift/`** — the Swift oracle (`apps/ios`) on **iPad A16 18.6**, the **branded** target
  (blue/cream palette, per-surface tinted nav bars, iPad master-detail). Captured via `idb`.

Roughly paired (naming is aligned across the two dirs where a match exists):

| Screen | Flutter (iPhone, wireframe) | Swift (iPad, branded) |
|---|---|---|
| Home / Rebuilds | `10-home-empty`, `01-home-light` | `ipad-01-home-light` |
| Profile | `20-profile` | `ipad-20-profile` |
| Counting | `40-counting` | `ipad-40-counting` |
| Party | `70-party-join` (join screen) | `ipad-70-party` (Party tab) |
| Search (empty / results) | `25-search-empty`, `30-search-results` | — |
| Set detail | `31-set-detail` | — |
| Review | `50-review` | — |
| Paywall | `60-paywall` | — |
| Sign-in | `61-signin` | — |
| Design gallery | `80-design-gallery` | — |

Swift screens beyond the four here weren't re-captured — the oracle stays live for interactive
side-by-side, and every screen is described in `docs/ios-swift/*.md`. The four branded shots already
cover the two marquee references: F2 (palette/typography/cards) and F3 (iPad adaptive layout +
multi-column counting grid).
