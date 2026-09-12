# Build notes — Calendar tab v2

Ported 2026-09-12 from `Calendar Tab v2.dc.html`, turn 3 (`#3a`), into
`ios/Sources/CalendarView.swift` (full rewrite, ~1,500 lines) with the clock rules in a new
pure file, `ios/Sources/Core/DayTimeline.swift` (12 tests in `ios/Tests/DayTimelineTests.swift`).
Four tokens added to `Theme.swift`; `QuickAddSheet` takes a start minute; Home's three
coin-flight pieces lost their `private` so the calendar can fly coins the same way.

## Direction chosen

Turn 3 (`3a`), as the README says — 2a's structure (object load, month as a sheet, no drag
handle, today as a raised card) with 2b's block anatomy. Chosen by Claude Design in the
prototype; nothing here was re-decided.

## What the handoff assumed, and what was actually there

| Named in the handoff | Actually in the tree |
| --- | --- |
| `CalendarView.swift` strip card | present — the 2026-09-10 build with Week · Month + ‹ Today › inside the card. Replaced. |
| `DayLoadStack` 20 × 3 bars | present. Replaced by `DayLoadGlyphs`. |
| `MonthLoadBars` 11 × 3 | present. Replaced by `DayLoadGlyphs(size: 11)`. |
| `EventRow` rail rule (44 + 20/hour, cap 140) | present. Replaced by the tinted block; the rail rule is gone. |
| A day timeline view | absent. `DayTimelineView` is new, pushed on a `NavigationStack` the tab did not have. |
| `MockCanvasClient` one minute off (2:59, 8:59) | already fixed — every mock time is on the hour. |
| The kin peek at the end of the scroll | removed on 2026-09-12 (`0a7739d`, "no fish in a void"). Not put back. |
| An export button in the title row | present and not in the drawing — see deviation 1. |

## Built as designed

- **Title row.** The month at 34pt with a 15pt chevron that opens the month sheet; the
  `Today` pill appears only when the ticker has left today's week; `CoinBadge` right. The
  count line under the title is gone with the controls.
- **Ticker.** Seven columns, gap 3, inset 12, no card. Weekday 10pt tracked, day 17pt, a
  14pt load row that is always reserved. Today is the one white card (r14, `cardEdge`);
  past days sit at 45% and keep their glyphs, so an overdue Monday still shows why.
  Paged by swipe; a tap pushes the day.
- **Load glyphs** (`DayLoadGlyphs`). 12 × 12 in course colour, r4 for work with a 6 × 1.6
  white mark, r6 for a class, chronological; more than three becomes two and a `+n` in
  `dim`. 11pt in the month cell, no mark.
- **Day header.** A 44pt tap target: `Today,` in `coralShade` + the date in ink; other days
  ink + `muted`; the summary right-aligned — `1 class · 2h 30m` when there are classes,
  `no classes` for today without any, `n due` for another day, `done` when everything is.
  Past a fortnight the lead is the month and the date is the day number ("September 24"),
  because `Upcoming.heading` already says the month there and "September, Sep 24" said it
  twice.
- **Task row** (`CalendarTaskRow`). White, r20, hairline, no shadow, min 62, padding
  11/14/11/12, gap 12. The 44pt tile is tinted with the course colour at 16% over white
  (`Theme.soft`), the coins are folded into the caption (`Physics 13 · all day · 30`), the
  box is 33 r10 in a 44 target. Done is 45% and stays put. The one caption function is
  `CalendarTaskRow.caption(for:)`, shared by the compact rows and the timeline.
- **Event row** (`EventRow`). A tinted block, r14, 26pt course disc, title 14, place 12 in
  `mutedDeep`, and `2:00 PM` over `1h` at the right — the time in the course's own ink
  (`Theme.deep`, which is `coralShade` for coral). No checkbox, no coins, no NOW chip.
- **Folded strip.** 44pt, chevron + `Sun – Tue · free`, hairline under. Opens in place: each
  day in the run comes out as a `Nothing due. Tap to add.` line, which is how a task lands
  on a Thursday without typing a date.
