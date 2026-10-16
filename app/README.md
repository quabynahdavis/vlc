# VLC Redesign — M0 hello-video (`app/`)

Minimal Qt6.6+ QML + C++ + libVLC + SQLite scaffold.

- Black video stage + minimal transport bar (prev/play/next, `00:02:10 / 00:25:40`, scrubber `Slider`).
- Dark theme `bg #0E0E0E`, orange accent `#D37918` via `Ds/Theme.qml` singleton.
- `main.cpp`: `QGuiApplication` + `QQmlApplicationEngine`, libVLC version log stub, CLI arg forwarded to QML as `initialSource` (stub ok).
- CMake requires `Qt6 Quick + Multimedia + Sql` and `libvlc`.

This folder is the only M0 scaffold. Do NOT touch `VLC Redesign (Community)/` assets or `docs/en/`.

## Requirements

| Dep | Min | Notes |
|-----|-----|-------|
| Qt | 6.6+ (tested 6.12) | Quick, Multimedia, Sql + dev tools (`rcc`, `moc`, `qmltyperegistrar`) |
| libVLC dev | 3.x (`libvlc-dev`) | headers `vlc/vlc.h` + `libvlc.so` |
| SQLite | 3.x | via `Qt6::Sql` (sqlite driver `QSQLITE` ships with Qt); system `libsqlite3` optional for direct use |
| CMake | 3.21+ | |
| Ninja | any | or Make / MSVC / Xcode |
| C++17 compiler | GCC 11+ / Clang 14+ / MSVC 2022+ | |

Check:

```sh
cmake --version
qmake6 --version        # expect Qt 6.6+
pkg-config --modversion libvlc
```

## Build — Linux

```sh
# Debian/Ubuntu
sudo apt install qt6-base-dev qt6-multimedia-dev qt6-declarative-dev \
  libvlc-dev vlc cmake ninja-build g++ pkg-config

cmake -S app -B /tmp/opencode/vlc-m0-build -G Ninja
cmake --build /tmp/opencode/vlc-m0-build
/tmp/opencode/vlc-m0-build/vlc-redesign-m0 [video.mp4]
```

`libvlc.so` + plugins resolve from system (`/usr/lib`, `/usr/lib/vlc/plugins`). No bundling needed for dev. For distribution use AppImage (see below).

## Build — Windows

1. Install Qt 6.6+ via Qt Online Installer (check `Qt Quick`, `Qt Multimedia`, `Qt SQL`).
2. Install VLC SDK: download matching-arch `vlc-<ver>-win64.7z` from VideoLAN, extract to e.g. `C:\VLC-SDK`.
   Or install full VLC (ships `libvlc.dll`, `libvlccore.dll`, `plugins/`).
3. Configure (x64 Native Tools or Qt Creator env):

```powershell
cmake -S app -B build -G "Ninja" `
  -DCMAKE_PREFIX_PATH="C:\Qt\6.8.0\msvc2022_64" `
  -DVLC_SDK_PATH="C:\VLC-SDK"
cmake --build build
.\build\vlc-redesign-m0.exe [video.mp4]
```

**Bundling:** ship `libvlc.dll`, `libvlccore.dll`, and `plugins/` next to the `.exe`. Qt deploy first:

```powershell
windeployqt --qmldir app build\vlc-redesign-m0.exe
# then copy libvlc*.dll + plugins\ beside exe
```

WiX Toolset v4/v5 can wrap the folder into an MSI (see Packaging).

## Build — macOS

```sh
# Qt via online installer or:
brew install qt@6 cmake ninja pkg-config

# VLC: install VLC.app (provides libvlc.dylib + plugins), headers from VLC SDK dmg
# or: brew install --cask vlc
cmake -S app -B build -G Ninja \
  -DCMAKE_PREFIX_PATH="$(brew --prefix qt@6)" \
  -DVLC_SDK_PATH="/Applications/VLC.app/Contents/MacOS"
cmake --build build
./build/vlc-redesign-m0 [video.mp4]
```

**Bundling:** use `macdeployqt` then copy `VLC.framework` / `libvlc.dylib`, `libvlccore.dylib`, `plugins/` into `MyApp.app/Contents/MacOS/` (or `Frameworks/` + `rpath` fix with `install_name_tool`). Then `create-dmg` for `.dmg`.

## CLI

```sh
./vlc-redesign-m0                 # hello-video stage, demo 00:02:10 / 00:25:40
./vlc-redesign-m0 movie.mp4       # M0 stub: forwarded to QML MediaPlayer preview
```

Real libVLC render (`libvlc_media_player_set_*`, hw output) lands in M1+.

## Layout

```text
app/
  CMakeLists.txt   # Qt6 Quick/Multimedia/Sql + libVLC, qml module VlcM0
  main.cpp         # QGuiApplication, QQmlApplicationEngine, libVLC stub
  Main.qml         # stage + transport bar
  Ds/Theme.qml     # singleton tokens (bg-app/surface, text, accent)
  README.md        # this file
```

