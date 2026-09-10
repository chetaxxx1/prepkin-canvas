# Handoff: Calendar tab — Prepkin Canvas

Target: `chetaxxx1/prepkin-canvas`, SwiftUI iPhone app.
Intended repo path: `design/handoff-calendar/`
Write `BUILD-NOTES.md` back into this folder when the port is done.

---

## About the design files

**The HTML in this bundle is a design reference, not production code.** `Calendar Tab.dc.html` is
a prototype that shows intended look, measurement and behaviour. Do not port the markup, the
inline styles or the JavaScript.

The job is to build this as **SwiftUI**, in `ios/Sources/`, using the app's existing patterns:
`Theme.swift` for every colour, font and radius; the named components in `KinComponents.swift`,
`PrepkinIcons.swift` and `HomeView.swift` reused as-is; `GameState` for coins and completion.
Where this document names a token or a component, use that name — do not re-derive the value.

Two things in the HTML are deliberately not real and must not be transcribed:

- **The kin.** Every dashed `KIN` box is a placeholder for `SproutImage` / `SproutView`. The
  caption under each artboard gives the size, coat and star count. Sprout is a finished character —
  nothing here approximates it.
- **The tab bar's Calendar icon**, which is traced from a screenshot because `PrepkinIcons.TabIcon`
  has no `calendar` case yet. Draw the real one.

Everything else — the `CategoryIcon` objects, the row anatomy, the tab bar, the coin discs — was
transcribed from the Swift source and can be trusted to the coordinate.

---

## Overview

Home is "what do I do right now." Calendar is "what is coming." The build works but reads
like a settings screen: three bands of chrome, then a stack of identical white cards, with the
first row at y≈330 on an 874pt phone.

Four changes carry this redesign.

**The strip is the chrome.** The Week · Month switch and ‹ Today › move *inside* the strip card,
so the header is two bands instead of three. First content lands at **y=221** instead of y≈330 —
109pt reclaimed, roughly one and a half task rows.

**Load is bars, not lint.** Each strip day carries up to four stacked 20×3 bars in course colour,
bottom-aligned so the stack grows upward like a bar chart. A three-item Thursday is visibly taller
than a one-item Friday from across the room. The month grid inherits the same language, laid
horizontally.

**Events are a different object, not a different tint.** A task is a white card floating on paper.
An event is a ruled entry *on* the paper: a right-aligned start time, a coloured dot, and a rail
whose height is the event's own duration. Two hours of Midterm 1 is a 64pt rail; one hour of office
hours is 44pt. An exam stops looking like an essay because it is physically bigger, and the size
comes from `startAt`/`endAt` — nothing is guessed.

**Empty days cost one line.** Past empty days fold into a single tappable strip
("Sun – Tue · free"). Future empty days are one 24pt line with "Free" at the right. Seven headers
for three items becomes one line for three empty days.

**One floating button, not two.** The scanner used to sit on every screen as a white camera
wearing a PLUS badge — a permanent advert for something most students cannot use. It moves inside
the `+` sheet as one of two ways to add. That matches the order a student actually thinks in
(*add something* → *how*), halves what floats over the list, and keeps the paywall out of the main
surface. The scanner still gets its full pitch on the empty week, where it is the hero.

The kin appears twice: peeking over the bottom edge at the end of the week's scroll, and at full
size on the empty week, where it is the whole point of the screen.

---

## Fidelity

Hi-fi, production-intent. Every colour, radius, font size and weight below is either a
`Theme.swift` token or a value read off an existing component in `HomeView.swift`,
`KinComponents.swift` or `PrepkinIcons.swift`. The category icons are the real `CategoryIcon`
geometry, transcribed path-for-path from the 24×24 coordinates in `PrepkinIcons.swift`.

Nunito stands in for SF Pro Rounded in the HTML. Weights map 700→`.bold`, 800→`.heavy`,
900→`.black`.

**What is a placeholder, deliberately:**

- Every kin is a dashed box labelled `KIN` at the size intended, with the coat and star count in
  the caption under the artboard. Sprout is a finished character; `SproutImage` / `SproutView` draw
  it. Nothing here sketches, restyles or approximates it.
- The Kin tab's chip in the tab bar is likewise a dashed 27pt circle — that slot is `SproutFace`.
- Artboard `1e` state 7 (all-day event) uses the title "Add/drop deadline". **There is no all-day
  event in the sample data.** The title is a specimen so the state can be drawn; do not ship it.

