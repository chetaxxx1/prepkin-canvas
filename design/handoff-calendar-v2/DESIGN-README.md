# Handoff — Calendar tab, artboards 1, 2 and 4 (three directions)

`Calendar Tab v2.dc.html` · 2026-09-12 · brief `01-calendar/BRIEF.md`

## Overview

The brief names artboards 1, 2 and 4 as the parts nobody should freehand: the ticker with
its drag handle, the month grid it opens into, and the day timeline with class blocks, the
now-line and the gap row. This handoff draws those three, three times, as three coherent
directions rather than nine unrelated screens. Pick a direction, not a screen — the three
frames in a column share one rule for load, one rule for hierarchy and one rule for the
axis.

- **1a — ticker + spine, as specified.** The brief read literally. Month name as the title,
  seven-day ticker in a white card with stacked load bars, the 38 × 4.5 handle under it,
  Things 3 spine with a big day number in the left margin, events as a tinted block above
  the day's tasks. The timeline uses the proportional rail rule `EventRow` already ships.
- **1b — no cards: load as weight.** The ticker loses its card and becomes seven wells
  filled from the bottom in course colour; the day number becomes a right-aligned 44pt rail
  with the items beside it; task rows lose their white card for a 3pt course rail on paper.
  The timeline is a true clock at 64pt/hour.
- **1c — clock first.** The tab's first answer is today's clock: a horizontal day bar with
  the now marker and due pins, which opens the day in place. No ticker at all; weeks come
  from a swipe on the bar, the month from the title. The month view is five week cards with
  a load lane under each.

Artboards 3, 5, 6 and 7 are already built and are not redrawn. Still counts is included in
1a behind the `showStillCounts` prop so its placement can be checked against the new day
header, not to redesign it.

## Fidelity

High for layout, type and colour; every value below is a pt value on the 402 × 874 canvas
with content starting at y = 99 and 90pt clear above the tab bar. The tab bar is a dashed
strip labelled `RootView.tabBar — not redrawn`. The kin is a dashed 120 × 78 box captioned
`KIN · mint · ★`. Icon tiles are placeholder flat shapes at the right size and tint — use
`IconTile` with the real set, not these. Nunito stands in for SF Pro Rounded. No status bar
and no keyboard is drawn. Live in the prototype: every checkbox, and the day bar in 1c.

## Layout per artboard

### 1a-1 · Upcoming
- Title row y = 59, h = 40. `September` 34/38 900 at gutter 18. `CoinBadge` right, 7 × 13
  padding, r100.
- Ticker card: left/right 12, y = 113, h = 96, r20, white, 1px `cardEdge`, no shadow.
  Seven equal columns; weekday letter 10.5 900 `inactive`, tracking .4; day number 17 900
  in a 26 box; today a 26 coral disc, number white. Load: up to 4 bars 20 × 3, r1.5,
  bottom-aligned, chronological, earliest at the bottom. Past days at 40%.
- Handle row y = 209, h = 28: pill 38 × 4.5, r2.25, `hex(0xE2D8C6)`. **Grab target is the
  full 402 × 44 band centred on the pill** (y = 201–245), so the tap never fights the
  ticker cells above or the first row below.
- List from y = 237, gutter 18, bottom padding 200 (112 clearance + the 60 button + 28).
- Day header: day number 26/28 900 in a 34 box, weekday 14 900 beside it, gap 10, then a
  1px `hairline` rule to the right margin. Header block padding 20 top / 8 bottom.
  Today's number and word are `coralShade`.
- Task row: white, r20 (`Radius.card`), 1px `cardEdge`, min-height 62, padding 11/14/11/12,
  gap 12. `IconTile` 44, r14. Title 15.5 900, caption 12.5 800 `muted`. `CoinDisc` 13 +
  amount 13 900 `coinDark`. Checkbox 33, r11, in a 44 target.
- Event row: tinted block r14 (`sky` at 8% → `#EEF5FC`, coral at 8% → `#FFEFEC`), padding
  9/12, time 12.5 900 in a 56 left column, title 13.5 900, caption 12 800. No checkbox.
