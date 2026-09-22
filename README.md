<div align="center">
  <img src="assets/logo.png" alt="Loftify logo" width="96" />
  <h1>Loftify</h1>
  <p>A Material 3 LOFTER client built with Flutter, for Android and Windows</p>
  <p>
    <img alt="Version 2.6.1" src="https://img.shields.io/badge/version-2.6.1-14C2BB?style=flat-square" />
    <img alt="Flutter 3.x" src="https://img.shields.io/badge/Flutter-3.x-027DFD?style=flat-square" />
    <img alt="Android" src="https://img.shields.io/badge/platform-Android-3DDC84?style=flat-square" />
    <img alt="Windows" src="https://img.shields.io/badge/platform-Windows-0078D6?style=flat-square" />
    <img alt="MIT license" src="https://img.shields.io/badge/license-MIT-9E9E9E?style=flat-square" />
  </p>
  <p><a href="README_CN.md">简体中文</a></p>
</div>

---

## Overview

Loftify is an unofficial third-party client for [LOFTER](https://www.lofter.com),
built with Flutter. This repository is a personal fork of
[Robert-Stackflow/Loftify](https://github.com/Robert-Stackflow/Loftify): it
tracks upstream and layers a Material 3 Expressive redesign, tablet layouts,
performance work and fixes on top. It is maintained for personal use and is
not intended to be merged back.

The application id of this fork is `com.loftify.yatmt`, so it installs side by
side with other builds.

## Highlights

### Material 3 design

- Full Material 3 visual language: seeded tonal color schemes, semantic
  color/motion/typography tokens, Material 3 components across the app
- Floating bottom navigation with three switchable placements: centered pill,
  bottom-right dock, or full-width dock
- Collapse/expand of the floating bar runs on a single animation clock with
  Material emphasized easing and a scroll hysteresis threshold, so the morph
  stays smooth and never jitters
- Reduced-motion, high-contrast and reduced-transparency fallbacks on every
  animated surface

### Built for tablets

- Portrait tablets use the phone shell with the floating bottom bar;
  landscape tablets use a Material 3 NavigationRail side shell
- Content layouts stay width-adaptive: multi-column feeds, two-column profile
- The post reader is content-first on tablets: the post takes the full column
  and recommendations follow below (the resizable two-pane split stays
  desktop-window only)

### Reading and tag tools

- Long-press (or right-click) any tag chip to shield it; one-tap otome
  content filter on the tag shield page
- LLM tag classification with persistent per-class filters and automatic
  classification of new posts
- Tag pagination chains server-provided offsets with per-page auto retry, so
  long tags keep loading instead of silently stopping
- Material 3 search bar with live suggestions that no longer rebuild the page
  on every keystroke

### Performance

- No full-page opacity save-layers while swiping between posts; dialogs and
  bottom sheets drop full-screen backdrop blur in favor of the Material scrim
- Hand-rolled button/tooltip/ink animation stacks replaced by Material 3
  `IconButton`, `FilledButton`, `AlertDialog`, `ModalBottomSheet` and
  `SnackBar`
- Lottie compositions are shared per asset and parsed in a background
  isolate; heavy like/celebrate animations are prewarmed at startup
- Feed images decode at layout size through a bounded decode pipeline; theming
  is memoized per theme instance

### Update checks

- Startup checks this repository's GitHub Releases by default and offers the
  update dialog with the changelog (configurable in general settings)
- Manual "Check for Updates" entry on the About page

## Download

Grab the latest build from the
[Releases](https://github.com/Yar1991-Translation/Loftify/releases) page:

| Platform | Artifact | Direct link |
| --- | --- | --- |
| Android | arm64-v8a APK | [Loftify-2.6.1-android-arm64.apk](https://github.com/Yar1991-Translation/Loftify/releases/download/v2.6.1/Loftify-2.6.1-android-arm64.apk) |
| Windows | x64 archive | [Loftify-2.6.1-windows-x64.zip](https://github.com/Yar1991-Translation/Loftify/releases/download/v2.6.1/Loftify-2.6.1-windows-x64.zip) |

## Features

| Capability | Status |
| --- | --- |
| Home recommendation feed | Supported |
| In-tag recommendations | Supported |
| Block articles and videos | Supported |
| Subscriptions (tags, collections, grain lists) | Supported |
| Search | Supported |
| Original image saving | Supported |
| Collections and grain lists | Supported |
| Likes, recommendations, collections, history | Supported |
| My works and my grain lists | Supported |
| Personal homepages | Supported |
| Update checks | Supported |
| Gesture / PIN lock | Supported |
| Publishing posts | Planned |
| Managing favorites and collections | Planned |

## Build from source

Prerequisites: Flutter stable (Dart 3.6+) with the Windows desktop and
Android toolchains.

```bash
flutter pub get

# Android (single-ABI release APK)
flutter build apk --release --target-platform android-arm64

# Windows
flutter build windows --release
```

Development switches, passed with `--dart-define`:

| Switch | Effect |
| --- | --- |
| `DEMO_MODE=true` | Runs the whole app on canned test data, no account or network needed |
| `FORCE_MOBILE_LAYOUT=true` | Forces the phone layout on desktop builds |

```bash
flutter run --dart-define=DEMO_MODE=true
```

The project ships 730 widget and unit tests; run them with `flutter test`.

## Known issues

- Huawei devices show a blank screen since 2.4
- Duplicated content on tag pages; grid layout option pending

## Changelog

See the in-app changelog (About page) or the
[Releases](https://github.com/Yar1991-Translation/Loftify/releases) page.
The changelog is maintained from version 2.6.0 onward.

## Credits

- Upstream project: [Robert-Stackflow/Loftify](https://github.com/Robert-Stackflow/Loftify)
- LOFTER is a product of NetEase. This client is unofficial and not
  affiliated with or endorsed by NetEase.

## License

[MIT](LICENSE), Copyright (c) 2022 Robert-Stackflow and contributors.
