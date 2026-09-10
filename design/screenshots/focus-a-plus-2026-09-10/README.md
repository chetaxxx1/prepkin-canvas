# Focus, B → A+ — 2026-09-10

Before and after for the Focus tab. Simulator `prepkin-focus`
(`4E08C723-6584-4F59-AA15-623F62E9D05B`), iPhone 17 Pro, iOS 26.5, launched with
`-unlockAll`. Kin is Moss (Sprout, mint, three stars, Blazer).

**Before** is the tab as last committed (`93b5488`), built from a worktree so the
other sessions' in-flight edits could not change it.

| Shot | What it shows |
|---|---|
| `before-focus-light.png` | Ready. Nothing between the coin pill and Start. |
| `before-shift.png` | On shift. "Put the phone down and let them work" (an order), "NEXT IN 1:24" (shorthand), and the coin line flush against the Pause button. |
| `before-clockout.png` | The old sheet: "1 coin waiting … Clock out now and they stay in the reef." The code pays zero. Clock out is the coral one. |
| `before-focus-dark.png`, `before-focus-axxl.png` | Ready in dark and at accessibility-XL. |
| `contact-before.png` | The five together. |

**After** is the current tree. It carries every session's uncommitted work, built in
`~/Library/Developer/prepkin-worktrees/focus-after` with two of another session's
in-flight compile errors patched locally (see the session notes) so it would build at
all. Nothing in `ios/Sources/Core/GameState.swift` was changed in the shared tree.

| Shot | What it shows |
|---|---|
| `after-focus-light.png` | Ready, with the Working on chip. |
| `after-workingon-sheet.png` | The picker: today's undone tasks, course as subtitle, Nothing in particular at the end. |
| `after-ask-notifications.png` | The one-line permission ask, shown once before the first shift ever. |
| `after-shift.png` | On shift: the riding-along chip, "Moss is swimming. The phone can wait.", "Next length in 1:25". |
| `after-shift-axxl.png`, `after-report-axxl.png` | The shift and the report at accessibility-XL. |
| `after-focus-dark.png`, `after-focus-axxl.png` | Ready in dark and at accessibility-XL (from the sweep). |
| `report-celebrate.gif` | The report's celebrate, for George's sign-off. Nothing animated ships without it. |
| `after-lockscreen-activity.png` | The Live Activity while the phone is locked. Minutes, not m:ss — the lock screen refreshes about once a minute, so seconds are not on offer there. |
| `after-dynamic-island.png` | The compact Dynamic Island, where the same text *does* tick m:ss. |
| `after-dynamic-island-expanded.png` | The expanded island. |
| `after-lockscreen-notification.png` | The shift-end notification on the lock screen. |
| `after-report.png` | The shift report, with the arithmetic and the Mark it done row. |
| `after-clockout-sheet.png` | The rewritten sheet. Keep working is coral now. |
| `after-clockout-report.png` | The same report after a clock-out, pay line at zero. |
| `contact-after.png` | The set together. |

The full six-tab sweep in light, dark and accessibility-XL is in
`design/screenshots/sweep-focus-a-plus-2026-09-10/`, with its lint.