- Folded past strip: `paperSunk`, r14, h 38, chevron 12 + `Sun – Tue · free` 12.5 800.
- `+`: 60 disc, `coral`, right 18, bottom 78.

### 1a-2 · Month grid
- Same title row; `Today` pill replaces the coin badge when the grid is not on today's
  month (`paperSunk`, 7 × 14, r100, 12.5 900).
- Grid card left/right 12, y = 113, r20. Weekday letters 10.5. **Six rows of seven always**,
  cell 52 tall, r10. Day 15 900; today a coral disc; selected day `coralSoft`; other-month
  days `inactive`. Load in-cell: `MonthLoadBars` 11 × 3, stacked, max 3, gap 2.
- The handle sits **inside the bottom of the grid card** (h 28) so the same pill drags both
  ways; the grab band is again 402 × 44.
- Selected day's list from y = 500.

### 1a-3 · Day timeline
- Back control 36, r14, white + hairline, at gutter 18, y = 59. `Tomorrow` 21/23 900 with
  `Thursday, Sep 10` 12.5 800 `muted` under it.
- Axis x = 56 (1px `hairline`), time labels right-aligned in a 50 column ending at x = 50.
- **Axis is proportional, not pt-per-hour**: a block is 44 for its first hour, +20 per hour
  after, capped 140 — the rule `EventRow` already uses, so a two-hour midterm is visibly
  bigger than an hour of office hours without a 24-hour scroll. Gaps are labelled, not
  scaled (46 for a long gap, 34 for a short one).
- A due time is a **pin**: a 12 dot on the axis with a 2.5 `paper` ring, title 14.5 900,
  caption 12 800.
- A class is a **block**: r14, 3pt left rail in the course colour, tint at 8%, title 15 900,
  location 12.5 800, range 12 800 in the course ink.
- Gap row: 2px dotted `hex(0xE2D8C6)` rail, `4h 50m · free` 12.5 800 `dim`, `+ Add task`
  pill right (7 × 11, r100, `paperSunk`), 44 target.
- Now-line: 2px `coral` across the axis, 10 dot on the axis, time 13 900 `coralShade` in the
  axis column. Drawn here as it appears when the day shown is today.
- 15-minute block: keeps the 44 minimum and drops its range caption, showing `2:00 · 15m`
  in the time column instead.
- All-day event: a pinned hollow-dot line above the first timed row, no rail (as built).

### 1b-1 · Upcoming, ruled
- Ticker has no card: y = 107, h 78, seven columns, 3 gap. Each day is a 34-tall well
  (`hex(0xF1EDE7)`, r8) filled from the bottom, 11pt per item in the course colour. Day
  number 13 900 under it (today a 22 coral disc), weekday letter 9.5 900.
- 1px `cardEdge` rule at y = 191 edge-to-edge, handle band y = 192–218, list from y = 222 —
  15pt earlier than 1a.
- Day rail: 44 wide, right-aligned; number 30/30 900, label 11 900 caps (`TODAY`,
  `TOMORROW`, `SAT`), items in the remaining column. Rows are separated by a 1px
  `hairline` across the day group, not by cards.
- Item row: 3pt course rail (34 tall for a task, 40–52 for an event, proportional), title
  15.5 900, one caption line `course · time · coins` 12.5 800, checkbox 30 r10 in a 44
  target. An event carries its start time right-aligned 12.5 900 in the course ink instead.

### 1b-2 · Month, full bleed
- No card. Grid left/right 8 from y = 107, cell 58, ruled rows (1px `hairline`), load as
  three 5pt dots under the number. Today a coral disc, selected day a full-width
  `coralSoft` cell. Handle band y = 510. List from y = 540.

### 1b-3 · Day timeline, to scale
- **64pt per hour**, axis x = 46, labels in a 40 column. Blocks take their true top and
  height (office hours 64, Chem lab 96). A 15-minute block keeps a 34 minimum and its true
  top. All-day events pin above the first hour. The axis opens at the first item minus one
  hour and scrolls; `3 things · 2h 30m booked` sits in the header.

