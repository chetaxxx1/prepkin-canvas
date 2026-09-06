# Canvas extension — test plan

Written 2026-09-04, results added 2026-09-05. How we prove the Canvas loop works
in every state a real student hits, with what exists today and what still has
to be built or rented.

**Status, 2026-09-05:** Layers 1 and 2 are built and green. Layer 1: 34
end-to-end scenarios in real Chromium plus 51 unit tests, about ten seconds.
Layer 2: a real self-hosted Canvas on George's Google Cloud trial, seeded with
every state, and `test/live.test.js` passes 6/6 against it with the real
extension. Seven bugs found and fixed. One blocker is still George's: the live
bridge is on the old schema (finding 1).

## The loop under test

```
Canvas  ──►  extension  ──►  bridge (Supabase)  ──►  phone (iOS app)
(school)     reads, filters,   pair, push list,        applies list, pays
             maps, pushes      pull wallet             coins once, pushes
                 ▲                                      wallet + "paid up to"
                 └──────────────── requests ◄───────────┘
                    (focus session done, look bought — paid once, ever)
```

Plus the on-page panel (Today / week / grades / what-if / looks / focus timer)
and the skin, which have to survive Canvas's own markup changes.

## What I found today, before testing anything

These change the plan, so they come first.

1. **The live bridge is still on the old, code-only schema.** I probed the
   Supabase project in `extension/config.js` with a junk code. `bind_writer` and
   `claim_code` do not exist (404). `fetch_todo(code)` answers with no token.
   `push_todo(code, todo)` accepted a junk code with 204. So:
   - Extension v0.4.0 cannot pair. Every paste of a code fails with "That code
     is not one the app is offering."
   - The app cannot claim a code either, so it falls back to mock data.
   - The security hole the schema header describes is live right now: anyone
     with the shipped key can push a task list to any code.
   - My probe may have written one junk row keyed `zz` with an empty list.
     Harmless. Re-running the schema does not remove it; delete it by hand or
     let the purge take it in 30 days.
   **Fix: re-run `bridge/schema.sql` in the Supabase SQL editor** with pg_cron
   enabled. Five minutes, George only. Nothing below pairs until this is done.
   **Still open on 2026-09-05.** The extension now says "The bridge is out of
   date" instead of blaming the code (row A9).

2. **First-run "Link" never binds a token.** `popup.js` onboarding step 3 stores
   the code and syncs. It never sends the `pair` message, so `bind_writer` is
   never called. The first sync says "Not paired yet — paste the code from the
   app." The main-screen Save button does it right. **Confirmed by row A5,
   fixed:** the Link step now sends `pair` like Save does.

3. **Sandbox README says use `http://localhost:3000`. The extension refuses
   http.** `originOf()` in `background.js` and the Connect button in `popup.js`
   both require `https:`. The sandbox needs an https front door. One line with
   Caddy on the Mac does it (below). **The sandbox README now says so.**

4. **A missing assignment graded 0 probably pays coins.** When a teacher enters
   0 for work never handed in, Canvas makes a submission row with
   `workflow_state: graded`, `submitted_at: null`, `graded_at` set,
   `missing: true`. `submissionTime()` returns `graded_at` for any `graded` row,
   so the phone marks it done and pays 30 coins for work the student skipped.
   Same question for `excused`. **Decided and fixed (C12, C13):** a missing
   zero stays owed and unpaid; excused work leaves the list. No coins either way.
   Work graded with no online submission and *not* marked missing (on paper,
   in class) still counts as handed in.

5. **There is no Canvas we can write to.** Free-for-Teacher is gone. George's
   Dartmouth account is a student: read only. This Mac is arm64 with no Docker,
   and Canvas's build wants x86. A real sandbox means a VM — see Layer 2 for
   the free-credit answer.

   Two more, found by the harness on 2026-09-05 and fixed:
   - **The to-do sweep undid the leftover filter.** The per-course pass drops an
     old, undated, unmarked assignment on purpose; the sweep listed it and the
     merge added it back. Now the sweep only adds work the course pass never
     looked at (`examinedIds`). The same change stops a quiz arriving twice,
     once as an assignment and once under its quiz id (C16).
   - **A list too big for the bridge unpaired the laptop.** The bridge answers
     400 to both "not paired" and "payload too large"; the extension treated
     both as unpaired and threw the token away. It now reads the message (C30).
   - **Weights were never checked against the course.** `readSchool` looked at
     `course.weighted`, a field nothing set. It now comes from Canvas's
     `apply_assignment_group_weights` (C33).