---

## ⚠ The repo does not contain the Calendar tab

Read this before porting. At `chetaxxx1/prepkin-canvas@main` (tree `3bd80e14`), the following
files named in the brief **do not exist**:

| Named in the brief | Status at `main` |
| --- | --- |
| `ios/Sources/CalendarView.swift` | absent |
| `ios/Sources/Core/DatedTask.swift` | absent |
| `CanvasEvent` (any file) | absent |
| `design/SOCIAL-PLAN.md` | absent |
| `design/handoff-friends/README.md` | absent |
| `design/handoff-first-run/README.md` | absent |
| `design/screenshots/calendar-2026-09-09/24–31` | absent (screenshots stop at `17-learn-v2-preview.png`) |

`RootView.Tab` still reads `home, focus, games, learn, friends, kin` — there is no `calendar`
case, and `games` has not been retired. `MockCanvasClient` still returns AP Physics / English 11 /
APUSH with a high-school framing.

This design was therefore built from: **every file that does exist and was read**
(`Theme.swift`, `RootView.swift`, `HomeView.swift`, `KinComponents.swift`, `PrepkinIcons.swift`,
`Models.swift`, `CanvasSync.swift`, `Core/TaskTemplate.swift`, `Core/DayKey.swift`), plus the two
supplied screenshots of the running Calendar tab, plus the brief.

**Fields assumed to exist, to be checked against the real `DatedTask` / `CanvasEvent`:**

- `CanvasEvent.allDay: Bool`, `.startAt`, `.endAt`, `.location: String?`, `.colorHex: String?`
- `DatedTask.minute: Int?` (nil ⇒ all day), `.notes: String?`, `.source: .typed | .scanned`
- `CanvasItem.submittedAt` is present and is what drives the locked state (confirmed in
  `CanvasSync.swift`).
- A `DatedTask` has **no** course and therefore no course colour. See Deviations.

---

## Layout, per artboard

Canvas 402 × 874 pt. y=0–59 status bar (never drawn). Tab bar occupies y=774–874 (100pt).

### `1a` — Week, a full week

| Band | y | h | Contents |
| --- | --- | --- | --- |
| Title | 59 | 50 | "Calendar" 25/900 at x=20 · count line 12.5/800 beneath · `WalletChip` right, x-inset 20 |
| Strip card | 113 | 120 | white, r24, x 12→390, shadow `0 2 8 rgba(46,38,34,.05)`, padding `6 10 8` |
| ├ control row | 119 | 32 | Week·Month pill left · ‹ Today › right |
| └ day columns | 153 | 72 | 7 × flex, gap 2, r15, padding `5 0 6` |
| Agenda scroll | 233 | → 874 | x-padding 16, **bottom inset 206**, scrolls under the tab bar |
| Fade | 710 | 64 | paper → transparent, `pointer-events:none` |
| Floating action | — | — | coral `+` 60pt, right 20, bottom 112 |
| Tab bar | 774 | 100 | `RootView.tabBar`, reproduced not redesigned |

**Strip day column** — weekday letter 10.5/900 `dim`; day number 17/900 in a 26pt box; load stack
20pt tall, `column-reverse`, gap 2.5, bars 20×3 r1.5, chronological with the earliest at the
bottom. Four bars maximum; a fifth item replaces the top bar with "+n" at 8.5/900 `dim`.
Today = a 26pt `coral` disc with a white number and the weekday letter in `coralShade`.
Selected = the whole 62pt column on `coralSoft`, r15. Past days: number `dim`, bars at 40%.

**Agenda order within a day** — all-day events → all-day / undated tasks → everything timed, in
time order, tasks and events interleaved. Thursday reads: Bio quiz (all day) → Essay outline
(8:00 AM) → Office hours (2:00 PM).

**Day header** — 20pt top padding, 9pt bottom. Day word 14/900 (`coralShade` for today, `ink`
otherwise), date 13/800 `dim`, then a 1pt `#EFE8DB` hairline leader filling the row, then a 26pt
`+` disc on `hairline` for today and future days. No `+` on past days.

**Empty future day** — one 24pt line: day word 13/900 `dim`, date 12.5/800 `inactive`, "Free"
right in `inactive`. The whole line is the tap target and opens that day's add sheet; there is no
separate `+`, which is what keeps it one quiet line.

