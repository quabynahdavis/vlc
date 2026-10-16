# VLC Redesign — Design Tokens

Extracted from `Player.png`, `Settings - global/audio.png`, `Subtitles.png`.

## Colors (dark default)
- `bg-0` #0C0C0C (app chrome), `bg-1` #1A1A1A (sidebar/panels), `bg-2` #242424 (cards/inputs), `bg-3` #2E2E2E (hover).
- `fg-1` #FFFFFF (headings), `fg-2` #B8B8B8 (body/labels), `fg-3` #7A7A7A (hints, shortcuts).
- `accent` #FF8800 (VLC orange; play button, sliders, active tab underline, toggles ON). Accent variants row: red/yellow/green/cyan/blue/purple/pink/gray — implement as `accent-*` swappable.
- `success` #3FB950, `danger` #F85149, subtitle text #B8B8B8 on outline #0C0C0C.
- Theme modes: Dark (default), Light (`bg-0` #F5F5F5, `fg-1` #111111), System (follow OS).

## Typography
- Family: **Inter** (confirmed in Subtitle Font field). Fallback: system sans.
- Scale: title 20/28, section 18/26 semibold, body 14/20, caption 12/16, mono for timecodes/dB (tabular nums).
- Time labels `00:02:10` / dB chips `12.0 dB` use tabular figures.

## Spacing / Layout
- Base 4px. Sidebar w 280, panel padding 24, card gap 16, grid gap 16, input h 44.
- Top bar h 40, transport bar h 56.

## Radii / Borders / Motion
- Radii: buttons/inputs 8, cards/thumbnails 12, sidebar 12, toggles full-round, sliders 4 track / full thumb.
- Borders: 1px #333 on inputs/cards; focus 2px accent.
- Motion: 120ms hover, 200ms panel/expand, ease-out. Sliders/toggles immediate.
- Icons: two-tone outline + orange active state (`*-two-tone=yes/no` assets).
