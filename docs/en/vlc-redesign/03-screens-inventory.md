# VLC Redesign — Screens Inventory

Source dir: `VLC Redesign (Community)/`.

## P1 — Player shell (`Player.png`, `Player-1..4.png`)
- Top bar: cone, `...`, layout toggle, `Videos` breadcrumb, `VLC Media Player` title, window controls.
- Left rail: Home/Videos/Music/Network/Playlists/Recent/Add-item; or compact icon rail (Player.png variant).
- Center: video canvas (dark #2A2A2A); playlist panel variant with Create playlist / Cool Songs / Anime to Watch.
- Bottom transport: prev/play/next, current `00:02:10` + seek bar (orange fill), total `00:25:40`, volume, EQ/sub/settings/queue icons.
- States: empty, playing, library-grid overlay.

## P2 — Library grid (`Player-1.png` = Videos > Shows > The Wand > S01)
- Breadcrumb, 15 items count, sort/grid/search/`...`, thumbnail cards with filename, orange progress on watched (`S01E01-04`).
- Reuse for Videos/Music/Recent; list/grid toggle.

## P3 — Global Settings (`Settings - global.png`)
- Left nav: Search; App (General/Interface/Privacy/Controls), Media (Playback/Video/Audio/Subtitles/Library), System (Network/Performance/Recording/Extensions).
- Right: Appearance (language dropdown, Dark/Light/System segmented, 9 accent swatches), Startup toggles, Diagnostics (dev mode, log file + Browse, log level), Advanced Options expander.

## P4 — Audio / Equalizer (`Settings - audio.png`)
- Equalizer OFF/ON, preset dropdown (None), 11 vertical sliders: Preamp/60Hz/170Hz/310Hz/600Hz/1KHz/3KHz/6KHz/12KHz/14KHz/16KHz with dB chips; Two-pass, Spatial audio, Stereo widening toggles; spatial mode dropdown.

## P5 — Subtitles (`Subtitles.png`)
- Tabs: Playback/Video/Audio/Subtitles(active). Sections: Defaults (track, language), Synchronization (delay -10..+10s slider + numeric, speed, duration factor), Appearance (embedded-format toggle, font=Inter, text #B8B8B8, outline #0C0C0C), Default Preset + Open Advanced Settings.

## P6 — Context menu (`right-click menu.png`)
- Play(Space)/Stop(S)/Previous(P)/Next(N)/Record(R)/Hide UI(Ctrl+\), submenus Playback/Video/Audio/Subtitle/Playlist/Open Media, Quit (Ctrl+Q). Orange icons, right-aligned hints/chevrons.

## P7 — Component states (`Property 1=expanded*.png`, `Frame 151*.png`, `Frame 159*.png`, `name=disc/ui*.png`)
- Expanded/collapsed rows, Dark swatch, toggle dot, disc/UI icon two-tone on/off. Implement as QML component states, not separate screens.
