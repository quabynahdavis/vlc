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

## Packaging notes (M0 → M1)

- **Linux AppImage:** `linuxdeploy` + `linuxdeploy-plugin-qt` + manual `libvlc.so*` and `/usr/lib/vlc/plugins` into `usr/lib/`. Set `VLC_PLUGIN_PATH` or keep relative `plugins/`.
- **Windows WiX:** `windeployqt` + libVLC DLLs/plugins → WiX v4 `heat` harvest → MSI. Keep `plugins/` hierarchy intact; VLC fails silently if missing.
- **macOS DMG:** `macdeployqt MyApp.app -qmldir=app` + VLC dylibs/plugins + `create-dmg`. Notarize for Gatekeeper.
- Always ship the exact `plugins/` matching the bundled `libvlc` version; mixing 3.x/4.x breaks load.
