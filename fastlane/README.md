# Fastlane (Google Play)

Listing metadata for **Listora** (`com.popupbits.listora`), uploaded via
`fastlane supply` (`upload_to_play_store`).

## One-time setup
1. In Play Console → Setup → API access, create/link a service account with the
   "Release manager" role and download its JSON key.
2. Save it as `fastlane/play-store-key.json` (gitignored — never commit it).

## Lanes
- `fastlane metadata` — push title/descriptions/images/screenshots only.
- `fastlane internal` — upload `build/app/outputs/bundle/release/app-release.aab`
  to the internal test track. Build it first with:
  `flutter build appbundle --release`

## Char limits (enforced in metadata/android/en-US)
- title.txt ≤ 30 · short_description.txt ≤ 80 · full_description.txt ≤ 4000
- changelogs/*.txt ≤ 500