## Packaging (M6: CMake install + CPack stub)

`cmake --install` + `cpack` produce a TGZ/DEB (Linux), ZIP/WIX (Windows), or
DMG (macOS) smoke artifact from the exact tree below. Store-grade installers
wrap the same payload per-OS:

```sh
cmake -S app -B /tmp/opencode/vlc-m6-build -G Ninja
cmake --build /tmp/opencode/vlc-m6-build
cmake --install /tmp/opencode/vlc-m6-build --prefix /tmp/opencode/vlc-m6-root
cmake --build /tmp/opencode/vlc-m6-build --target package   # CPack TGZ/DEB
```

Install tree: `bin/vlc-redesign-m0`, `share/doc/vlc-redesign-m0/README.md`,
`share/vlc-redesign-m0/i18n/*.ts`.

- **Linux AppImage:** `linuxdeploy` + `linuxdeploy-plugin-qt` + manual `libvlc.so*` and `/usr/lib/vlc/plugins` into `usr/lib/`. Set `VLC_PLUGIN_PATH` or keep relative `plugins/`.
- **Windows WiX:** `windeployqt --qmldir app build\vlc-redesign-m0.exe`, copy `libvlc.dll`, `libvlccore.dll`, `plugins\` beside the exe → WiX v4 `heat` harvest → MSI. Keep `plugins/` hierarchy intact; VLC fails silently if missing.
- **macOS DMG:** `macdeployqt MyApp.app -qmldir=app` + VLC dylibs/plugins + `create-dmg`. Notarize for Gatekeeper.
- Always ship the exact `plugins/` matching the bundled `libvlc` version; mixing 3.x/4.x breaks load.

Follow-ups: code signing (all OSes), `.qm` bundling via `qt_add_translations`
(`app/i18n/*.ts` → `:/i18n`), VLC plugins payload in CPack, signed update
feed.

## Auto-update (M6 stub)

Settings → Startup → *Check for updates automatically* (default OFF) +
*Check now*. The stub feed always reports "up to date"; a startup check runs
when the toggle is ON. Real HTTPS feed + signature verify + installer
relaunch lands after M6.

## Privacy (M6)

Telemetry defaults **OFF** (Settings → Privacy → *Share anonymous usage
statistics*, opt-in). M6 ships no network telemetry client — the toggle only
persists the preference. Crash reports always ask first.

## Diagnostics (M6)

Settings → Diagnostics: *Save a log* (default ON) writes to the log-file path
(default `~/.local/share/VLC/"VLC Redesign"/vlc-redesign.log`); *Log details*
defaults to **Errors only** (file keeps Critical/Fatal; Warnings/Info/Debug
opt in, console always keeps a copy). *Export log bundle* writes a
plain-text bundle (settings dump + last 200 log lines) for bug reports —
`.zip` compression is a follow-up. `Logger::selfTest()` logs one line per
level for filter QA.

## Keyboard map (M6 audit: 13/13 wired)

| Keys | Action |
|------|--------|
| Space | Play / pause |
| S | Stop |
| P / N | Previous / next item |
| R | Record (red REC badge + mm:ss) |
| Ctrl + \\ | Hide / show UI (Escape also exits Hide-UI) |
| Ctrl + Q | Quit |
| Ctrl + , | Open Global Settings |
| Ctrl + E | Effects dock |
| Ctrl + T | Subtitles panel |
| Ctrl + O | Open network stream |
| Ctrl + 1 / Ctrl + 2 | Player / Library view |

E/T stay Ctrl-modified on purpose: bare E/T would fire while typing in
library search, URL, and settings fields (`WindowShortcut` context), matching
real VLC (Ctrl+E Adjustments). Every control is Tab-focusable with a 2px
accent focus ring (`Ds.Theme.focusRing`); modal dialogs trap focus (search /
URL / name field focused on open, Escape closes).

## Accessibility (M6)

Icon buttons, sliders (name + live value), grid cards (name + episode +
watched %), toggles (row label + ON/OFF), and dialogs (role + name) expose
`Accessible.*`; toasts use a live-region alert; the record badge, stage state,
and volume wedge announce text equivalents. Canvas-only art (thumbnail
doodles, volume wedge, cone) always has a text counterpart.

## i18n (M6)

All user strings use `qsTr()`; Settings → Appearance → *Interface language*
drives a `QTranslator` stub (`English` built-in; French/German/Spanish fall
back to English until `.qm` ships — see `app/i18n/README.md` for the
`lupdate`/`linguist`/`lrelease` workflow). *Pseudo-RTL (test)* flips
`QGuiApplication` layout direction so `LayoutMirroring` row/anchor mirroring
can be checked with English strings. Known gap: the settings-taxonomy
`ListModel` labels stay English — `ListElement` forbids script calls, so
those rows need a model rebuild on language change (follow-up).
