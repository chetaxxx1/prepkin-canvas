# Build notes — Prepkin Plus sheet

Ported 2026-09-13 from `README.md` into `ios/Sources/PlusSheet.swift` and
`ios/Sources/PlusArt.swift`. Design turn built: `#2a` in `Plus Sheet.dc.html`, with the
compare table from `1c`.

## Built

- [x] Floating price card (`PlusFooterCard`), plan row two-up, 3.1.2 line and links inside it.
      Pinned in a `ZStack` that ignores the bottom safe area; the card runs under the home indicator so
      the 3.1.2 row lands where the drawing puts it. Used by the offer and the compare screen.
- [x] `D.shadow` deleted and all five uses removed. The card's `shadow(ink 10%, 26, y −8)` is
      the only shadow on the sheet.
- [x] Three goods bands with real UI fragments (`PickRowFragment`, `ChipRowFragment`,
      `CalendarFragment`), art 138 wide, no shadow, one `cardEdge` hairline.
- [x] `ReasonBand` — one 150pt band per `Reason`, nothing else swaps. `scan`/`calendarExport`
      draws the page, the corner mark, the arrow and two `ReadTaskRow`s at 46pt; `shop` the
      real pick row; `focus` the chip row at Focus's own 50 × 36; `grades` a `TermCardFragment`;
      `look`/`vibe`/`general` the kin.
- [x] Already-Plus screen: gift timeline, `On now` rows (`OnNowRow`), no price anywhere.
- [x] Purchasing and failed states inside the card.
- [x] `PlusCompare.Mark.no` deleted; table rebuilt to both-column rows only (3 ticked, 7 counted).
- [x] `Theme.caption` (#7B6C63) added; every caption on this sheet is on it.

## Where the port differs from the drawing

- **The pick row shows today's real picks.** The prototype's lamp / plant / book / cup / hat
  are stand-ins for shelf objects, but the Shop sells kins and scenes, so a tile carries a
  kin's face on its plate or a scene cut to a thumb, with the pick's real coin price
  (`state.picks`, `PlusGate.shopSlots`). Nothing is invented.
- **Three icons were generated into the house set** (`design/icons/src/grid-m.png`: camera,
  shopping bag, calendar page), cut and packed with `--only grid-m`. The camera is the reader
  on a task row and on the On-now row, the bag is the Shop on the On-now row, and the calendar
  page is the send-out in band 3. The clock is the existing `classTime`; the read-in calendar
  is the Calendar tab's own `tabCalendar`.
- **Band 3 draws the two calendars bare** on the sky tint, not on tiles — a tile on a tinted
  band read as a tile in a tile.
- **The scan band's dates are computed** (today + 5 and + 19 days through `PlusGift.stamp`),
  and the course is the first real course code, so the picture never shows last term.
- **The compare table has seven counted rows, not eight.** `1c` draws seven (picks, holds, off,
  rerolls, shift lengths, cards, saved looks); the README's "eight" would need a 0-against-7 row,
  which is the cross the brief bans.
- **The three scene plates** are not drawn yet, so the `look` / `general` band is the kin
  alone, as the README says to do until they land.

## Deviations taken or refused

| # | Deviation in the handoff | Decision |
| --- | --- | --- |
| 1 | A sixth radius, 24, for the floating card | Taken. `PlusFooterCard.radius = 24`. There is no `UniformTests` in the tree, so nothing fails on it. |
| 2 | Delete `Mark.no` rather than restyle the cross | Taken. `PlusBuildTests` now checks that every row after the ticked ones has a value in both columns. |
| 3 | Free line and headline left-aligned | Taken. |
| 4 | Compare link overlapping the card's top edge | Taken as drawn: the link's 44pt row is the last thing above the card at rest, and the words stay clear. |
| 5 | Perk 4's two halves in one band | Taken. |

## Owed elsewhere

- [ ] `Theme.caption` sweep on Calendar, Home, Focus, Kin — `Theme.muted` is 3.46:1 on white.
      `Theme.mutedDeep` is already the same hex; the sweep is renaming and moving captions.
- [x] `Theme.coinInk` (#8A5F14) already existed for coin prices on white.
- [ ] The three Plus scene paintings (Observatory, Lantern Street, Snow Cabin).
      `PlusLooks.sceneIDs` reserves `"lantern"`, which is also the 360-coin themed tank's id —
      the two collide the day the Plus painting lands under that name.

## Notes

- `PlusGift.timeline` carries the README's three rows now (Today / the end date / After).
  The middle row is the only place the end is named, as a date.
- `FocusView.freeLengths` and `FocusView.moreItems` are read by `ChipRowFragment`, so the
  picture cannot show a chip Focus does not offer.
- `SimplifyTests` held the 2026-09-12 shape (one-sentence free line, five perk titles). The
  handoff's free line is still one sentence and the goods are three, so the two tests now
  check that.
- Screenshots in the simulator: `shop`, `focus` and `grades` reasons, the compare table, and
  the fold. **Not photographed:** `scan` (the scanner is not deployed, so nothing opens that
  reason), and the already-Plus screen — every entry to the sheet is behind `!state.isPlus`,
  so it only compiles; it is never reached in the app today.