**Folded past** — a 38pt `#F3ECE0` r14 strip with a 13pt chevron and "Sun – Tue · free". Tapping
expands it in place into one quiet line per day; tapping again re-folds.

**Next week divider** — 26pt above, hairline · "NEXT WEEK" 10/900 `dim` tracking 1.5 · hairline.

**Kin peek** — 78×44 dashed box, top corners only, 26pt below the last item, centred. Sprout,
coat **mint**, **1 star**, emote **peek**.

### `1b` — Week, empty

Title band has **no count line** — there is nothing to count. Strip shows all seven days, numbers
in `dim`, no bars. No floating buttons: the card already carries both actions, and a coral `+`
floating over an invitation reads as two competing offers.

Invitation card at y=269, x 12→390, white, r28, padding `30 26 26`:

| Element | Spec |
| --- | --- |
| KIN box | 116 × 106, 2pt dashed `#CFC3B2`, r20, 20pt below |
| Headline | "Nothing on this week." 19/900 `ink`, centred |
| Sub | 13.5/800 `muted`, centred, max-width 270, `text-wrap: pretty` |
| Scan button | full width, 50pt, r100, fill `mintSoft`, 1.5pt `mint` border, label 15/900 `ink`, 21pt camera glyph, PLUS tag inline. Same treatment as the sheet's Scan row, so the two read as one action |
| Add button | full width, 46pt, r100, 1.5pt `tileRing` border, no fill, 14.5/900 `#7B6C63` |

The scan button is `mintSoft` with an `ink` label rather than a filled `mint` capsule with white
text: white on `#57C79B` is 2.4:1 and fails at 15pt.

### `1c` — Month

Grid card y=113, auto height (370pt for a 6-row month), x 12→390, r24, padding `6 10 10`.
Control row 32pt. Weekday letters 10.5/900 `inactive`, 18pt line, 4pt above.
Cell **51.1 × 50**, r14. Number in a 25pt box, 15/900. Bars 11×3 r1.5, horizontal, gap 2.5, 4pt
under the number, up to three then "+n" 8.5/900 `dim` in the fourth slot.
Today = 25pt `coral` disc, white number. Selected = whole cell on `coralSoft` r14.
Other-month numbers `#D8CFC0`. Selected day's list from y=495, same rows as the week.

See `1d` for every cell state drawn at size.

**Paging** — horizontal swipe. The grid cross-fades over **0.18s `easeInOut`** while the six week
rows slide ±28pt in the direction of travel (staggered 12ms per row, `spring(response: 0.34,
dampingFraction: 0.86)`). The selected-day list below cross-fades on the same 0.18s and does not
slide, so the eye stays on the grid. The header caption's month name uses
`.contentTransition(.numericText())`. Selection survives the page: paging to October keeps
"the 10th" selected only if the student then taps; otherwise the list shows the new month's first
day with anything on it, or "Free".

### `1e` — Rows

Board width 436, cards at the real 370pt row width.

### `1f` — One button, and what it opens

Bottom 300pt crop. A single coral `+`, 60pt, right 20, bottom 112. Nothing else floats. The 64pt
paper fade stays: with a 206pt scroll inset the last row already clears the button, and the fade is
what stops a half-cut row reading as a clipping bug.

The `+` sheet, below it: white, r28 on the top corners only, `.presentationDetents([.height(260)])`
— never full screen, because it is two choices, not a form. 38 × 4.5 grabber. Title 17/900 taking
the selected day, date 12.5/800 `muted` beneath.

| Row | Spec |
| --- | --- |
| Type it | 20pt r, `tile` fill, 1.5pt `tileRing` border, 44pt white icon circle carrying `CategoryIcon`'s pencil, label 15.5/900, caption 12.5/800 `muted`, 14pt chevron |
| Scan a syllabus | same metrics, `mintSoft` fill, 1.5pt `mint` border, camera glyph on white, PLUS tag inline beside the label, caption in `#7B6C63` for contrast on mint |

Scrim `rgba(46,38,34,.34)`. The PLUS tag sits on the label, not the row: the row is never disabled,
greyed or padlocked. A free student taps Scan and gets the paywall sheet — no error, no shake, no
bounce-back.

---

