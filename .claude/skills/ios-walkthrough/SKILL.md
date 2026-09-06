---
name: ios-walkthrough
description: Run the Prepkin iOS UI/UX test loop. Use when asked to walk through, audit, shakedown, or sweep the iPhone app, check a screen after a change, or find what looks off or is broken. Covers simulator rules, coordinates, the sweep script, the lint, comparables, severity words, and where findings go.
---

# iOS walkthrough

The loop is: sweep (script) → look (contact sheets) → poke (idb taps on the flows) →
compare (Mobbin/Refero) → file (Broken / Weak / Polish, one line each, with a file:line).

## Simulators

- `prepkin-fresh` `5982E2BF-C16C-4243-B049-26D1FA73FC07` is the test phone. Use it.
- `prepkin-today` `6D4CE1F6-6E5F-47C3-9EEA-52BB2DD5B66A` is George's real data. Screenshots only, never taps, never a reinstall, unless he says so.
- `prepkin-blank` `0DC4140E-0EE8-4B9D-A26A-99B3EA19763B` is for first run: erase it (`xcrun simctl erase`) and install, and the name → pick three → Day 1 flow shows. prepkin-fresh is paired and has a save, so it never shows first run.
- `idb` takes about a minute to answer on a sim that just booted (its companion spins up). A hung first call is that, not a wedge. macOS has no `timeout`; wrap idb in `python3 subprocess.run(..., timeout=45)` when probing.
- Two booted sims plus a build starve the tank web view of memory. Shut one down first.
- Build: `cd ios && xcodegen generate && xcodebuild -scheme PrepkinCanvas -destination "id=<udid>" build` then `xcrun simctl install <udid> <path/PrepkinCanvas.app>`. DerivedData stays at the Xcode default, never inside the repo (iCloud).
- If Swift changes show but JS/SVG changes do not, it is the WKWebView cache. See memory `sprout-embed-contract`.

## Driving it

- `test/ios-sweep.sh [udid] [outdir]` does light + dark + accessibility-XL for all six tabs, Shop and Your day, writes contact sheets and a lint (targets under 44pt, unlabeled buttons/images). Default output `design/screenshots/sweep-<date>/`.
- `test/ios-firstrun.sh` erases prepkin-blank, installs the built app and walks name → pick three → Home → first coin, asserting each step.
- `test/ios-flows.sh [udid] [focus lesson shop yourday task]` drives whole flows and asserts on labels; a failed step saves `FAIL-<flow>-<step>.png`. It relaunches the app first so a stale sheet cannot fail a run.
- One-off: `idb ui tap X Y --udid U`, `idb ui swipe`, `idb ui text`, `idb ui describe-all` (JSON accessibility tree with point frames). `xcrun simctl io U screenshot f.png`.
- Coordinates are points on iPhone 17 Pro (402 x 874). Tab bar y=812; x = 36 Home, 102 Focus, 168 Games, 234 Learn, 300 Friends, 366 Kin. Home coin chip 326,81. Edit your day 369,429.
- The Claude simulator panel screenshots are 919px wide: px ÷ 2.286 = pt. Prefer `idb` and `simctl` screenshots (1206 wide, ÷ 3).
- Dark mode: `xcrun simctl ui U appearance dark|light`. Text size: `xcrun simctl ui U content_size accessibility-extra-large|medium`. Always restore.
- Reduce motion has no simctl switch; toggle it in Settings > Accessibility > Motion on the sim.

## What to check on every screen

1. Does it fit: nothing clipped at either edge, nothing under the tab bar, nothing truncated with "…".
2. Does it say the truth: no promise without a backend, no banned words (sync, bridge, selector, behind), no "?" tiles, no timers or streak scolding (PRODUCT.md).
3. Can it be tapped: every control ≥ 44pt, every image or button has a label, disabled states still readable.
4. Does it hold in dark mode and at accessibility text sizes (the app forces light and fixed type; note what breaks anyway).
5. Does it feel like one app: same paper, chip, button and card language as Home (Theme.swift).
6. Motion: any animation needs George's GIF sign-off before it ships (memory `animation-approval`).

## Comparables

Mobbin (`mcp__mobbin__search_screens`, platform ios) and Refero (`mcp__refero__refero_search_screens`). Name the app to filter: Finch (pet + goals home), Duolingo (leagues, first run), Forest and Opal (focus), Headspace (calm empty states). Pull 4 to 6 screens, say in one line what each does better, never paste their layout.

## Filing

Severity words are shared with the extension work: **Broken** (a student hits it, no special state), **Weak** (works but reads unfinished or untrue), **Polish**. One line each, with `File.swift:line`. Prior lists live in `design/release-prompts.md` and the "Prepkin Shakedown" artifact; check them so nothing is re-found. Design calls (not code fixes) become a Claude Design prompt: `design/CLAUDE-DESIGN-PREAMBLE.md` + one screen per prompt, queued in `design/CLAUDE-DESIGN-QUEUE.md`.
