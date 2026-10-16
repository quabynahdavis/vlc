# i18n stubs (M6)

User strings in QML are wrapped in `qsTr()` (default context = file name).
`main.cpp` installs a `QTranslator` stub on `SettingsStore.language` change:

- `English` — built-in, no `.qm` needed.
- `French` / `German` / `Spanish` — stub entries: no `.qm` ships yet, so the
  app logs `M6 i18n: no .qm ... (stub: English fallback)` and keeps English.
- `Pseudo-RTL (test)` — no translation either, but flips
  `QGuiApplication::setLayoutDirection(Qt::RightToLeft)` so RTL mirroring of
  every `RowLayout` / anchor can be checked without a translation file.

## Workflow (follow-up)

```sh
lupdate app -ts app/i18n/vlc-redesign_fr.ts   # extract qsTr() strings
linguist app/i18n/vlc-redesign_fr.ts          # translate
lrelease app/i18n/*.ts                        # build .qm
# then wire qt_add_translations(... TS_FILES ...) so they embed as :/i18n/
```

The two `.ts` files below are checked-in extraction placeholders so the
pipeline shape is visible before any translator runs. Real `.qm` bundling +
per-locale QA is the remaining follow-up.
