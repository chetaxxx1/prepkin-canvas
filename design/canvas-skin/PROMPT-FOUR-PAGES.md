# Prompt: take the Planner, Modules, Course grades and All grades from 8.5 to 10

Copy everything below the line into a new Claude Code session opened at
`/Users/georgeshi/Desktop/app/prepkin-canvas`.

---

Work in the git worktree `~/Library/Developer/prepkin-worktrees/verdict` (branch main, pushed).
Do not edit `/Users/georgeshi/Desktop/app/prepkin-canvas/extension` directly; at the end,
`rsync -a --delete <worktree>/extension/ /Users/georgeshi/Desktop/app/prepkin-canvas/extension/`
and tell me to reload the extension and the page.

Read first, in this order:
1. `design/canvas-skin/PLAN-2026-09-18.md` (what landed today and why) and `DESIGN.md` (house rules).
2. The scores page: https://claude.ai/artifact/6tUGUqZsUFYhxYsFqkrGbM — the four pages I mean are
   "Planner tab", "Modules", "Course grades", "All grades". Each scored 8.5. Read the Like / Don't like
   lists; they are the brief.
3. Memory: `~/.claude/projects/-Users-georgeshi-Desktop-app-prepkin-canvas/memory/gap-plan-2026-09-18.md`,
   `a-pass-2026-09-16.md`, `streamline-icons.md` (traps, the icon recipe, the API key note).

## The goal

Each of the four pages should read as one designed product, not Canvas on new paper. A 10 means:
nothing on the page is Canvas's shape except what a student must recognise (links, the course menu,
the breadcrumb); every fact is said once; every control is ours or looks like ours; the page holds on
light paper, dark stock and an image look (Deep Sea) with no white block and no contrast miss.

## What is wrong today, per page (from the scores page)

**Planner tab** (`extension/planner.js` `renderPlanner`, `extension/skin.css` `#pk-planner`):
- "Later · 1" and "Missing, older · 4" are folded lines that read as afterthoughts under the days.
  Give the folds one shape with the day groups (same heading, a count chip, a chevron) or move them.
- "+ Add a task" is the only mint button and sits far right of the title. Decide where the one action
  lives (Todoist's Upcoming puts it at the foot of Today). One place, one shape.
- The past-due band says "Still counts: 100 points across 1 class." Dense. Say it in the row's meta.
- The GPA block is good. The grade rows under "Grades" duplicate the /grades page: keep them, but the
  heading "Grades" and the block should look like the day groups above (same type scale).

**Modules** (`extension/skin.css`, the `/* ---- rows: one row shape` block and `module-sticky`):
- Canvas's orange in-progress / green complete circles at the right of each row (`.module-item-status-icon i`)
  read as warnings. Replace with our tick outline (the `.pk-tick` shape from the planner) in the quiet ink,
  filled mint when complete. Never red or orange.
- "Collapse All" is a Canvas button stranded top right in its own 90px bar (`#content .header-bar:has(#expand_collapse_all)`).
  Put it in the title row as a quiet text button, or fold it into the first module header.
- The locked module's dimmed rows are a touch faint on Deep Sea. Check contrast on `.locked_title`.
- The row-type icons (page, assignment, quiz…) come from the look's icon set; make sure the 26px tile
  behind them is visible on all three modes (it is `var(--pk-paper-sunk)`; on the image look it can vanish).

**Course grades** (`/courses/:id/grades`, `extension/planner.js` `renderGradesPage`, `plGradeRow`):
- Canvas's right column repeats our total ("Total: 70.71% (C−)"), shows "Show All Details", and explains
  what-if in a paragraph. One place per fact: fold that column under the same "Show Canvas's table" link,
  or hide it with a put-back (the `grades-page` receipt row already covers the table; extend it).
- "Print Grades" is a Canvas button in the title row. Quiet text button, or fold it.
- Two text nodes fail the contrast floor on Deep Sea (found 2026-09-18 by `test/pages.test.js`, mode art,
  page grades). Run the floor, read the two nodes, fix them.
- The what-if row ("Aiming for B B− C+ C · The final is worth __ % · Set") is good but tall; try one line.

**All grades** (`/grades`, `allGradesPage()`):
- Sixty per cent of the page is empty at 1280. Either widen the sheet to the content column, or give the
  right side a reason: the finished-courses fold could sit beside the rows, or the GPA block could.
- "Show Canvas's table" is a tiny link. Make it the same quiet text button as the other folds.

## Rules that cannot move (the tests enforce them)

- Never write to Canvas. No network from the skin (data URIs only). No AI.
- Never red. One place per fact. No uppercase tracking labels. No `transform: translate`, no `font-family`,
  no `box-shadow` other than `var(--pk-lift)`. Never paint a property on a button except through the
  InstUI buttons rule (`extension/receipt.test.js` lints this: `BUTTON_RULE_GATE`, `TEXT_BUTTON_OK`).
- No commas inside `:has()` (the selector reader splits on commas). No InstUI hashed classes (`css-…`).
- Every change to Canvas's page is a receipt row with a Put back; the cap is 28 rows (`RULES` in
  `extension/receipt.js`, the cap in `receipt.test.js`). Raise it only for a real new change.