### 1c-1 · Day bar over the spine
- Day bar card: left/right 12, y = 107, r20, white + hairline. Header line `Today` 14 900
  `coralShade` + `Wed Sep 9 · 1 due, no classes` 12.5 800 + clock 11.5 900 right.
- The bar itself: 26 tall, r8, `paperSunk`, spanning 8 AM – 10 PM. Class blocks are course
  colour fills at their true position; a due time is a 3pt coral pin; now is a 2pt coral
  line with a 10 dot. Scale marks 9.5 800 under it.
- Footer of the card: 1px rule then `Open the day` 11.5 900 + chevron, whole card is the
  44pt+ target (live in the prototype).
- `Coming up` list from y = 265: one card per day, day number 19 900 + weekday 9.5 900 in a
  40 column, 1px divider, then the day's items stacked inside the card.

### 1c-2 · Month, load lanes
- Five or six **week cards** (r14, white + hairline, 4 padding) from y = 107, each with a
  28pt `W1`–`W6` label to its left. Inside: seven 32 cells r10 with the day number 14 900,
  then a row of seven 4pt load lanes. Lane is `hex(0xE2D8C6)` for one item and `coral` for
  two or more — the only place in the tab where colour encodes quantity.

### 1c-3 · Day opened
- A sheet, not a push: r28 card inset 12, y = 107 to 64 above the bottom, the tab bar stays
  and the close is a 36 `X` in the title row. Time column 52 wide carrying the start 15 900
  with the **duration** under it 10.5 800, so no block needs a range caption. Pin, gap rows
  and blocks as in 1a-3.

## Tokens, by `Theme` name

`paper` page · `card` white rows and the ticker card · `cardEdge` every hairline border ·
`ink` titles · `muted` captions · `dim` gap labels and typed-task rails · `inactive` weekday
letters and other-month days · `hairline` rules · `paperSunk` the folded strip, the Today
pill, the add-task pill, 1c's bar track · `tile`/`tileRing` unused here (icon tiles are
tinted with the course colour instead — see deviations) · `checkFill`/`checkBorder`/`check`
the checkbox · `coral` today, the `+`, the now-line, Physics 13 · `coralSoft` the selected
day · `coralShade` today's words · `mint` Writing 5 · `mintSoft` its tile · `sky` Intro
Psych · `coin`/`coinBorder` the disc · `coinDark` amounts and the Still counts header ·
`Radius.chip` 10 for grid cells and checkboxes · `Radius.control` 14 for blocks, tiles, the
back control · `Radius.card` 20 for rows and the ticker card · `Radius.sheet` 28 for 1c's
day sheet · `gutter` 18 · `tabClearance` 112. `hex(0xE2D8C6)` is the handle and the dotted
rail; it is the one raw hex used and it is already in the tree for the handle.

## Reused components, by name

`CoinBadge`, `CoinDisc`, `IconTile`, `PlusTag` (not shown; unchanged), `CalendarTaskRow`,
`EventRow`, `FoldedDaysStrip`, `DayLoadStack` (1a), `MonthLoadBars` (1a-2), `SproutImage`
(the kin peek). New, if a direction is chosen: `DayLoadWell` (1b), `WeekLoadCard` (1c-2),
`DayBar` (1c-1), `TimelinePin`, `TimelineBlock`, `GapRow`.

## State

- Checkbox: unchecked → checked pays coins and drops the row to 45% opacity; the row stays
  in place. Canvas rows that are submitted carry a lock and cannot be un-ticked (built).
- Events have no checkbox and no coin chip.
- `showStillCounts` (prop) puts the overdue group above Today in 1a.
- `showKinPeek` (prop) toggles the kin peek at the end of the scroll.
- 1c's day bar is open/closed; closed is the default.
- Ticker: past days at 40%, today on a coral disc, the `Today` pill appears only when the
  ticker is off today's week.

