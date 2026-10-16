# VLC Redesign — Implementation Plan

## 1. Scope
Rebuild VLC desktop shell per community mockups. In scope: Player shell, Library (Videos/Music/Playlists/Recent/Network), transport bar, context menu, Settings (Global + per-domain), Subtitles/Audio panels. Out of scope: mobile, streaming server, extension store.

## 2. Tech stack
Recommended: **Qt 6.6+ QML + C++ + libVLC + SQLite**.
- QML for all views in mockups (grid, sidebars,一模一样的 dark panels, equalizer sliders).
- C++ `PlayerController`, `LibraryModel`, `SettingsStore` wrapping libVLC (`libvlc_media_player_*`, equalizer, spu delay).
- SQLite for library metadata, playlists, recents, settings.
- Fallback: Tauri 2 + Rust + React + libVLC via bindings. Use only if Qt licensing/deployment blocked; cost is WebView overhead + Rust binding maintenance.

## 3. Architecture
```
QML Views (Player, LibraryGrid, SettingsPages, ContextMenu)
  -> C++ ViewModels (PlayerController, PlaylistModel, SettingsStore)
    -> libVLC (playback/audio/video/spu) + SQLite (library/settings)
```
- Single `PlayerController` owns time/seek/volume/rate state; QML binds read-only.
- `LibraryModel` scans folders, caches thumbnails async.
- `SettingsStore` QSettings-compatible schema, per-page QML + validation in C++.
- Theming via QML singleton `Tokens` (see 02-design-tokens.md).

## 4. Milestones M0-M6
- **M0 Scaffold (1 wk):** Qt6 CMake, libVLC link, QML shell + Tokens singleton, CI Linux/Win.
- **M1 Playback core (2 wk):** video surface, transport (play/stop/prev/next, seek, time labels, volume), Hide-UI mode. Exit: play local mp4.
- **M2 Library + Playlists (2 wk):** Home/Videos/Music/Network/Playlists/Recent nav, grid + breadcrumbs + search/sort, playlist create/rename. Exit: browse `The_Wand_S01` grid.
- **M3 Settings shell (1 wk):** Global Settings layout (search, App/Media/System sections, Advanced Options), theme/accent/language, toggles. Exit: persist Dark/Light/System + accent.
- **M4 Audio/Subtitles/Video (2 wk):** Equalizer (Preamp + 10 bands), spatial/stereo, subtitle track/lang/delay/speed/font/colors. Exit: EQ + spu delay round-trip via libVLC.
- **M5 Context menu + polish (1 wk):** right-click menu with shortcuts, keyboard map, i18n, a11y, empty/error states.
- **M6 Packaging (1 wk):** installers, file assoc, update check, log bundle, perf pass.

## 5. Risks
- libVLC/QML video sink integration (Wayland/X11) — spike in M0, fallback to QWidget container.
- Thumbnail scan perf on large libs — async worker + SQLite cache.
- Settings parity with legacy VLC prefs — scope to mockup pages, gate rest under Advanced.
- Accent/theme contrast (orange on dark) — verify WCAG AA for text.
