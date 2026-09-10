# Build notes — Calendar tab

Ported 2026-09-09 into `ios/Sources/CalendarView.swift` (full rewrite, 1,300 lines) plus one
new token in `ios/Sources/Theme.swift`. Nothing else was touched. Uncommitted, on `main`.

---

## What the handoff assumed, and what was actually there

The README was written against `main` at `3bd80e14`, where the Calendar tab did not exist. It
does exist — it is uncommitted work in George's tree — so most of the "absent" list in the
handoff is wrong in a good way:

| Named as absent | Actually |
| --- | --- |
| `ios/Sources/CalendarView.swift` | present, 726 lines, the screen in the two screenshots |
| `ios/Sources/Core/DatedTask.swift` | present, with `CanvasEvent` in the same file |
| `RootView.Tab.calendar` | present. Six tabs, `games` already retired |
| `TabIcon` calendar case | present and drawn — deviation 6 is closed, the traced icon was not needed |
| `design/SOCIAL-PLAN.md`, `handoff-friends/`, `handoff-first-run/` | all present |

**Every field the handoff guessed at exists**, with two corrections:

- `CanvasEvent` has `.allDay`, `.startAt`, `.endAt`, `.location`, `.colorHex` — as assumed.
- `DatedTask` has `.minute` (nil ⇒ all day), `.notes`, and `.source` — but the source is
  `.mine | .photo`, not `.typed | .scanned`. It is never shown, as the handoff asks.
- A `DatedTask` really does have no course colour: `GameState.datedRow` builds its `DailyTask`
  with `colorHex: nil`. Deviation 2 (typed work gets `dim`, never coral) is therefore not a
  choice, it is the only truthful option. Built as specified.

## Built as designed

- **The strip card is the chrome.** Week · Month and ‹ Today › live inside the card. Two bands,
  not three. `CalendarStripCard` is `stripCard` in the view; `gridCard` is its month twin and
  shares the same `controlRow`.
- **Load is bars.** `DayLoadStack` — up to four 20×3 bars, bottom-aligned, chronological with
  the earliest at the bottom, past days at 40%. `MonthLoadBars` is the horizontal version,
  11×3, in the month cell.
- **Events are a different object.** `EventRow` is no longer a card: right-aligned start time,
  a coloured dot, and a rail whose height is the event's own duration (44pt for the first hour,
  +20 per hour after, capped at 140 so an all-afternoon block cannot own the screen). All-day
  is a hollow dot with no rail, pinned above the timed run. Happening-now is a coral ring, a
  `NOW` chip and the `until {h:mm a}` caption.
- **Empty days cost one line.** `EmptyDayLine`, and `FoldedDaysStrip` for a run of past empty
  days ("Sun – Tue · free"), which opens in place.
- **One floating button.** The camera FAB is gone. The `+` opens `AddSheet` — Type it / Scan a
  syllabus, `.presentationDetents([.height(260)])`. The PLUS tag sits on the label; the row is
  never disabled, and a free student taps Scan and gets the paywall sheet.
- Agenda order, every caption format, the NEXT WEEK divider, the kin peek, the empty-week
  invitation card, and the count line that hides on scroll — all as written.
- Reduce Motion: page transitions become a 0.12s cross-fade, the kin plays `idle`, the NOW dot
  stops pulsing. Nothing on the screen is carried by motion alone.

## Deviations from the handoff

1. **Tokens beat the hexes.** The handoff's token table is a snapshot of an older `Theme.swift`:
   it lists `Theme.paper` as `#FAF5EC`. The app moved to a near-white page (`#F8F8F8`) with the
   uniformity sweep. The README's own rule — *use the token name, do not re-derive the value* —
   was followed, so the screen is warm-grey-on-near-white rather than cream. Everything still
   matches Home, which is the point.
2. **Radii come from `Theme.Radius`.** The five-radius rule in `Theme.swift` is load-bearing
   (`chip 10 · control 14 · card 20 · sheet 28`). The handoff's 24 and 15 became `card` (20) and
   `control` (14); 14 and 11 landed as-is. The checkbox keeps Home's 11.
