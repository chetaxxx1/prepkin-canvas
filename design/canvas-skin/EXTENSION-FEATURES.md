# Chrome extension — the feature list

Written 2026-09-05. What the extension has, what the research says to build next,
and where the two disagree. Sources: `CONCEPTS-SELECTION.md` (the pick: Receipt),
`SPEC-RECEIPT.md` §10–12 (catalog, build order, refusals), `BETTERCAMPUS-PARITY.md`,
`design/CLAUDE-DESIGN-PROMPT-EXTENSION-V4.md`, and the code.

## A. What exists today, all tested (keep)

| Feature | Where | Tests |
|---|---|---|
| Connect any school's Canvas, per-site permission, "is this Canvas?" check | `background.js`, `popup.js` | e2e B1–B9 |
| Pair with the phone by code, token exchange, unpair | `background.js` | e2e A1–A9 |
| Sync: courses, assignments, submissions, grades, the to-do sweep; paging; 14/7-day window; concluded-course and TA-course filters; missing/excused rules | `canvas.js`, `background.js` | unit 51, e2e C1–C35, stress X1–X8, live L1–L6 |
| Two-way bridge: focus sessions and look purchases paid by the phone once | `background.js` | e2e E1–E9, phone loop |
| Buddy panel on Canvas pages: Today / This week / Overdue, next-up, focus timer (15/25/45), grades with sparkline and recent scores, what-if calculator, looks shop | `content.js`, `panel.css` | unit 11, e2e F1–F3, live L5 |
| Skin toggles: warm theme and cards, tidy sidebar, dark mode | `skin.css`, popup | e2e F2 |
| Next-due line on each dashboard card (new 2026-09-05) | `content.js` | e2e F3, live L5 |
| First-run popup, coin chip, Sync now | `popup.js` | e2e A1, A4, A5 |
| Store packaging with checks | `bridge/package.sh` | run |

## B. What the research says to build: Receipt

The pick, with two conditions. "It quietly takes the junk off your Canvas pages
and fixes what Canvas gets wrong, then shows you the list of everything it took
so you can put any of it back with one click." Build order from the spec:

| # | Feature | What it is | Size |
|---|---|---|---|
| R1 | **Navigation plumbing** | Re-run the skin's JS on Canvas's own page changes (`pushState`, `popstate`, `hashchange`, `canvasReadyStateChange`, one debounced observer). Today the only re-render trigger is a data change. Prerequisite for everything below. | ~120 JS |
| R2 | **Kill switches and tokens** | Skin off when the student runs high contrast, on New Quizzes and on the widget dashboard; the token layer on `html.pk-on`; the reduced-motion block. | ~70 CSS, ~80 JS |
| R3 | **Subtract and fix, per page** | Duplicate To Do gone from the sidebar, Coming Up un-truncated, 8px card hero, a right-aligned tabular due column on Modules, a pinned module header, four low-use course tabs dimmed (never hidden), Word-paste colours repaired, the flash-error red left alone. Every rule has a "Show me" twin. Never sets `font-family`, a radius, a shadow, a hover lift; never writes any property on a button. | ~360 CSS |
| R4 | **The receipt, in the popup** | "This page": every change listed, **Put back** per item (15 keys, remembered forever), **Show me** (dashed reveal on the page), the toolbar badge. No deletion ships without its undo. | ~90 CSS, ~250 JS |
| R5 | **Sidebar dedupe and un-truncate** | The JS half of R3. Needs both To Do variants on a real dashboard — the sandbox has them. | ~15 CSS, ~70 JS |
| R6 | **Selector file and smoke check** | Every Canvas selector in one annotated file; a live check that each still matches, run against the sandbox on every Canvas release. | ~150 JS |
| R7 | **Papers and the Looks split** | Six paper stocks (Newsprint, Manila, Bond, Vellum, Carbon, Blueprint), each card printing its measured contrast; a Look owns a paper pair and an accessory; dark is free forever; Night Shift keeps its price and gets Blueprint; `dark: true` deleted. | ~60 CSS, ~90 JS |
| R8 | **The seam** | A brightness veil on Files v2 and third-party tools in dark; an optional Canvadocs permission with honest popup copy. Last, on purpose. | ~15 CSS, ~50 JS |
| R9 | **Popup "Due next"** | Today across every class, in the popup, from data already synced. Amber "still counts". A **Missed** section. The one screenshot-worthy screen and, per the spec, the funnel. | ~70 CSS, ~120 JS |

Spec estimate for a human team: 19 days.

**Status, 2026-09-05 evening — decided: option 1 below, and built.** R1–R9 are
in, with these notes:

