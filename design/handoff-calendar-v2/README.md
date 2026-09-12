# Handoff: Prepkin Canvas — Calendar tab (artboards 1, 2, 4, plus 3 and 7)

Design date 2026-09-12 · brief `design/…/01-calendar/BRIEF.md` · target `ios/Sources/CalendarView.swift`

## Overview

The Calendar tab answers "what is coming" (Home answers "what do I do right now"). It shows
only dated things: Canvas work on its due day, course events from the Canvas calendar, and
the student's own dated tasks. This handoff redesigns the parts the brief said nobody should
freehand — the week ticker, the month view it opens into, and the day timeline — and resolves
them into one direction, plus the overdue group and the empty-today state.

**What changes from the shipping build**

1. The page title becomes the **month name** (`September`), with a chevron that opens the month.
2. The **Week · Month segmented pill and the ‹ Today › stepper are deleted**, and so is the
   drag handle the earlier design proposed. The month arrives as a **sheet** with its own
   header (month + year, `Today`, close `X`).
3. The ticker's load marks become **course-coloured object glyphs** (12pt chips) instead of
   abstract bars, and **today is a raised white card** rather than a filled coral disc, so it
   still reads while past days sit at 45% opacity.
4. A new **day timeline** screen: 48pt per hour, with any free run over two hours collapsed
   into one 44pt row that names the wait ("3h 50m free until 2:00").
5. Class blocks carry their **duration inside the block, right-aligned** — one line saved per
   class over a `2:00 – 3:00 PM · 1h` caption.