6. **Existing coverage:** 43 mapping tests pass (`node --test`). The iOS side has
   bridge, ledger and game-state tests covering "pays once, resync does not pay
   twice, cannot untick what Canvas says you handed in." Nothing runs the real
   extension in a real browser. Nothing exercises paging, 401s, two schools,
   unpair, or the request queue end to end.

## Four layers

| Layer | What it is | Who | Cost | Catches |
|---|---|---|---|---|
| 0 | Unit tests on `canvas.js` (exists) | me | 0 | Mapping and date-window rules |
| 1 | Fake Canvas + fake bridge + real extension in real Chrome (Playwright) | me | 0 | Everything in the matrix, deterministically, in minutes |
| 2 | Real self-hosted Canvas on a VM, seeded with every state | George rents, I drive | ~$0.06–0.10/hr, off when idle | Wrong field names, real markup, feature flags |
| 3 | George's real Dartmouth account on the `prepkin-today` sim | George | 0 | The one thing fakes cannot: a real school |

Layer 1 is where the scenarios live. Layer 2 keeps Layer 1 honest: it records
real API responses into fixtures that Layer 1 replays. Layer 3 is the final
smoke test.

### Layer 1 — the harness I will build

New folder `test/`, nothing added to `extension/`.

- **`test/fake-canvas/server.js`** — Node, no dependencies beyond Playwright.
  Serves `https://localhost:8443` with a self-signed cert (openssl is on the
  Mac; Chrome is launched with `--ignore-certificate-errors`). Implements the
  six endpoints the extension calls: `users/self`, `courses`, `users/self/colors`,
  `courses/:id/assignments`, `courses/:id/assignment_groups`, `users/self/todo`.
  Real `Link` paging headers. A control endpoint (`POST /__scenario`) loads a
  scenario file and mutates it mid-test: submit, grade, excuse, conclude a
  course, log the student out (401), slow down, return junk. Also serves one
  HTML page with Canvas's skeleton ids (`#application`, `#content`,
  `.ic-Layout-*`) so the panel and skin inject.
- **`test/fake-canvas/scenarios/*.json`** — one file per world: a plain
  semester, a 250-assignment semester (paging), two schools, a TA who also
  studies, a dead 2020 course, a course with no term, and so on.
- **`test/fake-bridge.js`** — the seven RPC functions from `schema.sql`, same
  rules (15-minute claim window, first laptop wins, token hashes, 256 KB cap,
  400/404 on a dead pairing). Lets the matrix run with no network and lets me
  fake "the phone unpaired" or "the bridge is down" on demand.
- **`test/fake-phone.js`** — acts as the iOS app against either bridge:
  `claim_code`, read what the extension pushed with `fetch_todo`, push coins
  and `requestsAppliedAt` with `push_state`. This is how the two-way scenarios
  get asserted without the simulator.
- **`test/e2e/*.spec.js`** — Playwright, `channel: 'chrome'`, headed, persistent
  context, `--load-extension` pointed at a scratch copy of `extension/`. The
  copy's manifest gets `https://localhost:8443/*` added to `host_permissions`
  so no permission click is needed, and its `config.js` points at the fake
  bridge. Tests drive the service worker directly
  (`serviceWorker.evaluate(() => syncNow(origin))`), read `chrome.storage.local`,
  and open `popup.html` as a page for the pairing flow and its error copy.
  The panel sits in a closed shadow root, so panel checks are screenshots plus
  storage state, not DOM queries.
- **`npm run test:e2e`** — target under three minutes for the whole matrix.

### Layer 2 — real Canvas on a VM

`design/canvas-skin/sandbox/README.md` already has the provisioning steps and
`seed.py`. Two changes:

- **TLS.** After the SSH tunnel, on the Mac:
  `caddy reverse-proxy --from https://localhost:8443 --to localhost:3000`.
  Same origin the harness uses, so the same test manifest works.
- **Record mode.** The fake server gets `--record`, which proxies to the real
  Canvas and writes every response into `scenarios/recorded/`. Then the matrix
  replays real shapes forever, and a Canvas change shows up as a fixture diff.

`seed.py` has never been run; expect one or two field names to need fixing.
Add to the seed: a resubmission after grading, a quiz that also appears in the
assignments list, an assignment with section overrides, a New Quizzes item, a
graded discussion, and a TA enrollment for the primary student in one course.