| # | Built | Tests |
|---|---|---|
| R1 | `boot.js` at document_start puts the classes on before paint; `content.js` re-reads the page on a debounced observer, `canvasReadyStateChange`, `popstate`, `hashchange`. No `webNavigation` permission was needed. | receipt R1 ×2 |
| R2 | High Contrast (school ENV, OS forced colours, prefers-contrast), New Quizzes, widget dashboard → skin off with the verbatim sentence in the popup. Reduced-motion block owned. | receipt R2 ×3 |
| R3 | The per-page rules in `skin.css`, every one gated on its put-back class. Stylesheet lint: no property on a button, no font-family, no shadow, no lift, no red, no `css-`, no brand variable. | unit ×3, receipt R3 ×3 |
| R4 | The receipt in the popup: Taken / Fixed / Added, Put back (remembered, survives reload and navigation), Undo, Show me (dashed outline for 4 s), the off-state sentence. | receipt R4 ×2 |
| R5 | Dedupe and un-truncate are CSS gated on facts `content.js` detects (`pk-todo-dup`, `pk-logo-dup`); Recent Feedback untouched. | receipt R3, R1 |
| R6 | `selectors.js`; live L7 asserts every load-bearing hook on the sandbox and writes `selectors.json`. Two real findings on first run: modules must be published to render for a student, and Files/Outcomes tabs only exist once used. | live L7 |
| R7 | Six papers as classes, ratios computed at runtime and printed on every shop card; a Look owns a paper pair; `dark: true` and inline tints deleted; Night Shift keeps 500 and gets Blueprint. Manila and Vellum link inks nudged to `#9A4A30` (5.2:1) and `#57534A` (6.2:1) to clear AA; body ratios unchanged. | unit ×3, receipt R7 |
| R8 | Dark-only seam rule and veil on `.tool_content_wrapper`. The Canvadocs optional permission is not added: it widens the permission surface and the research says the frame interior is unauditable. | receipt (CSS lint) |
| R9 | Popup "Due next" across every class from the last sync, Missed in amber "still counts", one click to open in Canvas. `day.js` is now shared by panel and popup. | receipt R9 |

**2026-09-05 late:** the catalog grew to twelve papers and ten Looks (George
asked for skins like BetterCampus's; these are the readable version, every one
measured). Also: Auto paper mode following the OS, "+5" on a running focus
session, the popup's time column and folded days, the Linked moment.

**2026-09-06: themes and the dashboard summary.** George asked for skins with
the pull BetterCampus's have, and for a summary on the first page. Built:

- **Themes** (`extension/themes.js`): a theme is a paper pair, an accent for
  links and marks, a card-header treatment (the course band as is, or a soft
  wash of the accent over it: the course colour and its opacity stay), and an
  optional texture drawn inline in the paper's ink at 7–10% (dots, grid,
  grain, waves; no request ever leaves). Twelve, named for what students say
  they want: Classic Cream, Dark Academia, Blush, Lavender Haze, Matcha,
  Coastal, Midnight, Sunset, Cherry Blossom, Lo-fi, Cottage, Night Shift.
  Every accent is 4.5:1 or better on both tones of its paper (unit test).
  The shop shows a scrap of the page each makes, and the vibe in a line.
- **Today, at the top of the dashboard** (`#pk-today`): the buddy's line,
  counts (today, still count, this week), the next thing with Start, a focus
  button at the student's chosen length, and a Grades button that opens the
  panel. Titles, counts and dates only: grades never enter the page DOM. On
  the receipt as Added, with one-click Put back that survives reload.
- **The timer stays on screen while it runs**, panel open or not.

Not built, on purpose: the on-page dashed strip and the proofreader words
(spec §12.1), the dashcard badge fix, hiding any tab, `--ic-brand-*` writes.

## C. Where Receipt and today's extension disagree

Receipt §12.2 refuses, on the Canvas page: any mascot, coin or Prepkin colour; any
due-date colour or urgency pill; any what-if calculator or grade trend. Today's
extension puts all of those on the page in the buddy panel (opt-out), and the new
card line adds an amber "still counts". The selection doc names the cost of
following Receipt strictly: "a good utility and a bad funnel, on purpose."

Three ways to settle it:

1. **Receipt page, panel stays.** Build R1–R9 as the page layer. The buddy panel
   stays as it is, on by default, and *appears on the receipt* as one more thing
   Prepkin did to the page, with the same one-click "Take off". The card line
   stays too, listed the same way (it reads dates from the API, not the page, so
   the spec's locale objection does not apply). Honest with the student, keeps
   the funnel. **My recommendation.**
2. **Receipt as written.** Page gets zero Prepkin pixels. Today, week, grades,
   what-if, focus and looks move into the popup (R9 grows into the whole panel).
   Cleanest for a district security review; loses the on-page buddy.
3. **Skip Receipt.** Keep today's design and close the parity gaps only:
   density/sidebar-width toggle, same-origin iframe dark mode, hide-completed,
   weighted GPA option.

## D. Parity gaps that fold into the above

| Gap (BETTERCAMPUS-PARITY rank) | Lands in |
|---|---|
| #2 hide completed / duplicate To Do | R3/R5 |
| #3 sidebar width / density toggle | R4 as a Put-back key, or a popup toggle |
| #4 same-origin iframe dark | R8 |
| #6, #7 card images, page background | rejected by design (hotlinks); papers in R7 are the safe version |
| #8 submit-button contrast | R3's "never write a property on a button" + a lint test |
| #9 weighted GPA | small, panel |

## E. Testing plan for whatever is chosen

Every feature gets: unit rows where it has logic, an e2e row on the fake page,
a live row on the sandbox with a screenshot, and — for anything that removes or
dims — a Put-back row proving it comes back and stays back after a reload and a
navigation. R6's smoke check runs first and alarms when Canvas moves.
