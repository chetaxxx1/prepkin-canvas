# Prepkin for Canvas: one cohesive product — brief for Codex

How to run (from the repo root, on George's Mac, Codex logged in):

```bash
cd /Users/georgeshi/Desktop/app/prepkin-canvas
git worktree add ~/Library/Developer/prepkin-worktrees/codex-cohesion -b codex/cohesion main
cd ~/Library/Developer/prepkin-worktrees/codex-cohesion
/Applications/ChatGPT.app/Contents/Resources/codex exec --full-auto --skip-git-repo-check - < design/CODEX-EXTENSION-COHESION-PROMPT.md
```

Or open the worktree in the Codex app and paste everything below the line. Codex commits
on its branch; George reviews with `git log --oneline main..codex/cohesion` and the
screenshots, then merges. Playwright and its Chromium live outside the repo
(`~/Library/Developer/prepkin-canvas-test-deps`); if `npm run test:e2e` says Chromium is
missing, `cd ~/Library/Developer/prepkin-canvas-test-deps && npx playwright install chromium`.

---

Make the Prepkin Chrome extension in this repo (`extension/`) one cohesive product: one
visual language on every surface a student meets, one place for every fact, every
feature finished end to end or removed, nothing that reads as bloat. You are editing a
product that already works at 137 real schools (`design/signoff/canvas-schools/every-canvas.html`);
you are making it read as one thing. The bar is the apps students already love, named
below, held at the size they ship at.

## What "cohesive" means here, in checkable terms

1. **One look.** One radius scale, one type scale, one spacing scale, one icon language,
   one row shape, one button shape, across the popup, the side panel, the dashboard rail,
   the Planner and Looks tabs, the receipt rows, the first-run steps and the ⌘K palette.
   Today the extension has grown surface by surface; the iOS app went through this exact
   pass (`design/prepkin-look.html`, and `Theme.Radius` 10/14/20/28 in `ios/`) and the
   extension has not.
2. **One place per fact.** What is due appears in exactly one place per screen. "Still
   counts" is said once per screen. A count is said once.
3. **Every feature has a home or is gone.** `content.js` still carries `panelView`,
   `weekView`, `looksView`, `whatIfView`, `courseView`, `addTaskView`, `recapView`,
   `gradesCard`, `leagueCard` from the pop-out panel that was removed on 2026-09-12
   (`design/canvas-skin/EXTENSION-FEATURES.md` §H). What-if, the course view and the term
   recap have no home. Give each a home inside the Planner tab or delete it; nothing stays
   half-alive.
4. **The page belongs to the school.** Everything the skin changes is on the receipt with
   Undo. Nothing in this brief adds a request from a Canvas page, a web font, a property on
   a button, or a selector with a `css-` hash.

## Read first, in this order

1. `PRODUCT.md`, `DESIGN.md` — the voice, the tokens (OKLCH warm neutrals, one accent, one
   amber for "still counts", never red), the copy rules (no "!", no engineering words to a
   student).
2. `design/canvas-skin/EXTENSION-FEATURES.md` — §A what exists, §G the Mobbin pass (each
   surface and the app it was held against), §H the planner pass and what the pop-out's
   removal left homeless. This is the map of the product as it is on `main`.
3. `design/canvas-skin/STEAL-BRIEF.md` and `research-bettercampus-likes.md` — what students
   love (to-do + dark mode + grades *is* the product) and what drove them off BetterCampus
   (bloat 34 people, AI 19, theme editor 18, paywall 16, forced updates 14, a contrast
   checker refusing their theme 13, an extension that broke a final exam). Every item you
   add is measured against "bloat".
4. `design/EXTENSION-SIMPLIFY-PROMPT.md` — the 2026-09-12 B+→A subtraction list. It was
   built on branch `canvas-subtract` (not merged; `main` went the other way and removed
   the pop-out panel). Items 1–8 still describe the duplicates to remove; apply them to
   `main`'s shape, not the branch's.
5. `git show 24f856c 01bc96f 1c8a691 54a8791` on branch `canvas-subtract` — **the Finch
   pass George picked** (from three built at ship size: Things, Todoist, Finch): plain-word
   headings, one rounded row per piece of work with a tile in the class colour and its
   first letter, amber cards for slipped work, one mint button, a grouped settings list, no
   uppercase tracking labels anywhere. Port the *shape*, by hand, onto `main`'s surfaces.
   Do not merge the branch; it conflicts with `main` on purpose.
6. `design/canvas-skin/RESEARCH.md` §3 (per-page anatomy) and §4 (the technical floor:
   the selector ladder, `--ic-brand` strategy, SPA behaviour, iframes, course colour, the
   accessibility settings a skin must not fight) and `SPEC-RECEIPT.md` §9, §10, §12 (what
   the receipt must not fight, the papers and the AAA floor, what it refuses).
7. `design/CANVAS-SKIN-PERFECT-PROMPT.md` — the per-page checklist (subtract, fix, buttons,
   quizzes, reading contrast, one visible title, SPA, cost, preferences). Use it as the
   acceptance test for step 5 below.
8. `extension/README.md`, then the code: `selectors.js` (every Canvas selector, nowhere
   else), `receipt.js`, `themes.js`, `boot.js`, `content.js` (`applySkin`, `detectKill`,
   `renderWeek`/the rail, `decorateCards`, `spritePlace`/`placeSprite`, the storage
   listener), `planner.js` (the Planner and Looks tabs; runs before `content.js`, only its
   plain function declarations reach the world — Annex B), `popup.html`/`popup.js`,
   `sidepanel.html`/`sidepanel.js`, `day.js` (`voice()`, the day buckets), `skin.css`,
   `panel.css`.
9. The tests, all green on `main` except R27 (a pre-existing Planner drag failure — fix it
   in step 3): `npm test` (143), `npm run test:e2e` (39), `npm run test:stress` (10),
   `npm run test:receipt` (36; R18 reads every `skin.css` selector off disk and proves none
   touches a quiz being taken), `CANVAS_UPSTREAM=none npm run test:schools` (135 real
   schools' themes on the fake pages, offline, ~15 min). Keep every one green after every
   commit. `extension/copy-sweep.test.js` fails on any "!" or banned word in a student-facing
   string.
10. `design/CANVAS-TEST-PLAN.md` Round 10 — what was learned about every school: one Canvas
    build everywhere, themes are public and now in `test/schools/`, Canvas's request bucket,
    right-to-left Canvas, and the traps (Stanford's synchronous script, widened nav rails).

## References, and exactly what to take from each

Look at each in Mobbin (mobbin.com) or the app itself at 1× before touching the surface.
Take the mechanic named; leave the rest.

| Surface | Reference | Take this and only this |
|---|---|---|
| Every list of work (rail, side panel, popup Due next, Planner day columns) | **Finch** goals list; **Things** Today | One row shape: 44px tall, 12px radius, class tile (first letter, class colour) at left, title one line cut at a word, date or "was due" at right in the quiet ink. Slipped work: the same row on the amber ground. Nothing else on the row. |
| Page and section headings | **Imprint** | Plain words in the body face at 17/600, air above (24px) and a little below (8px). No uppercase, no letter-spacing, no eyebrow labels. |
| The one loud moment per screen | **TikTok**'s single accent moment, **Duolingo**'s payoff | Exactly one: the mint Start button on the rail; the "+30" float on hand-in; the ring completing. Everything else quiet. |
| The rail (dashboard right column, ~176px inner) | **Finch** Home (the pet stands in a scene above its list) | Tank → his one line → Start with (one row, one mint button) → Then (three rows) → foot in words. No ring, no 7-day strip, no legend. |
| Planner tab (week) | **Todoist** Upcoming, **Structured** | Days as columns, today outlined, amber band above for slipped, drag to plan, Plan on hover. Cards are the row shape above, stacked. One "+ Add a task" per week, not per day. |
| Focus | **Oura** session | Task on top, time inside the ring, "Ends at", two quiet words (+5 min, Stop). Already built; make its card the same radius, type and tile as the rest. |
| Looks tab (theme shop) | **Numo** covers | Yours first, worn one ticked, Locked with a price, six on the sheet then "More". The tile is the paper itself, no mascot on tiles. |
| ⌘K palette | **Linear** | Grouped before typing (Classes, Canvas pages), key hints at the foot, one ranked list while typing. Already built; match the row shape. |
| Popup (the store screenshot) | **Things** Today, **Finch** | Sprout, the name, the coin chip; "Due next" rows; one button "Open the side panel"; "What changed on this page" folded with its count; settings as a grouped list. Two green buttons never. |
| Side panel | **Todoist** | Today / Still counts / This week / Missing as four plain headings over the row shape. Reads storage, never fetches. |
| Receipt rows | **iOS Settings** grouped list | One row per change: what was taken or fixed, Undo at right, "Show me" as a text link. Undo all at the foot. |
| First run | **Arc**'s first-run (three cards, one action each) | Keep the three steps as they are; only the type, radius and button shape join the rest. |
| Dark mode | **Things** dark, **Bear** | Warm charcoal papers already measured (`themes.js`). Every surface above must read on Carbon at 7:1 body ink. Print the measured numbers in the theme cards. |

What NOT to take from anyone: BetterCampus's theme editor, AI anything, streak numbers,
badges, a notes box, hover previews that fetch, sounds, confetti (one ring completing is
enough), anything that lags a quiz.

## Rules of the house (non-negotiable; the tests enforce most of them)

- Every Canvas selector lives in `extension/selectors.js` with page and confidence. Never a
  selector containing `css-`. Never `!important` against Canvas's own rules except on
  `:root` custom properties. A rule whose hook is missing must be a no-op, never a broken
  page.
- Never a property on `button`, `[type=submit]`, `input[type=submit]`, `[role=button]`.
  Never `font-family`. Never a shadow or hover lift on Canvas's own elements. Never red.
  Never hide a course tab, only dim. Never touch `hide_dashcard_color_overlays`, a hero's
  opacity, or the course colour.
- Nothing runs on `/quizzes/N/take`, New Quizzes, submission pages, or with High Contrast
  on (R18, `killReason`). Keep those proofs green.
- The panel host `#prepkin-buddy` lives in a closed shadow root; the Sprout frame
  `#prepkin-sprout` must never sit inside anything that re-renders. In right-to-left
  Canvas the panel flips to the buddy's right (`data-flip`); keep that.
- No request leaves a Canvas page except to the school's own API and the bridge. No web
  fonts. Course pictures stay local.
- Copy: no "!", no "buddy" (it is Sprout), no "receipt" to a student ("What changed on this
  page"), "Undo" not "Put back", "still counts" once per screen, plain words a college
  student already knows. `copy-sweep.test.js` is the gate.
- Reads go six at a time (`inTurns`) and a throttled answer waits; do not add parallel
  fetches.
- Skin edits: never cut a `skin.css` block by slicing between two markers; rebuild from
  `git show HEAD:extension/skin.css` plus your hunks and check `.pk-card-due {` is still
  there. Re-run R18 after every `skin.css` change.
- Do not touch `ios/`, `bridge/`, the pairing flow, the kill switches, the themes catalogue's
  papers, `test/schools/` fixtures, or `manifest.json` permissions.

## The work, in order, one commit per numbered item, tests green after each

**1. The token sheet.** Add `extension/tokens.css` (or a `:host`/`html.pk-on` block at the top
of `panel.css` and `skin.css` — one source, imported nowhere else) with: radius 8/12/16/20,
type 13/15/17/22 with weights 400/600, spacing 4/8/12/16/24, the row height 44, the tile
24, one hairline, the inks and papers from `themes.js`. Replace every literal radius, size
and gap in `panel.css`, `popup.html`'s styles, `sidepanel.html`'s styles and the `.pk-*`
rules in `skin.css` with the tokens. Add `extension/tokens.test.js`: no `border-radius`,
`font-size` or `gap` literal in those files outside the token block. Files: `panel.css`,
`skin.css`, `popup.html`, `sidepanel.html`, new `tokens.test.js`, `package.json` test line.

**2. The row.** One `.pk-row` (tile, title, right text; amber variant; link variant with
Start on hover as R26 has today) rendered by one function in `day.js` or a new
`extension/row.js` that `content.js`, `planner.js`, `popup.js` and `sidepanel.js` all
call. Replace the four hand-rolled row markups. Port the Finch shape from the
`canvas-subtract` commits. Unit-test the renderer (title cut at a word, tile letter, amber
only when slipped, the Start link only when pending). Files: new `row.js` (+ manifest
`content_scripts` order in `background.js` `CONTENT_SCRIPTS`, and the popup/side panel
script tags), `content.js`, `planner.js`, `popup.js`, `sidepanel.js`, `panel.css`.

**3. The Planner tab finished, R27 green.** Fix the drag-to-plan failure R27 reports
("planned onto a day"). Then give the homeless views a home or delete them: what-if lives
under the Grades card in the Planner (one line "Aim for A: needs 91 on the final"), the
course view becomes the Grades card's expanded state, the term recap shows only at term
end where the rail is. Delete `panelView`, `weekView`, `looksView`, `addTaskView` and their
tests if nothing reaches them after this; `content.js` should lose at least 400 lines.
Files: `planner.js`, `content.js`, `content.test.js`, `test/receipt.test.js` (R27).

**4. Subtraction on main's shape** — `design/EXTENSION-SIMPLIFY-PROMPT.md` items 1–8,
re-read against `main`: one list per place (rail on the dashboard, side panel elsewhere,
popup = Due next; the ⌘K palette drops "Due soon"); the rail at five things (no strip, no
ring; the done count in the foot, in words); one due line per card with "+2 more"; the
popup as Due next with one button; the words (Sprout, Undo, "What changed on this page",
"Tidy Canvas"); the past-due wall at three rows + "N more"; six themes then More; 32px
controls. One commit per item, 4a–4h. Files as the simplify prompt lists them, mapped to
`main` (`planner.js` where it says `panelView`).

**5. Every page, the checklist.** Run `design/CANVAS-SKIN-PERFECT-PROMPT.md`'s checklist on
the sandbox if the tunnel is up (`ssh -N -L 3000:localhost:3000 canvas@<VM IP>`; student
`alex@prepkin.test` / `PrepkinSandbox!2026` at `https://localhost:8443/login/canvas` through
`node test/fake-canvas.js 8443 --upstream http://127.0.0.1:3000`) or on the fake pages
(`test/fake-canvas.js` alone) if not — and say which. Dashboard, course home, modules,
assignment, grades, assignments index, calendar, courses index, a classic quiz index, the
inbox: light and Carbon, 1280 and 768 wide. Fix only through the surfaces rule in
`skin.css` ("surfaces, not pages"); never a page-specific hack. One visible title per page.
Files: `skin.css`, `selectors.js` (new hooks with page and confidence), `receipt.js` (a new
row for anything new the skin takes or fixes).

**6. The cohesion sheet.** `node design/canvas-skin/gallery/build.js` then
`OUT=design/screenshots/cohesion-<date> node design/canvas-skin/gallery/shoot.js`, plus the
live popup, side panel and dashboard (`SURFACES=1 node design/site-shots/shoot.js` on the
sandbox, or your own Chromium through `test/harness.stageExtension`). Assemble one PNG at
1×: popup, side panel, rail, Planner, Looks, receipt, first run, ⌘K, light row above, dark
row below. That sheet is the deliverable George judges; anything on it that is a different
radius, type size, row shape or heading style from its neighbours is not done.

## Prove it

- `npm test`, `npm run test:e2e`, `npm run test:stress`, `npm run test:receipt`,
  `CANVAS_UPSTREAM=none npm run test:schools` green at the end, and the first four green
  after every commit. New tests: the token lint; the row renderer; the Planner drag; the
  panel/planner shows no due rows outside its one list; the popup renders Due next from a
  synced world; a card with three items renders one line and "+2 more"; "buddy",
  "receipt", "Put back" in no student-facing string.
- The counts on the after screenshots: places that show the number of tasks due, and places
  that say "still counts" — one each per screen.
- Contrast: body ink on every paper ≥ 7:1, links ≥ 4.5:1, measured (`themes.js` already
  measures; print the numbers).
- The cohesion sheet, before and after, side by side.

## Finish with

A short report in `design/signoff/cohesion-<date>/REPORT.md`: the sheet (before/after), the
counts, the test totals, the list of commits one per numbered item, what was deleted (with
line counts), and anything you left because a rule above forbade it. Plain words, under a
page. No summary of your process.
