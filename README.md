# Loftify (Personal Fork)

A LOFTER third-party app built with Flutter.

This is my personal fork of [Robert-Stackflow/Loftify](https://github.com/Robert-Stackflow/Loftify) — it tracks upstream, then layers my own Material 3 Expressive redesign, performance work and bug fixes on top. It is not intended to be merged back.

## What's different in this fork

### Material 3 Expressive UI

- Full M3E visual pass: seeded color schemes, tonal surfaces, semantic color
  tokens, motion tokens and M3 typography ("Quiet Content Atelier" direction)
- The bottom navigation bar floats as a pill above the content; scrolling
  down morphs it into a circular button docked to the bottom-right corner,
  and tapping it (or scrolling up) expands it again
- Selected destinations expand into an active indicator that carries their
  label; badge counts clamp at 99+
- Reduced-motion, high-contrast and reduced-transparency accessibility
  fallbacks for every animated surface

### Performance

- Scoped `MaterialApp` rebuilds: provider notifications (tab switches,
  pushes, token updates) no longer rebuild the whole app
- `ThemeData` construction is memoized per theme instance
- Lottie compositions are shared per asset, parsed in a background isolate,
  and the heavy like/celebrate animations are prewarmed at startup
- No `Opacity` saveLayer over the frosted navigation bar while it hides;
  fade route pages are isolated in repaint boundaries
- Feed images decode at layout size through a bounded decode pipeline

### Bug fixes

- Fixed posts failing to render with
  `FormatException: Invalid empty scheme` when no source url is available,
  plus scheme-less (`://x`, `//x`) urls inside content attributes and CSS
- Fixed the login captcha rendering cropped and unreadable

# Features

- [x] Recommended features
  - [x] Home page recommendation flow
  - [x] Support blocking articles/videos
  - [x] Recommendations within tags
- [x] Subscription function
  - [x] Subscribed tags
  - [x] Subscribed collections
  - [x] Subscribed food orders
- [x] Support search function
- [x] Save original image
- [x] Support collection and food list functions
- [x] Support my likes, my recommendations, my collections, and my footprints
- [x] Support my works, my collections, my food list
- [x] Support personal homepage
- [x] Support checking for updates
- [x] Support gesture password
- [ ] Support creative
  - [ ] supports publishing posts
  - [ ] Support managing favorites
  - [ ] Support management of food orders
  - [ ] Support management collections

# Known bugs

- Huawei devices show a blank screen since 2.4
- Duplicated content on tag pages; grid layout option

# Build

- Flutter stable (Dart 3.6+)
- `flutter build apk --release` for Android; desktop targets build with the
  usual `windows`/`linux`/`macos` commands

# License

MIT, same as upstream. LOFTER is a product of NetEase; this app is an
unofficial client and is not affiliated with NetEase.
