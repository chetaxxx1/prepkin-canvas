# Focus, B → A+ — 2026-09-10

What changed on the Focus tab, what it was proven against, and what is still open.
Everything here is uncommitted; other sessions are live in the same tree.

## The B

A student tapped Start, put the phone down, and the phone could not tell them when the
shift was over. When it was over, it said nothing.

## What shipped

| # | Change | Where |
|---|---|---|
| 1 | **Shift-end notification.** A fourth kind. Booked at Start, cancelled on Pause and on clock out, re-booked on Resume. "Shift over. 15 coins paid." / "Moss swam 10 lengths." Fires whether or not reminders are on — the student asked for a timer, and that is not a reminder. Never a badge. | `Core/Notifications.swift` |
| 2 | **Live Activity.** New `PrepkinActivity` app-extension target, Live Activity only. Kin still, "Moss is on shift", the countdown, "16 lengths · 25 coins at the end". Its own 684KB kin catalogue, not the app's 38MB one. | `ios/Activity/`, `ios/Shared/` |
| 3 | **The shift report.** Full screen after a finish *and* after a clock-out. "25 minutes. 25 coins." with the arithmetic visible; the task that rode along with a Mark it done row (no checkbox for Canvas work); lengths, and best shift only if it changed; one coral Done and a quiet Another shift. | `FocusView.reportScreen` |
| 4 | **Clock-out copy.** Was "N coins waiting … they stay in the reef", which reads as *kept for you*. Now "Clock out now and this shift pays nothing. Finish it and it pays 25." **Keep working is the coral one** — the screen's one primary button had been sitting on the choice that pays zero. | `FocusView.quitSheet` |
| 5 | **Working on chip.** Defaults to the next undone task, tap to pick another or "Nothing in particular". Rides into the shift screen and the report. Nothing about it goes to a friend (`StudySync` rule 3). | `FocusView.workingOnChip` |
| 6 | "NEXT IN 4:12" → **"Next length in 4:12"**. | `FocusView.countBlock` |
| 7 | "Put the phone down and let them work" (an order) → **"Moss is swimming. The phone can wait."** 36 characters; falls back to "The phone can wait." for a long kin name. | `Core/FocusReport.swift` |
| 8 | Study Together's **Join button 34pt → 44pt**. | `FocusView.atTheTable` |
| 9 | **Strict mode: not built.** See below. | — |
| 10 | **"This week · 3 shifts · 1h 15m"** on the Ready screen, off the ledger. No graph, no calendar, no streak. | `Core/FocusReport.swift` |

## Three things found while proving it

- **The shift did not survive being killed.** The clock lived in `@State`, so iOS
  jetsamming a backgrounded app lost it — and the new notification would have said
  "45 coins paid" over a save where nothing was paid. `SavedShift` / `ShiftStore` now
  write the running shift to `UserDefaults` with the ledger's own idempotency key.
  Proven by terminating and reinstalling the app mid-shift: the shift came back running.
- **The report's kin never animated.** `state.play(.celebrate)` fires in `settle`,
  before the report exists, so `SproutImage`'s change-watcher had nothing to see. It
  uses the `replay:` hook now.
- **The coin line sat flush against the Pause button** — no gap at all, on the shipped
  build as well as this one. The shift screen's scale divisor was measured before the
  count block grew a third line. 646 → 680.

## Strict mode — the one-sentence decision

**Not built:** under all-or-nothing pay, clocking a student out for leaving the app
costs them the whole shift, so a text answered at minute 24 of a 25 pays nothing — that
is a punishment, and nothing on this tab punishes.

## Proof

- **375 unit tests, 0 failures** in the shared tree, including 23 new ones in
  `ios/Tests/FocusShiftTests.swift`:
  the notification present on start, absent after pause and after clock out, present
  again after resume and re-booked for the time that is left; the pay line at 0, 15, 25
  and 45; the Working on default; the week line; and the restore path.
- **On the simulator** (`prepkin-focus`, iPhone 17 Pro, iOS 26.5): a real 15-minute
  shift, phone locked, the Live Activity on the lock screen, the notification on the
  lock screen when it ran out, then the report. Then a clock-out with its sheet and its
  zero report. Screenshots in `design/screenshots/focus-a-plus-2026-09-10/`.
- **Sweep** in light, dark and accessibility-XL:
  `design/screenshots/sweep-focus-a-plus-2026-09-10/`. Focus lints clean — no control
  under 44pt, no unlabeled button or image — on the Ready screen, the shift screen, the
  report, the clock-out sheet and the Working on sheet.

## Notes for the other sessions in this tree

- The shared tree would not compile for about an hour this morning (`CalendarView.swift`,
  then `GameState.swift:399` mid-refactor). This work was built in a worktree until it
  cleared; it now builds and tests green in the shared tree, 375/375.
- `ios/PrepkinCanvas.xcodeproj` was regenerated (`xcodegen generate`) to pick up the new
  `Core/FocusShift.swift`, `Core/FocusReport.swift`, `Core/SavedShift.swift`,
  `Core/FocusLiveActivity.swift`, `Shared/`, `Activity/` and the `PrepkinActivity` target.
- One test run used the `prepkin-cal2` simulator while `prepkin-focus` was mid-shift, so
  that sim now has this build installed. Reinstall yours over it.

## Open

- **The report pays when the tab is opened, not at launch.** A student who taps the
  notification and lands on Home sees no coins until they visit Focus, which is where
  the report lives. One tap away, and the notification is what brings them back — but a
  notification-response handler that opens the tab would close it properly.
- **`SproutImage` ignores Reduce Motion** — app-wide, not this tab. The report itself has
  no coin motion to suppress.
- **The celebrate animation needs George's GIF sign-off before it ships**
  (`memory: animation-approval`). GIF is in this folder.
- The rewritten brief `CLAUDE-DESIGN-PROMPT-FOCUS-CLOCKOUT.md` is now a designer's pass
  over three working screens rather than a blank page.

## Comparables, once (Mobbin, iOS)

- **Forest, running screen** — the whole instruction is three words with a period,
  "Put down your phone.", set *above* the art rather than as a caption under the title.
  Ours was nine words and an order. <https://mobbin.com/screens/306dc902-3ac9-47b9-be01-4434da19dadf>
- **Forest, lock-screen notification** — names the actual clock span, "12:14 – 12:39",
  under "Successfully focused for 25 m", so the alert is a receipt you can check rather
  than a claim. Ours names the coins and the lengths; the span would be a cheap add.
  <https://mobbin.com/screens/1959671e-3363-44c0-938a-3e4bcbc9f1ea>
- **Forest, session complete** — the reward is a small card layered over the scene
  ("You've Got / tree / 27"), so the number is the one thing you read. It never shows
  the arithmetic, which is exactly where our "25 minutes. 25 coins." beats it.
  <https://mobbin.com/screens/ba58c8aa-a408-4c3a-8f2f-d0ef3459d14b>
- **Opal, Dynamic Island** — the island carries the countdown *and* one action button,
  so the lock screen can act, not only inform. Ours informs only, on purpose for now.
  <https://mobbin.com/screens/c4b08830-1f6d-4da7-9e69-7d029abc4bb6>
- Flora is not in Mobbin's index; the search returned other apps. The closest real
  "finished" screen was **Brick, "First tap complete."** — a three-row receipt table
  (Mode / Apps blocked / Duration), facts and no praise. That is the register the shift
  report aims at. <https://mobbin.com/screens/eb2562e9-5f2c-4e6a-87da-8ca18fdc29eb>

Structure and honesty borrowed; none of the look.