- **Empty today.** On the header row itself: `Today,` `Sep 9` … `Nothing due.` `Tap to add.`
  No card, no mascot, no scanner line.
- **`+`.** 60 disc, coral, right 18, bottom 78, `0 6 18 coralShade@.34`. Opens quick add.
- **Month sheet** (`MonthSheet`). `.fraction(0.83)`, r28, white. Header: month 22 + year 22
  `muted`, a 44-tall `Today` pill, a 32 close disc in a 44 target. Six rows of seven always,
  cells 60 tall r10, other-month days `inactive`, the selected day `coralSoft`, load as 11pt
  glyphs. Under a hairline: the picked day's header (a tap closes the sheet and pushes the
  day) and its things as compact rows (3pt rail, 14.5 / 12, 30pt box for work only), or the
  `Nothing due` line. The whole thing scrolls internally. Swipe the grid to change month;
  `Today` scrolls to the current month and picks today, 0.25s; a pick is 0.12s and the list
  cross-fades in 0.15s; closing the sheet moves the ticker to the picked day's week.
- **Day timeline** (`DayTimelineView`). Pushed, tab bar hidden. Back control 36 r14 white +
  hairline in a 44 target at the gutter. `Tomorrow` 21 over `Thursday, Sep 10 · 2h 30m
  booked · 1 due`. All-day work is one line above the axis under a hairline. 30pt hour
  column, 48pt per hour. A class is a block at its true height (never under 34; under 30
  minutes it drops its place line), duration inside at the right. A due time is an 11pt pin
  on the column edge, `Writing 5 · pays 30`, box at the right. Free time under 2h is a 22pt
  row with the length; 2h or more is a 44pt row — `3h 50m free until 2:00` — with an
  `Add task` pill that opens quick add with the day and the gap's start filled in. The last
  row is `Free the rest of the day` (`Free all day` when nothing is timed) with a 28 `+`
  disc in a 44 target. The now-line is 1.5pt coral with a 9pt dot and the word `now` in the
  column; when now falls inside a class the line rides on the block itself.
- **Still counts.** 44pt header in `coinInk` with a `coinHairline` rule; rows are the task
  row without its tile, a 4pt rail in the course colour, the caption in `coinInk`
  (`Physics 13 · was due Mon · 30`), never faded. A typed row swipes to reveal one 96pt
  `Move` (`paperSunk`, calendar glyph, `mutedInk`) that opens the built When sheet and
  re-dates the task in place; a Canvas row has no swipe at all.
- **Not paired.** `NotPairedCard` at the end of the list while `lastCanvasSyncAt` is nil:
  `Got your class schedule?` / `Open Prepkin on your laptop and your classes land here.` /
  `Show me how`, which opens the Your day sheet where the pairing code lives.
- **Check-off.** Box fill 0.18s, checkmark cross-fades, row to 45% and stays; three coins
  fly from the box to the badge exactly as Home does (`FlyingCoin`, the same curve); under
  Reduce Motion the badge counts up in place.
- The NEXT WEEK divider and the far-ahead day (the 2026-09-12 "no fish in a void" rules)
  are kept under the agenda unchanged.

## Deviations from the handoff

1. **The export menu stays in the title row, and the `Today` pill takes its slot.** The
   drawing has `September ›` and the coin badge and nothing between. The tree has a share
   button there — Plus's Apple Calendar export (`PLUS-SPEC.md` signature 5) and the grade
   calculator's second door — which the handoff did not see. Cutting it would cut a paid
   feature's only entry, so it stays. When the ticker leaves today's week the pill appears
   *in its place* rather than beside it: with both up next to a five-digit coin badge the
   title needed a 0.59 scale, under the 0.6 floor, and SwiftUI truncates rather than
   scales below the floor ("Septem…"). One tap on the pill brings the share button back.
2. **Today in the month grid is a 28pt coral disc behind the number**, not the whole
   60pt cell. The README text says "a coral disc with white ink"; the prototype's script
   paints the whole cell. A full cell swallows the day's glyphs (coral on coral) and is the
   heaviest thing on the sheet; the disc keeps both.
