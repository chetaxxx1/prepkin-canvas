# Prepkin for Canvas — release pass (the session after the ten steps)

Work in `~/Library/Developer/prepkin-worktrees/verdict` (branch main, pushed at 1149431f). Read
`design/canvas-skin/PLAN-2026-09-14.md` §6 first: it is the ledger of what landed on 2026-09-14
(tick done, Looks tiles, planner by day, the floor at two widths, Firefox) and what was left.
Then do these, in this order, one commit each, plain words in every message to me (under 100
words, the numbers, what broke).

## 1. Prove nothing regressed where the day's tests could not see

- `npm run test:schools` — the harvested themes of 137 real schools on the sandbox. The
  surfaces rules in `extension/skin.css` changed a lot on 09-14 (InstUI tables, calendar,
  files, the four button carve-outs). Every school must still pass. Fix through surfaces
  rules only; never a `css-` hash, never a property on a button outside `TEXT_BUTTON_OK`.
- `CANVAS_TOKEN=<admin token> node --test test/live.test.js` on the sandbox: the real hand-in
  path with the new `done` map. Then make `live.test.js` delete what it creates (teacher
  session + `_csrf_token`) so the ~30 "Live: submit then grade" assignments in course 4 stop
  leading every list; clear the existing ones the same way.
- `npm run test:variants` if it still exists and runs.
- Report the counts. If the sandbox is under load 200+, run subsets and say so.

## 2. Ship it

- Bump `extension/manifest.json` to 0.7.0. `bridge/package.sh` for the Chrome zip. Tell me
  where the zip is; I upload. Update `README.md` and the store listing text
  (`design/canvas-skin/` or wherever the listing copy lives; grep "Chrome Web Store") for the
  new things a student sees: the circle, the tiles, the planner by day, "Next in this class".
  No "receipt" in any student-facing string.
- The phone: `ios/` has `CanvasItem.doneAt` (5ddfcac). Build for the ONE shared simulator
  `Prepkin` (id 7D3E10A4-C1D0-4DC1-BD83-C7181B1D556E; `xcodegen generate` first; never make
  another device), run the full iOS suite (608; `ContentTests.testTracksComeOutInCatalogueOrder`
  was already failing on main, the lessons catalogue gained a seventh track: fix that test if
  the track is real), and tell me what a TestFlight build needs from me.
- Firefox: `npm run test:firefox` must pass (needs `selenium-webdriver` + `geckodriver` in
  `~/Library/Developer/prepkin-canvas-test-deps`). Then list what an AMO submission needs
  (signing, the data-collection manifest key, the source for the minified Sprout bundle) and
  stop; do not submit.

## 3. Small debts from the ledger

- `bridge/art-pack.sh`: write a `wallpaper-thumb.webp` (480×270) per image theme and make the
  Looks tiles use it (`tileTokens` in `extension/receipt.js`, `--twall`). Prove with the R27
  assertions and the mount check (`mount.looks` in the floor's report).
- The floor's skin-off mount read 60 s once (a sandbox stall). Make the mount check retry a
  stalled load once before it compares, and say in the log which loads stalled.

## 4. Then a fresh second look

Shoot the dashboard, a course home, Modules, Grades, Files, Calendar in both papers at 1280
on the sandbox with the skin on (the floor's shots in `design/signoff/canvas-pages/` are the
start), put them on one page, and grade each against the references in
`VERDICT-2026-09-14.md` §4 (Finch rows, Todoist planner, Contra tiles, Imprint headings).
Say what is still B and why, in one line each. No fixes in this step; a list for me.

## Rules that cost time last session (from memory, all true)

- Tunnel: `ssh -i ~/.ssh/prepkin-canvas-sandbox -N -L 3000:localhost:3000 canvas@34.121.59.86`
  in a `while true; do …; sleep 3; done` loop; it drops. Stop the VM when you are done.
- `PREPKIN_PORT=8445` (floor) / `8447` (fake suites) / `8448` (Firefox); never `pkill -f
  "test-concurrency"` (it kills every node --test, including another shell's run).
- `PREPKIN_TMP=<your scratchpad>/tmp` for Chromium profiles; `/tmp` and scratchpads get wiped
  by cleanup sessions, so copy anything durable into the repo the same hour.
- A Firefox match pattern with a port is silently invalid; `cqw` on the container itself reads
  its ancestor; `body [class*="pk-"] *`, never `[class*="pk-"] *`.
- The auto-mode classifier refuses commit messages that carry a URL. Plain messages commit.
- Every commit: unit (`npm test`), receipt, e2e, stress green; the floor for any page touched.
