# Widget and notifications — 2026-09-12

Shot on `prepkin-widget` (iPhone 17 Pro, iOS 26.5), a fresh install walked through
the first run, then patched to look like day two. Nothing here is a mock: every
widget frame is WidgetKit drawing `widget.json` from the app group, every
notification was delivered with `xcrun simctl push`.

## What each piece copies

| Piece | Copies | Mobbin |
|---|---|---|
| Small widget: the kin, one line, tap opens the app | Finch's home screen widget (the bird and a line); Apple's Weather and Reminders for the size grammar, small is one thing | [d11b11e0](https://mobbin.com/screens/d11b11e0-3abc-4c9a-8cc7-31e98c571367) (the "Lee widget" card shows the widget itself) |
| Medium widget: a list with boxes | Apple's Reminders widget: medium is a list | — |
| Install card "Want Moss on your home screen?" | Finch's "Lee widget" card: the pet in a widget on a drawn phone, Add / No thanks | [d11b11e0](https://mobbin.com/screens/d11b11e0-3abc-4c9a-8cc7-31e98c571367) |
| Three-step how-to sheet | Finch's add-widget walk: one step a page, progress bar, Next / Back / Done | [336081a1](https://mobbin.com/screens/336081a1-706e-4e7d-8def-140d5294b0f6) (hold the home screen), [ae5b66f2](https://mobbin.com/screens/ae5b66f2-28bc-41af-9cfb-c2ddf6f2a891) (search, then Add Widget) |
| Reminder preview sheet before the system prompt | Finch's "Get reminders from Lee": a mock notification card above the button | [3e88469e](https://mobbin.com/screens/3e88469e-f60a-439d-ac4d-0bd06fd8eae4) |
| One time for the evening check-in | Finch's per-goal reminder time picker, ours is one time not per task | [13453dd2](https://mobbin.com/screens/13453dd2-3f02-4946-8549-54d8ce5135bd), [30d5339a](https://mobbin.com/screens/30d5339a-4275-4e71-bced-6a1cf69c0718) |
| Anti-reference | Duolingo's streak widget and red-flame nag. Nothing here counts days or warns. | — |

## The files

Widget states (small and medium together, page 1 of the home screen):

- `widget-3-things-today.png` — morning, nothing done: "3 things today. Read for one… first."
- `widget-2-left.png` — one done: "2 left. Start the thing…, then done."
- `widget-all-done.png` — "All done. Moss noticed."
- `widget-nothing-on-the-list.png` — every template off: a day-bank line, "Moss says hi. That's all."
- `widget-on-shift.png` — a shift running in Focus: "On shift"
- `widget-medium-box-tapped.png` — a box tapped on the medium: the row ticks and the line counts it; coins stay at 20 because the app has not paid yet
- `widget-box-paid-on-open.png` — the app opened: 40 coins, the row done, the mark file cleared

Lock screen (iOS 26 puts lock-screen widgets under the notifications; the
simulator dims the lock screen at once, so these are the always-on look):

- `lock-widgets.png` — the circle (the kin's face) and the rectangle ("All done" over "Moss noticed."; with work open it is "2 left today" over the next due title and time)
- `lock-notification-due.png`, `lock-notification-checkin.png`, `lock-notification-shiftend.png` — one banner each
- `lock-notifications-all-five.png` — the group opened: board, come-back, shift-end, check-in, due
- `lock-notification-names-one-task.png` — a check-in naming one task, the kind that carries the Done button. **Not shown: the button itself.** The lock-screen long-press cannot be driven from idb (the hold never expands the banner), so the Done tap could not be photographed. What is proven instead: the category with its one Done action is registered with iOS (`NotificationActionsTests`), the handler writes the same mark the widget box writes, and that mark paying once on the next open is shown by the medium-widget pair below and covered by `DoneMarksTests`.

Sheets:

- `reminder-preview-sheet.png` — the half sheet from the Day 1 card, our check-in drawn as a banner, the hour picker, Turn on
- `day1-notify-card.png` — the Day 1 card that opens it
- `focus-first-start-ask.png` — Focus's own one-line ask before the first shift (already built; shown for the record)
- `install-card.png` — the Home card, once, after the second day's first coin
- `install-sheet-1.png`, `install-sheet-2.png`, `install-sheet-3.png` — the three steps

## Rules kept

No badge number (the permission request no longer asks for one). No streak, no day
count, no "you missed", no exclamation mark anywhere — a unit test sweeps every
planned notification and every widget string. Nothing but a due reminder fires
before 8 AM or after 10 PM, and a due reminder never after 11 PM. One non-due note
a day. Every widget string under 40 characters with a 14-letter kin name. No
countdown with seconds on the lock screen. A costume with no still in the widget's
catalogue draws the plain coat.
