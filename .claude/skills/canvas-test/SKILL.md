---
name: canvas-test
description: Run and extend the Prepkin Canvas test layers — unit, fake-Canvas e2e, stress, the real self-hosted Canvas sandbox, and the iOS app in the loop. Use when asked to test the extension, the bridge, the sync into the app, or to verify a Canvas-related change.
---

# Canvas test layers

Everything is documented in `design/CANVAS-TEST-PLAN.md` (scenario matrix, results,
findings). This skill is the short operating guide.

## Fast suites (no network, ~1 min total)

```bash
npm test               # 62 unit tests: extension/canvas.test.js + extension/content.test.js
npm run test:e2e       # 36 scenarios: real extension in Playwright Chromium, fake Canvas + bridge + phone
npm run test:stress    # 8 rows: timeouts, throttling, races, volume
```

Playwright and its Chromium live OUTSIDE the repo (iCloud syncs ~/Desktop):
`~/Library/Developer/prepkin-canvas-test-deps`. Branded Chrome cannot load unpacked
extensions any more; the harness uses Playwright's Chromium (`test/harness.js`).
`HEADED=1` shows the browser. If port 8443 is busy: `lsof -t -i :8443 | xargs kill`.

Rules that the harness relies on:
- The fake Canvas serves `https://localhost:8443` and `https://127.0.0.1:8443` (two schools).
- The fake bridge implements `bridge/schema.sql` exactly; `test/fake-phone.js` is the app's half.
- The extension's real action popup is driven over CDP (`test/popup.js`); opening
  popup.html in a tab is refused by the sender gate, correctly.
- Tests drive the service worker directly: `h.sw((o) => syncNow(o), origin)`.

## Real Canvas (Layer 2)

A self-hosted canvas-lms on George's Google Cloud VM (memory: canvas-sandbox-vm).
```bash
ssh -i ~/.ssh/prepkin-canvas-sandbox -N -L 3000:localhost:3000 canvas@<VM IP> &
CANVAS_TOKEN=<admin token> node --test test/live.test.js   # 6 rows, ~2 min, re-runnable
node test/compare-shapes.js                                 # real API shapes vs the fake's
```
Seed once with `design/canvas-skin/sandbox/seed.py`. Screenshots land in
`design/signoff/canvas-live/`. Stop the VM when done (console → Stop).

## The app in the loop

```bash
test/make-cert.sh prepkin-fresh      # once; trusts the lasting cert in that simulator
# point ios/Resources/bridge-config.json at https://localhost:8443 / test-key, build for
# prepkin-fresh, then RESTORE the real config (it is gitignored and George's)
PREPKIN_CERT_DIR=~/Library/Developer/prepkin-canvas-test-deps/certs node test/phone-loop.js
```
Use `prepkin-fresh`, never `prepkin-today` (George's real data). Always pass the device
name to simulator tools. The driver prints the code the app claims; write it to the
pair-code file it names; send `submit`, `focus`, `sync`, `storage`, `quit` via the cmd file.

## iOS unit tests

`cd ios && xcodegen generate && xcodebuild test -scheme PrepkinCanvas -destination
'platform=iOS Simulator,name=prepkin-fresh'`. Regenerate the project whenever a Swift
file was added (another session may be editing iOS in parallel).

## When something fails

Read the row in the plan first — most rows document a real-Canvas fact (a student cannot
backdate a submission; `missing` is only true after the due date; a sequential module
locks submissions; the sweep is "upcoming", never past due).