## Tokens, by Theme name

| Use | Token | Hex |
| --- | --- | --- |
| page | `Theme.paper` | `#FAF5EC` |
| task row, strip card, grid card, wallet, camera FAB | `Theme.card` | `#FFFFFF` |
| all primary text | `Theme.ink` | `#2E2622` |
| captions | `Theme.muted` | `#96877F` |
| dates, past numbers, "+n", note text | `Theme.dim` | `#B4A996` |
| "Free", empty-day date, weekday letters | `Theme.inactive` | `#C9BEAC` |
| day-header leader, `+` disc fill | `Theme.hairline` | `#F0E9DC` |
| icon tile / its ring | `Theme.tile` / `Theme.tileRing` | `#FDF9F4` / `#EDE1D3` |
| unchecked box / its border | `Theme.checkFill` / `Theme.checkBorder` | `#F4F0EB` / `#E6DFD7` |
| checked box | `Theme.check` | `#6FC79E` |
| `+` FAB, today disc, "now" ring, Physics 13 | `Theme.coral` | `#FF6F61` |
| selected day, "NOW" chip ground | `Theme.coralSoft` | `#FFE9E5` |
| "Today" day-word, "NOW" chip text | `Theme.coralShade` | `#C4523F` |
| Writing 5, scan-button border | `Theme.mint` | `#57C79B` |
| scan-button fill | `Theme.mintSoft` | `#DFF3E9` |
| Intro Psych | `Theme.sky` | `#9BC8F2` |
| coin disc / its ring | `Theme.coin` / `Theme.coinBorder` | `#FFC24B` / `#E8A62E` |
| coin numeral, PLUS tag text | `Theme.coinDark` | `#A8761D` |
| PLUS tag ground | `Theme.coinSoft` | `#FFF3D6` |
| tab bar / active pill / active label | `Theme.tabBar` / `.tabActiveFill` / `.tabActiveInk` | `#FFFDF8` / `#FFE0DA` / `#C24A3E` |
| next-week rule | `Theme.chipDivider` | `#E9E1D6` |

Two values are **not** tokens and need one: the folded-past strip `#F3ECE0`, and the
control-pill track `#F5EFE3`. Both are one step darker than `paper` and one step lighter than
`hairline`. Suggest `Theme.paperSunk = hex(0xF3ECE0)` and use it for both.

Radii: 44 device · 28 invitation card · 24 strip/grid card · 20 task row · 15 strip column ·
14 month cell / folded strip · 11 checkbox · 100 pills. Font `Theme.font(_:_:)` throughout.

Row shadow `Color.black.opacity(0.07), radius 3, y 2` (the exact `HomeView.TaskRow` shadow).
Card shadow `rgba(46,38,34,.05), radius 8, y 2`.

---

## Reused components, by name

Nothing below was restyled.

| Component | Where | Source |
| --- | --- | --- |
| `WalletChip` | title band, every artboard | `KinComponents.swift` |
| `CoinDisc` | wallet, every coin chip | `HomeView.swift` |
| `CategoryIcon` | every task row's tile | `PrepkinIcons.swift` — ruler / pencil / flashcards |
| `TaskRow` anatomy | `CalendarTaskRow` inherits tile, title, caption, coin column, 33pt checkbox, 62% done fade, no strikethrough | `HomeView.swift` |
| `KinIcon(.lock)` | submitted row | `KinComponents.swift` |
| `TabIcon` | Home / Focus / Learn / Friends | `PrepkinIcons.swift` |
| `KinChip` → `SproutFace` | Kin tab | `RootView.swift` |
| `RootView.tabBar` | all artboards | `RootView.swift` |
| `TabPressStyle` | every button press | `RootView.swift` |
| `SproutImage` | the two KIN boxes | `SproutImage.swift` |

New, and needing a name: `CalendarStripCard`, `DayLoadStack`, `EventRail`, `FoldedDaysStrip`,
`EmptyDayLine`, `MonthCell`.

---

## State

| State | Type | Default | Notes |
| --- | --- | --- | --- |
| `mode` | `.week / .month` | `.week` | the switch; no third zoom |
| `anchorWeek` | `DayKey` | week containing today | ‹ › and swipe move it |
| `anchorMonth` | `DayKey` | month containing today | |
| `selectedDay` | `DayKey` | today | strip tap, grid tap, ‹ Today › |
| `pastExpanded` | `Bool` | `false` | resets when `anchorWeek` changes |
| `captionVisible` | `Bool` | `true` | `false` once the agenda scrolls past 10pt |

