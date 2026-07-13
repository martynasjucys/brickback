# Branding assets — app icon & launch logo (drop-in guide)

> **Status:** the launch screen and asset **slots are wired**; only the artwork is missing. This
> is the one-step handoff for when the icon vector arrives. Everything else in S7 (design system,
> dark mode, i18n, motion, haptics, accessibility) is done.

The app currently launches on a **solid branded background** (`LaunchBackground.colorset`, which
matches `AppColors.canvas` in both light and dark — cream `#F6F3E7` / near-black `#161619`), so
there is no colour flash into the first frame. No logo is shown yet. The app icon slot is present
but empty (Xcode shows the default placeholder on the Home screen).

Nothing here needs `xcodegen generate` — asset-catalog contents are compiled directly. Just drop
the files, edit the two `Contents.json` files (and one Info.plist line), and rebuild.

---

## 1. App icon

**Provide:** a single **1024×1024 PNG**, square, **no alpha / no transparency**, no rounded corners
(iOS masks it). Export it from the vector at 1024. This uses the modern **single-size** icon format
(iOS 17+ upscales/downscales all sizes from the one image).

**Install:**
1. Save it as `apps/ios/BrickBack/Resources/Assets.xcassets/AppIcon.appiconset/Icon-1024.png`.
2. Add the `filename` to that set's `Contents.json`:

```json
{
  "images" : [
    {
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024",
      "filename" : "Icon-1024.png"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

The build already points at this set (`ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` in
`project.yml`), so nothing else is needed.

**Optional — dark & tinted variants (iOS 18):** if the vector has a dark-appearance or
monochrome-tintable version, export `Icon-1024-Dark.png` and `Icon-1024-Tinted.png` and expand the
`images` array with `"appearances": [{ "appearance": "luminosity", "value": "dark" }]` and
`{ "appearance": "luminosity", "value": "tinted" }` entries pointing at them. Skip this for the
first drop — the single universal icon is enough to ship.

---

## 2. Launch-screen logo (optional but recommended)

A centred logo on the launch background makes the launch feel first-party. It's optional — the
solid background alone is a clean launch.

**Provide:** the logo as a **vector PDF** (preferred) or a **single high-res PNG** (~600pt wide,
@1x — iOS renders the launch image at its natural size). A white/light logo reads best; if the logo
is dark, switch the launch background to brand blue (step 3).

**Install:**
1. Create the folder
   `apps/ios/BrickBack/Resources/Assets.xcassets/LaunchLogo.imageset/`.
2. Drop the file in (e.g. `LaunchLogo.pdf`).
3. Add a `Contents.json` (PDF-vector form shown; for a PNG, use `"filename": "LaunchLogo.png"` with
   1x/2x/3x scales instead):

```json
{
  "images" : [
    { "idiom" : "universal", "filename" : "LaunchLogo.pdf" }
  ],
  "info" : { "author" : "xcode", "version" : 1 },
  "properties" : { "preserves-vector-representation" : true }
}
```

4. In `apps/ios/BrickBack/Resources/Info.plist`, uncomment the `UIImageName` line inside
   `UILaunchScreen`:

```xml
<key>UIImageName</key>
<string>LaunchLogo</string>
```

That's the whole change — the `UIColorName`, safe-area key, and background colour set are already
in place.

---

## 3. (Optional) launch background colour

`LaunchBackground.colorset` currently mirrors `AppColors.canvas` (cream / near-black) for a
seamless fade into the app. If the logo is dark and needs a coloured field, edit that colour set's
`Contents.json` to the brand blue used by the Home header — `AppColors.brand` (light `#0253C4`,
dark `#0B54C0`):

```json
"components" : { "alpha" : "1.000", "red" : "0x02", "green" : "0x53", "blue" : "0xC4" }
```

(with the dark appearance entry set to `0x0B / 0x54 / 0xC0`).

---

## Checklist

- [ ] `Icon-1024.png` (+ optional dark/tinted) in `AppIcon.appiconset`, `Contents.json` updated
- [ ] `LaunchLogo` image set added (if using a logo) + `UIImageName` uncommented in Info.plist
- [ ] Decide launch background: canvas (default, seamless) vs. brand blue (logo-forward)
- [ ] Rebuild, confirm the Home-screen icon and the launch screen in **light + dark**
