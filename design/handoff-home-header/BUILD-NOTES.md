# Build notes — Home header band

Built 2026-09-13 from `README.md` (direction **A · Eyebrow**). Port by Codex
(`codex-home-band-brief.md`), reviewed by Cursor (`REVIEW-cursor.md`: no findings), proven on
the simulator by Claude Code. Landed as cefbcdd.

**What changed** — `ios/Sources/HomeView.swift` only, 9 lines in, 13 out: `levelBand` (the
ink-8% plate, 17pt pips) became `eyebrow` (13pt `StarPips`, words in `Theme.mutedInk`), and the
header's outer `VStack` went from `spacing: 12` to `alignment: .leading, spacing: 5`. Goals row,
`Edit` pill, quiet line, copy and padding untouched. No new tokens, no test needed (copy did not
change; `HomeCopyTests.swift` does not exist).

**Deviations from the canvas:** none.

**Alternate B (chip)** is on the canvas, not built.

## Shots — `shots/built-*.jpg`, iPhone 17 Pro, iOS 26.5, simulator `prepkin-band`

- [x] a · no laptop paired — two stars, "190 to the next", four habits, no quiet line
- [x] b · empty day — "Nothing due today", "Last list from your laptop 2h ago.", Tomorrow line
- [x] c · normal evening — two goals left, "From your laptop 2h ago."; the Tomorrow line now clears the tab bar
- [x] d · all done — "All goals done today"
- [x] e · one star, seven goals — "Ready for the next star"
- [x] xl · accessibility XXXL — eyebrow words scale, pips stay 13pt, nothing shares a row
- `built-sheet.jpg` is all six side by side.

`make-states.py <udid> <base-state.json> a b c d e xl` seeds and shoots them. Two facts it
depends on, both new since the 2026-09-10 driver: the app falls back to the **sample Canvas feed
whenever `bridge-config.json` is missing from the bundle** (a worktree build has none — copy
`ios/Resources/bridge-config.json` into the built `.app` before `simctl install`), and the
**widget offer card** shows unless `widgetOfferDone` is true in the save.
