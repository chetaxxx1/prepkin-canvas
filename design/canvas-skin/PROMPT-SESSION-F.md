# Copy everything below the line into a new Claude Code session opened at /Users/georgeshi/Desktop/app/prepkin-canvas. Sessions C, D, E and F may run at the same time.

---

# Session F: Discussions, Settings, from 6 / 5.5 to 10

You are session F of four that run at the same time (C course pages, D tables, E calendar and inbox,
F discussions and settings). Each has its own worktree, branch, ports and marker regions in the shared
files, so nobody overwrites anybody. Follow the parallel rules below exactly.

## Your worktree

```bash
git -C ~/Library/Developer/prepkin-worktrees/verdict fetch origin
git -C ~/Library/Developer/prepkin-worktrees/verdict worktree add ~/Library/Developer/prepkin-worktrees/skin-f -b skin/f-discussions-settings origin/main
cd ~/Library/Developer/prepkin-worktrees/skin-f
```
Work only there. Never edit `~/Library/Developer/prepkin-worktrees/verdict` or
`/Users/georgeshi/Desktop/app/prepkin-canvas/extension`. Landing and the rsync are described at the end.

## Parallel rules (the other three sessions depend on these)

- The shared files carry marker pairs for you, `---- Session F … ----` / `---- end Session F ----`.
  Write only between your own pair: in `extension/skin.css` (the region at the end of the file),
  `extension/receipt.js` (`RULES`, one new row at most), `extension/receipt.test.js` (`TEXT_BUTTON_OK`),
  `extension/content.js` (`KEPT_CLASSES` and your `passF()` function, already called after
  `decorateLists()`), and `test/fake-canvas.js` (your `pageF(p, url)` function, tried before the page
  chain: return `{ main, side }` or null). Do not touch the receipt cap (it is 33, a budget of one row per
  session). Do not edit the modules, planner, assignments or grades rules that other passes landed today.
- New tests go in a new file `test/f-pages.test.js` (copy the harness setup from `test/receipt.test.js`:
  `stageExtension`, `FakeServer`, `h.connect`), not in `receipt.test.js`. New unit tests likewise in a new
  file next to the one they test. If you must change an existing test's expectation, say so in the commit.
- Use only your ports: fake-Canvas e2e 8811, your own test file 8812, the floor 8821,
  the mount test 8831. Your scratch temp is `PREPKIN_TMP=/tmp/prepkin-tmp-f`.
- On the sandbox, change nothing about the student (no settings, no dashboard view, no course
  favourites). Seed only content on your own pages, as admin, and only add, never delete.
- Chromium timeouts: four sessions share one machine. If a suite times out, rerun it once before you
  read it as a failure; run the mount test only when yours is the last commit.
- The scores page and the memory file are shared too: read each right before you write it, edit only
  your own cards or append your own section, publish or save once.

Read first, in this order:
1. `design/canvas-skin/PLAN-2026-09-18.md` (what landed on 2026-09-18 and why) and `DESIGN.md` (house rules).
2. The scores page: https://claude.ai/artifact/6tUGUqZsUFYhxYsFqkrGbM. Your pages are
   "Discussions", "Settings". Read each card's Like / Don't like lists; they are the brief. Read the
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

These are the two lowest scores. Both are InstUI screens with a blue primary and Canvas's own voice;
both need a shape decided for them, not a repaint.

**Discussions** (`/courses/4/discussion_topics`; `.discussions-v2__wrapper`,
`.ic-discussion-row-container`; `skin.css` 191 and 437; 6):
- Dashed empty boxes with Canvas's cartoons (the InstUI empty state and its SVG). Hide the drawing and
  the dashed edge (one receipt row with a Put back); our empty state is one quiet line per section, or
  one line for the page when every section is empty ("No discussions yet").
- "+ Add Discussion" is a blue primary. It is not a submit: through the buttons rule, our paper shape
  (or a text button on the title line via the `TEXT_BUTTON_OK` door).
- Two empty sections stacked (Pinned, Discussions, Closed). Show a section head only when it has rows;
  the heads take the group-head shape (14px bold, count chip, hairline).
- With content it is Canvas's InstUI rows: give them the announcements row shape (face tile, title, one
  preview line, replies count and last-post date right, unread as our mark). Seed two discussions as
  admin so you design against rows, and dump the row's outerHTML before writing the rule.
- The discussion's own page (`/discussion_topics/:id`) is out of scope unless a rule leaks onto it;
  check it once on Deep Sea and leave it.

