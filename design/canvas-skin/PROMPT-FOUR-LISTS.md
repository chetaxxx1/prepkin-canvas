# Prompt: take the Dashboard, Assignments, Announcements and Quizzes from 8 to 10

Copy everything below the line into a new Claude Code session opened at
`/Users/georgeshi/Desktop/app/prepkin-canvas`. Sister prompt: `PROMPT-FOUR-PAGES.md`
(Planner, Modules, Course grades, All grades). Run them in separate sessions; both work
on branch main in the same worktree, so pull before you start and commit per page.

---

Work in the git worktree `~/Library/Developer/prepkin-worktrees/verdict` (branch main, pushed).
Do not edit `/Users/georgeshi/Desktop/app/prepkin-canvas/extension` directly; at the end,
`rsync -a --delete <worktree>/extension/ /Users/georgeshi/Desktop/app/prepkin-canvas/extension/`
and tell me to reload the extension and the page. Another session may be working on the Planner,
Modules and grades pages in the same worktree: `git pull` first, do not touch `planner.js`
functions for those pages, and rebase before pushing.

Read first, in this order:
1. `design/canvas-skin/PLAN-2026-09-18.md` (what landed on 2026-09-18 and why) and `DESIGN.md` (house rules).
2. The scores page: https://claude.ai/artifact/6tUGUqZsUFYhxYsFqkrGbM — the four pages I mean are
   "Dashboard", "Assignments", "Announcements", "Quizzes". Each scored 8. Read the Like / Don't like
   lists; they are the brief. Read the "What would lift the whole set" list too: table header bands,
   stranded buttons, Canvas primaries, status marks and empty states all show up on these four pages.
3. Memory: `~/.claude/projects/-Users-georgeshi-Desktop-app-prepkin-canvas/memory/gap-plan-2026-09-18.md`,
   `a-pass-2026-09-16.md`, `streamline-icons.md` (traps, the icon recipe, the API key note),
   `dashboard-rail.md` (rail order, 206px, specificity traps).

## The goal

Each of the four pages should read as one designed product, not Canvas on new paper. A 10 means:
nothing on the page is Canvas's shape except what a student must recognise (links, the course menu,
the breadcrumb); every fact is said once; every control is ours or looks like ours; the page holds on
light paper, dark stock and an image look (Deep Sea) with no white block and no contrast miss.
A list page with one row should still look designed, not empty.

## What is wrong today, per page (from the scores page)

**Dashboard** (`extension/content.js` cards + `renderPastFold` in `planner.js`; `extension/skin.css`
`.ic-DashboardCard*` near line 156 and 232, `#right-side` near 125, `.recent_feedback` near 720):
- Recent Feedback under the rail is still Canvas's list in three type styles (`.events_list.recent_feedback`,
  receipt row `feedback-rows`). Give it the rail's row shape: one line per item, class colour on the
  edge, the grade as our chip. Same type scale as "This week" above it.
- "Finished courses · 2" (`.pk-past`) sits small and alone under four cards. It should share a shape
  with the Planner's group heads (heading, count chip, chevron), or sit at the foot of the card grid
  as a full-width quiet row.
- The four card action icons (announcements, assignments, discussions, files) are Canvas's line set,
  not the look's. Every look names an icon set (`themes.js icons`); the row-type masks already exist
  for assignment, discussion and file in the icon block of `skin.css`. Reuse them on
  `.ic-DashboardCard__action` with a mask, the same way `gen2.py` does for `i.icon-*`. Add an
  "announcement" icon to each of the six sets with the Streamline recipe (megaphone / bullhorn).
- Check the card's grade chip and Next line on Deep Sea: the wash under the band must not eat the chip.

**Assignments** (`/courses/4/assignments`; `skin.css` `.item-group-condensed` near 183, `.ig-header` near 159
and 250, the `/* ---- rows: one row shape` block, the toggle note near 295):
- Four cards for six rows: chrome outweighs content. Groups should be one sheet with quiet section
  heads (14px bold, count chip, hairline), not a card each. Keep the row shape from R40.
- "-/15 pts" reads as a minus sign. Canvas writes it in `.ig-details .points_possible_display` or
  `.score-display`; when there is no score, show "15 pts" only. CSS only if a `::before`/`:has()` can do
  it; otherwise a small content.js pass that never edits Canvas's node text, only adds a class.