3. **Blocks are r10, not r12.** 12 is not one of the five radii and the README's own note
   points at a deviation that was never written. `Radius.chip` on a 34–72pt block reads
   right; `control` (14) did not on the short ones.
4. **No floating "11" label in a collapsed gap.** The prototype's 3a-3 has an `11` at
   y = 92, a leftover from the true-clock axis. With gaps collapsed there is no honest place
   for an hour that is not the start of anything, so labels sit only where things start
   (and on the now-line, as the word).
5. **The now-line is its own 20pt row** between two things, at its place in time, rather
   than a line at a proportional height inside a collapsed gap — a collapsed gap has no
   proportional height. Inside a class it is drawn at the true fraction of the block.
6. **The day header summary follows one rule** (classes · booked; else today says `no
   classes`; else `n due`; else `done`). The prototype's three headers agree with it.
7. **Sheet day header opens the day.** The README only says a ticker day or an agenda day
   header pushes the timeline; in the sheet the same tap closes the sheet and pushes, so the
   grid is a way into a day and not a dead end.
8. **`Theme.skySoft` was not added.** Course colours arrive as arbitrary hex from Canvas, so
   one formula (`Theme.soft`: the colour at 16% over white) makes every tint; for sky it lands
   on the prototype's `#EEF5FC` within a point. `mutedDeep`, `mutedInk`, `coinInk` and
   `coinHairline` were added as named.
9. **The pulse is not the README's 2.4s on/off** — it is 1.2s each way with autoreverse,
   which is the same 2.4s cycle. It plays only on the line, never on the dot or the word.
10. **`Move` slides in over the row's right end** rather than the row sliding off the left.
    The first cut pushed the card 96pt left and clipped the title and the "was due" — the
    two things the row exists to say. The prototype's markup keeps the whole card in place
    with the action inside its right end, which is what this does.
11. **A gap that starts now rounds its `Add task` time up to five minutes** (12:49 → 12:50).
    The gap itself still says the true length.
12. **The rest-of-day row drops its hour label when a pin already carries it.** A due time
    is a point, so "Free the rest of the day" starts on the same minute; "3 PM" twice, two
    rows apart, was noise.

## The look pass (same day, after the port)

Checked against Structured, Tiimo, Amie, Things 3 and Saturn on Mobbin at ship size, then
six icons were generated into the house set (`design/icons/src/grid-l.png`: laptop, clock,
lectern, backpack, date page, campus — cut and packed with the new `--only grid-l` switch so
the hand-tuned Play icon was not re-cut). What changed:

- **Load marks carry the object** (Structured draws its load this way): a 13pt chip in the
  course colour with the task's mark in white — book, pencil, ruler, flask, cards — and a
  disc with a clock for a class. `TaskCategory.mark` maps category → SF mark. The month
  cell keeps the plain 11pt shapes; a mark under 12pt is mud.
- **A class row has an object**: the illustrated clock (`icon-classTime`) on a white 38pt
  tile, on the tinted block, with a 4pt course rail down the left edge. It is now the task
  row's anatomy minus the box, which is what makes the two read as one list.