6. Every informational caption is `Theme.muted` or darker (4.5:1 on white); the `Still counts`
   header moves to `#8A5F14` because `Theme.coinDark` (#A8761D) fails on white.

## About the design files

`Calendar Tab v2.dc.html` in this bundle is a **design reference written in HTML**, not
production code. It is a streaming "Design Component" prototype: one file with a template and
a small logic class, opened directly in a browser. Do not port the HTML. Recreate these
screens in **SwiftUI inside `ios/Sources/CalendarView.swift`**, using Prepkin's existing
patterns: `Theme` tokens by name, the five radii in `Theme.Radius`, and the components already
in `KinComponents.swift` / `PrepkinIcons.swift` / `CalendarView.swift`. Nunito in the
prototype stands in for **SF Pro Rounded** (`Theme.font(_:_:)`); every hex in the prototype
has a token name in the table below — use the token, never the literal.

The file contains three turns of work stacked newest-first. **Turn 3 (`#3a`) is the design to
build.** Turns 2 and 1 are the explorations it was chosen from; they are kept for context and
should not be ported.

## Fidelity

**High.** Every value below is a pt value on the 402 × 874 iPhone canvas. Content starts at
y = 99 (59 status bar + 40 title row) and leaves `Theme.tabClearance` (112) at the bottom.

Three things in the prototype are deliberately not final art:
- The **kin** is a dashed 120 × 78 box captioned `KIN · mint · ★`. Render `SproutImage` at
  78pt in a 44pt box, top-aligned (the existing kin-peek treatment). Never draw the character.
- **Icon tiles** are placeholder flat shapes at the right size and tint. Use
  `IconTile(icon:size:)` with the real flat-vector set.
- The **tab bar** is a dashed strip labelled "not redrawn". `RootView.tabBar` is unchanged.

## Screens

### 1 · Upcoming (`#3a`, frame `3a-1`) — the default screen

**Purpose.** See what is coming, check things off, jump to a day.

**Layout, top to bottom**
| y | Element | Spec |
| --- | --- | --- |
| 0–59 | status bar | not drawn |
| 59, h 40 | title row | `September` `Theme.font(34, .black)` `Theme.ink` at gutter 18; a 15pt chevron `Theme.muted` after it (opens the month sheet); `CoinBadge` right — white, 1px `cardEdge`, r100, padding 7 × 13, coin disc 17 + `120` at 15 `.black` |
| 107, h 84 | ticker | 7 equal columns, gap 3, inset 12. Each column: weekday 3-letter label 10 `.black` `muted`, tracking .4 · day number 17 `.black` · a 14pt load row. **Today** is a white card, r14 (`Radius.control`), 1px `cardEdge`, padding 8/0/9, its weekday label `coralShade`. Past days at 45% opacity. |
| 197 → bottom | agenda scroll | gutter 18, bottom padding 200 |

**Load glyphs.** 12 × 12, r4 (r6 for an event), gap 2, filled with the course colour, carrying
a 6 × 1.6 white mark. Max three; a fourth becomes a `+n` chip in `Theme.dim`. Order is
chronological. A day with nothing shows an empty 14pt row (the row is always reserved so day
numbers stay on one baseline).

**Day header.** A 44pt row (not 37 — it is a tap target that opens the day): `Today,` /
`Tomorrow,` / `Saturday,` at 15 `.black` (`coralShade` for today, `ink` otherwise), then the
date at 15 `.black` `muted`, then a spacer, then a right-aligned summary at 12 `.heavy`
`muted` — `no classes` · `1 class · 2h 30m` · `2 due`. No rule; the 44pt rhythm separates it.

**Task row** (`CalendarTaskRow`). White, r20 (`Radius.card`), 1px `cardEdge`, **no shadow**,
min-height 62, padding 11/14/11/12, gap 12. `IconTile` 44 r14 tinted with the course colour at
~8% (`coralSoft` / `mintSoft` / `#EEF5FC` / `checkFill`). Title 15.5 `.black` `ink`; caption
12.5 `.heavy` `muted` in the form `course · time · coins` — the coin amount is folded into the
caption rather than carried as a separate chip, which removes an element from every row.
Checkbox 33, r11, `checkFill` with a 2.5 `checkBorder` stroke, inside a 44 target with −5
margins; checked is `check` fill with a white SF `checkmark` at 18.

**Event row** (`EventRow`). Tinted block, r14, padding 11/14, gap 11: a 26 course-colour disc,
title 14 `.black`, location 12 `.heavy` `#7B6C63`, and a right-aligned two-line time —
`2:00 PM` 12.5 `.black` in the course ink over `1h` 11 `.heavy` `#7B6C63`. No checkbox, no
coins.

**Folded strip** (`FoldedDaysStrip`). 44pt row, 12pt chevron + `Sun – Tue · free` 12.5
`.heavy` `muted`, 1px `hairline` under it. Opens in place.

**Floating `+`.** 60 disc, `Theme.coral`, right 18, bottom 78, white plus glyph 26, shadow
`0 6 18 rgba(196,82,63,.34)`. The only add button; it opens the built quick add.

### 2 · The month sheet (frame `3a-2`)

**Purpose.** Scan the month's load; pick a day.

Presented over the agenda, which dims to `rgba(46,38,34,.16)` below y = 99. The sheet top sits
at y = 150, r28 (`Radius.sheet`) on the top corners only, `0 -6 30 rgba(46,38,34,.14)`,
padding 16/14/0, and **scrolls internally** so the selected day's items are reachable with the
grid still visible.

- Sheet header: `September` 22 `.black` `ink` + `2026` 22 `.black` `muted`, spacer, a 44-tall
  `Today` pill (`paperSunk`, r100, 12 `.black`), then a 32 close disc (`paperSunk`, X stroke
  `#5F534A`) inside a 44 target.
- Weekday labels 10 `.black` `muted`, three letters, centred.
- **Six rows of seven, always** — the grid never changes height between months. Cell height
  60, r10 (`Radius.chip`). Day number 15 `.black`; other-month days `inactive`; **today** a
  `coral` disc with white ink; the **selected** day `coralSoft`. Load in-cell: the same 11pt
  glyph chips, wrapping, centred, max three.
- Under a 1px `hairline`: a 44pt day header (`Thursday,` + `Sep 10` + `2 things`) and the
  day's items as compact rows — a 3pt course rail 30 tall, title 14.5 `.black`, caption 12
  `.heavy` `muted`, checkbox 30 r10 for tasks only.

### 3 · The day timeline (frame `3a-3`)

**Purpose.** "I have office hours 2 to 3 and the problem set is due at 5."

Pushed from a day header or a ticker day; the tab bar hides (pushed screen).

- Back control: 36 r14 white + `cardEdge` inside a 44 target at gutter 18, y = 59. Title
  `Tomorrow` 21 `.black` with `Thursday, Sep 10 · 2h 30m booked` 12.5 `.heavy` `muted` under it.
- All-day work is **one row above the axis**, under a 1px `hairline`: 3pt course rail, title
  14, caption 11.5, checkbox 30.
- Axis: hour labels 10.5 `.heavy` `muted`, right-aligned in a 30pt column; content starts at
  x = 30. **No rules across the page.**
- **48pt per hour.** A block takes its true top and height (1h = 48, 1h 30m = 72); a block
  under 30 minutes keeps a 34pt minimum and drops its location line.
- A **due time is a pin**: an 11pt course-colour dot centred on the axis (margin-left −5.5),
  title 14.5 `.black`, caption 11.5 `.heavy` `muted`, checkbox at the right.
- A **class is a block**: r12, course tint fill (`#EEF5FC` sky, `checkFill` grey), title 14
  `.black`, location 11.5 `.heavy` `#7B6C63`, **duration right-aligned inside the block**.
- **Gap rows.** A free run under 2h is a 22pt row: 2px dotted `inactive` rail + the length
  (`30m`) at 12 `.heavy` `muted`. A run over 2h is a 44pt row that names the wait —
  `3h 50m free until 2:00` — with a 44-tall `Add task` pill (`paperSunk`, r100, plus glyph +
  label 11.5 `.black` `#5F534A`) at the right. The last row of the day is
  `Free the rest of the day` with a 28 `+` disc in a 44 target.
- **Now-line.** 1.5pt `coral` from x = 30 to the right margin, a 9pt `coral` dot at x = 24,
  and the word **`now`** at 11 `.black` `coralShade` in the hour column — a word, not a time.
  **Suppress the hour label the now-line lands on** (the prototype's 10 AM label is absent for
  exactly this reason): the column shows one thing at a time and `now` always wins. The hours
  either side of it stay.

### 4 · Overdue above an empty today (frame `3a-4`, artboards 7 + 3)

- **`Still counts`** header: 44pt row, label 14 `.black` `#8A5F14`, then a 1px `#E8CFA0`
  hairline out to the right margin. No count badge, no red, never "you missed".
- Rows: the standard task row plus a **4pt left border in the course colour**, and the caption
  in `#8A5F14`: `Physics 13 · was due Mon · 30`. Rows are **not** faded.
- **Swipe.** A typed row (`DatedTask`) reveals one 96pt `Move` action (`paperSunk`, calendar
  glyph + label 12 `.black` `#5F534A`) that opens the built When sheet. A Canvas row has **no
  swipe action at all** — a Canvas date is not ours to move. The one-line explainer under the
  group in the prototype is annotation, not UI.
- **Empty today** is the built inline line, on the day header row itself: `Today,` `Sep 9` …
  `Nothing due.` `Tap to add.` (the action in `coralShade` 12.5 `.black`). No card, no mascot,
  **no scanner line** — the scanner backend is not deployed and nothing on this tab may
  promise it.
- Then `Thu – Sun · free` as the folded strip.
- **Not paired**: one card at the end of the list — white, r20, 1px `cardEdge`, padding 16.
  `Got your class schedule?` 16 `.black`; `Open Prepkin on your laptop and your classes land
  here.` 12.5 `.heavy` `muted`; `Show me how` 13 `.black` `coralShade` in a 44pt row. It points
  at laptop pairing, never at a form, and appears only when the student is not paired.
- Past ticker days keep their load glyphs when they carry overdue work — the only reason a
  past day is not simply dimmed away.

## Interactions and behaviour

| Interaction | Behaviour |
| --- | --- |
| Tap the title chevron | Month sheet presents, `.presentationDetents([.fraction(0.83)])`, standard sheet spring |
| Tap `Today` in the sheet | Grid scrolls to the current month and selects today, 0.25s `easeOut`; the sheet stays open |
| Tap a grid day | Selects it, `coralSoft` fill 0.12s `easeOut`; the list under the grid swaps with a 0.15s cross-fade |
| Tap the sheet `X` / swipe down | Dismisses; the ticker week follows the selected day |
| Swipe the ticker horizontally | Paged week change, one week per swipe; the `Today` pill appears in the title row when the ticker is off today's week |
| Tap a ticker day or a day header | Pushes the day timeline, 0.35s system push |
| Tap a task row | Typed rows open the editor; Canvas rows do nothing (submitted ones carry a lock and cannot be un-ticked) |
| Check off | Checkbox fill 0.18s `easeOut`; SF `checkmark` cross-fades in over 0.2s (**no trim animation** — that needs George's GIF sign-off); the row drops to 45% opacity over 0.2s and stays in place; coins fly to `CoinBadge` exactly as Home does |
| Swipe a typed overdue row | Reveals `Move`; opens the When sheet |
| Tap `Add task` in a gap | Opens the built quick add with the day and the gap's start time pre-filled |
| Tap the `+` | Opens the built quick add |
| Now-line | 2.4s infinite ease-in-out opacity pulse 1 → .42, on the line only; the dot and the word do not pulse |

**Reduce Motion.** Sheet and push become 0.12s cross-fades; the now-line stops pulsing and
stays at full opacity; the coin does not fly (the badge counts up in place); the kin plays
`idle`. Nothing on these screens is carried by motion alone.

**Dynamic Type.** All reading sizes (≤ 20pt) go through `Theme.font`, which caps at 1.3×. The
34pt title, the 22pt sheet title and the ticker's 17pt day numbers are display sizes and stay
put. At 1.3× the day header row grows past 44 (fine) and the ticker load row must not — clip
the glyph row, not the number.

## State

```
selectedDay: Date            // drives the ticker week, the grid selection and the list
tickerWeek: Date             // the Sunday of the week on screen; paged by swipe
monthSheetPresented: Bool
monthCursor: Date            // the month the grid shows; independent of selectedDay
timelineDay: Date?           // non-nil while the day timeline is pushed
swipedRowID: UUID?           // one open swipe at a time
```
Everything else is read from `GameState` / `CanvasSync`: `CanvasItem` (title, courseName,
colorHex, dueAt, submitted), `CanvasEvent` (title, courseName, colorHex, startAt, endAt,
allDay, location), `DatedTask` (title, day, minute, kind, notes). **Invent no stat and no
number the app could not already know.** `DatedTask` has no course colour — it renders with
`Theme.dim`, which is the only truthful option.

## Design tokens

| Prototype hex | Token | Used for |
| --- | --- | --- |
| `#F8F8F8` | `Theme.paper` | the page |
| `#FFFFFF` | `Theme.card` | rows, the ticker's today card, the sheet |
| `#ECEAE6` | `Theme.cardEdge` | every card hairline |
| `#2E2622` | `Theme.ink` | titles |
| `#96877F` | `Theme.muted` | **every** caption, hour label, weekday label |
| `#B4A996` | `Theme.dim` | typed-task rails, the `+n` chip |
| `#C9BEAC` | `Theme.inactive` | other-month days, dotted gap rails |
| `#F0E9DC` | `Theme.hairline` | rules |
| `#F3ECE0` | `Theme.paperSunk` | the `Today` pill, `Add task`, the close disc, swipe actions |
| `#F4F0EB` / `#E6DFD7` / `#6FC79E` | `Theme.checkFill` / `checkBorder` / `check` | the checkbox |
| `#FF6F61` | `Theme.coral` | today, the `+`, the now-line, Physics 13 |
| `#FFE9E5` | `Theme.coralSoft` | the selected grid day, the Physics tile |
| `#FF8A7E` | `Theme.coralIcon` | glyph fills inside a coral tile |
| `#C4523F` | `Theme.coralShade` | today's words, `Tap to add`, `Show me how` |
| `#57C79B` / `#DFF3E9` | `Theme.mint` / `mintSoft` | Writing 5 |
| `#9BC8F2` | `Theme.sky` | Intro Psych |
| `#EEF5FC` | *new* `Theme.skySoft` | sky at ~8% — add it, or use `sky.opacity(0.12)` |
| `#FFC24B` / `#E8A62E` | `Theme.coin` / `coinBorder` | the coin disc |
| `#8A5F14` | *new* `Theme.coinInk` | the `Still counts` header and captions — `coinDark` (#A8761D) is 3.2:1 on white and fails |
| `#7B6C63` / `#5F534A` | *new* darker steps of `muted` | text on tinted blocks, and glyph strokes in `paperSunk` pills |
| `#E8CFA0` | *new* `Theme.coinHairline` | the `Still counts` rule |

Radii: `Radius.chip` 10 (grid cells, checkboxes) · `Radius.control` 14 (the today card, icon
tiles, the back control, event blocks use 12 — see deviations) · `Radius.card` 20 (rows, the
not-paired card) · `Radius.sheet` 28 (the month sheet). Spacing: `gutter` 18, `band` 14,
`tabClearance` 112. Type: `Theme.font(size, weight)` with weights 600–900 only.

## Components

**Reuse, do not restyle:** `CoinBadge`, `CoinDisc`, `IconTile`, `PlusTag`, `CalendarTaskRow`,
`EventRow`, `FoldedDaysStrip`, `SproutImage`, and the built `QuickAddSheet`, `WhenSheet`,
`DatePhrase`, `Upcoming`.

**Replace:** `DayLoadStack` (20 × 3 bars → 12pt object glyphs) and `MonthLoadBars` (11 × 3
bars → 11pt glyph chips). Keep the type names; change the body.

**New:** `DayLoadGlyphs`, `MonthSheet`, `DayTimelineView`, `TimelinePin`, `TimelineBlock`,
`GapRow`, `StillCountsHeader`, `NotPairedCard`.

**Delete:** the Week · Month segmented control, the ‹ Today › stepper, `CalendarStripCard`'s
`controlRow`, `gridCard`, and any per-day `+`.

## Assets

None new. Load glyphs are the existing flat-vector object set through `IconTile`; chevrons,
plus, check, calendar and X are SF Symbols (as the current file already does); the kin is
`SproutImage`; the coin is `CoinDisc`.

## Files in this bundle

- `Calendar Tab v2.dc.html` — the prototype. Open in a browser. **Turn 3 (`#3a`) is the
  design to build**; turns 2 and 1 are the explorations behind it.
- `support.js` — the runtime the prototype needs. Keep it beside the HTML.
- `DESIGN-README.md` — the original three-direction handoff, with the full exploration notes,
  the Mobbin references and the deviations argued in turn 1 and 2.
- `BUILD-NOTES.md` — the stub to fill in while porting.

## Rules that still apply

Coins pay for finishing, never for grades. No meters, no streaks, no countdowns, no padlocks,
no `?` tiles, no red, no exclamation marks, no engineering words. Every number shown only goes
up (the puzzle rating is the one exception and it does not appear on this tab). Overdue is
amber and reads "still counts". Every string under 40 characters on a line; every control 44pt;
every image and button labelled. Nothing on this tab promises a feature that is not live.
