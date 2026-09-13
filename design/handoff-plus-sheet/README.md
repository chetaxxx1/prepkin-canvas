# Handoff: Prepkin Plus — the sheet (artboards 1–5)

Design date 2026-09-12 · brief `design/CLAUDE-DESIGN-PROMPT-PLUS.md` · spec `design/PLUS-SPEC.md`
· target `ios/Sources/PlusSheet.swift`

## Overview

This is the one screen in Prepkin that asks for money. It is **already on its second draft** —
`PlusSheet.swift` has the kin hero, the free line first, five drawn perk tiles, the compare
table, the gift timeline and the Apple 3.1.2 block. This handoff is the third, and it changes
four things. Nothing about the offer, the prices, the perk list or the rules changes: every
number still comes from `PlusGate`, every price from `PlusStore.products`, and the copy is the
built copy except where noted.

**What changes**

1. **The price and the button move into a floating card pinned to the bottom of the sheet.**
   Today `Get Plus` sits roughly 900pt into the scroll, below the hero, the free line, five
   perk tiles, a compare link and two stacked price cards. It is now always on screen, with the
   two plans as a compact two-up row inside the card, and the 3.1.2 line and links in the same
   card — so the four things App Review looks for can never be scrolled away from.
2. **Every card loses its shadow.** The sheet currently draws `shadow(radius:10, y:6)` on the
   perk tiles, the price cards, the gift timeline and the compare table. `Theme.swift` took that
   out of `CardStyle` on purpose — "a page of eight shadowed cards has no hierarchy left to
   spend". A card is white with one `cardEdge` hairline. **The only shadow on this screen is the
   floating price card**, because it is the one thing that genuinely floats.
3. **The perks become fragments of the app's own UI, at the size they appear in the app.** Not
   illustrations, not icons in circles. The shop perk is the real pick row with real drawn
   objects and real coin prices; the focus perk is the real chip row; the calendar perk is a
   real task row with an arrow out to a calendar. Five tiles become three bands, and the other
   five perks live in the table.
4. **The compare table stops using a cross.** `PlusCompare.Mark.no` renders an `xmark` in the
   Free column today, and the brief's own words for that are "a cross is a padlock wearing a
   different hat". The table now carries only rows that have a value in **both** columns: three
   ticked in both at the top, then eight numbers against numbers. The four Plus-only goods (the
   look, the three scenes, the reader, the GPA) are not in the table at all — they are on the
   offer screen as pictures, which is where a student can judge them.

## One correction that reaches past this screen

