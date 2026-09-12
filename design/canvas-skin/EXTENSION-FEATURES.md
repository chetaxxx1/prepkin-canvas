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
- **This week, at the top of the sidebar** (`#pk-week`, 2026-09-11, replaces
  the Today banner that sat above the cards): a ring per course in the course
  colour, filled by how much of that course's week is handed in; the week's
  count in the middle; arrows to the weeks either side; **Start with** (the
  oldest slipped task, or the next due) with Start and a focus button at the
  student's chosen length; **Then**, the next four, coming work before slipped
  work; the league tier when there is one; a foot that counts. Canvas's own To
  Do folds to one line under it (`#pk-todo-fold`, receipt key `todo-fold`,
  Show opens it for the page view, Put back keeps it open). The fold only
  applies while the rail is on the page: no rail, no fold. Titles, counts and
  dates only: grades never enter the page DOM. Both on the receipt as Added
  and Taken, with one-click Put back that survives reload. The pattern is
  Tasks for Canvas's (Coursicle) sidebar, which students run next to
  BetterCampus; the rings are theirs, the one-thing-first is ours.
- **The timer stays on screen while it runs**, panel open or not.
- **Your term, in numbers** (`recap.js`, 2026-09-11): the BetterCampus corpus's
  one delight, on our rules. `recapDue()` opens it only when a course's term
  end is within a week ahead or three weeks behind (courses now carry
  `termEndsAt`), or, with no dates, when every due date is two weeks gone and
  there were at least ten things. Then one quiet row in the panel opens a
  view: things handed in of total, on-time share, busiest week, the hour it
  all went in, which course asked the most, a bar per course. "Save as a
  picture" draws a 1080×1350 PNG on a canvas of our own and downloads it;
  the picture holds course names and counts, never a grade. Never a daily
  counter, never a streak.
- **Sprout, on the page** (2026-09-11): the app's own Sprout web build, copied
  into `extension/sprout/` by `sync.sh` from `ios/SproutWeb`, runs in a frame
  of the extension's origin (`#prepkin-sprout`, its own closed host, because
  the panel redraws with innerHTML and a moved frame reloads). No bubble. On
  the dashboard he lives in a tank: a band of water at the top of the This
  week card (`.pk-w-tank`, 108px), the week and the work flowing under him —
  Finch's home stack, ClassDojo's monster card. The frame is absolute in the
  document over the band, so he scrolls with the card and nothing is ever
  under him; the launcher covers the band with the count badge in its corner,
  and the panel opens to his left, top-aligned. Four placements were built
  and shot on the sandbox before picking (`design/canvas-skin/rail-mock/
  sprout-places.png`): rail foot, tank, perched on the card, small corner.
  `skin.buddyPlace` still switches between them; on a page with no week card
  he takes the foot of the global nav rail (radius 26, 17 collapsed), and
  with no rail at all the bottom right. He idles
  on his own, turns to look when the pointer comes near, waves when clicked;
  pauses in a hidden tab; honours reduced motion. Which kin: the phone now
  publishes `kin: {species, level, skin}` in `push_state` (`BridgeKin`), the
  laptop keeps it on `wallet.kin`; without a phone he is stage-two mint. The
  frame is driven by `sprout/bridge.js`, a message listener that only knows
  play / wake / paused / reduceMotion / signature. The six
  stills in `art/kin/` (board rows, the track rider) are cut from the current
  rig's stage-two stills.

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

## F. Built 2026-09-10, from the BetterCampus evidence

Four changes, from `STEAL-BRIEF.md`. Two of the parity gaps above are now closed
and one is answered differently than section D expected.

| Row | What | Where | Tests |
|---|---|---|---|
| — | **Trio-first copy.** The listing, the manifest, the popup subline, first-run and the README lead with dark mode + one to-do list + your grades, free, no account, no AI. Three separate top-voted Reddit comments say that trio is the whole product. | `design/store/chrome-listing.md`, `manifest.json`, `popup.html`, `popup.js`, `extension/README.md` | copy sweep |
| **R20** | **Courses you have finished, folded away.** An `opt` receipt row (`hidePast`), off by default, CSS only. The heading goes with its table via `:has`, and Show me brings both back while the outline is up. | `selectors.js` `pastCourses`, `receipt.js`, `skin.css`, `boot.js` | unit + e2e R20 |
| **R21** | **A picture the student chose, on a course card.** A local file, shrunk in the page to at most 720px wide, kept in this browser, never uploaded and never pushed to the phone. `scrimFor()` measures how bright it is and dims it exactly enough that Canvas's own white card controls clear 4.5:1 — **it never refuses a picture.** Variables from JS, rules in `skin.css`, one receipt row, one Put back. | `receipt.js` `scrimFor`, `content.js` `readPicture`/`applyCardArt`/`picturesSection`, `panel.css`, `skin.css` | unit (scrim, row) + e2e R21 |
| — | **What's due, in Chrome's side panel.** The list with no Canvas tab open — the most-upvoted thing on BetterCampus's own board that they never built. Reads what the worker already collected, makes no request of its own, never writes. | `sidepanel.html`, `sidepanel.js`, `manifest.json`, `popup.js` | — |

