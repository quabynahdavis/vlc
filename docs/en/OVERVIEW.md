# VLC Redesign — English Docs Overview

Scope: Implement community VLC redesign (dark, modern) as desktop app. Source mockups in `VLC Redesign (Community)/` (26 assets: Player, Settings, Subtitles, context menu, icon states).

Stack (recommended): Qt 6.6+ QML + C++ + libVLC + SQLite. Fallback: Tauri 2 + Rust + React.

## File index

- `vlc-redesign/01-implementation-plan.md` — scope, stack decision, architecture, milestones M0-M6, risks.
- `vlc-redesign/02-design-tokens.md` — colors, typography (Inter), spacing, radii, motion.
- `vlc-redesign/03-screens-inventory.md` — screen-by-screen inventory mapped to source PNGs.
