# Copy everything below the line into a new Claude Code session opened at /Users/georgeshi/Desktop/app/prepkin-canvas. Sessions C, D, E and F may run at the same time.

---

# Session E: Calendar, Inbox, from 7 / 6.5 to 10

You are session E of four that run at the same time (C course pages, D tables, E calendar and inbox,
F discussions and settings). Each has its own worktree, branch, ports and marker regions in the shared
files, so nobody overwrites anybody. Follow the parallel rules below exactly.

## Your worktree

```bash
git -C ~/Library/Developer/prepkin-worktrees/verdict fetch origin
git -C ~/Library/Developer/prepkin-worktrees/verdict worktree add ~/Library/Developer/prepkin-worktrees/skin-e -b skin/e-calendar-inbox origin/main
cd ~/Library/Developer/prepkin-worktrees/skin-e
```
Work only there. Never edit `~/Library/Developer/prepkin-worktrees/verdict` or
`/Users/georgeshi/Desktop/app/prepkin-canvas/extension`. Landing and the rsync are described at the end.

## Parallel rules (the other three sessions depend on these)

- The shared files carry marker pairs for you, `---- Session E … ----` / `---- end Session E ----`.
  Write only between your own pair: in `extension/skin.css` (the region at the end of the file),
  `extension/receipt.js` (`RULES`, one new row at most), `extension/receipt.test.js` (`TEXT_BUTTON_OK`),
  `extension/content.js` (`KEPT_CLASSES` and your `passE()` function, already called after
  `decorateLists()`), and `test/fake-canvas.js` (your `pageE(p, url)` function, tried before the page
  chain: return `{ main, side }` or null). Do not touch the receipt cap (it is 33, a budget of one row per
  session). Do not edit the modules, planner, assignments or grades rules that other passes landed today.
- New tests go in a new file `test/e-pages.test.js` (copy the harness setup from `test/receipt.test.js`:
  `stageExtension`, `FakeServer`, `h.connect`), not in `receipt.test.js`. New unit tests likewise in a new
  file next to the one they test. If you must change an existing test's expectation, say so in the commit.
- Use only your ports: fake-Canvas e2e 8711, your own test file 8712, the floor 8721,
  the mount test 8731. Your scratch temp is `PREPKIN_TMP=/tmp/prepkin-tmp-e`.
- On the sandbox, change nothing about the student (no settings, no dashboard view, no course
  favourites). Seed only content on your own pages, as admin, and only add, never delete.
- Chromium timeouts: four sessions share one machine. If a suite times out, rerun it once before you
  read it as a failure; run the mount test only when yours is the last commit.
- The scores page and the memory file are shared too: read each right before you write it, edit only
  your own cards or append your own section, publish or save once.

Read first, in this order:
1. `design/canvas-skin/PLAN-2026-09-18.md` (what landed on 2026-09-18 and why) and `DESIGN.md` (house rules).
2. The scores page: https://claude.ai/artifact/6tUGUqZsUFYhxYsFqkrGbM. Your pages are
   "Calendar", "Inbox". Read each card's Like / Don't like lists; they are the brief. Read the
   "What would lift the whole set" list too.
3. Memory: `~/.claude/projects/-Users-georgeshi-Desktop-app-prepkin-canvas/memory/gap-plan-2026-09-18.md`
   (every trap and recipe from the three passes today: text buttons, the html sweep, `decorateLists()`,
   the font-size-0 chip recipe, the header-bar lift), `a-pass-2026-09-16.md`, `streamline-icons.md`.
4. The pages already at 10 (Planner, Modules, Assignments) are the reference for shape. Open them on
   the sandbox before you design anything: group heads, chips, text buttons, ticks, the row shape.

## The goal

Each page should read as one designed product, not Canvas on new paper. A 10 means: nothing on the page is
Canvas's shape except what a student must recognise (links, the course menu, the breadcrumb); every fact is
said once; every control is ours or looks like ours; the page holds on light paper, dark stock and an image
look (Deep Sea) with no white block and no contrast miss. An empty page still looks designed.

## What is wrong today, per page (from the scores page)

Both pages are app screens, not documents: a grid and a two-pane list. The bar is to make each read as
one designed screen without touching what it does.

**Calendar** (`/calendar`; `#calendar-app .fc-view-container`, `#calendar_header`, `.fc-event`;
`skin.css` 188 and 405; 7):
- Canvas's grid: the grey weekday band (`.fc-day-header`), boxed cells. Weekday letters quiet 12px, no
  band; cell edges as hairlines in `--pk-rule`; today's cell a paper tint, not a colour; the other month's
  days at half ink. Never a filled band.
- Every chip truncates ("5:03a Quiz…"). Drop the time from the chip when the event is all-day or when
  the title needs the room; the class colour on the edge already says the class; the title gets two
  lines at most. Canvas writes the chip's text; re-say it with `data-pk-*` and `::after` only if you must.
- Week / Month / Agenda and "+" are Canvas's controls (`.calendar_view_buttons`, `#create_new_event_link`).
  A segmented control in our ink for the view (the Assignments "Show by" recipe, through the buttons
  rule), and the "+" as a quiet round button; the month name and the arrows on the same line.
