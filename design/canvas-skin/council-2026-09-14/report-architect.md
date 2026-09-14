# Council report — ARCHITECT / CORRECTNESS

Checkout read: `/Users/georgeshi/Library/Developer/prepkin-worktrees/verdict` at e10d2bce. `npm test`: 143 pass. Nothing edited. Q2 and Q4 in full; Q1, Q3, Q5 one paragraph each, only where the code changes the answer.

---

## Q2. Tick a row done (A1)

### 1. Evidence inspected

- `extension/canvas.js` L109–146 `mapAssignments` (the task shape: `id, title, courseName, courseId, colorHex, dueAt, submittedAt, score, pointsPossible, gradedAt, missing, url`), L157–161 `submissionTime`, L173–185 `isWorthShowing` (a pending task stays 7 days past due, 90 if Canvas marked it missing), L199–223 `mapTodo`, L391–395 `merge`.
- `extension/background.js` L458–507 `send()` (`lastPayload` written L481, `forBridge` filter L491–495, `pushToBridge` L496, `pullWallet` L503), L544–580 `pullWallet` (retires requests up to `requestsAppliedAt`), L591–607 `changeRequests`/`queueRequest` (the one locked read-modify-write), L297–307 `senderMayAsk` (page messages only from a connected top frame; own-page messages only for `SETUP_MESSAGES`), L323–367 `handleMessage`, L615–680 `readSchool` (`lastResults` is Canvas's word, refreshed every sync).
- `extension/content.js` L126–133 `composeData` (own tasks get `own: true`; the payload itself is never changed), L488–517 `taskRow` (the `data-own-done` button L504), L1346–1350 `isStaleMissing`, L1355–1359 `nextLineFor`, L1361–1367 `dueRowsFor`, L1439–1487 the card's one line, L1701–1826 `renderWeek` (`first`/`then` L1714–1715, key L1718–1720, foot L1812–1822), L2253–2256 the own-done handler (sets `submittedAt` on an own task and writes `ownTasks`), L2580–2591 `storage.onChanged` (cheer + `+30` float only when the `submittedAt` count rises, L2584–2588).
- `extension/day.js` L31–58 `buckets` (pending = `!submittedAt`; `doneToday` = submitted today), L83–105 `voice`, L115–129 `weekStats`.
- `extension/planner.js` L63–79 `plColumns`, L225–250 `plCard` (`done` class from `submittedAt`). `extension/sidepanel.js` L84–120 `draw` (reads `lastPayload` + `ownTasks` straight from storage). `extension/popup.js` L420–433: the popup has no due rows.
- `bridge/schema.sql` L36–48 `pairings.todo jsonb`, L153–174 `push_todo` (256 KB cap, otherwise opaque), L196–204 `fetch_todo`. No column knows a task's shape.
- `ios/Sources/CanvasSync.swift` L6–20 `CanvasItem` (`submittedAt` → `isSubmitted`), L63–80 `BridgeRequest.ledgerKey`, L109–123 `BridgeState`, L258–291 `decode`, L323–338 `WireItem` (synthesised `Decodable`: unknown JSON keys are ignored).
- `ios/Sources/Core/GameState.swift` L623 `canvasKey` = `task:<id>`, L632–634 `isCanvasPaid`, L655–657 `done: item.isSubmitted || isCanvasPaid(id)`, `isLocked: item.isSubmitted`, L817–849 `complete`/`pay`, L859–867 `applyDoneMarks`, L948–981 `applyBridgeRequests` (unknown `kind` → `default: break`, watermark still advances), L1271–1279 `applyCanvas` (pays every `isSubmitted` item through `complete`), L1285–1300 `uncomplete` (refuses a submitted item; otherwise revokes `task:<id>`). `ios/Sources/AppState.swift` L397–406: `applyCanvas` runs before `applyBridgeRequests`. `ios/Sources/Core/Ledger.swift` L128–134 `revoke` fails if the balance would go negative. `ios/Shared/DoneMarks.swift` (widget → app file; untouched by this design). `ios/Sources/Models.swift` L126–130: `TaskKind.canvas.reward` = 30.
- Tests: `test/receipt.test.js` R17 L306, R21 L422, R24 L525, R26 L577; `test/pages.test.js` L160–176 (rail ≤ 5 rows, one line per card, one count); `extension/receipt.test.js` L318–333 (button lint exempts `#pk-week`, `#pk-planner`, `.pk-card-due`); `ios/Tests/GameStateTests.swift` L200–221; `ios/Tests/BridgeTests.swift` L203–210.

### 2. Current behaviour

A Canvas row clears only when Canvas reports `submittedAt`. `lastResults` is rewritten from Canvas every sync, so nothing the extension wrote onto a task would survive half an hour. Own tasks have a Done button, but only inside `panelView`, which is reachable today only by ⌘K → the Back chevron (see Q4). **The phone already lets a student hand-tick any Canvas row** (`isLocked` is only for submitted work) and pays 30 under `task:<id>`; the widget does the same through `DoneMarks`; `uncomplete` takes the coins back. So the cheat surface the brief worries about already exists on the phone, item for item.

### 3. Options and costs

**Wire shape.**
(a) A per-task field `doneAt` stamped onto the pushed `tasks`. Phone: one optional on `CanvasItem`, old phones ignore it (Decodable drops unknown keys). Undo = the next push lacks the field; the phone diffs against its stored `canvasItems`.
(b) A request `{kind:'done', taskId, at}` through the existing queue. Idempotent by `ledgerKey`, but `pay()` L823–849 falls through to a day-keyed line when the id is not in `canvasItems`, so a ticked task the extension has dropped from the list would pay again tomorrow; and undo needs a second kind. Old phones swallow both kinds silently.
(c) Both. Two places for one fact.
(a) is smaller and the diff is against data the phone already stores. Pick (a).

**Who writes the done-set.** Content script and side panel both writing `chrome.storage.local.done` is two unlocked read-modify-writes. The worker already owns the only locked queue (`changeRequests`). Route every tick through a `done`/`undone` message to the worker; the gate needs one line so those two types are accepted from a connected top frame *or* our own pages (the side panel has no `sender.tab`).

**Reward.** None vs 30 on the phone. The phone pays 30 for its own hand tick today; refusing to pay a laptop tick would push students to tick on the phone instead (two places). Pay 30, on the phone, through the same key. The page never floats `+30` for a tick (that float and the cheer stay tied to `submittedAt`, L2584–2588): a tick is a quiet bounce, a hand-in is the loud moment. Wording cost: planner.js L440/L450 say "verified work earns 30" — change to "finished work" in step 9.

### 4. Edge cases

- Canvas later reports `submittedAt`: Canvas wins; the entry is pruned at the next `send()`; the phone's `complete` finds `task:<id>` already claimed and pays 0; the row becomes locked.
- Canvas marks it `missing` after the tick: the student's word stands for the row (out of Past due, out of the Missing list); `missing` stays on the raw task so the recap and the panel's numbers are still Canvas's.
- The task ages out of `isWorthShowing` (7 days past due): prune the entry; the phone's ledger line stays, `lifetime.canvasFinished` stays.
- Undo after the coins were spent: `Ledger.revoke` refuses, the phone keeps the row done, the laptop shows it open; a re-tick pays nothing new. Say so in the code, not to the student.
- A phone tick never reaches the laptop (BridgeState carries no ids). Not a regression: that is today. v1.1 adds `done: [ids]` to `BridgeState` and `pullWallet` mirrors it.
- Ticked, then the school's read fails: `readSchool` keeps `previous.tasks`, ids persist, the overlay still applies.
- Two schools: ids already carry the host (`c-<host>-a<id>`), no collision.
- A forged id: the worker only accepts an id present in `lastPayload.tasks` or `ownTasks`; own tasks are never pushed (R21), so the phone can only be asked to pay for a real assignment, once, ever.
- Synthetic clicks: keep the `e.isTrusted` check every handler already uses.
- `renderWeek`'s key L1718 lists `submittedAt`; a tick changes which ids are in `then`, so the key already changes.

### 5. Recommendation

**One `done` map owned by the worker, overlaid as `doneAt` on every reader and baked into the bridge push; the phone pays 30 once under the hand-in key and revokes on an undo diff.**

What the student sees. A circle at the left of every row of ours on the dashboard: the rail's Start-with row and the three Then rows, the card's one line, every planner row, every side-panel row. Not the popup (no rows) and not ⌘K results (links). Rail and card: the row leaves at once and the next thing slides in; the rail's foot reads "Done: Problem Set 8 · Undo" for 8 s (Todoist's toast, in words). Planner and side panel: the row stays in its day, struck, circle filled, for the rest of today; tapping the circle again un-ticks it any time. The card says "All done" when nothing is pending and something was ticked, "All handed in" only when something was submitted. Sprout bounces; no `+30` on the page.