## Copy, every string

`September` · `120` · `Sun – Tue · free` · `Today` · `Tomorrow` · `Saturday` · `Sunday` ·
`Thursday, Sep 10` · `Thu 10` · `Thursday 10` · `Wed Sep 9 · 1 due, no classes` ·
`Ch. 5 Problem Set` / `Physics 13 · all day` · `Essay outline` / `Writing 5 · due 9:00 AM` ·
`Essay outline due` / `Writing 5 · pays 30` · `Office hours` / `Intro Psych · Moore 202` /
`2:00 – 3:00 PM · 1h` / `to 3:00` · `Chem lab` / `Chem 21 · Bard 110` / `3:30 – 5:00 PM ·
1h 30m` · `Week 3 quiz` / `Intro Psych · due 4:00 PM` · `Bio quiz, ch. 3–4` / `Study ·
4:00 PM` · `Midterm 1` / `Physics 13 · to 11:00` · `4h 50m · free` · `30m · free` ·
`11h 48m · free` · `Nothing after 5:00` · `Add task` · `Open the day` · `Coming up` ·
`3 things · 2h 30m booked` · `2h 30m booked · 1 due` · `2 things` · `Still counts` /
`Unit 4 concept check` / `Physics 13 · was due Tue`. Every one is under 40 characters on a
line; none contains an exclamation mark, a streak, a countdown or an engineering word.

## Interactions and motion

- **Handle drag (1a, 1b).** The handle follows the finger 1:1 in the ticker's own height,
  ticker 96 → grid 356 (1a) / 404 (1b). Past the **halfway point** on release it completes
  in the direction of travel: `spring(response: .34, dampingFraction: .86)`. Under halfway
  it returns with the same spring. A flick over 600 pt/s completes regardless of position.
  Rubber-band at each end: beyond the open or shut limit the ticker follows at 0.35× and
  releases back over 0.22s `easeOut`. Load marks cross-fade bars → in-cell bars over the
  first 40% of the drag; day numbers never move horizontally, so the grid appears to grow
  downward out of the ticker.
- **Tap a ticker day / day header (1a, 1b).** Push the timeline, standard navigation,
  0.35s. Selection tint 0.12s `easeOut`.
- **Tap the day bar (1c).** The day sheet rises 0.3s `spring(response: .3, damping: .9)`;
  the bar's now marker is the shared element and stays put. Close is the mirror.
- **Check off.** Checkbox fill 0.18s `easeOut`, SF `checkmark` cross-fades in over 0.2s (no
  trim animation — that needs the GIF sign-off). Row opacity to 45% over 0.2s. Coin flies
  to the badge as Home does.
- **Now-line.** 2.4s infinite ease-in-out opacity pulse 1 → .42 on the line only; the dot
  does not pulse.
- **Add task in a gap.** Opens the built quick add with the day and the gap's start time
  pre-filled.

### Reduce Motion

The handle drag becomes a 0.12s cross-fade between ticker and grid, with no rubber-band and
no follow; the day sheet cross-fades at 0.12s; the now-line stops pulsing and stays at full
opacity; the coin does not fly, the badge counts up in place; the kin plays `idle`. Nothing
on these screens is carried by motion alone.

## Deviations, and why

1. **The title is the month, at 34pt.** The brief asks for the month; `BUILD-NOTES`
   deviation 3 asks for 34pt. Both are satisfied — `September` at `font(34, .black)`. The
   room the redesign reclaims still comes from folding the controls away, not from the type.
2. **Paper is `#F8F8F8`, not the prototype's cream.** Today's `Theme.swift` moved the page
   to near-white with white cards and a `cardEdge` hairline and no card shadow. The 2026-09-09
   prototype is stale on this; these artboards follow the tokens, per the house rule.
3. **Icon tiles are tinted with the course colour**, not the constant `tile` circle. A
   calendar row already carries a course colour on its rail, and duplicating it in the tile
   is the cheapest way to make four courses scannable. If this reads as too much colour,
   drop back to `tile`/`tileRing` and the rail alone carries it — a one-line change.
