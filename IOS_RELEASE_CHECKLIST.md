# iOS App Store Release Checklist — Listora

> Companion to the Android pipeline. This file is the App Store Connect field
> reference — the values a human types into the console by hand and the
> submission gates fastlane cannot set.

## App Store Connect Information

| Field | Value |
|-------|-------|
| **App Name** | Listora – LibriVox Audiobooks |
| **Subtitle** | Stream & download classics |
| **Bundle ID** | `com.popupbits.listora` |
| **SKU** | `listora` |
| **Version** | 1.0.0 (Build 4) |
| **Primary Language** | English (U.S.) |
| **Primary Category** | Books |
| **Secondary Category** | Entertainment |
| **Price** | Free |
| **Copyright** | 2026 Popup Bits Pvt. Ltd. |
| **Age Rating** | 4+ (review — see note) |
| **Developer** | Popup Bits Pvt. Ltd. |

## URLs

| Field | URL |
|-------|-----|
| **Support URL** | https://popupbits.com/products |
| **Marketing URL** | https://popupbits.com/products |
| **Privacy Policy URL** | https://popupbits.com/contact/listora-privacy-policy |

> **Privacy policy is a hard App Store requirement.** The URL above follows the
> PopupBits-site convention (`src/routes/contact/listora-privacy-policy/`). It
> **must be live and reachable before submission** — add it to the popupbits
> site repo first.

## App Privacy (Data Collection)

**The app does NOT collect any data.** Select "Data Not Collected" in App Store Connect.

- No analytics, tracking, or advertising SDKs (verified in `pubspec.yaml`)
- No account or login
- Audio and metadata are fetched over HTTPS from the public Internet Archive /
  LibriVox — public content, not user data
- Downloads are stored on-device only
- No in-app purchases

## Age Rating Questionnaire

The app itself contains no objectionable content — it is a player. Answer the
questionnaire None/No for a **4+** rating. **Note:** the *content* is
public-domain classic literature; if any surfaced title warrants it, Apple may
expect a higher band. It is not "Unrestricted Web Access" (curated in-app
catalog, not a browser).

## App Review Notes

```
Listora is a free audiobook player for public-domain LibriVox recordings served
from the Internet Archive. No login or account is required — open the app and
browse or search thousands of titles. Audio streams over HTTPS from archive.org;
chapters can be downloaded for offline playback. There are no in-app purchases
and no advertisements.
```

## Background audio

The app declares `UIBackgroundModes` = `audio` (via `just_audio_background`),
which is legitimate for an audiobook player. Reviewers expect the app to be
actively playing audio when backgrounded — it is.

## Pre-Submission Checklist

### Apple Developer / App Store Connect
- [ ] App ID `com.popupbits.listora` registered (created via API / `produce`)
- [ ] App Store Connect record created
- [ ] Distribution cert + App Store profile in the match repo (seeded once)
- [ ] Category Books / Entertainment, pricing Free
- [ ] Age rating questionnaire → 4+ (review content note)
- [ ] App Privacy → "Data Not Collected"
- [ ] Privacy policy URL live and reachable
- [ ] Review notes + contact info

### Build & Upload
- [ ] Set `APP_IDENTIFIER`, `APPLE_ID`, `TEAM_ID`, `ITC_TEAM_ID` + match/ASC secrets on the repo
- [ ] Run **Actions → iOS Release → beta** (TestFlight) or **release** (App Store)

### Screenshots (REQUIRED — universal app needs iPhone + iPad)
Rendered with **moksha** from the `integration_test/screenshot_test.dart`
captures (home, book_detail, library):
- [ ] 6.9" iPhone — 1320x2868, min 3
- [ ] 13" iPad — 2064x2752, min 3

## Build Commands

```bash
# TestFlight
cd ios && bundle exec fastlane beta
# App Store
cd ios && bundle exec fastlane release
```