What the code does.
- Storage: `chrome.storage.local.done = { [taskId]: isoAt }`. Worker: `changeDone(fn)` on the same lock pattern as `changeRequests`; messages `done`/`undone` (id, at). Prune inside `send()` after `readSchool`: drop ids not in any school's tasks or now carrying `submittedAt`.
- One pure helper in `day.js`: `withDone(tasks, done)` → copies with `doneAt`; `isDone(t) = !!(t.submittedAt || t.doneAt)`. `buckets` pending = `!isDone`; `doneToday` = submitted **or** ticked today. `dueRowsFor`, `nextLineFor`, `weekStats`, `plColumns`/the new day groups, `sidepanel.draw` all use `isDone`. `submittedAt` keeps meaning "Canvas verified" everywhere (recap on-time, cheer, R21). Own tasks: their circle writes the same map; old stored `submittedAt` on own rows still reads as done.
- Readers: `composeData` and `sidepanel.draw` overlay from storage; `storage.onChanged` remounts on `changes.done`. `send()` bakes `doneAt` into `forBridge.tasks` only (never into `lastResults`).
- Phone: `CanvasItem.doneAt: Date?` (+ `WireItem`); `tasks` → `done: isSubmitted || doneAt != nil || isCanvasPaid`, `isLocked` unchanged; `applyCanvas`: for each new item with `doneAt` → `complete(id, 30)`; for each new item where the old copy had `doneAt`, the new has none and is not submitted → `uncomplete(id)`. Items absent from the new snapshot: nothing.
- Bridge: no SQL change.