Everything else is derived. Nothing is persisted except by way of `GameState`: a check-off is a
`state.complete(task)` call, exactly as Home does it, and coins move through the same ledger.

`selectedDay` never scrolls the agenda to a *hidden* day — tapping a strip day scrolls its header
to the top of the agenda with `spring(response: 0.4, dampingFraction: 0.9)`. Do not use
`scrollIntoView`-style jumps; the header must land at the scroll top, not merely become visible.

---

## Every string of copy

Header
```
Calendar
4 things due this week · 1 event      (week)
4 things due September · 2 events     (month)
Week      Month      Today
```

Day headers and empty days
```
Today  Sep 9
Thursday  Sep 10
Sun – Tue · free
Saturday  Sep 12               Free
NEXT WEEK
```

Task captions — exact formats
```
{course} · all day                        Physics 13 · all day
{course} · due {h:mm a}                   Writing 5 · due 8:00 AM
{course} · handed in                      Writing 5 · handed in
{course} · was due {EEE}                  Physics 13 · was due Tue
{kind} · all day                          Study · all day
{kind} · {h:mm a}                         Study · 7:30 PM
```
`all day` is used when a Canvas due time is 23:59 — Canvas's own end-of-day default, so the
student is not told a minute that means nothing. `{kind}` is `TaskKind.label`: `Study` or `Life`.
A `DatedTask` note is a **second caption line**, 11.5/700 `dim`, one line, ellipsised, behind an
11pt note glyph. A scanned task carries the same glyph; the row never says where it came from.

Event captions — exact formats
```
{course} · {h:mm}–{h:mm a} · {location}   Intro Psych · 2:00–3:00 PM · Moore 202
{course} · {h:mm}–{h:mm a}                Physics 13 · 9:00–11:00 AM
{course} · all day                        Intro Psych · all day
{course} · until {h:mm a} · {location}    Intro Psych · until 3:00 PM · Moore 202
```
The last is the happening-now form. It replaces the start time with what a student actually wants
mid-event: when it ends. Chip label: `NOW`.

The + sheet
```
Add to Thursday
Sep 10
Type it
One thing, on one day
Scan a syllabus          PLUS
One photo and I'll fill in the dates
```
On today the title reads `Add to today` and the date line is dropped.

Empty week
```
Nothing on this week.
Point the camera at a syllabus and I'll fill this in.
Scan a syllabus          PLUS
Add something yourself
```

No exclamation marks. No "No events scheduled." No streak, no countdown, no overdue count, no
padlock, no "?" tile. "was due Tue" is the strongest thing on the screen and it is grey.

---

## Interactions and motion

| Interaction | Behaviour | Motion |
| --- | --- | --- |
| Tap a strip day | selects it, agenda scrolls that day's header to the top | `spring(response: 0.4, dampingFraction: 0.9)`; the `coralSoft` column fades in over 0.14s `easeOut` |
| Swipe the strip / ‹ › | pages one week | rows slide ±28pt, cross-fade 0.18s `easeInOut` |
| Tap ‹ Today › | `anchorWeek` and `selectedDay` return to today | same page transition; if already on today, a 0.2s scale-to-1.04 pulse on the today disc and nothing else |
| Tap a checkbox | box fills `check`, checkmark draws, row fades to 62%, wallet counts up | box `spring(0.28, 0.72)`; checkmark `trim` 0→1 over 0.16s `easeOut`; opacity 0.2s `easeOut`; wallet `.contentTransition(.numericText())` with `.snappy` — the same combination Home uses |
| Untick | reverses, coins come back off | 0.2s `easeOut`, no animation flourish — undoing is not an event |
| Tap a submitted row's box | nothing; a 0.12s 3pt horizontal nudge on the lock glyph | Canvas owns that state |
| Tap `+` | the add sheet rises | scrim 0.2s `easeOut`; sheet `spring(response: 0.42, dampingFraction: 0.86)`; the `+` rotates 45° into a close glyph over 0.2s `easeInOut` |
| Tap the folded past strip | expands to one line per day | height `spring(0.34, 0.86)`, lines fade in staggered 20ms |
| Tap an empty day line | opens the add sheet for that day | sheet, standard |
| Tap a typed row | opens the day editor (separate brief) | |
| Tap a Canvas row's body | nothing — Canvas rows are not editable | |
| Tap an event | nothing on this screen | |
| Scroll the agenda past 10pt | count line hides, title stays | 0.18s `easeOut` on opacity and height |
| Swipe the month grid | pages one month | as above |
| Any button press | scale 0.94 | `spring(response: 0.22, dampingFraction: 0.7)` — `TabPressStyle` |
| Kin peek reaches the bottom | rises 10pt and plays **peek** once | `spring(0.44, 0.8)`, fires once per appearance |
| Empty week card appears | kin plays **bounce** once, 0.3s after the card lands | card `spring(0.4, 0.85)` |
| Happening-now dot | opacity 1 → 0.45 → 1 | `nowPulse`, 2.4s `easeInOut`, infinite |

