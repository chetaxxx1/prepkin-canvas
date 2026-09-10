# Prepkin Plus — what was built, 2026-09-10

Companion to `PLUS-SPEC.md`, which stays the source of truth for the perk list, the prices
and the rules. This file records what actually landed, what is waiting, and on what.

## The perk table, as built

| # | Perk | State | Where it lives |
|---|---|---|---|
| 1 | Plus looks and scenes | **Waiting on art.** The rail slot, the entitlement check and the example-fish preview are built and shipped; `PlusLooks.looks` is empty and `PlusLooks.scenes` resolves to nothing, so the rail draws nothing at all rather than an empty shelf. One signed-off coat drops in as one line. | `Core/PlusLooks.swift`, `KinView.plusLookSwatch` |
| 2 | Shop: 7 picks, 3 holds, 30%, 6 rerolls | **Built.** All four read `PlusGate`. `rerollCanChange` now compares against the live slot count. `lockedPick` became `lockedPicks`, with a decode migration so an old single hold survives. | `Core/KinState.swift`, `KinShopView.swift` |
| 3 | Focus: 60, 90, any length, a week of hours | **Built.** 60 and 90 in full colour beside 15/25/45 with "Plus" under them, a typed length clamped to 5–240, and seven bars off the ledger. Bars only — no target line. | `FocusView.swift`, `Core/FocusReport.focusDays` |
| 4 | Calendar: out to a real calendar | **Built.** EventKit write-only, plus an `.ics` file for everything else. No Google account anywhere. | `Core/CalendarExport.swift`, `CalendarView.exportButton` |
| 5 | Grades: term GPA and a goal per course | **Built.** One card under the free what-if. Unweighted, every course once, and never a percentage over 100. | `Core/GradeProjection.swift`, `GradeCalcView.termCard` |
| 6 | Friends: 6 vibe cards and a Plus mark | **Gate in place, unused.** Vibe cards are Friends phase 2 and are not built, so there is nothing to split yet. `PlusGate.vibeCards` is 3/6 and `PlusGateTests` holds it there. | `Core/PlusGate.swift` |
| 7 | Unlimited saved looks | **Built, free version first.** Three free, unlimited on Plus, in the same build. A lapse stops new saves and never deletes one. | `Core/PlusLocal.swift`, `KinView.savedLooksCard` |
| 8 | "Can't swing it? Ask." | **Built.** A plain text row on the sheet, over `mailto:support@prepkin.com`. | `PlusSheet.hardship` |
| 9 | The season | **Built.** One seeded season, Midterms, 2026-09-22 to 2026-10-12, seven rungs. Free pays coins, Plus adds a costume, and the last Plus rung is the Grad. **The card is dark until 09-22**, by design. | `Core/Season.swift`, `SeasonCard.swift` |
| 10 | The compare table | **Built.** Second screen of the sheet, behind "See everything, side by side". Its numbers are read off `PlusGate`. | `Core/PlusCompare.swift` |
| 11 | "Support our mission" | **Built.** One line, last on the sheet. | `PlusSheet.mission` |
| 12 | Refer a friend | **Not built, 1.1.** Needs App Store offer codes wired to the friend code — a server and a redemption path, neither of which exists. Row written so it is not re-invented. | — |

## Three things found and fixed while building

1. **A bounced card would have cost a student their perks.** `PlusEntitlement.resolve` compared
   `expiresAt` against now, and a subscription in Apple's billing grace period has a date already
   in the past. It resolved to "not Plus". `PlusRecord.inGracePeriod` now carries it, read off the
   subscription status rather than the transaction.
2. **The Shop showed two different discounts on one card.** The cost badge was the literal
   `"−20%"` while the price under it was already 30% off. `PlusCopyTests` now fails the build on
   any string that hard-codes the free discount.
3. **Seven slots pushed the Shop off its own screen.** `PickSlot`'s kin art was 54pt inside a
   46pt slot, so the `HStack` grew past the screen and — because the column centres — dragged
   every heading on the page off the left edge. The art shrinks at seven now.

## What is not proven

- **The purchase itself was not driven end to end.** `PlusPurchaseTests` is written against
  `SKTestSession` and covers buying monthly and yearly, restoring, refunding and expiry — but
  `xcodebuild test` does not attach the scheme's StoreKit configuration, so under it the session
  loads and `Product.products` comes back empty. The tests skip there with a message rather than
  fail. **Run that file from Xcode to close this.** What *is* proven without a store: the app
  reaches Apple's real purchase sheet when Get Plus is tapped, the price fallbacks render the
  spec's numbers when StoreKit is silent, and every entitlement rule — resolution, grace, expiry,
  the lapse promise — is covered in `PlusTests` and `PlusBuildTests`.
- **Six screens were not captured.** Already-Plus, the gift-week timeline, the Season card, the
  Shop at seven slots, the calendar export menu, and the accessibility-XL sweep. The
  seven-slot Shop *was* driven — that is how two of the three bugs above were found —
  but the file that would prove it landed on Home instead, so it was deleted rather
  than shipped under a name it did not earn. Every simulator on the machine was
  deleted twice by another session while the sweep was running. `test/plus-shots.sh` is the
  script; it needs one simulator that stays alive.
- **The app is light-only** (`INFOPLIST_KEY_UIUserInterfaceStyle: Light`), so the dark pass the
  brief asked for cannot exist. Light and accessibility-XL are the two that apply.

## Testing affordance added

`-plusOn` turns the entitlement on and **nothing else**. It exists because `-unlockAll` grants the
whole catalogue, which empties the shop's draw pool — so the one screen that most needs checking
at seven slots is the one screen `-unlockAll` cannot show. `#if DEBUG`, and deliberately not
sticky: an entitlement that outlives its launch is exactly the bug worth not writing.