`Theme.muted` (#96877F) is **3.46:1 on white**, not 4.5:1. I stated otherwise in the Calendar
handoff and it was wrong. Almost every line on this sheet other than a title is a caption, so
it matters here more than anywhere: **captions at 10–13pt use `#7B6C63` (5.04:1)**. `muted`
stays correct for labels at 19pt and above, where 3:1 is the bar. This is one new token, and
the same fix is owed on Calendar, Home, Focus and Kin — worth one sweep rather than five.

## About the design files

`Plus Sheet.dc.html` is a **design reference written in HTML**, not production code. Do not port
the HTML. Recreate these screens in SwiftUI inside `ios/Sources/PlusSheet.swift`, using `Theme`
tokens by name, the five radii in `Theme.Radius`, and the components already in
`KinComponents.swift` / `PrepkinIcons.swift`. Nunito in the prototype stands in for **SF Pro
Rounded** (`Theme.font(_:_:)`); every hex in it has a token name in the table below.

The file holds two turns, newest first. **Turn 2 (`#2a`) is the design to build.** Turn 1 is the
three explorations it was chosen from (`1a` above the fold, `1b` pinned footer, `1c` full-width
goods) and should not be ported; `1c`'s compare table, however, **is** the table to build and is
drawn in full there.

## Fidelity

**High.** Every value is a pt value on the 402 × 874 iPhone canvas. The sheet's own top edge is
at y = 64; all positions below are **sheet-relative** unless stated.

Not final art, and marked as such in the prototype:

- The **kin** is a dashed box labelled `KIN`. Render `PlusArt.kin(state.activeChibi)` — the
  existing call — at 118pt. Never draw the character.
- The **three scenes** are flat tints labelled Observatory, Lantern Street and Snow Cabin. The
  paintings do not exist yet; this is the one place on the sheet waiting on art, and until it
  lands, reason `general` and reason `look` should use the kin hero rather than a tinted
  placeholder.
- **Object glyphs** in the pick row (lamp, plant, book, cup, hat) are stand-ins at the right
  size and tint for the real flat-vector shelf objects. Use the real ones through `IconTile`.

## Screens

### 1 · The offer, reason `scan` (frame `2a-1`) — the default

| y (sheet-rel) | Element | Spec |
| --- | --- | --- |
| 0 | sheet | `Theme.paper`, `Radius.sheet` 28 on the top corners, `presentationBackground(Theme.paper)`, drag indicator hidden |
| 9 | grabber | 38 × 5, r3, `hairline` — or white at 85% when it sits on the art band |
| 0–150 | **art band** | full-bleed, no radius of its own, tinted per reason. This is the only part that changes with `Reason` |
| 162 | headline | `Theme.font(23, .black)`, `ink`, **left aligned** at gutter 22, two lines |
| 222 | free line | `Theme.font(11.5, .heavy)`, `#7B6C63`, left aligned, 3 lines |
| 276, 380, 484 | three goods bands | 358 × 96, white, 1px `cardEdge`, `Radius.card` 20, **no shadow** |
| 582 | compare link | 44pt row, `Theme.font(13, .heavy)` `#7B6C63`, underlined, left aligned. The row ends at 626, so its bottom edge slips under the card while the words stay fully clear — the overlap is the scroll signal, and it must never cover the text |
| 620–810 | **floating price card** | 378 wide (12 inset each side), 190 tall, white, 1px `cardEdge`, top corners r24, `shadow(color: ink 10%, radius: 26, y: -8)`, padding 12 |

**The art band, per reason.** One 150pt band, tinted, holding a real fragment:

| `Reason` | Tint | Fragment |
| --- | --- | --- |
| `.scan`, `.calendarExport` | `coralSoft` | a 104pt syllabus page rotated −4°, two corner marks, an arrow, and **two real `CalendarTaskRow`s at 46pt** with the camera object in their tile and the read dates in their caption |
| `.shop` | `coinSoft` | **the real pick row**: seven 44 × 52 `IconTile`s at r14, five with a drawn object and its coin price at 8pt `coinInk`, two `coralSoft` with a dashed `coralIcon` border and the word `Plus`, and the hold pin as a 14pt `coral` disc on the first tile. Caption under it: "today's picks · the pin holds one through a reroll" |
| `.focus` | `mintSoft` | the real chip row, 15 / 25 / 45 on white, 60 / 90 in `coralSoft` with a `coralIcon` hairline, and a dashed chip showing a typed length |
| `.look`, `.vibe`, `.general` | `checkFill` | the kin at 70pt beside the three scene plates at 52 × 46 with their names under them |
| `.grades` | `unowned` | the real `GradeCalcView` term card: `3.41`, "this term", and two course rows |

**The three goods bands.** Art 138 wide on the left, full band height, flat tint; text at 14
padding on the right. Title `Theme.font(15, .black)` `ink`; detail `Theme.font(11.5, .heavy)`
`#7B6C63`, one line of plain fact.

| Band | Art tint | Title | Detail |
| --- | --- | --- | --- |
| 1 | `coinSoft` | Seven picks, three holds, 30% off | Six free rerolls. Every item is still on the shelf at full coin price. |
| 2 | `mintSoft` | Sixty and ninety minute shifts | Or any length you type, and a week of your own hours. |
| 3 | `#EEF5FC` | Read in, and sent back out | Photos into your calendar, and every dated task out to Apple Calendar. |

Band 1's art is seven 24pt object tiles on two rows (4 + 3) with the hold pin on one and a
`Plus` chip beside the two dashed slots. Band 2's art is a 22pt clock object over the two chip
rows. Band 3's art is a calendar page, an arrow, and a second calendar — the read-in and the
send-out in one picture, which is why perk 4's two halves share a band.

**The floating price card**, top to bottom inside its 12pt padding:

- **Plan row**, two cards 175 × 68, gap 8. Yearly (selected by default): `coralSoft`, 2px
  `coral` border, r18 — "Plus, yearly" 12 `.black` `coralShade`; `$69.99` 19 `.black` with
  `saves 42%` 9.5 `.black` `mintDark` on the same baseline; "$5.83 a month, once a year" 9.5
  `.heavy` `#7B6C63`. Monthly: `paper` fill, 1px `cardEdge` — "Plus, monthly", `$9.99`, "Billed
  every month". **No "most popular" badge.** Yearly is the default because it saves 42%, and
  that number is arithmetic off the two prices.
- **`Get Plus`**, 354 × 52, r18, `Theme.coral`, label 17 `.heavy` `onDarkWarm`. The only coral
  thing on the sheet.
- **The 3.1.2 line**, one row: "Prepkin Plus renews until you turn it off. Cancel any time in
  Settings." 10 `.bold` `#7B6C63` on the left, then `Privacy` and `Terms of Use` as underlined
  10 `.heavy` links on the right. Title, length, price, price per period and both links are all
  inside this card.

**Below the fold**, in the scroll under the card, in this order: `Restore a purchase`,
`Can't swing it? Ask.`, and the mission line "Plus keeps Canvas, coins and every lesson free for
everyone else." (`Theme.font(12, .heavy)`, `bagInk`). All three keep their built copy and their
44pt rows.

### 2 · Reason `shop` and 3 · reason `general` (frame `2a-2`)

The proof the swap works: **only the 150pt band and the headline change.** Everything from
y = 222 down — the free line, the three bands, the compare link, the price card, the footer — is
identical on all eight reasons. Reason `general` is the once-only arrival the day the gift week
ends: same sheet, headline "More of your fish, a longer shift, and your own calendar.", and
**no countdown, no days named, never the words "your trial is ending"**.

### 4 · Already Plus (frame `2a-3`)

The shortest screen and the one most apps get wrong. **No price, no plan row, no Restore, no
compare link, nothing to buy.**

- Kin at 118 in a 92-wide box, centred, y = 30.
- Headline centred at y = 166, `Theme.font(22, .black)`: "Plus is on. Nothing to cancel, because
  nothing was started." during the gift week; "Plus is on. Thank you." when paid.
- **The gift timeline**, only during the gift week: one card, three rows, each a 62pt date
  column (12.5 `.black` `ink`) and a sentence (12.5 `.heavy` `#7B6C63`), dividers inset 74.
  `Today` · "Plus is on for a week. No card, nothing to cancel." / `Sep 19` · "It goes off on
  its own. Everything you wore, made or saved stays." / `After` · "You will find Plus in the
  Shop, on Focus and on Calendar if you want it." The middle row is the only place the end of
  the week is named, **as a date, never as a count of days left**.
- `On now`, a 13 `.black` `#7B6C63` section label, then three 62pt rows — a 44pt `IconTile`
  with the object, the perk title 14.5 `.black`, and where it is: "In the Shop, now." / "On
  Focus, now." / "On the Calendar tab."
- The lapse promise, centred: "Everything you wear, make or save stays yours, whatever happens
  to this."
- `Done`, 358 × 56, r20, `coral`, at sheet-rel 736.

The gift timeline is auto-height and its rows wrap to two lines, so everything below it is laid
out **after** it, not at fixed offsets: `On now` gets 16pt of air under the card, the three rows
follow at 62 + 10, and the lapse line gets 20 above it.

### 5 · Purchasing and failed (frame `2a-4`)

Both states live entirely inside the floating card.

- **Purchasing:** the plan row drops to 50% opacity and stops taking taps; the button keeps its
  full `coral` and reads `One moment` with a 15pt spinner tinted `onDarkWarm` to its left.
  `disabled(busy)`.
- **Failed:** the button returns to `Get Plus`, and "That didn't go through. Nothing was
  charged." appears under it **inside the card**, `Theme.font(11.5, .heavy)` `coralDeep`,
  centred. Never a dialog, never an alert.

## Interactions and motion

| Interaction | Behaviour |
| --- | --- |
| Any entry point | Sheet presents at one large detent; the band and headline are chosen by `Reason`, nothing else |
| Tap a plan | `UISelectionFeedbackGenerator`, fill and border cross-fade 0.22s `snappy` |
| Tap `Get Plus` | Button goes busy immediately; on success `state.syncPlus(paid:)` fires, the sheet dismisses itself, and **the thing the student was doing continues** — the camera opens, the 90 chip is selected, the look goes on |
| Tap the compare link | Pushes the table in place, 0.24s `snappy`; `Back` returns |
| Scroll | Content scrolls under the price card; the card never moves |
| Tap `Can't swing it? Ask.` | Opens `mailto:support@prepkin.com?subject=Prepkin%20Plus` |
| Tap `Restore a purchase` | `plus.restore()`, then `syncPlus`; no spinner on the row, the button state is the only busy signal |
| Already Plus | The entitlement is read before the body renders, so a paying student never sees a price frame even for one tick |

**Reduce Motion.** The plan selection becomes an instant swap; the spinner stays (it is a
progress indicator, not decoration); the compare push becomes a 0.12s cross-fade. Nothing on
this sheet is carried by motion.

**Dynamic Type.** Everything 20pt and under goes through `Theme.font` and caps at 1.3×. The 23pt
headline and the 19pt prices are display sizes and stay put. At 1.3× the price card grows to
about 214pt — let it, and let the scroll content shorten; do not clip the 3.1.2 row.

## State

```
pick: PlusProduct          // .yearly by default
busy: Bool
failed: Bool
showingCompare: Bool
```
Everything else is read: `plus.products` for the prices and `priceFormatStyle`, `plus.entitlement`
for whether this is the already-Plus screen, `state.plusAccess.isGift()` and
`state.game.plus.giftStartedAt` for the timeline, `PlusGate` for every number in the table,
`state.activeChibi` for the kin. **Invent no number.** If `plus.products` is empty, the fallback
strings are `$69.99` and `$9.99`, and the per-month figure is derived from the real product price
so a non-dollar storefront is never told a dollar figure — that logic exists today, keep it.

## Design tokens

| Prototype hex | Token | Used for |
| --- | --- | --- |
| `#F8F8F8` | `Theme.paper` | the sheet, the unselected plan card |
| `#FFFFFF` | `Theme.card` | bands, the price card, the timeline |
| `#ECEAE6` | `Theme.cardEdge` | every hairline |
| `#2E2622` | `Theme.ink` | headlines, titles, prices |
| `#7B6C63` | *new* `Theme.caption` | **every caption on this sheet** — 5.04:1 on white |
| `#96877F` | `Theme.muted` | labels 19pt and up only |
| `#B4A996` | `Theme.dim` | annotation in the prototype; not used in the shipped sheet |
| `#C9BEAC` | `Theme.inactive` | the dashed kin box (prototype only) |
| `#F0E9DC` | `Theme.hairline` | the grabber, dividers |
| `#F3ECE0` | `Theme.paperSunk` | free chips in the focus fragment |
| `#FDF9F4` / `#EDE1D3` | `Theme.tile` / `tileRing` | object tiles in the pick row |
| `#F4F0EB` / `#E6DFD7` | `Theme.checkFill` / `checkBorder` | the checkbox in the task-row fragment, and the `general` band tint |
| `#FF6F61` | `Theme.coral` | `Get Plus`, `Done`, the plan border, the hold pin |
| `#FFE9E5` | `Theme.coralSoft` | the selected plan, Plus chips, the `scan` band |
| `#FF8A7E` | `Theme.coralIcon` | dashed Plus slots, corner marks, the camera object |
| `#C4523F` | `Theme.coralShade` | "Plus, yearly", the word `Plus` on a chip |
| `#E4735F` | `Theme.coralDeep` | the failed line |
| `#57C79B` / `#DFF3E9` / `#3E9E78` | `Theme.mint` / `mintSoft` / `mintDark` | the clock, the focus band, `saves 42%` |
| `#FFC24B` / `#FFF3D6` | `Theme.coin` / `coinSoft` | the lamp object, the shop band and band 1's art |
| `#8A5F14` | *new* `Theme.coinInk` | coin prices under a pick tile — `coinDark` is 3.2:1 on white and fails |
| `#9BC8F2` / `#5C8FBD` / `#EEF5FC` | `Theme.sky` / darker sky / *new* `skySoft` | the calendar objects and band 3 |
| `#C3B2F0` / `#A98FE0` | `Theme.lavender` / darker | the hat object |
| `#E9A07C` | `Theme.species("sprout")` | the plant pot |
| `#FFF3E4` | `Theme.onDarkWarm` | label on coral |
| `#8A7869` | `Theme.bagInk` | the mission line |
| `#FBF7F0` | `Theme.unowned` | the `grades` band tint |

Radii: `Radius.chip` 10 · `Radius.control` 14 (object tiles, task rows in the fragment) · 18 for
the plan cards and the button inside the floating card · `Radius.card` 20 (goods bands, the
timeline, the table, `Done`) · 24 for the floating card · `Radius.sheet` 28 (the sheet).
`Radius.control` and 18 are both already in the five-value list via `UniformTests`; 24 is not —
see deviations.

## Components

**Reuse, do not restyle:** `PlusArt.kin`, `IconTile`, `CoinDisc`, `PlusTag`, `CalendarTaskRow`
(inside the `scan` fragment), `PressStyle`, `PlusGift.timeline`, `PlusCompare.rows`, the existing
`buy()` / `restore()` / `displayPrice` / `perMonth` logic.

**Replace:** `perkTile` (art 78 × 62 beside two lines, with a shadow → a 96pt band with a 138pt
UI fragment and no shadow) · `prices` and `cta` (stacked in the scroll → a two-up row inside the
pinned card) · `cell(_:tint:)` (drop the `.no` case entirely) · `PlusArt.slots`, `.chips`,
`.page`, `.grades` (abstractions → real fragments at real size).

**New:** `PlusFooterCard` (the floating card, used by the offer and the compare screen),
`ReasonBand`, `PickRowFragment`, `ChipRowFragment`, `CalendarFragment`, `OnNowRow`.

**Delete:** the `D.shadow` constant and all five of its uses.

## Deviations, argued

1. **A sixth radius, 24, on the floating card.** `UniformTests` fails the build on a new value.
   The card sits between `Radius.card` 20 and `Radius.sheet` 28 and needs to read as neither —
   at 20 it looks like a big band, at 28 it looks like a second sheet. If that is not worth a
   test change, use 28 and accept that the card echoes the sheet's own corner.
2. **`PlusCompare.Mark.no` is deleted rather than restyled.** A row that reads "nothing / yes"
   is a cross with better manners, and the rule in the brief is absolute. This means
   `PlusCompare.rows` loses four rows and gains three that are ticked in both columns; the four
   Plus-only goods move to the offer screen, where three of them already are.
3. **The free line is left-aligned, not centred.** It is three lines of real information, and
   centred ragged text at 11.5pt is harder to read than the same words on a left edge. The
   headline moves with it, which also lets it sit on the gutter every other screen uses.
4. **The compare link's row overlaps the price card, but its text does not.** The overlap is the
   only signal that the sheet scrolls, now that the button no longer moves — but the link is the
   only route to the table, so the words stay above the card's edge with 7pt of air. If a build
   at larger Dynamic Type pushes the text under the card, move the link up rather than letting
   it slide under; a 4pt `paper` fade at the card's top edge is the alternative signal.
5. **Perk 4's two halves share one band.** The spec lists the reader and the calendar write as
   one perk, and drawing them as one picture — page, arrow, calendar — says more than two rows
   would.

## Rules this screen is checked against

Not once the word "unlock". No padlocks, no `?` tiles, no greyed-out anything, no crossed-out
price, no countdown, no "limited time", no "most popular" badge, no exclamation marks (and none
of `sync`, `bridge`, `endpoint`, `selector`, `api`, `token`, `schema`, `payload` —
`CopySweepTests` fails the build). The kin is never sad, pleading, locked or holding a sign. One
coral button. A student who is already Plus never sees a price. Every perk on the sheet is a
row in `PLUS-SPEC.md` section 2, and every number in the table comes from `PlusGate`.

## References

Mobbin, platform ios, looked at 2026-09-12. Structure taken, never a look.

- [Flighty Pro](https://mobbin.com/screens/d3ea4611-a6ed-4e3e-b8f7-0badfe402162) — the whole
  reason the perks changed shape: Flighty does not illustrate a feature, it shows a picture of
  the real screen at real size and lets it sell itself. Also the source for the floating plan
  card over scrolling content, and for putting the per-month figure beside the saving rather
  than under it.
- [Gentler Streak Premium](https://mobbin.com/screens/d1082010-dfa6-40c7-96af-66f2bea1e8ad) —
  the second instance of the pinned card, with the plan sentence inside it above the button.
  Two apps doing it is what turned `1b`'s footer from a guess into the answer.
- [Finch Plus benefits sheet](https://mobbin.com/screens/0525a643-772d-4665-b5fc-b0d7d10a3a3a)
  — the structure: mascot, perks with one plain line each, the price as a sentence above one
  button, "See all plans" as a text link. Kept.
- [Finch Plus, scrolled to the perk list](https://mobbin.com/screens/11ec5a8d-7a51-4e18-b70c-9d2da2a0e59a)
  — "Support our mission" as the last row, kept. Its 24pt stroke glyphs beside two lines of
  text are the **anti-reference**: that is the settings-screen shape this brief bans, and it is
  what the built sheet had drifted toward.
- [Finch "Become a Guardian"](https://mobbin.com/screens/5476a849-e09a-437e-b4c8-c39260617658)
  — the hardship path. Ours stays one mail row, not three sponsor tiers.
- [Finch's cancel-save sheet](https://mobbin.com/screens/ccd5acdc-1b85-4092-a306-dc2aa52bb3c7)
  — **anti-reference**, already named in the spec. We build no cancel-save screen in any wording.

## Files in this bundle

- `Plus Sheet.dc.html` — the prototype. **Turn 2 (`#2a`) is the design to build**; turn 1 is the
  three explorations behind it, and `1c` holds the compare table drawn in full.
- `support.js` — the runtime the prototype needs. Keep it beside the HTML.
- `BUILD-NOTES.md` — the stub to fill in while porting.