**Settings** (`/profile/settings`; `.profile_table`, `#right-side`, the feature disclosures handled at
`skin.css` ~1511; 5.5):
- Canvas's settings page untouched: a label column and paragraphs of explanation. One column: each
  setting as a row (label bold, value or control on the right, the explanation as a 12px quiet line
  under the label). Sections (Name, Language, Time zone, Features, Approved integrations) as our group
  heads. Keep every control working; change shape, never structure that scripts depend on (Canvas's
  edit form toggles by id).
- "New Access Token" is a blue primary (`.add_access_token_link`). Not a submit: our paper shape through
  the buttons rule. "Edit Settings" likewise.
- Right column boxes ("Ways to Contact", "Other Contacts", "Web Services") are Canvas's type. Rows
  44px, the email as the row's link, "+ Email Address" as a text button, the box edges as hairlines.
- The Feature Options list: keep the disclosure toggles as they are (already a text button), align the
  switches right.
- The profile picture and the display-name field: our field shape, the picture as a 48px tile.
- Nothing here may touch the password or login fields' behaviour; if a rule reaches a form input, it
  paints only edge and paper.

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
export PREPKIN_TMP=/tmp/prepkin-tmp-f; mkdir -p $PREPKIN_TMP
```
- Unit + lint (fast, run after every CSS edit): `npm test` (148 tests).
- Fake-Canvas end to end: `PREPKIN_PORT=8811 npm run test:receipt` (51 tests, ~2 min). The tests that
  matter here: R16 (buttons untouched where they must be), R18 (an open editor drops the skin but keeps the buddy). Subset: `node --test --test-name-pattern="R16|R18" test/receipt.test.js`.
- The fake Canvas (`test/fake-canvas.js`, worlds in `test/scenarios.js`) serves the dashboard, modules, the
  assignments / quizzes / announcements indexes, a quiz page and the grades pages. It serves neither page; both need a page from a sandbox dump.
  To put an R-test on a page the fake lacks: dump the real page's `#content` and `#right-side` `outerHTML`
  from the sandbox (a scratch Playwright script, model on `test/pages.test.js`), trim it, add a route, then
  write the rule. A rule the fake never sees is a rule no test guards.
- The visual floor on the real sandbox (the grade):
  `PAGES=discussions,settings MODES=light,dark,art WIDTHS=1280 PREPKIN_PORT=8821 node --test test/pages.test.js`
  It fails on any text under the contrast floor, a white block in dark or art, an invisible control, a
  broken word, uppercase, red, a painted label inside an unpainted button, or a blank page. Shots land in
  `design/signoff/canvas-pages/<page>-<mode>-1280.jpg`; read them, do not trust green alone. The floor may
  scroll a page mid-way for a control; for a clean top-of-page shot use a script (scratchpad `shoot.js`
  from 2026-09-18: login, `h.setStorage`, `h.connect`, `syncNow`, `scrollTo(0,0)`).
- Mount time under a 4× CPU throttle: `PREPKIN_PORT=8831 npm run test:mount` (skin on must stay within
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
- References, when a shape is in doubt: Mobbin and Refero are connected. Search "forum list", "settings page", "account settings". Linear and Arc for settings rows; Discourse and Circle for discussion lists.

## How to work

1. For each page: read the shot, list what is Canvas's shape, decide the one shape it should take, write
   the CSS (or a small pass in your `passF()`), add a test in your own test file (with a fake page in
   your `pageF()` where none exists), `npm test`, run the R subset, run the floor for that page in all
   three modes, read the shots. Commit per page with a plain message (no URLs in messages; use
   `git commit -F file` if the message has an apostrophe).
2. Order: Discussions first, then Settings.
3. Show me, don't tell me: after each page, a before/after crop (light and Deep Sea) as an image in chat,
   one line under it. Keep chat under 100 words.
4. Landing, after the last page:
   ```bash
   git fetch origin && git rebase origin/main
   npm test && PREPKIN_TMP=/tmp/prepkin-tmp-f PREPKIN_PORT=8811 npm run test:receipt
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
5. Update the memory file `gap-plan-2026-09-18.md` (read it first, append a section named "Session F",
   what moved and any new trap), and republish the scores page
   (https://claude.ai/artifact/6tUGUqZsUFYhxYsFqkrGbM: read it with the Artifact tool right before, edit
   only your cards, rescore honestly, publish once) with fresh shots. If a page is still not a 10, say
   what is left and why.