- The right pane (`#calendar-list-holder`, the mini month `#minical`, the calendar list with colour
  checkboxes) is half ours already; finish it: the list rows 32px, the colour swatch as an 8px dot, the
  undated events list in the row shape.
- The events' colours are the class colours. Never repaint them (R16 asserts).

**Inbox** (`/conversations`; `[data-testid="conversation-list-container"]`,
`#inbox-conversation-holder`; 6.5):
- A row of eight icon buttons is Canvas's toolbar. Group them: Compose alone at the left as our shape
  (it is not a submit); Reply, Reply all, Archive, Delete, Mark as read, Star as a quiet strip that shows
  only when a conversation is selected; Settings at the far right. Through the buttons rule; never paint
  an InstUI button property outside it.
- The conversation row is Canvas's type. The announcements row shape: sender's face tile (initials on
  colour), name bold, subject, one preview line, date right; unread as our 8px mark on the tile; a
  hairline between rows.
- The "No Conversations Selected" envelope is Canvas's drawing. Hide it (a receipt row with a Put back)
  and put one quiet line in its place ("Pick a message on the left").
- The course filter and the mailbox select at the top are native or InstUI selects: our field shape, on
  one line with the search.
- Test on a real thread: seed one as admin if the sandbox inbox is empty (send from the teacher to alex).

## Rules that cannot move (the tests enforce them)

- Never write to Canvas. No network from the skin (data URIs only). No AI.
- Never red. One place per fact. No uppercase tracking labels. No `transform: translate`, no `font-family`,
  no `box-shadow` other than `var(--pk-lift)`. Never paint a property on a button except through the
  InstUI buttons rule (`extension/receipt.test.js` lints this: `BUTTON_RULE_GATE`).
- Text buttons: a Canvas button may become plain words only by adding its full selector to
  `TEXT_BUTTON_OK` in `receipt.test.js`, gated `html.pk-on:not(.pk-back-buttons)`, and giving it exactly
  `TEXT_BUTTON_TOKENS` (transparent ground and edge, `--pk-link`, 13/700, hover underline, focus outline).
  No by-id shortcut past the `buttonish` regex. Five exist today (Collapse All, Print Grades, the sidebar
  wide buttons, Mark All as Read); copy one.
- No commas inside `:has()` (the selector reader splits on commas). No InstUI hashed classes (`css-…`);
  match by attribute (`[class*="-avatar"]`, `[data-testid="…"]`, `[data-cid="…"]`).
- Every change to Canvas's page is a receipt row with a Put back; the cap is 29 rows (`RULES` in
  `extension/receipt.js`, the cap in `receipt.test.js`). Prefer extending an existing row's `label` and
  hook (`module-band`, `buttons`, `feedback-rows`, `due-column`, `grades-fit`) to adding one.
- Never change Canvas's words in the DOM. To re-say a number ("-/15 pts" → "15 pts"), `decorateLists()` in
  content.js writes a `data-pk-*` attribute and CSS draws it with font-size 0 + `::after`
  (`display:inline-block; line-height:16px; vertical-align:top`). A screen reader keeps Canvas's words.
- Any per-visit class of ours on `<html>` must be named in the sweep list in `applySkin` or it is
  stripped a moment later (the `pk-grades-open` trap).