### Reduce Motion

With `accessibilityReduceMotion` on: all page transitions become a 0.12s cross-fade with no slide.
The checkmark appears at full size rather than drawing; the row's opacity change stays, because it
carries meaning. The wallet number swaps without the rolling digits. The `NOW` pulse stops
entirely — the ring and chip are static and already sufficient. The kin peek and the empty-week
bounce do not play; the kin appears in `idle`. No information is only ever conveyed by motion.

---

## Assets

No new image assets. Everything on this screen is a drawn vector or a type treatment.

| Asset | Where it comes from |
| --- | --- |
| `CategoryIcon` — ruler, pencil, flashcards | `ios/Sources/PrepkinIcons.swift`, already in the app. Transcribed into the prototype as SVG at their real 24×24 coordinates; use the Swift originals |
| `TabIcon` — house, hourglass, books, heads | `ios/Sources/PrepkinIcons.swift`, already in the app |
| `TabIcon` — calendar | **does not exist.** Needs drawing to the same rule book: an object not a symbol, filled not stroked, one hue family. The prototype's traced version is a starting point only |
| `CoinDisc` | `ios/Sources/HomeView.swift`, already in the app |
| `KinIcon(.lock)` | `ios/Sources/KinComponents.swift`, already in the app |
| Chevrons, plus, checkmark, camera, note glyph | New, drawn in the prototype. Small enough to build as `Canvas` paths in the `KinGlyph` set — suggest adding `.chevronLeft`, `.chevronRight`, `.plus`, `.check`, `.camera`, `.note` |
| Sprout, all sizes | `SproutImage` (still) / `SproutView` (animated, Home only) |
| Fonts | `Theme.font(_:_:)` — SF Pro Rounded. Nunito is the HTML stand-in only |

---

## Files in this bundle

| File | What it is |
| --- | --- |
| `Calendar Tab.dc.html` | The prototype. Six artboards, `1a`–`1f`. Open it in a browser — `1a` and `1c` are interactive: check off a row and the wallet counts up, tap the folded past strip, tap strip and grid days, scroll to see the count line hide |
| `support.js` | Runtime the prototype needs. Keep it beside the HTML; it is not part of the design |
| `24calendarweek.png` | The Calendar tab as it runs today, Week |
| `25calendarmonth.png` | The Calendar tab as it runs today, Month |
| `README.md` | This document |

Artboard map:

| id | Artboard |
| --- | --- |
| `1a` | Week, a full week — the main screen |
| `1b` | Week, empty — nothing paired |
| `1c` | Month |
| `1d` | Month cell, every state, drawn at size |
| `1e` | The rows — five task states, three event states |
| `1f` | The floating action, and the sheet it opens |

---

## Deviations, and why

1. **The agenda runs past Saturday into "NEXT WEEK".**
   The sample data puts Midterm 1 on Sunday Sep 13 — one day past the week the strip is showing.
   "What is coming" should not stop at a grid boundary that only exists because weeks start on
   Sunday. The agenda continues under a hairline divider; the strip still pages weeks. If you
   would rather it hard-stop, cut everything after the divider — nothing else depends on it.

2. **Typed tasks get `dim`, not `coral`.**
   The running build gives a `DatedTask` a coral bar, which collides with Physics 13's course
   colour and with the `+` FAB. On this screen colour means *course*; a task with no course gets a
   warm grey. If you want typed tasks to carry a colour, it should be one the course palette can
   never produce.

