# Agent notes — dui

- DUB `dui`; repo `dlang-supplemental/dui`
- Depends on `dew` (engine). Touch/hit-test/focus live in dew; dui adds State + DuiApp + forms/nav/gestures
- Co-dev: `path="../dew"` + CI sibling checkout; before DUB tag flip to registry `dew` `~>0.1.4`
- Keep `VERSION` and `DUI_VERSION` in sync (string import uses `DUI_VERSION`)
- Legacy DUB `rmgui` was removed — never depend on it
- Use `DuiApp.tap` in tests (buttons click on pointer Up)
- Categories: `library.gui`