- **A timeline pin has a tile** (34pt, course tint, the task's object) between the dot and
  the title; a **timeline block has the 4pt course rail** (Amie's blocks carry one).
- **Still counts rows keep their tile** — deviation 13: the drawing drops it, but a list
  where some rows have an object and some do not reads as two kinds of row, and overdue is
  not a kind, it is a date.
- **The not-paired card has the laptop** on a 52pt tile at the left (Saturn's card has its
  app mark there).
- **The month sheet opens at `.fraction(0.89)`** so its top lands near the drawing's y = 150
  (0.83 is measured under the status bar and landed at 214).

References looked at (Mobbin): Structured timeline
https://mobbin.com/screens/26fae4e6-2163-4d93-8c47-5bd9839cb369 and week strip
https://mobbin.com/screens/e4f1982d-084a-4bdb-8553-e2729644a4eb · Tiimo gap row
https://mobbin.com/screens/2e5e28b9-c537-46b3-89fe-5d46c59fe6a3 · Amie blocks
https://mobbin.com/screens/01485571-fc31-4229-908a-943657e6b9c0 · Things 3 Upcoming
https://mobbin.com/screens/590f4dd6-1a6d-45a3-91c3-3508a762b041 · Saturn day
https://mobbin.com/screens/e81e74a6-7629-431d-9f2c-d49b674f772e.

Shots `12-polish-upcoming`, `12b-polish-timeline`, `13-polish-month`,
`13b-polish-month-picked`, `14-polish-still-counts`, `15-polish-empty`.

## New components added

`CalendarFeed` (the one read of a day for all three screens) · `CalendarEntry` · `LoadMark`
· `DayLoadGlyphs` · `DayHeading` · `CheckBox` · `CompactRow` · `StillCountsHeader` ·
`NotPairedCard` · `SwipeToMove` · `MonthSheet` · `DayTimelineView` · `TimelinePin` ·
`TimelineBlock` · `GapRow` · `AddTarget` · `DayTimeline` (Core). Deleted: `DayLoadStack`,
`MonthLoadBars`, the Week · Month segment, the ‹ Today › stepper, `controlRow`, `gridCard`,
the count line, `AgendaTopKey`.

## Motion actually shipped

- Ticker page 0.18s easeInOut; month page the same; sheet `.fraction(0.83)` system spring.
- Grid pick 0.12s easeOut; list cross-fade 0.15s; `Today` 0.25s easeOut.
- Check-off 0.18s fill + 0.2s row fade; coin flight 0.9s on Home's curve, three discs.
- Now-line 2.4s breathing on the line only. **Needs George's GIF sign-off** (memory
  `animation-approval`) before it counts as shipped; the same note was open on the old
  NOW dot.
- Reduce Motion: 0.12s cross-fades for paging, no pulse, no coin flight.

## Bugs found while porting

- `CalendarFeed` had to be `@MainActor`: `AppState.tasks(on:)` is main-actor isolated and
  a plain struct calling it does not compile under strict concurrency.
- `Theme.swift`'s comment still names `ios/Tests/UniformTests.swift` as the radius guard;
  the file does not exist. Not touched.

## Verified on the simulator

iPhone 17 Pro (`prepkin-cal2`), `-unlockAll -sampleCanvas`, Saturday 2026-09-12 (so the
raised today card sits at the right end of the ticker and the mock's week lands under a
NEXT WEEK divider). Shots in `shots/`:

- `01-upcoming` — the tab: title, ticker with today raised and past days at 45%, the
  agenda with a class block and course-tinted tiles.
- `02-month-sheet`, `02b-month-picked`, `02c-after-close` — the sheet, a pick (list swaps),
  and the ticker following the pick with the `Today` pill up.
- `03-timeline-tomorrow` — pin, `6h free until 2:00` with `Add task`, a 1h block, the rest.
- `04-next-week` — paged by swipe; folded strips with the hairline.
- `05-checkoff-flight` / `05b-checkoff-done` — check-off; `/tmp/flight.mp4` frames showed
  the three coins crossing from the box to the badge.
- `06-quickadd`, `06b-when` — the built sheets, untouched.
- `07-still-counts`, `07b-still-counts-swiped` — a typed task moved to Sep 10 through the
  When sheet lands in Still counts with its glyph on the past Thursday; the swipe reveals
  `Move`; `Move` → Monday took it out of the group ("Monday, Sep 14. 2 due").
- `08-timeline-today` — the now-line, the gap from now, a 3 PM pin, the rest.
- `09-gap-add` — `Add task` in the gap opened quick add with `Today 12:49 PM` filled in.
- `10-empty-today` — a fresh install with no laptop: `Today, Sep 12 … Nothing due. Tap to
  add.` and the not-paired card.

Every control in `idb ui describe-all` is 44pt or more and labelled; the day headers read
"Today, Sep 12. no classes" with an "Opens the day" hint. 74 unit tests pass (12 new).

## Open, and worth a decision

- Whether the now-line pulse ships (GIF sign-off).
- Whether the export button moves out of the title row once the calendar has a settings
  or overflow home; today it is the only place it can be.
- A tinted tile per course versus the constant `tile` circle (turn 1 deviation 3, still
  George's call — a one-line change either way).
