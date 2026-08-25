# Agent notes — dui

- DUB `dui`; repo `dlang-supplemental/dui`
- Depends on `dew` (engine). Touch/hit-test live in dew; dui adds State + DuiApp
- Prefer registry `dew` `~>0.1.3` after that tag exists; path `../dew` is fine for local co-dev
- Keep `VERSION` and `DUI_VERSION` in sync (string import uses `DUI_VERSION`)
- Legacy DUB `rmgui` was removed — never depend on it
- Categories: `library.gui`
