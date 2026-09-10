Take the Focus tab of the Prepkin iPhone app from a B to an A+, in this repo (/Users/georgeshi/Desktop/app/prepkin-canvas). Focus is a shift: the kin swims the Reef Route for 15, 25 or 45 minutes, coins are paid all-or-nothing at the end, and the screen tells the student to put the phone down. The B is because the app then cannot tell them when the shift is over, and when it is over it says nothing. Fix that, then prove it on the simulator.

Read first, in this order:
1. ios/Sources/FocusView.swift, ios/Sources/SwimSceneView.swift, ios/Sources/StudySync.swift, and the focus parts of ios/Sources/AppState.swift and ios/Sources/Core/GameState.swift (grep focus, shift, bestShift, settle).
2. ios/Sources/Core/Notifications.swift — the planner and scheduler. You will add a fourth kind.
3. PRODUCT.md and design/hicks-law-plan.md "House rules" and "Decided 2026-09-06": 15 / 25 / 45, no steppers, one coral button, no streaks, no scolding, no red, every number only goes up.
4. design/CLAUDE-DESIGN-PROMPT-FOCUS-CLOCKOUT.md — the design brief for the clock-out sheet, shift report and settings row. It is STALE: it describes a van scene, 25/45/60 with a stepper, and pay-for-minutes-worked. The app now has the Reef Route swim scene (memory: Reef Route shipped 4e3d350) and all-or-nothing coins (3bd80e1, George's rule from Focus Friend, 2026-09-06). Your first job is to rewrite that brief to the current facts before anything is designed from it.
5. design/reef-route/ (the scene mock and tools) and design/screenshots/sweep-2026-09-09/light-focus.png, axxl-focus.png.
6. .claude/skills/ios-walkthrough/SKILL.md for simulator rules. Check `xcrun simctl list devices booted` first; four booted sims starved the Mac on 2026-09-09. Any new animation needs a GIF sign-off from George before it ships (memory: animation-approval). The tank page owns the mascot's safe area (memory: sprout-embed-contract); Focus deliberately does not run the live web tank.

What is already right and must not change: three chips with 25 preselected and one Start button; clock-out never scolded and never red; lengths swum and best shift as cosmetic only-up counters; Study Together showing only when a friend is live; the wall-clock timer that keeps honest time in the background; all-or-nothing pay.

Fix these, in this order:
1. Shift-end notification. Scheduled the moment Start is tapped for now + minutes, removed on Pause and on clock out, rescheduled on Resume. Title "Shift over. 25 coins paid." Body "Moss swam 6 lengths." (kin name, real count). Fires whether or not reminders are on, because the student asked for a timer; ask for notification permission on the first Start if never asked, with one line: "So you can put the phone down and still know when it's over." Add it to NotificationPlanner as its own kind with a test. Never a badge.
2. Live Activity. ActivityKit, started in FocusView.start, ended on finish and clock out, paused state on Pause. Lock screen and Dynamic Island: kin still, "Moss is on shift", the countdown as Text(timerInterval:) so it ticks with no updates, "4 lengths swum · 25 coins at the end". Needs NSSupportsLiveActivities in project.yml and the kin stills in the widget/activity target's slim asset catalog (the main catalog carries every lesson figure; do not ship it in an extension). If the widget target from the 2026-09-09 review does not exist yet, create the extension target for the Live Activity only and leave the widget for its own session.
3. The shift report. When the timer hits zero (and after a clock-out, with the pay line reading zero), a full screen for one beat: the kin large, "25 minutes. 25 coins." with the arithmetic visible, the task that rode along with a Mark it done row that pays that task's own coins (Canvas tasks show without a checkbox, Canvas has to see the submission), lengths this shift and best shift only if it changed, one coral Done and a quiet Another shift. Play celebrate at 25 minutes or more, bounce below; today finish() plays nothing. Build from the rewritten brief; if you change layout beyond the brief, write a Claude Design prompt instead of freehanding.
4. The clock-out sheet copy. Today it says "N coins waiting … Clock out now and they stay in the reef." A tired reader hears "kept for you". The code pays zero. Say it straight: "Clock out now and this shift pays nothing. Finish it and it pays 25." Keep working stays primary, coral. Clock out is the quiet secondary. No red, no "are you sure".
5. A "Working on" chip on the Ready screen: defaults to the next undone task, tap to pick another from today's list or "Nothing in particular". The chip rides into the shift screen and the report. Nothing about it travels to friends (StudySync rule 3).
6. "NEXT IN 4:12" is unexplained shorthand. Say what it is: "Next length in 4:12", or drop it and let the length count speak. Pick one.
7. "Put the phone down and let them work" is a command. Try "Moss is swimming. The phone can wait." Keep it under 40 characters and not an order.
8. The Join button on the Study Together row is 34pt. Make it 44.
9. Strict mode, from the brief: off by default, leaving the app clocks the shift out. With all-or-nothing pay that means leaving pays nothing, which is harsh, so build it only as an opt-in switch on the Ready screen with one honest line under it, or make the case for not building it at all and say so.
10. Focus history: a small "This week" line on the Ready screen, "3 shifts · 1h 15m", from the ledger, only ever up. No graph, no calendar, no streak. If a graph is wanted later it is a Plus perk (design/PLUS-PROMPT.md).

Do not add app blocking. Screen Time APIs need a Family Controls entitlement review and the fish is the hook, not a wall.

Compare, once, with Mobbin (search_screens, platform ios): "Forest focus timer running screen with tree", "Forest session complete screen", "Opal focus session Live Activity lock screen", "Flora focus timer finished screen". Look at the images. One line each on what they do better. Cite mobbin_url for anything borrowed. Structure and honesty, never the look.

Prove it:
- Unit tests: the shift-end notification is planned on start, absent after pause and clock out, present again after resume; the report's pay line at 0, 15, 25, 45; the Working on default; the week line.
- On one simulator: start a 15 (or a debug 1-minute length behind -unlockAll), lock the sim with `xcrun simctl io <udid> ...` or the Simulator menu, wait it out, and screenshot the notification on the lock screen and the Live Activity. Then the report. Then a clock-out at 3 minutes with its sheet and its zero report.
- Run test/ios-sweep.sh light, dark and accessibility-XL. Before and after contact sheets in design/screenshots/focus-a-plus-<date>/.
- Every control on Focus at least 44pt, every image and button labelled.
- Record a short GIF of the report's celebrate for George's sign-off; do not ship the animation without it.

What an A+ looks like: a student taps Start, locks the phone, and the lock screen shows the fish swimming down. When the shift ends the phone says so and names the coins. Opening the app shows what the shift paid, in plain arithmetic, and lets them tick off the thing they were working on. Quitting early is calm and honest about paying nothing. Nothing on the tab is a meter, a streak, a warning, or an order.

Do not touch Home, Learn, Calendar, Friends, Kin or the Shop in this session. `git diff` before editing AppState.swift and Notifications.swift; other sessions are active in this tree.

Finish with: the rewritten CLOCKOUT brief, before and after contact sheets, the lock-screen and report screenshots, the GIF, the test count and result, the Mobbin lines, and the Strict-mode decision in one sentence.