**Free options, researched 2026-09-04.** There is no free hosted Canvas any
more: Free-for-Teacher is closed, its promised replacement has no name, price
or signup date yet (instructure.com/try-canvas only offers a sales demo), and
Canvas Network only lets you *take* courses. A university's `*.test` and
`*.beta` instances belong to the school's contract, so do not use Dartmouth's
for this.

What is free is cloud credit, and it covers Layer 2 comfortably:

| Provider | Credit | Window | Needs a card | x86 |
|---|---|---|---|---|
| Google Cloud | $300 | 90 days | Yes, for identity only; no charge unless you upgrade | Yes |
| DigitalOcean | $200 | 60 days | Yes | Yes |
| Azure | $200 | 30 days | Yes, plus phone | Yes |
| Oracle Always Free | — | forever | No | x86 shape is 1 GB, too small; the big one is ARM |
| GitHub Codespaces | 120 core-hours/mo | monthly | No | 15 GB disk, too tight for the Canvas images |

**Recommendation: Google Cloud trial**, an `e2-standard-4` (4 vCPU, 16 GB,
x86) with a 160 GB disk, Ubuntu 24.04, powered off between sessions. Then the
steps in `design/canvas-skin/sandbox/README.md` as written. George makes the
account; I cannot create accounts or spend money.

### Layer 3 — a real school

- `prepkin-today` sim, George's Dartmouth account, extension reloaded, fresh
  code. Read-only. Confirms the 2020 orientation course is gone, counts match,
  grades match the Canvas grades page.
- Optional: `dartmouth.test.instructure.com` is a copy of prod that Instructure
  wipes every few weeks. If George can log in there, submitting one real
  assignment is harmless and proves submit → `submittedAt` → 30 coins, once.
  Question for George: does that login work?

## The scenario matrix

Every row gets a pass / fail / blocked mark. "Phone" means what the fake phone
or app must see.

### A. Pairing