What proves it.
- `extension/content.test.js`: `buckets` with `doneAt` today → in `doneToday`, not `today`; `voice` says "1 done, 1 to go"; `withDone` never sets `submittedAt`, ignores a submitted task, prune drops the aged and the submitted.
- `test/receipt.test.js` new R27: click the first Then row's circle (a Playwright click is trusted) → the row is gone from `#pk-week` in 400 ms, `.pk-card-due` for that course names the next thing, `h.storage().done` holds the id, Undo in the foot restores it, then `syncNow` → `phone.fetchTodo().tasks` carries `doneAt` and `submittedAt: null`. Extend R24: after the real hand-in, `done` no longer holds `c-localhost-a11`. `pages.test.js` L160–176 unchanged: the circle adds no row and no count.
- `ios/Tests/GameStateTests.swift`: a `doneAt` item pays 30 once; the same item resent pays 0; resent with `submittedAt` pays 0 and locks; resent without `doneAt` revokes; a phone hand-tick with no laptop `doneAt` is never revoked.

### 6. Confidence

High on the extension half and the reward rule (every path read). Medium on the phone diff: I did not run the Swift suite. Unknown: whether George wants the side panel to tick at all (it can, with the one-line gate change).

---

## Q4. The Planner tab shape

### 1. Evidence inspected