3. **The empty future day has no `+`.**
   Brief asked for a small `+` on future days. It is there on days that have content; on empty
   days the whole line is the tap target instead, because a 24pt line with a date, "Free" and a
   button is not a quiet line. Say the word and it goes back.

4. **Header count says 4, the screenshot says 3.**
   `4 things due this week · 1 event` counts the typed Bio quiz. The running build's count appears
   to skip `DatedTask`s. Worth checking which is intended.

5. **The wallet reads 1,240.** The screenshots show 99,000, which is a debug balance.

6. **The tab bar's Calendar icon is traced from `25-calendar-month.png`**, not from source —
   `PrepkinIcons.TabIcon` has no `calendar` case at `main` (it still has `games`). Replace it with
   the real one when the tab lands.

7. **Two colours have no token.** `#F3ECE0` and `#F5EFE3`. See Tokens.

8. **One floating button, not the two the brief specified.** Your call, taken 2026-09-09. The
   camera came off Week and Month; the scanner is the second row of the `+` sheet. Everything the
   old camera did still exists, one tap further in, and the main surface no longer carries a
   permanent PLUS badge. Artboard `1f` shows both halves.

9. **Controls are 26–32pt tall, not 44.** The Week·Month segments, ‹ ›, ‹ Today › and the day
   `+` all carry transparent padding out to 44 × 44. The checkbox does the same (33pt visual,
   44pt target, −5.5pt margin). Do not shrink the targets to match the paint.

### Considered and rejected

- **Today pinned as a sticky card.** Pins one day and shoves the other six under it; the tab is
  about the week, not about today — that is Home's job.
- **Both FABs moved into the header.** Solves the overlap but puts "add" 700pt away from the day
  the student is looking at, and leaves a hole where the buttons were.
- **Keeping the camera and dropping only its PLUS tag.** An unlabelled button that opens a paywall
  is worse than a labelled one — the tag is honest, the button's placement was the problem.
- **A tinted day cell whose depth reads as load.** Two items and three items are the same
  swatch to most eyes; the bars are countable.
- **Course colour as caption text.** `Theme.sky` at 12.5pt is 2.1:1 on white. Course colour stays
  on bars, dots and the 4pt rail — never on type.

---

## References

Mechanics only. Every colour, radius and font here still comes from `Theme.swift`.

- [Amie — day timeline with week strip](https://mobbin.com/screens/5330247b-2fcd-497e-9dfe-8355835bfb14) — the compact week strip living in the header with the month at the left and a coral today disc; this is why the switch and ‹ Today › could move into the strip card.
- [Amie — day agenda under a date strip](https://mobbin.com/screens/18d0ae58-327f-4eed-9e90-de3dd079b250) — timed entries reading as a ruled timeline rather than a stack of cards; the source of the event rail.
- [Todoist — Upcoming, grouped by day](https://mobbin.com/screens/d47e73a3-2711-4811-b66f-616f1c905bf3) — small one-line day headers over big content, and load dots under the strip numbers. Our day headers are the same idea with a hairline leader; our bars are its dots given a height.
- [Structured — timeline with a pinned band above it](https://mobbin.com/screens/297aa3fc-85b4-4fc6-b9c2-8ba935f089e5) — undated and all-day items pinned in a band above the timed run; this is the all-day-above-timed rule.
- [Crouton — meal plan as a stack of day cards](https://mobbin.com/screens/ca1e3eb1-7f04-4954-ad8a-73e709972ec0) — one block per day with its own `+`, and empty days that stay small. Taken: the per-day `+`. Rejected: its empty days are full-height dashed boxes, which is the problem we are fixing.
- [Finch — daily goals under the pet](https://mobbin.com/screens/b5d29fad-9c88-43e0-9aa0-05b7602ab48d) — the warmth level to match: character present, never in the way of the list. Our kin peeks at the end of the scroll rather than sitting on top of it, because Calendar's job is the list.

Searched and not used: Microsoft Outlook and Notion day views (both returned dense
enterprise agendas with no equivalent of a load indicator), Recime / Wabi / Centr meal planners
(day cards without the empty-day problem), Evernote (no day grouping). No "Rodeo By Day" or
"Fantastical" screen surfaced in the iOS index; the all-day-above-timed mechanic came from
Structured and Amie instead.