- "Show by Date" / "Show by Type" is Canvas's heavy green primary in `#content .header-bar`. Make it a
  quiet segmented control in our ink through the buttons rule (never paint a button property outside it).
- The search field in the same bar: fold it into the title row at the right, 240px wide, our field
  style, or hide it behind the Search pill we already put in every title bar (receipt row `search`).
- Group weights ("30% of total") are a fact a student wants: if Canvas prints them, keep them in the
  section head's meta; if not, do not add them (one place per fact; the grades page owns weights).

**Announcements** (`/courses/4/announcements`; `skin.css` `.ic-item-row` block near 653):
- Filter select, search and "Mark All as Read" make a heavy top row. One quiet line: the filter as
  a text button with a chevron, the search folded as on Assignments, "Mark All as Read" as a quiet
  text button at the right. Never a Canvas primary.
- "Reply" under each row repeats the row's own link. Hide the reply link (`.ic-item-row__reply`, check
  the real class on the sandbox) with a receipt row and a Put back; the row is the link.
- The unread dot: Canvas draws it in blue at the row's left. If it survives our row, make it our mark
  colour (`var(--pk-mark)`), 8px, on the face tile's corner. Never red.
- Check the face tile on Deep Sea: a grey placeholder face on a dark wash needs a ring or a fill.

**Quizzes** (`/courses/4/quizzes`; the same `.ig-row` block; `#assignment-quizzes`):
- A lone search field above one row. Same fold as Assignments: into the title row, or behind the
  Search pill.
- One row in a card looks empty. Drop the card around a single group; the sheet is the page. With no
  rows at all, our empty state: one line, quiet ink, no Canvas cartoon, no dashed box.
- Quiz meta ("Due Sep 8 · 10 pts · 12 questions") should sit on the row's line as on Modules; check
  `.ig-details__item` count and the "·" separator hold when there are four items.
- Availability text ("Available until …") must not wrap to a second line at 1280.

## Rules that cannot move (the tests enforce them)

- Never write to Canvas. No network from the skin (data URIs only). No AI.
- Never red. One place per fact. No uppercase tracking labels. No `transform: translate`, no `font-family`,
  no `box-shadow` other than `var(--pk-lift)`. Never paint a property on a button except through the
  InstUI buttons rule (`extension/receipt.test.js` lints this: `BUTTON_RULE_GATE`, `TEXT_BUTTON_OK`).
- No commas inside `:has()` (the selector reader splits on commas). No InstUI hashed classes (`css-…`);
  match by attribute (`[class*="-avatar"]`) as the announcements block does.
- Every change to Canvas's page is a receipt row with a Put back; the cap is 28 rows (`RULES` in
  `extension/receipt.js`, the cap in `receipt.test.js`). Raise it only for a real new change, and prefer
  extending an existing row (`feedback-rows`, `module-band`, `buttons`) to adding one.