| # | Scenario | Expected |
|---|---|---|
| A1 | Fresh code from app, pasted within 15 min | Paired; first sync sends N assignments |
| A2 | Same code pasted on a second laptop | Refused: "expired or already paired" |
| A3 | Code pasted after 15 min | Refused, same message |
| A4 | Code with O/0/I/1 typos, lowercase, spaces | Normalised to 8 chars or rejected before any request |
| A5 | First-run "Link" path (finding 2) | Must pair. Today it does not |
| A6 | Phone unpairs (`delete_pairing`) then extension syncs | 404 → token dropped, popup says "Tap New code" |
| A7 | Bridge unreachable | "Could not reach the bridge"; Canvas data still saved locally; panel still works |
| A8 | No `config.js` | Reads Canvas, popup says missing config, no crash |
| A9 | Old schema live (today's state) | Pair fails with a clear message, not a silent hang |

### B. Connecting a school

| # | Scenario | Expected |
|---|---|---|
| B1 | Logged in, real Canvas | Connected as <name>; skin injected; sync runs |
| B2 | Canvas but logged out (401) | "That is Canvas, but you are logged out"; permission dropped |
| B3 | A site that returns `{"id":1}` | "Does not look like Canvas"; permission dropped |
| B4 | An http site | No Connect button at all |
| B5 | Two schools connected | Ids prefixed by host; both lists in one push; no collisions |
| B6 | Remove one school | Its tasks gone from the next push and from the phone; other school intact |
| B7 | Chrome revokes the permission behind our back | Origin silently treated as gone; no errors on sync |
| B8 | Login expires after connecting | That school keeps its last good list; other schools fresh; popup says "log in again" only when all fail |

### C. What gets synced — the assignment lifecycle

| # | State in Canvas | Extension | Phone |
|---|---|---|---|
| C1 | Unsubmitted, due in 2 h / 1 d / 6 d / 13 d | Shows | Task, not done |
| C2 | Due in 15 d | Hidden (14-day horizon) | Absent |
| C3 | Overdue 1 d / 6 d | Shows | Task, not done |
| C4 | Overdue 8 d | Hidden (7-day tail) | Absent |
| C5 | No due date, has points | Shows, sorts last | Task |
| C6 | No due date, no points, created 30 d ago | Shows | Task |
| C7 | No due date, no points, created 90 d ago | Hidden | Absent |
| C8 | Submitted, ungraded | `submittedAt` set | Done, pays 30 once |
| C9 | Submitted 4 d ago | Hidden (3-day grace) | Absent, but ledger keeps the payment |
| C10 | Graded 41/50 | `submittedAt`, `score` 41 | Done, no second payment |
| C11 | Graded 0 after a real submission | `score` 0, not null | Done, paid once |
| C12 | **Missing, teacher entered 0, never submitted** | Today: `submittedAt = graded_at` | Today: pays 30. Decide: should not |
| C13 | **Excused** | Today: treated as submitted | Decide: done without coins? |
| C14 | Late, accepted | Submitted | Done, paid once |
| C15 | Resubmitted after grading | Still one task, one payment | No double pay |
| C16 | Classic quiz, untaken | Appears via assignments (`a<id>`) and todo (`q<id>`) | App collapses by title + course + due; one row |
| C17 | Classic quiz, taken | Submitted | Paid once |
| C18 | New Quizzes (LTI) item | Appears as an assignment | Task |
| C19 | Graded discussion, no reply yet / replied | Not submitted / submitted | Task / paid once |
| C20 | Section override: my section due Friday, default null | `dueAt` is my Friday, not undated | Correct date |
| C21 | Locked (`unlock_at` in future), due in 5 d | Shows | Task |
| C22 | Unpublished assignment | Canvas never returns it | Absent |
| C23 | Course whose term ended 2020 | Course and all its work dropped, including via the todo sweep | Absent |
| C24 | Course `workflow_state: completed` | Dropped | Absent |
| C25 | Course with no term at all | Kept | Present |
| C26 | Student is TA elsewhere: `grading` todo items | Dropped | Absent |
| C27 | 250 assignments in one course (3 pages) | All pages read, this week's work present | Present |
| C28 | 500 assignments (5 pages, cap is 4) | Page 5 lost; note whether that is acceptable | — |
| C29 | `Link` next page pointing off-origin | Refused | — |
| C30 | Payload over 256 KB | Bridge raises; popup shows an error, not "Sent" | Old list stays |
| C31 | Dashboard colour set / missing / junk `red;background:url(` | Hex / null / null | No markup on the phone |
| C32 | Course grade null vs 0 | null / 0 | "No grade yet" vs 0 |
| C33 | Weighted vs unweighted assignment groups | Weights / null | Panel asks instead of guessing |
| C34 | Junk JSON, HTML instead of JSON, network drop on page 2 | Never throws; that page lost, rest kept | — |
| C35 | Due date Canvas cannot parse | Kept, undated | Task, no date |

### D. When it syncs

| # | Scenario | Expected |
|---|---|---|
| D1 | Land on a connected Canvas page | Sync, once per 10 min per school |
| D2 | Click around 20 pages in a minute | One sync |
| D3 | 30-minute alarm | Sync; alarm survives browser restart |
| D4 | Sync now | Always runs, no rate limit |
| D5 | One of two schools fails | Failing school keeps last list; badge count still right |

### E. Two-way: coins and requests

| # | Scenario | Expected |
|---|---|---|
| E1 | 25-min focus finishes | Request queued with `at`; pushed; phone pays; `requestsAppliedAt` returned; request retired |
| E2 | Phone has not read the push yet | Request re-sent on every push until `requestsAppliedAt` covers it |
| E3 | Same request arrives three times | Paid once (ledger key) |
| E4 | Focus timer survives navigating Canvas | Countdown continues; ends on alarm even with the tab closed |
| E5 | Give up mid-focus | Nothing queued, nothing lost |
| E6 | Buy a look with enough coins | Request queued; phone deducts; `owned` comes back; look stays on |
| E7 | Buy with too few coins | Phone refuses; extension shows the real balance next pull |
| E8 | Wallet never published | Shop says "no balance yet", never invents a number |
| E9 | 51 requests queued | Oldest dropped (cap 50); note if that can lose a payment |
| E10 | Request with junk `at` | Phone drops it rather than risk paying twice |

### F. Panel and skin (Layer 2 mostly; Layer 1 for smoke)

| # | Scenario | Expected |
|---|---|---|
| F1 | Panel mounts on a connected page, closed shadow root | Page scripts cannot read grades |
| F2 | Mascot toggle off | Panel gone, skin stays |
| F3 | Dark mode | Warm charcoal; Canvas course colours untouched |
| F4 | Feature flags: `modules_page_rewrite`, `student_grade_summary_upgrade`, `instui_nav`, `instui_topnav`, `files_v2`, `widget_dashboard` | Page degrades to plain Canvas, never half-styled |
| F5 | Restrict quantitative data on | Grades view says so; no crash |
| F6 | Very long title, no due date, empty course | Truncates; no layout break; empty state copy |
| F7 | `panel.css` fails to load | Host removed; page untouched |

### G. Phone side (add to iOS tests)

| # | Scenario | Expected |
|---|---|---|
| G1 | C12 and C13 | Per the decision below |
| G2 | Remove a school | Tasks vanish; paid ledger entries stay |
| G3 | Two schools, same assignment id | Two tasks |
| G4 | Snapshot with 0 tasks after one with 5 | List really clears |

## Decisions

1. **Missing-with-zero and excused (C12, C13).** Decided 2026-09-04: neither
   pays. Built: a missing zero stays on the list as owed; excused leaves the
   list. If George would rather see excused work as a ticked row with no coins,
   that is an iOS change (a new `excused` flag on the wire) — not done.
2. **Layer 2.** George asked for a free route. Answer above: the Google Cloud
   trial. Waiting on George.
3. **Dartmouth test instance.** Never tried. Recommendation after the research:
   skip it. It is the school's system, and Layers 1 and 2 cover what it would
   have shown.

## Results, 2026-09-05

`npm test` — 50 unit tests, pass. `npm run test:e2e` — 34 scenarios, pass.

| Rows | Result | Note |
|---|---|---|
| A1–A9 | pass | A1, A4, A5 drive the real popup over CDP. A8 by nulling the bridge config inside the worker. |
| B1–B8 | pass | B4 tests `originOf`; the hidden Connect button itself is UI, not automated. B7 by listing an origin Chrome never granted. |
| C1–C14, C16, C18–C21, C23–C35 | pass | One world of 26 assignments across 5 courses (C1–C26), then paging, off-origin links, oversize payload, colours, weights, junk. |
| C15, C17 | covered by construction | Same id before and after a resubmission or a quiz attempt; the phone's ledger key pays once (iOS `testResyncingDoesNotPayTwice`). |
| C22 | n/a | Canvas never returns unpublished work. |
| C28 | pass, documented | The four-page cap really does lose the fifth page. 400 assignments due within two weeks is not a real course; left as is. |
| D1–D5 | pass | |
| E1, E2, E4–E9 | pass | E1 also shows the one extra re-send after payment; harmless by design. |
| E3, E10 | iOS | `testTheSameRequestArrivingTwiceIsPaidOnce`, `testNonsenseFromTheBridgeIsIgnoredRatherThanPaid`. Not re-run this session. |
| F1, F2 | pass | Closed shadow root confirmed; mascot toggle confirmed. |
| F3–F7 | Layer 2 | Need real Canvas markup and feature flags. |
| G1–G4 | iOS | G1 is now moot on the phone: the extension never sends a paid-looking missing or excused item. G2 is `testDisconnectingClearsTheCanvasSide`; G3, G4 follow from id prefixes and `applyCanvas`. Not re-run this session. |

Not verified against real Canvas yet (Layer 2): the exact field shapes the fake
uses for `missing`, `excused`, `apply_assignment_group_weights`, the to-do
sweep's contents, and section-override due dates. They follow the API docs;
the record pass will confirm them.

## Layer 2 results, 2026-09-05

The VM took 16 minutes to build, not 90: Instructure ships prebuilt images.
`seed.py` needed one fix (a student cannot backdate a submission; the teacher
sets lateness through Canvas's late policy status). Everything else ran first
time. `test/live.test.js`, 6/6:

| Row | What the real Canvas did |
|---|---|
| L1 | Recognised as Canvas; panel mounts in a closed root on real pages |
| L2 | Every seeded state arrives as the fake predicted: submitted, graded, late, resubmitted, on paper, missing-zero, excused, undated, override date, graded discussion, classic quiz once |
| L3 | A real submission shows as handed in on the next sync; a grade shows as the score |
| L4 | A zero entered before the due date stays owed; excusing takes it off |
| L5 | Screenshots of dashboard, panel open, assignments, grades, modules, planner, empty course in `design/signoff/canvas-live/` |
| L6 | The two flags this build has, flipped and screenshotted |

`test/compare-shapes.js` over the recorded replies: every field the fake
assumes is present, with the enum values the fake uses. `apply_assignment_group_weights`
is always sent. `has_overrides` is not sent in the list, but `due_at` already
carries the student's own override date. The to-do sweep uses `assignment`
for graded quizzes; `quiz` only for ungraded ones.

Real-Canvas facts that changed code or tests:
- **A TA course listed its assignments as homework.** Found by L2, fixed:
  a course with no student enrollment is not your coursework.
- **`missing` is only true after the due date.** A zero entered early is a
  `graded` row with no submission time and `missing: false`. The rule is now:
  for online submission types, a grade without a submission time is never
  "handed in"; for on-paper or no-submission types it is.
- A student cannot backdate `submitted_at` (403), masquerade or not.
- A sequential module with a must-view page locks the assignment behind it:
  it still lists, and submitting is refused (403).
- The six flag names in RESEARCH.md do not exist in this build. Only
  `modules_page_rewrite_student_view` and `responsive_student_grades_page`
  remain switchable. The modules one disables the page outright here.
- New Quizzes is not in the open-source build; C18 stays unverified.

## Round 3, 2026-09-05 afternoon: stress, the phone in the loop, parity

Asked for: keep testing, fix what breaks, cover what BetterCampus has, prove
the sync into the app, stress it.

**New suites.** `test/stress.test.js` (8 rows: slow school, dead school,
throttled course, request races, fifty syncs, a heavy semester, badge count)
and `extension/content.test.js` (11 rows on the panel's date, grade and
safety helpers, run in four time zones). The panel's pure functions are now
exported for node. `test/phone-loop.js` holds the fake bridge and the real
extension open while the real iOS app, built against the fake bridge on the
`prepkin-fresh` simulator (which trusts `test/make-cert.sh`'s certificate),
pairs and syncs by hand.

**Proven with the real app on the simulator.** The app claimed a code on the
bridge, the extension bound to it and pushed six tasks, the app fetched them,
ticked the two Canvas says were handed in, paid 30 each (60 → 120), then a real
submission and a finished focus session paid again (→ 175), and the app
published its wallet and watermark back. Screenshots were taken along the way.

**Bugs found this round, all fixed:**
- **A Canvas that never answers hung every sync forever.** No fetch had a
  timeout. Now every request aborts at 20 s (X2).
- **One throttled course vanished from the phone.** A 429 on a course's
  assignment list used to drop that course's tasks until the next sync. Now
  the course keeps its last good list (X3).
- **Requests could be lost in a race.** Queueing a finished focus session
  while the wallet pull retired paid ones was a read-modify-write race on
  storage. One lock now serialises every change to the queue (X4, X5).
- **The phone's "paid up to" watermark dropped milliseconds**, so a request
  stamped 12:06:26.126Z was never retired by a watermark of 12:06:26Z and was
  re-sent on every push. Seen live on the simulator; the app now stamps with
  milliseconds (`SupabaseCanvasClient.stamp`, with a test).
- **Page messages were accepted from frames.** An embedded same-origin tool
  could have driven the timer or filed spend requests. Only the top frame
  may now (B9).
- Panel: "yesterday" was elapsed hours, not a calendar day, and mislabelled
  across a clock change; what-if targets offered two choices instead of four
  below a C; a group weight of exactly 0 was read as "not published"; a look
  removed from the catalog left a ghost look; a wallet that changed between
  paint and click could go negative; colours from storage went into a style
  attribute without a second check.
- Two iOS tests were stale after the Sprout scene rename (night → deep,
  meadow → kelp); updated.

**BetterCampus parity.** `design/canvas-skin/BETTERCAMPUS-PARITY.md` has the
full table, the ten gaps ranked, and what not to copy. Prepkin already has
the two headline features (GPA and what-if). Gap #1, the next due date on the
dashboard card itself, is now built: each card of the student's own courses
carries "Due Fri 8:03 AM · Problem Set 7" (or "Was due … · still counts" in
amber, never red), updates on every sync, and disappears with the cards
toggle. Verified on the fake page (F3) and on the real sandbox dashboard
(screenshot `07-dashboard-cards.png`). The dark-mode assignment page keeps
its submit button visible (`08-dark-assignment.png`), which was BetterCanvas's
worst bug. Gaps #2–#10 remain open; #3 (density toggle) and #4 (iframe dark
mode) are the next cheapest.

**Counts now:** unit 62, e2e 36, stress 8, live 6, iOS 129 — all green.

## Round 4, 2026-09-05 evening: the Receipt page skin

George chose the direction (design/canvas-skin/EXTENSION-FEATURES.md, option 1:
Receipt page, buddy stays). Built R1–R9 the same evening; every row tested
three ways: unit (`extension/receipt.test.js`, 14 rows: papers ≥ 7:1, the
catalog, classes, rows, kill reasons, and a stylesheet lint that fails the
build if any rule ever selects a button, sets `font-family`, a shadow, a lift,
red, a brand variable or an InstUI hash), browser (`test/receipt.test.js`, 12
rows on the fake pages: no-flash boot, the three kill switches plus OS forced
colours, off = no classes and no inline style, every dashboard/modules/
assignment rule and what it must leave alone, all six papers × light/dark with
course colours untouched, the popup receipt with Put back / Undo / Show me
surviving reload and navigation, a sidebar that lands late, reduced motion,
Due next with Missed in amber), and live (`live.test.js` L7: every
load-bearing selector on the real Canvas, the receipt read from the real
dashboard and modules page, rendered-pixel checks of the paper in both modes).

What the real Canvas taught this round, all handled:
- Modules are created unpublished whatever the create call says; a student sees
  nothing (only Canvas's hidden template row) until each is published.
- Files and Outcomes tabs are admin-only until the course has a file or an
  outcome; the "menu items dimmed" row now counts what the course shows.
- Conferences and Collaborations are account-disabled here (500 on the tabs
  API), so the rule covers two of its four on this Canvas.
- The dashboard heading is an InstUI Heading (`data-cid="Heading"`), not an h1;
  the card header block, the assignments-index group headers and containers,
  the breadcrumb bar and its links, module/assignment row titles, InstUI text
  inputs and status pills all needed their own paper or ink in dark. A probe
  that lists every light surface left on a page found them; it is in the
  scratch notes and easy to re-run.
- The dashboard sidebar paints white for about a second while Canvas fills it
  by XHR, then settles to the paper. A 600 ms screenshot lies; the pixel check
  waits 1.8 s.
- A locked assignment (sequential module) renders no prose at all.

Deviations from the spec, on purpose: Manila and Vellum link inks darkened to
clear AA (5.2:1 and 6.2:1; body ratios unchanged); no Canvadocs permission; the
buddy and the card line stay on the page, listed on the receipt with one-click
Take off.

**Counts now:** unit 76, e2e 36, stress 8, Receipt browser 12, live 7, iOS 129.

## Round 5, 2026-09-05 night: the UI

Design context now lives in `PRODUCT.md` and `DESIGN.md` at the repo root (the
`impeccable` skill reads them). The popup and the buddy panel were rebuilt on
that system: one family (`ui-rounded`, the iPhone app's voice), warm-tinted
neutrals inherited from the paper, mint as the single accent, amber only for
"still counts"; lists divided by hairlines instead of cards inside cards; a day
rail in the popup with a dot in each course's own Canvas colour; the buddy's
voice at the top of the popup; pairing hidden once the phone is linked; the
popup follows the dark switch. Motion 150–220 ms ease-out-quint, off under
reduced motion. Captures in `design/signoff/extension-ui/` (fake pages) and
`design/signoff/canvas-live/` (real Canvas). Every earlier test still passes:
the ids the tests hold are unchanged.

## Round 6, 2026-09-05 night: production pass

Every view of the popup and panel captured light and dark
(`design/signoff/extension-ui/`, 24 files) and polished: the first-run head stays
neutral until set-up is done, look tiles show their real paper, the look sheet
prints light and dark stocks on two lines, titles may take two lines in the
popup, the empty day shows the buddy at rest, no em dashes or arrows in any
student-facing string, no "sync" in copy. Hardening: sign-in pages get neither
paper nor buddy (before paint and after), Canvas's ENV is read once per page,
the panel is a labelled dialog with a controls relation on the launcher.
Version 0.5.0. `design/RELEASE-CHECKLIST.md` lists what is done and what only
George can do (schema, reload, privacy URL, listing, art sign-off, VM).

**Final counts:** unit 77 · Receipt browser 13 · e2e 36 · stress 8 · live 7 · iOS 145.

## Round 7, 2026-09-05 late: Mobbin patterns and twelve papers

Reference patterns from Mobbin shaped four changes: a time column read
straight down with day headers that carry the date and a relative "in 2h 24m"
on the next item (Tiimo, Outlook); a ring around the buddy on the focus card
with "+5" (Tiimo, Toggl, Oura); Light / Dark / Auto as a segmented control
(Matter, Binance); a "Linked" moment after pairing (WHOOP). Long days fold
after four rows.

The paper catalog doubled: Rose, Lavender, Sage, Sky (light) and Ink, Moss
(dark), every one measured (body 13.8:1 to 14.4:1, links 4.5:1 or better),
and four Looks that wear them: Blossom, Lavender Haze, Meadow, Skyline. Look
tiles now show a scrap of the page they make. `design/signoff/papers/gallery.html`
shows all twelve on the real Canvas Modules page. The active course tab takes
the paper's ink on dark papers (found in that gallery).

**Counts:** unit 77 · Receipt browser 13 · e2e 37 · stress 8 · live 7 · iOS 145.

## Round 8, 2026-09-06: themes and the dashboard summary

Twelve themes (paper pair + accent + header wash + inline texture), the Today
block at the top of the dashboard, the timer visible while running. Unit tests
hold every accent to 4.5:1 on both paper tones and check the texture SVGs
(one caught: a double-encoded filter reference painted the grain solid).
Browser rows R7 (theme: texture, wash, course colour untouched) and R10 (the
Today block: counts, Start, no grades, Put back). Captures per theme, light
and dark, in `design/signoff/themes/`; the real-Canvas gallery is
`design/signoff/themes/gallery.html` (48 captures, VM restarted at 34.68.124.132).
Live 7/7 on the restarted Canvas after every navigation was made to wait for
the DOM rather than `load` (a fresh Canvas serves its first pages slowly), and
the flag test now resets its flags in a `finally` (an aborted run had left the
modules rewrite on).

**Counts:** unit 79 · Receipt browser 15 · e2e 37 · stress 8.

## How to run

```bash
npm test              # mapping and panel rules, no browser (also try TZ=Asia/Kolkata npm test)
npm run test:e2e      # real extension in Chromium; HEADED=1 to watch
npm run test:stress   # slow, dead, throttled schools; races; volume
npm run test:receipt  # the Receipt page skin on the fake pages, real Chromium
# Layer 2, with the VM running and its tunnel open:
ssh -i ~/.ssh/prepkin-canvas-sandbox -N -L 3000:localhost:3000 canvas@<VM IP>
CANVAS_TOKEN=<admin token> node --test test/live.test.js
node test/compare-shapes.js
# The real app on a simulator against the fake bridge:
test/make-cert.sh prepkin-fresh              # once: a lasting cert, trusted by the simulator
# build the app with ios/Resources/bridge-config.json pointing at https://localhost:8443 (restore it after)
PREPKIN_CERT_DIR=~/Library/Developer/prepkin-canvas-test-deps/certs node test/phone-loop.js
# then in the app: Today → sliders; the driver prints the code the app claimed;
# write it to the pair-code file the driver names, and watch the bridge calls.
```

The VM: `canvas-sandbox` on George's Google Cloud trial. Stop it in the console
when idle; the disk keeps everything. Its external IP can change on restart.
Admin login `admin@prepkin.test`, password in `~/canvas-admin.txt` on the VM;
seeded logins and the password are printed by `seed.py`.

Playwright and its Chromium live in `~/Library/Developer/prepkin-canvas-test-deps`
and `~/Library/Caches/ms-playwright`, outside the iCloud-synced repo. First time
on a new Mac:

```bash
mkdir -p ~/Library/Developer/prepkin-canvas-test-deps && cd $_ && npm init -y && npm i playwright@1.62.1 && npx playwright install chromium
```

Branded Google Chrome ignores `--load-extension` since version 137, so the
harness uses Playwright's Chromium. The self-signed cert is made fresh in a temp
folder on every run.

Files: `test/fake-canvas.js` (Canvas + bridge), `test/scenarios.js` (Canvas
object builders), `test/fake-phone.js` (the app's half), `test/harness.js`
(launch, patched manifest), `test/popup.js` (CDP popup driver),
`test/e2e.test.js` (the matrix).

## Order of work

1. George: re-run `bridge/schema.sql` in Supabase. Then reload the extension
   and pair with a fresh code — nothing pairs until then.
2. ~~Layer 2~~ done 2026-09-05. Left for a design pass, not a test pass: the
   skin itself on the real pages (F3–F6), from the screenshots.
3. George: Dartmouth smoke on `prepkin-today` with the reloaded extension.