4. **No per-day `+`.** As built, and the brief agrees. In 1a-3 and 1c-3 the only add inside
   a day is the one in the gap row.
5. **The load mark differs per direction, deliberately.** 1a keeps `DayLoadStack`'s 20 × 3
   bars. 1b fills a well from the bottom — at arm's length it reads as weight rather than as
   three small marks, which is what the Binance pattern is actually doing. 1c drops per-day
   marks in the ticker (there is no ticker) and puts one lane per day under a week card.
   **Recommendation: 1b's well.** It is the only one of the three that survives a glance, and
   it needs no `+3` overflow because height, not count, carries the load.
6. **1a-3's axis is proportional, 1b-3's is a true clock.** Two honest answers to the same
   question: proportional keeps a day on one screen, true clock makes 9 AM feel like the
   morning. Both are drawn so the choice can be made on the artboards.
7. **1c drops the ticker.** The largest departure. A day bar answers "what is my day"
   directly, but it gives up the week at a glance; flagged rather than smuggled in.
8. **No `Move to today` on Still counts**, as the brief asks. Nothing here offers it, since
   half those rows are Canvas dates and a Canvas date is not ours to move.
9. **The Chem lab block invents a course and a room** (`Chem 21 · Bard 110`) because the
   brief asks for the block shape twice and `MockCanvasClient` only has one class meeting.
   It is sample data, not a proposal.

## References

The Mobbin connector was not available in this canvas, so nothing here was taken from a
freshly opened screen. The patterns are the ones `01-calendar/MOBBIN.md` and the brief
already record as looked at on 2026-09-10, applied from those written descriptions and from
`built-week.jpg` / `built-month.jpg` / `today-light-calendar.jpg`:

- Things 3 Upcoming — only days with something, big day number, events tinted above tasks —
  https://mobbin.com/screens/1f3adaff-5def-4789-a938-456435ecd4df
- Microsoft Outlook agenda — month as the title, seven-day ticker, the grey handle pill —
  https://mobbin.com/screens/3a21d1a0-0bec-472b-9c07-8a33dddf45cf and the grid it opens into
  https://mobbin.com/screens/a6fd424b-68a6-40e5-ad65-e0257449ff2a
- Binance calendar — load marks under the day number, the Today pill —
  https://mobbin.com/screens/8339ece6-cfa5-4995-a7ab-e52de69fb419
- Structured timeline — the axis, blocks, the add inside the gap —
  https://mobbin.com/screens/574482d9-3640-4553-805e-944f11f27428
- Tiimo gap line — `4h 50m · free` with the `+` at the right of the gap row —
  https://mobbin.com/screens/2e5e28b9-c537-46b3-89fe-5d46c59fe6a3
- Saturn Calendar — class blocks with the current one lit, the now-line —
  https://mobbin.com/screens/f4d20fce-ae76-45c2-8d1f-6132b25fa29c
- Google Calendar schedule — the folded empty run —
  https://mobbin.com/screens/1f51ee68-947e-4ce0-b371-4d307313f77b
- Todoist overdue — the group above today with the action on the header —
  https://mobbin.com/screens/ecb1790e-e9b8-494c-8022-224b41476d34

Drawn from the pattern rather than from a screen, as the brief permits: Saturn's "Got your
class schedule?" card (not drawn here; artboard 3 is already built), Structured's day-header
chrome, and 1c's day bar, which has no source — it is the one invented mechanic in this
handoff and should be treated as such.

## Open questions for the next pass

- Which direction, and whether the load mark travels independently of it (see deviation 5).
- 1a-3 versus 1b-3 on the axis (deviation 6).
- Whether the day opens as a push (1a, 1b) or as a sheet with the tab bar kept (1c).
- Artboards 3 and 7 were not redrawn; say the word and they come back in the chosen
  direction, including the not-paired card and the swipe.