`extension/planner.js` whole (578 lines): `plColumns` L63–79, tabs L88–128, `renderPlanner` L132–221 (count "· N of M in" L162–164; seven-column grid L191–205; cards row L217–219), `plCard` L225–250 (icon per kind L34–43), drag L253–278, `plGradesCard` L281–301, `plLeagueCard` L304–330, `plFocusCard` L334–389, `plAddForm` L392–419. `extension/skin.css`: the only `@media` in the file is `prefers-reduced-motion` (L470); planner rules L830–~1000 (136 `#pk-planner`/`#pk-looks` lines), grid L861, uppercase day label L867 (breaks R1). `extension/content.js`: `render()` L2118–2142, `wire()` L2225–2303, `searchView` L874–884 (Back chevron `data-view="panel"`), `panelView` L576–606, `weekGroups` L900–964, the views listed below, exports L2574–2576, `weekDays` L1601. `extension/recap.js` L15–23 `recapDue`. Grep, as ordered: `grep -n "panelView\|weekView\|looksView\|addTaskView\|panelViewFallback\|leagueCard\|gradesCard\|whatIfView\|courseView\|recapView" extension/*.js extension/*.test.js test/*.js` → 26 hits, **all in `extension/content.js`; zero in any test**. `extension/content.test.js` L5–6 imports only helpers (`missingCost`, `targetsFor`, `sparkline`, `gpa`, `LETTERS`, `weekDays`, `TIERS`, `tierOf`, `kinFace`…).

### 2. Current behaviour

Seven columns at every width (no breakpoint exists), an icon per task kind, a "N of M in" count, League/Grades/Focus cards under the grid. The old panel is not dead: `render()` builds `panelView` on every draw into a hidden `<div>`, and ⌘K → the Back chevron (`data-view="panel"`, handler L2301) shows it, with its grades card, coins → `looksView`, "+ Add a task" → `addTaskView`, course/what-if buttons, and the recap row. `weekView` has no door at all (no element sets `data-filter="week"`). `weekDays` is called by nothing. `panelView` still runs on every render, hidden or not.

### 3. Options and costs

(a) **Width.** Vertical everywhere vs columns above ~1440. Columns need the first `@media` in the skin, a second layout in the 1280/768 gauntlet, and the four-letter wrap comes back on any narrow column. Todoist Upcoming is vertical on desktop. Vertical, one layout.
(b) **Rail while Planner is open.** Keep the list (fact twice) vs hide the list, keep tank + line + foot. `renderWeek` already keys on `plTab` (L1720) and blanks the foot link; hiding Start with/Then is one branch.
(c) **Doors.** Modal views with back chevrons (today) vs inline expansions in the planner's Grades block. Inline removes `ui.view`, four back buttons and `panelViewFallback`.
(d) **Deletion.** Delete now (before the tick, ~900 lines in one commit, no test names them) vs after. Both step 4 and step 5 edit `content.js`; deleting first makes both diffs readable and stops `panelView` running on every draw.

### 4. Edge cases

- Tasks 8–14 days out (`DAYS_AHEAD` = 14) fall outside "next five days": they need a folded "Later · N" group or they lose their home.
- Undated work: keep the "No due date" group (already in `weekGroups`).
- Nicknames, class level (Honors/AP for the weighted GPA) and "Aiming for" live only in `gradeRow` L732–796; deleting `gradesCard` orphans three features. R19 sets nicknames through storage, so no test catches it.
- `missingCost` (L430) feeds only `panelView`; it has three unit tests (content.test.js L277–300).
- `TIERS`/`tierOf`/`leagueDaysLeft` serve both league cards; tests at content.test.js L177–186; `pullWallet` still stores `wallet.league`.
- The gauntlet opens `/` on the Courses tab, so the planner's uppercase label (skin.css L867) is never audited.
- Drag: `plans` is per task id, so a ticked or moved row keeps working; dropping on its due day clears the plan (L274–277) — keep.

### 5. Recommendation

**One vertical list grouped by day, rows in the rail's shape, the rail's list folded while it is open, grades expanding inline, dead views deleted first.**