3. **The title stays 34pt.** Every other tab's page title is `Theme.font(34, .black)`; a 25pt
   Calendar title would read as a different app. The ~110pt the redesign reclaims comes from
   folding the controls into the card, and that is all still there.
4. **`IconTile`, not the circular `CategoryIcon`.** The prototype draws the old hand-drawn icon
   in a cream circle. The app now has one flat-vector set and one way to draw it —
   `IconTile(icon:size:)`, a tinted rounded tile. Using the prototype's circle would have
   reverted the icon work.
5. **Small glyphs are SF Symbols, not new `KinGlyph` cases.** Chevrons, plus, check, camera and
   the note mark are one line each this way; six new `Canvas` path cases would be ~200 lines to
   draw what is already on the phone. The existing file used SF Symbols for exactly these.
   Say the word and they become drawn glyphs.
6. **The empty-day line takes 34pt, not 24.** 24pt of paint, 5pt of padding each side. A 24pt
   tap target fails the walkthrough's 44pt rule outright, and the usual trick — transparent
   padding out to 44 — makes two adjacent empty lines overlap and steal each other's taps.
   34 is the compromise; it is still one quiet line.
7. **The ‹ Today › pulse is on the pill, not on the today disc.** Same answer to the same tap,
   one fewer piece of state.
8. **The checkmark does not draw itself.** Home's checkbox swaps an SF `checkmark` in on a 0.2s
   fade. A `trim` animation would be a new motion, and motion needs George's GIF sign-off
   (memory `animation-approval`). The two new motions that *are* in — the NOW pulse and the kin
   peek — are the handoff's own and should get that sign-off before release.
9. **The kin peek is a clip, not new art.** `SproutImage` at 78pt in a 44pt box, top-aligned.
   The still is bottom-anchored art, so this shows the top of the fish over the edge.
10. **The agenda opens at the top when the past is only a fold.** The build this replaces
   always jumped to today on appear, which pushed the folded strip off screen — and the fold
   is the thing the redesign added. It now jumps only when a day above today carries rows.
   Artboard `1a` shows exactly this: the fold sitting under the card, today right below it.

## Two bugs found while porting, both fixed

- **`02:59 PM` in the time column.** `.hour(.defaultDigits(amPM: .omitted))` pads to two digits.
  The clock now builds its pattern from the locale's own `jmm` template with the meridiem
  struck out, so a 12-hour locale reads `2:59` and a 24-hour one still reads `14:59`.
- **The count line never hid.** The scroll-offset preference was being clobbered: every sibling
  in the scroll content hands the reduce a default `0`, so `value = nextValue()` ended the walk
  on zero and the offset never moved. `AgendaTopKey.reduce` now ignores zeros. Verified on the
  simulator — the line goes on the first scroll and the title stays.

## Verified on the simulator

iPhone 17 Pro, `-unlockAll -sampleCanvas`, 2026-09-10: week with content (fold, day headers,
task rows, the 44pt and 64pt event rails, NEXT WEEK, kin peek), month grid with the selected
day's list, the empty week's invitation card, the `+` sheet, and the count line hiding on
scroll. `CalendarTests` and `CopySweepTests` pass.

## Open, and worth a decision

- **Deviation 1 and 3 in the handoff are still offered back.** The agenda runs past Saturday
  into NEXT WEEK, and an empty future day has no `+`. Both are built the handoff's way. Say the
  word on either and it is a five-line change.
- **The sample data is one minute off.** `MockCanvasClient` puts office hours at 2:59–3:59 PM
  and the essay at 8:59 AM, so the screen reads "due 8:59 AM" where the design reads 8:00. That
  is the mock, not the layout — worth fixing in `CanvasSync.swift` before any screenshot ships.
- **The wallet still shows a debug 99,000** on this simulator, as the handoff noticed.
- **The Plus tag is now a component** (`PlusTag`) rather than an inline capsule in three places.
  It only lives in `CalendarView.swift`; if Plus grows a fourth surface, move it to
  `KinComponents.swift`.
- Motion sign-off: NOW pulse (2.4s, infinite) and the kin peek.