- Never name an element of ours `.row` (Canvas's grid reaches in).

## Tools, and how to run them

The sandbox is a real self-hosted Canvas on a GCP VM; ask me for the IP if the tunnel is down.
Canvas listens on the VM's localhost:3000 only, so everything goes through the tunnel:
```bash
while true; do ssh -o ExitOnForwardFailure=yes -i ~/.ssh/prepkin-canvas-sandbox -N -L 3000:localhost:3000 canvas@<VM IP>; sleep 20; done
```
Check it with `curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/login/canvas` (200).
Student: `alex@prepkin.test` / `PrepkinSandbox!2026`. Course 4 is AP Physics C (modules, grades).
The student has a Spring 2026 term with two finished courses (Calculus I, World History) for the GPA.
If the dashboard shows List View, flip it back: `PUT /dashboard/view {"dashboard_view":"cards"}` with the
`_csrf_token` cookie (a recipe is in memory `gap-plan-2026-09-18.md`).

Every run needs its own free port and the scratch temp:
```bash
export PREPKIN_TMP=/tmp/prepkin-tmp; mkdir -p $PREPKIN_TMP
```
- Unit + lint (fast, run after every CSS edit): `npm test` (148 tests).
- Fake-Canvas end to end: `PREPKIN_PORT=8461 npm run test:receipt` (49 tests, ~2 min). The tests that
  matter here: R27 (planner), R31 (/grades), R38 (fold + GPA), R40 (row shape), R3 (modules), R18 (a quiz
  page gets nothing from us). Run a subset with `node --test --test-name-pattern="R27|R31|R38|R40" test/receipt.test.js`.
- The visual floor on the real sandbox (the grade):
  `PAGES=dashboard-planner,modules,grades,all-grades MODES=light,dark,art WIDTHS=1280 PREPKIN_PORT=8471 node --test test/pages.test.js`
  It fails on any text under the contrast floor, a white block in dark or art, an invisible control, a
  broken word, uppercase, red, a painted label inside an unpainted button, or a blank page. Shots land in
  `design/signoff/canvas-pages/<page>-<mode>-1280.jpg`; read them, do not trust green alone.
- Mount time under a 4× CPU throttle: `PREPKIN_PORT=8446 npm run test:mount` (skin on must stay within
  1.5× of plain Canvas + 1 s; today it is faster on three of four pages).
- Harness facts: `PREPKIN_PORT` must be in the env when the file is required; `stageExtension` copies the
  extension at launch, so a suite mid-run never sees a later edit — rerun after the last edit. Scratch
  Playwright scripts need `NODE_PATH=~/Library/Developer/prepkin-canvas-test-deps/node_modules`. A model
  for a shoot script is `test/pages.test.js` (login, `h.setStorage`, `h.connect`, `syncNow`).
- The fake Canvas (`test/fake-canvas.js`, worlds in `test/scenarios.js`) must carry any Canvas markup a
  new rule depends on, or R-tests will not see it. Real markup: dump `outerHTML` on the sandbox first.
- Icons: every look names an icon set (`themes.js icons`). To add or change an icon, use the Streamline API
  recipe in `design/canvas-skin/icons/` (`repick.py` picks by exact name, `gen2.py` writes the CSS block);
  the API key is George's, ask for it. Never draw an icon by hand.
- References, when a shape is in doubt: Mobbin and Refero are connected (search "planner", "grades",
  "course modules"). Todoist Upcoming and Structured were the planner's references; Things 3 for folds.

## How to work

1. For each page: read the shot, list what is Canvas's shape, decide the one shape it should take, write
   the CSS (or planner.js) change, add or extend an R-test, `npm test`, run the R subset, run the floor for
   that page in all three modes, read the shots. Commit per page with a plain message (no URLs in messages;
   use `git commit -F file` if the message has an apostrophe).
2. Show me, don't tell me: after each page, a before/after crop (light and Deep Sea) as an image in chat,
   one line under it. Keep chat under 100 words.
3. At the end: push to origin main, rsync into my folder, update the memory file
   `gap-plan-2026-09-18.md` with what moved and any new trap, and republish the scores page
   (https://claude.ai/artifact/6tUGUqZsUFYhxYsFqkrGbM: read it first with the Artifact tool, then edit
   the four cards and rescore honestly) with fresh shots. If a page is still not a 10, say what is left
   and why.