What the student sees. Tab "Planner": one head row with "+ Add a task" and nothing else (no arrows, no week title, no count). Then: Past due (amber dates only; one subline from `missingCost` — "Still counts: 40 points across 2 classes") → Today (outlined) → Tomorrow → the next five weekdays by name → Later · N (folded) → No due date. Each row: circle · class tile with its letter · title cut at a word · date right; hover shows Start. The first pending row of Today wears the rail's `pk-w-first` shape with the mint Focus button; while a session runs it shows the clock, as the rail does. Drag a row onto any day header. Under the list, one "Grades" block: a row per course (tile · name · % · letter); tapping a row expands it in place: sparkline, the three recent marks, one what-if line ("An A needs 91% on the final"; when weights are missing, one inline "final is worth __ %" field), nickname field, level chips, and "Every assignment" which opens the Missing / Upcoming / Graded lists under it. "Aiming for" merges into the what-if target. The rail on this tab: tank, his line, foot ("3 things finished this week" — the one count). Term recap: when `recapDue()`, a `pk-pl-recap` card sits at the top of the planner with Save as a picture and a dismiss that stores the term key; the rail's foot gets the "Your term, in numbers" row, and it opens the Planner tab. The League card is gone.

What the code does.
- Move the grouping out of `weekGroups` into `day.js` as `dayGroups(tasks, now, plannedOn)` → `{ past, days: [{date, items}], later, undated }`, pure, unit-tested. `planner.js` renders it with `el()`; `plColumns`, `plWeek`, `PLANNER_ICONS`, `plIconFor`, `plCard`, `plLeagueCard`, `plFocusCard` go; `plGradesCard` becomes `plGrades()` with the expansion state (`plOpenCourse`), absorbing `gradeRow`, `courseView`, `whatIfView` logic (their pure parts — `targetsFor`, `requiredScore`, `sparkline`, `gpa` — stay in content.js/canvas.js as today).
- `renderWeek`: when `plTab === 'planner'`, skip the Start-with/Then block; keep tank, line, foot.
- Delete from content.js: `panelView`, `weekView`, `weekGroups`, `plannerRow`, `nextUpCard`, `addTaskView`, `looksView`, `panelViewFallback`, `leagueCard`, `gradesCard`, `gradeRow`, `courseView`, `whatIfView`, `recapView`, `weekDays`, the `[data-own-done]`/`[data-own-remove]`/`#pk-addtask`/`[data-view]`/`[data-filter]`/`[data-cfilter]`/`[data-target]`/`#pk-weight-go`/`[data-buy]`/`[data-banner]`/`[data-pic-course]` handlers, the header's coins button (L2168), the search view's Back chevron (Escape closes; the tab button closes). `saveRecapPicture` and `missingCost` move to planner use. Drop `weekDays` and its test (content.test.js L334); keep the `missingCost`, `targetsFor`, `sparkline`, `gpa` tests. `TIERS`/`tierOf`/`kinFace` keep their tests only if the pod names still draw anywhere; otherwise delete with `podnames.js` and stop storing `wallet.league` in `pullWallet` (flag, not decided here).
- `ui` shrinks to `{ open, query, sheet }` for search.
- skin.css: replace L861–~900 grid/column/task rules with the rail's row rules (reuse `.pk-w-list li` shape), drop the uppercase day label.

What proves it.
- `content.test.js`: `dayGroups` puts a task due 9 days out in `later`, yesterday's in `past`, a plan moves one from Friday to today, undated stays undated.
- `test/receipt.test.js` R9 (popup opens the planner) still passes; new R28: open `/`, set `dashTab: 'planner'`, assert `#pk-planner .pk-pl-grid` is absent, group labels read `Past due|Today|Tomorrow|<weekday>|Later|No due date`, no element inside `#pk-planner` has `text-transform: uppercase`, `#pk-week .pk-w-label` count is 0 while the tab is open and 2 after switching to Courses, no `.league` node, and `#pk-planner` `innerText` does not match `/\d+ of \d+/`.
- `test/pages.test.js`: add a `dashboard-planner` page (storage `dashTab: 'planner'`) so the words/uppercase/red/contrast floor runs on the planner in both modes; the mount check is unaffected (the planner draws after the cards).
- `node --test` after the deletion: 143 → 142 (weekDays) and nothing else moves.