### R18 grew teeth

The exam risk is the strongest finding in the Reddit corpus: BetterCampus's
worst-voted post is an extension that lagged a final-exam timer and blocked a
submission, and three schools now block it. R18 no longer just checks for
classes. It reads **every selector in `skin.css` off disk** and asserts that on a
quiz being taken, not one of them matches anything, no element carries an id,
class or attribute of ours, and no `<style>` of ours exists.

It found a real one on its first run: `applySkin` was creating an empty
`#pk-theme-vars` element on pages the skin is switched off for, including a quiz
being taken. Fixed — the element is removed instead.

### Where this differs from section D

- **D says "card images: rejected by design (hotlinks)".** Still true of a
  *marketplace* of hotlinked images. R21 is the local-file version: nothing is
  fetched, so the privacy and reliability objection does not apply.
- **"hide completed" (#2)** is unchanged; R20 hides finished *courses*, not
  finished items.

### Not built, and why

- **Firefox and Edge.** Nine distinct people on Reddit ask, and BetterCampus has
  promised it for nine months. Real, and bigger than a session.
- **A term recap ("Canvas Wraps").** The only feature in the whole corpus that
  produced plain delight. Worth doing, end-of-term only.

## G. Built 2026-09-11, each surface held against a Mobbin reference

One pass over every surface a student meets, each one compared with the
best-known app that does the same job, and only the simplifications kept.
Nothing here adds a feature; every row makes an existing one read faster.

| Surface | Reference | What changed | Where |
|---|---|---|---|
| Week view | Todoist Upcoming | One amber "Past due" group, dated headers ("Sep 11 · Today"), no instruction paragraph, Plan only on hover | `content.js` `weekView`, `panel.css` |
| League card | Duolingo leagues | "3 days left" under the tier, one-sentence foot; no card when there is no league | `content.js` `leagueCard`, `leagueDaysLeft` |
| Focus timer | Oura session, Tiimo, Forest | Task on top, time left inside the ring, "Ends at 3:41 PM", two quiet words (+5 min, Stop). The buddy is out of the ring; he is live in the tank beside it and **cheers when the timer runs out** | `content.js` `focusCard`, `panel.css` |
| Theme shop | Numo covers, Snapchat themes | "Yours" first with the worn one ticked in the corner, "Locked" after with a price. Buddy still off every tile. Four-line explainer is one line | `content.js` `looksView`, `panel.css` `.pk-tick` |
| Search (⌘K) | Linear, Causal palettes | Before typing: Classes, Due soon (three, not handed in), Canvas pages, under small headers; key hints at the foot. Typing is one ranked list | `content.js` `searchGroups`, `resultsHTML` |
| Buddy | Finch, Duolingo | A sync that finds newly handed-in work plays the cheer. Real work, real reaction, nothing else | `content.js` storage listener |
| Panel home | — | "Still counts" said once per screen (headline only); GPA foot no longer advertises Honors/AP (the audience is college) | `content.js` `nextUpCard`, `gradesCard` |
| Side panel | Todoist | Past-due rows drop "still counts" under a header that already says it | `sidepanel.js` |
| Popup first run | — | The head hides during setup so the tagline is not on screen twice | `popup.js` |
| Chips | App Store rows | Filter rows bleed to the edges and scroll instead of clipping the fourth chip | `panel.css` `.pk-filters` |
| Mascot band | Finch's Home (the pet stands in a scene with a floor), the app's own Home tank | The band is the phone's tank: the five Home plates cut to 206×108 (`extension/art/tanks/*.webp`, 41 KB total), painted through `--pk-tank`; the phone names its tank in `BridgeKin.scene`; Lagoon until a phone is linked. The count badge wears a paper ring | `content.js` `tankId`, `skin.css` `.pk-w-tank`, `background.js`, `ios/Sources/CanvasSync.swift` |
| Right column | BetterCampus's To Do sidebar (their product shot + `setupBetterTodo` in their source, which empties `#right-side` and keeps only Recent Feedback) | One list: the thing to start is the first row with its two buttons, the next three under it, one label ("Up next"). The league card left the rail (it is in the panel). Canvas's To Do **and Coming Up** fold to one line together, and the stray `h2.todo-list-header` folds with them. Column 1631 → 1148 px; the rail card 895 → 658 (the next few are one line each: dot, title, day) | `content.js` `renderWeek`/`renderFold`, `skin.css`, `receipt.js` |

Renders for every panel view come from `design/canvas-skin/gallery/` — `build.js`
stubs `chrome`, feeds `content.js` sample data and writes one HTML file per view;
`shoot.js` screenshots them with the e2e suite's Playwright (`DARK=1`, `ONLY=`,
`H=`, `OUT=`). The live popup, side panel and panel-on-page shots come from
`design/site-shots/shoot.js` with `SURFACES=1`.

## E. Testing plan for whatever is chosen

Every feature gets: unit rows where it has logic, an e2e row on the fake page,
a live row on the sandbox with a screenshot, and — for anything that removes or
dims — a Put-back row proving it comes back and stays back after a reload and a
navigation. R6's smoke check runs first and alarms when Canvas moves.
