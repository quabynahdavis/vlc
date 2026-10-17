# VLC Redesign — 04 Mini Player (M7)

## 1. Scope
Frameless compact player sharing the main `PlayerController` / `MediaPlayer` instance. No re-buffer, no second pipeline. All 4 triggers user-locked — implement all, gate each behind a setting.

## 2. Activation triggers (all required)

| # | Trigger | Entry point | Condition |
|---|---------|-------------|-----------|
| T1 | Manual | `Ctrl+M`, `View > Mini Player`, titlebar compact button | Always available when media loaded |
| T2 | Minimize-to-mini | OS minimize event during playback | `state == Playing`, `triggers.minimize == true` |
| T3 | In-app PiP | Navigate to Library / Settings / any non-Player route while video playing | `state == Playing && hasVideo`, `triggers.navigate == true`; main view swaps to route, mini spawns floating |
| T4 | Close-to-mini | Window `X` while playing | `state == Playing`, `triggers.closeToMini == true` (default ON); collapses to mini instead of quit. If paused/stopped, `X` quits normally |

Deactivation: `Esc` or Restore button → return to main Player view at same position. `Quit` action inside mini → full app quit.

## 3. Window spec
- Size: `360×140` default, resizable; remember size/position per `sizeMemory`.
- Chrome: frameless, floating (`Qt.Tool | FramelessWindowHint | WindowStaysOnTopHint` when `alwaysOnTop`), rounded `12px`, `bg-1` surface, 1px `#333` border.
- Always-on-top toggle (pin icon); default **ON** in mini, independent of main window setting.
- Drag anywhere (empty area + artwork) to move; double-click toggles restore.
- Theme: Dark/Light aware via `Tokens` singleton; accent-bound controls.

## 4. Layout (360×140)
```
[art 64px] [title 14 semibold / episode 12 fg-2 ] [pin][restore][close]
           [prev][play][next] [cur time / scrubber / total] [volume]
```
- Artwork `64×64`, radius 8; fallback cone icon.
- Title: filename / show `S01E02`-style; elide right.
- Controls: prev/play/next (play = accent filled circle), linear scrubber (accent fill, same binding as main), time labels mono tabular, volume slider + mute, restore (`⤢`), close (`×`).
- Accessible names: `Mini player`, `Play/Pause`, `Previous`, `Next`, `Seek`, `Volume`, `Restore player`, `Close`. Minimal focus trap: `Tab` cycles within mini; `Esc` restores.

## 5. Behavior / sync
- Same `PlayerController` instance as main: `QML MiniPlayerView` binds `time`, `duration`, `playing`, `volume`, `mediaTitle`, `artwork` read-only; all commands (`play/pause/seek/volume/prev/next`) delegate to controller.
- No re-buffer: video surface reparented (or second `VideoOutput` sharing same `libvlc_media_player_t`); audio uninterrupted.
- Scrubber/time live-synced with main (same `positionChanged` signal, throttle ≤ 4 Hz for labels, slider live).
- Restore lossless: position ±250 ms, same track/sub/audio delay/EQ state, playlist index unchanged.
- T3 in-app PiP: mini is the *only* video surface while browsing Library/Settings; closing mini while in another route pauses nothing — video keeps playing audio-only until restore.
- Quit in mini: `closeToMini` bypass — explicit `Quit` menu item / `Ctrl+Q` / mini close-button long-press menu → `QCoreApplication::quit()`.

## 6. Settings schema + UI
`SettingsStore` key `appearance.miniPlayer`:
```json
{
  "enabled": true,
  "triggers": { "manual": true, "minimize": true, "navigate": true, "closeToMini": true },
  "alwaysOnTop": true,
  "sizeMemory": { "w": 360, "h": 140, "x": -1, "y": -1 }
}
```
- `appearance.closeToMini` (bool, default ON) is the T4 master switch, surfaced under Appearance as well.
- Settings UI (`Settings > Interface`, Appearance section): rows —
  - `Mini Player` master toggle,
  - `Show on minimize` / `Show when browsing library` / `Close button collapses to mini` checkboxes,
  - `Always on top in mini mode` toggle.
- Persist via existing `SettingsStore` round-trip (QSettings/SQLite); no separate file.

## 7. Implementation notes
- New QML: `MiniPlayerView.qml` + `MiniPlayerControls.qml`; C++: `MiniPlayerController` (thin proxy → `PlayerController`) or direct binding — prefer direct binding, no duplicated state.
- Window management: `QQuickWindow` subclass or second `ApplicationWindow` with flags; handle `changeEvent(QEvent::WindowStateChange)` for T2, `closeEvent` intercept for T4, route-change signal for T3.
- Reuse `Tokens` radii/colors; reuse transport slider component.

## 8. Exit criteria (M7)
- [ ] All 4 triggers work and each is individually toggleable.
- [ ] Restore lossless (position, track, playlist index) via T1–T4.
- [ ] Playback uninterrupted (no re-buffer gap on enter/exit).
- [ ] `qmllint` clean, CMake build clean, no new warnings.