### 6. Confidence

High on what is dead and the doors (every call site read). Medium on the grades expansion size: it is the one place that grows, and George may prefer to cut nicknames/levels rather than move them.

---

## Q1. The button rule in dark mode — one paragraph

The unit lint (`extension/receipt.test.js` L326–333) already lets any selector containing `:not([type="submit"])` through, so `button.btn-link:not([type="submit"])` would pass today by accident; that loophole should close whatever George picks. If he picks (b): allow exactly one rule, marked `/* button-ink */`, gated `html.pk-on.pk-dark:not(.pk-back-paper)`, an explicit selector allowlist (`.btn.btn-link`, `button.Button--link`, the calendar's `.navigate_prev/.navigate_next`, `td.dates > button`), body `color: inherit` only, every selector ending in `:not([type="submit"])`; the lint asserts that one rule's body is `color` alone and that no other rule matches `buttonish`. R18 stays true because it measures reach on a quiz page, which carries no `pk-` class, so a `pk-dark`-gated rule matches nothing there; R3 (`#assignment_submit` unchanged) stays true because the allowlist never names `.btn-primary`, `#assignment_submit` or `[data-testid="submit-button"]`. The two `KNOWN` rows in `pages.test.js` L76–78 then come out.

## Q3. Looks tiles — one paragraph

Only (a) keeps the mount test honest: `renderLooks` runs solely when `plTab === 'looks'` (planner.js L433), so 26 CSS mini-pages built from `PAPERS[stockFor(look, dark)]`, `look.accent`, `artFor(look).wallpaper` and the student's first two `data.courses` (name + `colorHex`) cost nothing on the Courses tab; ~15 nodes a tile, no network, no iframe boot, no clone of Canvas markup that would arrive without Canvas's CSS. Inline the tokens on the tile (`--pk-paper`, `--pk-mark`, `--pk-wallpaper`, `--pk-paper-wash`) rather than a `pk-theme-<id>` class, so `themeStyle()` (receipt.js L210–235) is the one source and the page's own theme never leaks in. Prove it in `test/receipt.test.js`: with `dashTab: 'looks'`, three tiles (Newsprint, a dark stock, one image theme) report `backgroundColor === rgb(PAPERS[stock].paper)` on the paper node, the card band equals course 1's `colorHex`, the image tile's `backgroundImage` contains `art/`, and the harness's request log shows no request outside the extension's own origin.

## Q5. Order and cuts — one paragraph

Insert "delete the dead views" as step 4.0 (one commit, no test moves but `weekDays`), because steps 4 and 5 both edit `content.js` and `panelView` runs on every draw today; then tick (4) before planner (5), since the planner rows need `isDone` and the circle; fold step 9's words into 4 and 5 (each surface's headings are rewritten as it is rebuilt), leaving only the popup's "receipt" line for a separate commit. Firefox, from `extension/manifest.json` and code: `background.service_worker` is not run by Firefox (it needs `background.scripts`; a manifest may list both, Chrome and Firefox 121+ each take theirs — exact versions unverified); `sidePanel` permission and `side_panel` are Chrome-only (Firefox warns and ignores; popup.js L454 already guards `chrome.sidePanel?.open`); `use_dynamic_url` is ignored with a warning; `minimum_chrome_version` ignored, and AMO signing needs `browser_specific_settings.gecko.id`; `chrome.*` (`storage`, `alarms`, `scripting.registerContentScripts`, `action`, `permissions`, `tabs`, `windows`) resolves in Firefox; `'wasm-unsafe-eval'` is accepted; the real trap is that Firefox MV3 treats `host_permissions` (`https://*.supabase.co/*`) as optional at install, so the bridge push fails until the student grants it — unverified on the current Firefox, and the one thing to test first. `optional_host_permissions` support: unverified.