- Never name an element of ours `.row` (Canvas's grid reaches in). Never draw an icon by hand; icons come
  from the look's Streamline set (`--pk-icon-<key>` vars on `html.pk-on.pk-icons-<set>`).
- A quiz being taken and a submission page get nothing from us (R18). The sign-in page is the school's.

## Tools, and how to run them

The sandbox is a real self-hosted Canvas on a GCP VM; ask me for the IP if the tunnel is down.
Canvas listens on the VM's localhost:3000 only, so everything goes through the tunnel:
```bash
while true; do ssh -o ExitOnForwardFailure=yes -i ~/.ssh/prepkin-canvas-sandbox -N -L 3000:localhost:3000 canvas@<VM IP>; sleep 20; done
```
Check it with `curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/login/canvas` (200).
Student: `alex@prepkin.test` / `PrepkinSandbox!2026`. Course 4 is AP Physics C. The student has a Spring
2026 term with two finished courses (Calculus I, World History). If the dashboard shows List View, flip it
back: `PUT /dashboard/view {"dashboard_view":"cards"}` with the `_csrf_token` cookie (recipe in memory
`gap-plan-2026-09-18.md`). Admin sign-in is in `~/canvas-admin.txt` on the VM; if the tool refuses to read
it, ask me and I will paste it. Seed more content (a second discussion, a file, an inbox thread) so you are
not designing against a one-row page.

Every run needs its own free port and the scratch temp:
```bash
export PREPKIN_TMP=/tmp/prepkin-tmp-e; mkdir -p $PREPKIN_TMP
```
- Unit + lint (fast, run after every CSS edit): `npm test` (148 tests).
- Fake-Canvas end to end: `PREPKIN_PORT=8711 npm run test:receipt` (51 tests, ~2 min). The tests that
  matter here: R16 (calendar events keep their colours), R3 (the dashboard, for the rail). Subset: `node --test --test-name-pattern="R16|R3 dashboard" test/receipt.test.js`.
- The fake Canvas (`test/fake-canvas.js`, worlds in `test/scenarios.js`) serves the dashboard, modules, the
  assignments / quizzes / announcements indexes, a quiz page and the grades pages. It serves neither the calendar nor the inbox; both need a page from a sandbox dump (the calendar is FullCalendar markup: dump the rendered month).
  To put an R-test on a page the fake lacks: dump the real page's `#content` and `#right-side` `outerHTML`
  from the sandbox (a scratch Playwright script, model on `test/pages.test.js`), trim it, add a route, then
  write the rule. A rule the fake never sees is a rule no test guards.
- The visual floor on the real sandbox (the grade):
  `PAGES=calendar,inbox MODES=light,dark,art WIDTHS=1280 PREPKIN_PORT=8721 node --test test/pages.test.js`
  It fails on any text under the contrast floor, a white block in dark or art, an invisible control, a
  broken word, uppercase, red, a painted label inside an unpainted button, or a blank page. Shots land in
  `design/signoff/canvas-pages/<page>-<mode>-1280.jpg`; read them, do not trust green alone. The floor may
  scroll a page mid-way for a control; for a clean top-of-page shot use a script (scratchpad `shoot.js`
  from 2026-09-18: login, `h.setStorage`, `h.connect`, `syncNow`, `scrollTo(0,0)`).
- Mount time under a 4× CPU throttle: `PREPKIN_PORT=8731 npm run test:mount` (skin on must stay within
  1.5× of plain Canvas + 1 s). Run it alone; other Chromiums on the machine make it time out.
- Harness facts: `PREPKIN_PORT` must be in the env when the file is required; `stageExtension` copies the
  extension at launch, so a suite mid-run never sees a later edit; rerun after the last edit. Scratch
  Playwright scripts need `NODE_PATH=~/Library/Developer/prepkin-canvas-test-deps/node_modules`
  (Playwright, not Puppeteer). Computed `display` of a child under `display:none` stays `block`: test
  `getClientRects().length`.
- Icons: recipe in `design/canvas-skin/icons/` (`repick.py` picks by exact name per family, `gen2.py`
  writes the CSS block, `fromcss.py` rebuilds `sets/` from the block in skin.css; `sets.json` names the
  light and dark family per set). To add an icon, add a key to `Q` and `P` in `repick.py`, run it per
  family slug, regenerate, paste the block over the old one (it starts at `/* Icon sets:`). Base URL
  `https://public-api.streamlinehq.com/v1/`, header `x-api-key`, 1000 requests an hour; the key is mine,
  ask for it and keep it in the shell env only. Line families need `strokeWidth=2.6`; `strokeToFill` and
  `strokeWidth` together return 400.
- References, when a shape is in doubt: Mobbin and Refero are connected. Search "calendar month", "inbox", "email list". Fantastical and Notion Calendar for the month; Superhuman and Hey for the two-pane inbox.

## How to work

1. For each page: read the shot, list what is Canvas's shape, decide the one shape it should take, write
   the CSS (or a small pass in your `passE()`), add a test in your own test file (with a fake page in
   your `pageE()` where none exists), `npm test`, run the R subset, run the floor for that page in all
   three modes, read the shots. Commit per page with a plain message (no URLs in messages; use
   `git commit -F file` if the message has an apostrophe).
2. Order: Calendar first, then Inbox.
3. Show me, don't tell me: after each page, a before/after crop (light and Deep Sea) as an image in chat,
   one line under it. Keep chat under 100 words.
4. Landing, after the last page:
   ```bash
   git fetch origin && git rebase origin/main
   npm test && PREPKIN_TMP=/tmp/prepkin-tmp-e PREPKIN_PORT=8711 npm run test:receipt
   git push origin HEAD:main
   ```
   If the push is rejected because main moved, rebase and push again. A rebase conflict means someone
   wrote outside their region: resolve it keeping both sides, run the tests, and tell me which file.
   Then sync my folder only from the main worktree, and only if it is clean:
   ```bash
   git -C ~/Library/Developer/prepkin-worktrees/verdict status --porcelain
   git -C ~/Library/Developer/prepkin-worktrees/verdict pull --ff-only
   rsync -a --delete ~/Library/Developer/prepkin-worktrees/verdict/extension/ /Users/georgeshi/Desktop/app/prepkin-canvas/extension/
   ```
   If `status` prints anything, skip the pull and the rsync and tell me. Then tell me to reload the
   extension and the page.
5. Update the memory file `gap-plan-2026-09-18.md` (read it first, append a section named "Session E",
   what moved and any new trap), and republish the scores page
   (https://claude.ai/artifact/6tUGUqZsUFYhxYsFqkrGbM: read it with the Artifact tool right before, edit
   only your cards, rescore honestly, publish once) with fresh shots. If a page is still not a 10, say
   what is left and why.