- Never name an element of ours `.row` (Canvas's grid reaches in).
- Never draw an icon by hand; every icon comes from the look's Streamline set.
- A quiz being taken (`/quizzes/:id/take`) gets nothing from us: R18 checks it, do not widen a quiz
  rule past the index page.

## Tools, and how to run them

The sandbox is a real self-hosted Canvas on a GCP VM; ask me for the IP if the tunnel is down.
Canvas listens on the VM's localhost:3000 only, so everything goes through the tunnel:
```bash
while true; do ssh -o ExitOnForwardFailure=yes -i ~/.ssh/prepkin-canvas-sandbox -N -L 3000:localhost:3000 canvas@<VM IP>; sleep 20; done
```
Check it with `curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/login/canvas` (200).
Student: `alex@prepkin.test` / `PrepkinSandbox!2026`. Course 4 is AP Physics C (assignments in groups,
announcements, one quiz). If the dashboard shows List View, flip it back:
`PUT /dashboard/view {"dashboard_view":"cards"}` with the `_csrf_token` cookie (recipe in memory
`gap-plan-2026-09-18.md`). Admin credentials are in `~/canvas-admin.txt` on the VM if you need to seed
more announcements or a second quiz so the pages are not one-row pages while you design.

Every run needs its own free port and the scratch temp:
```bash
export PREPKIN_TMP=/tmp/prepkin-tmp; mkdir -p $PREPKIN_TMP
```
- Unit + lint (fast, run after every CSS edit): `npm test` (148 tests).
- Fake-Canvas end to end: `PREPKIN_PORT=8481 npm run test:receipt` (49 tests, ~2 min). The tests that
  matter here: R3 (dashboard; and "what is left alone"), R10 (the rail), R38 (finished fold on the
  dashboard), R40 (row shape), R16 (a quiz page takes the paper, buttons do not), R18 (quiz take gets
  nothing). Subset: `node --test --test-name-pattern="R3|R10|R38|R40|R16|R18" test/receipt.test.js`.
- The fake Canvas (`test/fake-canvas.js`, worlds in `test/scenarios.js`) serves the dashboard, modules,
  a quiz page and the grades pages. It does NOT serve the Assignments index, Announcements or the
  Quizzes index. To put an R-test on those, dump the real page's `#content` `outerHTML` from the sandbox
  first (a scratch Playwright script; model on `test/pages.test.js`), trim it, add a route in
  `fake-canvas.js`, and only then write the rule. A rule the fake never sees is a rule no test guards.
- The visual floor on the real sandbox (the grade):
  `PAGES=dashboard,assignments,announcements,quizzes MODES=light,dark,art WIDTHS=1280 PREPKIN_PORT=8491 node --test test/pages.test.js`
  It fails on any text under the contrast floor, a white block in dark or art, an invisible control, a
  broken word, uppercase, red, a painted label inside an unpainted button, or a blank page. Shots land in
  `design/signoff/canvas-pages/<page>-<mode>-1280.jpg`; read them, do not trust green alone.
- Mount time under a 4× CPU throttle: `PREPKIN_PORT=8446 npm run test:mount` (skin on must stay within
  1.5× of plain Canvas + 1 s; dashboard is 0.74× today, keep it there). Run it alone; other Chromiums
  on the machine make it time out.
- Harness facts: `PREPKIN_PORT` must be in the env when the file is required; `stageExtension` copies the
  extension at launch, so a suite mid-run never sees a later edit; rerun after the last edit. Scratch
  Playwright scripts need `NODE_PATH=~/Library/Developer/prepkin-canvas-test-deps/node_modules`
  (Playwright, not Puppeteer).
- Icons: recipe in `design/canvas-skin/icons/` (`repick.py` picks by exact name per family, `gen2.py`
  writes the CSS block; `sets.json` names the light and dark family per set, `picked.json` records the
  picks). To add "announcement": add a key to `Q` and `P` in `repick.py` (names like `^Megaphone( \d)?$`,
  `^Bullhorn( \d)?$`, `^Announcement( \d)?$`), run it per family slug, then regenerate the block and paste
  it over the old one in `skin.css` (the block starts at the comment `/* Icon sets:`). Base URL
  `https://public-api.streamlinehq.com/v1/`, header `x-api-key`, 1000 requests an hour; the API key is
  mine, ask for it and keep it in the shell env only. Line families need `strokeWidth=2.6` at 26px;
  `strokeToFill` and `strokeWidth` together return 400. Round path numbers to two decimals.
- References, when a shape is in doubt: Mobbin and Refero are connected. Search "assignment list",
  "notifications feed", "inbox list", "segmented control", "empty state". Things 3 and Todoist for group
  heads; Linear for a quiet filter bar; Arc and Notion for empty states.

## How to work

1. For each page: read the shot, list what is Canvas's shape, decide the one shape it should take, write
   the CSS (or a small content.js pass), add or extend an R-test (with a fake route where none exists),
   `npm test`, run the R subset, run the floor for that page in all three modes, read the shots. Commit
   per page with a plain message (no URLs in messages; use `git commit -F file` if the message has an
   apostrophe).
2. Order: Dashboard first (most seen), then Assignments, Announcements, Quizzes. Assignments and Quizzes
   share the bar and the row; solve the bar once and reuse it.
3. Show me, don't tell me: after each page, a before/after crop (light and Deep Sea) as an image in chat,
   one line under it. Keep chat under 100 words.
4. At the end: rebase on origin main, push, rsync into my folder, update the memory file
   `gap-plan-2026-09-18.md` with what moved and any new trap, and republish the scores page
   (https://claude.ai/artifact/6tUGUqZsUFYhxYsFqkrGbM: read it first with the Artifact tool, then edit
   the four cards and rescore honestly) with fresh shots. If a page is still not a 10, say what is left
   and why.
