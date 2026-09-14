# Council brief: the rest of the Prepkin Canvas extension build

**Read-only.** Do not edit, commit, branch, or run suites that need the sandbox. You may run `npm test` (unit, fast). Inspect files with cat/grep/sed.

## Where
Repo checkout: `/Users/georgeshi/Library/Developer/prepkin-worktrees/verdict` (branch main, HEAD e10d2bce). The iOS app lives in the same repo under `ios/`.

## What this is
A Chrome extension (MV3) for the Canvas LMS: dark mode + one to-do list + grades, a skin that never breaks a page, and Sprout (a fish mascot) as the door to the iOS app. Rival: BetterCampus (2M users, six LMSs, AI suite, paid pet). Students' number-one complaint about the rival is bloat; the most-loved things are themes, the to-do list, dark mode, grades.

Today's state and the full feature verdict: `design/canvas-skin/VERDICT-2026-09-14.md` (read §2, §3, §4, §6, §7 in full). What students said, feature by feature: `design/canvas-skin/reference/bettercampus/FEATURES-STUDENTS.md` (read the Summary and "Old simple vs new suite"). House rules: `design/canvas-skin/HANDOFF-2026-09-11.md` L42 (never a `css-` selector, never a property on a button, never red), plus: no uppercase tracking labels, one place per fact, say a count once, every feature has a home or is gone, no request leaves the school, no write to Canvas, no account, no AI.

Steps 1–3 of §6 are built (see §7). The council decides how to build steps 4–10.

## The five questions

**Q1. The button rule in dark mode.** `extension/receipt.test.js` L326 asserts no `skin.css` selector matches a button. Cost: on a dark paper, Canvas's text-only buttons (the syllabus's "due by" times, the calendar's month arrows, every icon-only kebab) stay in Canvas's own dark ink at 1.1–1.4:1. Two are carved out in `test/pages.test.js` `KNOWN`. Options: (a) keep strict; (b) allow ONE rule, dark only, `color` only, on buttons with no background of their own (`.btn.btn-link`-style, `[class*="baseButton"]` with transparent ground), never a submit; (c) something else. Decide, and say exactly what the lint should permit so R18 (the quiz kill switch test) and the "never touch a submit button" promise stay true.

**Q2. Tick a row done (A1).** Students' most-used gesture on the rival's to-do. Today only a Canvas submission clears a row. Design the whole thing: where the circle lives (rail "Start with"/"Then" rows, the card's one line, the planner rows, the side panel, the popup — all, or fewer?); what a tick does to the row (leaves at once / strikes for the day / moves to a Done group); undo; storage (`chrome.storage.local` done-set keyed by task id + at); reconciliation when Canvas later reports `submittedAt` or marks the task missing; how it reaches the phone (bridge payload in `extension/background.js` ~L460–500; the app already pays a ticked Canvas item once through `GameState.complete()` / `applyDoneMarks()` in `ios/Sources/Core/GameState.swift` L835–885 and `ios/Shared/DoneMarks.swift`; the widget's tick already pays coins without Canvas proof); the reward (30 coins on the phone, same as a hand-in, or none?); and the cheat surface (a student ticks everything). Also `ownTasks` (student-added tasks) already have a done handler at `extension/content.js` ~L2253. Constraint: **no write to Canvas, ever.**

**Q3. Looks tiles as real renders (D1/A4).** The Looks tab (`extension/planner.js`, `looksView` in content.js is dead) shows 26 themes as blank outlines. Wanted: every tile is a real 4:3 render of THIS student's dashboard in that theme (paper, rail, two of their cards in their Canvas colours, the accent), worn one ticked, locked ones with a price. Zero network requests. Themes include image themes (a wallpaper under a paper wash, art already bundled under `art/`). Options: (a) a CSS mini-page per tile built from the theme's tokens (`extension/receipt.js` `PAPERS`, `themeStyle()`), scaled with `zoom`/`transform`; (b) clone the live dashboard DOM into a shadow root per tile and scale it; (c) an offscreen iframe per theme; (d) pre-rendered images. Decide, with the performance budget (26 tiles, the page must not slow: `test/pages.test.js` measures card mount time skin on vs off, 2 s allowance) and a test that proves a tile shows the theme.

**Q4. The Planner tab shape (D4, B7, X2, X4, X5, X6, X7, A5, A6).** Today: seven day-columns at 1280 wide wrap titles four letters a line. Verdict says: vertical list grouped by day (Todoist Upcoming / Structured): Past due → Today → Tomorrow → next five days; drag to a day header; one "+ Add a task"; class tiles not icons; no League card; no "0 of 1 in" count. Decide: (a) vertical at every width, or columns above some width; (b) whether the rail's Start with/Then list hides while the Planner tab is open (one place per fact) and what the rail keeps; (c) how what-if (`whatIfView` L979), the course view (`courseView` L798) and the term recap (`recapView` L2046, `extension/recap.js`) get a door on the Planner tab (one line that expands? a row at the rail's foot only when due?); (d) confirm which of `panelView`, `weekView`, `looksView`, `addTaskView`, `panelViewFallback`, `leagueCard`, `gradesCard` are dead and can go (grep their call sites and tests before saying so).

**Q5. Order and cuts.** §6 lists 4 → 10 (tick, planner, looks tiles, course-home next-three, per-page pass at 1280 and 768, words, Firefox). Is that the right order for a one-person team? Should anything be cut, merged, or moved? For Firefox specifically, list what actually breaks in MV3 on Firefox from `extension/manifest.json` (side_panel, service_worker, `chrome.*`, `sidePanel` permission, `use_dynamic_url`) — facts, not guesses; say "unverified" where you cannot check.

## Report format (required)
For each question you were assigned:
1. Evidence inspected (exact file paths, symbols, line ranges).
2. Current behaviour.
3. The options and what each costs (implementation, testing, risk to the house rules).
4. Edge cases that would bite.
5. Recommendation: one option, in one sentence, then the concrete shape (what the student sees, what the code does, what test proves it).
6. Confidence (high/medium/low) and unknowns.
Plain words. Under 1,200 words per question. Never invent a file, symbol or measurement; say "did not check".
