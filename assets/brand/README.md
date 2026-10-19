# Leera brand

From the Leera design canvas (Claude Design, October 2026).

| File | Use |
| --- | --- |
| `app_icon.svg` | iOS app icon: full-bleed square, iOS rounds the corners itself |
| `logo.svg` | The icon with its own rounded corners, for use on a background |
| `app_icon_1024.png` | `app_icon.svg` at 1024 px, for App Store Connect |
| `logo.png` | `logo.svg` at 360 px, shown at 120 pt in the app (sign-in page) |

The mark is a speech bubble with three bars that rise: a voice that grows
stronger. Palette: teal `#5FC4D2`, cream `#FBF0E7`, peach `#F09669`,
coral `#D96266`, ink `#24323A`. Type: Bricolage Grotesque (wordmark, titles),
Nunito (text). The wordmark is written in lower case: `leera`.

The PNGs in `ios/Runner/Assets.xcassets` (app icon, `LaunchImage`,
`LaunchDots`) are rendered from these files by `scripts/render_brand.mjs`.
