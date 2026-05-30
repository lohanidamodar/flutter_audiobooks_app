# Listora — Backlog

Optional enhancements for releases after v1.0. None of these block launch —
the v1.0 core loop (browse → search → play in background → download offline →
favourites/library) is complete.

## High value
- **Android Auto** — car playback is a major audiobook use case (media browse +
  playback over the existing `audio_service` media session).
- **Configurable skip interval** — let users choose back/forward seconds
  (currently fixed at back 10s / forward 30s in `now_playing.dart`).

## Medium value
- **Chromecast / cast** support.
- **Sleep-timer extras** — "end of chapter" option, shake-to-extend.
- **Per-book playback speed** (currently a global default + per-session speed).
- **Multiple bookmarks per book** with notes (currently a single resume point).
- **Auto-download** next chapters / whole-library download management.

## Lower value / later
- **Localization (i18n)** — currently English only; no `intl`/`.arb` wired up.
- **Onboarding / first-run intro.**
- **Equalizer / silence trimming / volume boost.**
- **Listening stats & history.**
- **Home-screen widget.**

## Tech debt
- **Built-in Kotlin migration** — blocked: Flutter 3.44 bundles Kotlin 2.0.0,
  older than the 2.3.21 we pin, and it fails to compile `background_downloader`;
  the KGP deprecation warning is also driven by third-party plugins. Revisit
  when Flutter bundles Kotlin ≥ 2.2.20 and those plugins ship built-in-Kotlin
  builds. Keep the explicit Kotlin 2.3.21 until then.
- Next Play upload must use a higher `versionCode` (currently `1.0.0+4`).
