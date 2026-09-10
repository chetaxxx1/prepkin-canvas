# Calendar redesign — 2026-09-10

Simulator `prepkin-cal2` (`D7B59D32`), iPhone 17 Pro, `-unlockAll -sampleCanvas`, on
2026-09-10 (a Thursday). Brief: `design/CLAUDE-DESIGN-PROMPT-CALENDAR.md`.

## Before

The tab as it ran at 02:05 the same morning, copied from `design/handoff-calendar/`.
There is no "before" contact sheet: `CalendarView.swift` is untracked, so there is no
commit to build the old screen from, and `git stash` would have swept up three other
sessions' work in this tree.

| File | What it shows |
| --- | --- |
| `before-01-list.png` | Week list with a header for every empty day and a small `+` in each |
| `before-03-month.png` | Month grid |
| `before-06-empty.png` | The empty week: a card, the kin, and "Point the camera at a syllabus" — a promise for a reader that is not deployed |
| `before-04-add-sheet.png` | The `+` sheet: Type it / Scan a syllabus |

## After

| File | What it shows |
| --- | --- |
| `after-01-list.png` | Only days with something on them. Days already gone are dropped, Today and Tomorrow in words, one coral `+` |
| `after-02-list-typed.png` | The same list with "Bio quiz" typed onto tomorrow at 4:00 PM |
| `after-03-month.png` | The month grid with load bars, and the picked day's list under it |
| `after-04-quickadd-parsed.png` | Quick add mid-typing: `fri 4pm` lit inside the field, the chip reading "Tomorrow 4:00 PM" |
| `after-05-when-sheet.png` | The When sheet: Today, This evening, the month grid, At a time |
| `after-06-empty-today.png` | An empty today: one inline line, one folded strip, no card and no scanner line |
| `after-07-still-counts.png` | The Still counts group at the top, amber, "was due Tue" |
| `after-08-quickadd-weekday.png` | `Lab report mon` — the weekday lit, the chip reading "Monday". This one caught a real bug: autocorrect was turning `mon` into `mom`, so the field is now `.autocorrectionDisabled()`, the way Todoist's is |

Not here: **the day timeline**. It is not built. It is artboard 4 of the brief and waits
on the handoff.

## Contact sheets

`sweep-after/contact-light.png`, `contact-dark.png`, `contact-axxl.png` — six tabs plus
Shop and Your day, from `test/ios-sweep.sh`. Only the three sheets are kept; the 24 raw
frames and their accessibility dumps were 25 MB and re-run in four minutes. The app forces light, so the dark sheet is
the light one; that is the 2026-09-05 decision, not a bug.

Lint, light pass: **Calendar has no control under 44 pt and no unlabeled button or
image.** Two rows still flagged on Kin (`Coins and shop` 143×34, `Name your kin` 152×28),
untouched this session.

Two fixes went into `test/ios-sweep.sh` itself while running this: the Shop is closed with
its own X and Your day with **Done**, because the swipe left both sheets up and every
screenshot after them landed on the Shop.

## Two things this could not check

- **The keyboard.** A headless simulator keeps a hardware keyboard attached and `idb`
  types over HID, so the software keyboard never came up and the quick-add sheet was
  never seen sitting above it. Worth one look by hand: open Calendar, tap `+`, and check
  the chip row and the coral arrow are above the keys, not behind them.
- **"Type them instead."** Both buttons are wired to close the reader and open quick add,
  but the reader has no way in until the scan function is deployed, so the path could not
  be walked on a simulator.

## The tree, while these were taken

`ios/Sources/FocusView.swift` does not compile in the working tree — another session is
mid-edit on the clock-out work and it refers to a `ShiftStore` that is not there yet.
Everything from `after-08` on was built from a copy of the tree with that one file put
back to `HEAD`. Nothing in this session touched Focus.
