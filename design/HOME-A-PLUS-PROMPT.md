Take the Home tab of the Prepkin iPhone app from an A− to an A+, in this repo (/Users/georgeshi/Desktop/app/prepkin-canvas). Home is the best screen in the app and the one every student sees every day. Do not rebuild it. Close the gaps, then prove it on the simulator with before and after screenshots.

Read first, in this order:
1. ios/Sources/HomeView.swift, ios/Sources/DayEditorView.swift, ios/Sources/TaskEditorSheet.swift, and `GameState.tasks` in ios/Sources/Core/GameState.swift (line ~338, how today's list is built from Canvas, dated tasks and templates).
2. PRODUCT.md and design/hicks-law-plan.md "House rules". No meters, no streaks, no scolding, no exclamation marks, no "sync / bridge / selector", every number only goes up, amber means "still counts", never red.
3. design/screenshots/calendar-2026-09-09/31-home-six-tabs.png (Home as of 2026-09-09) and design/screenshots/sweep-2026-09-09/contact-light.png, contact-dark.png, contact-axxl.png.
4. .claude/skills/ios-walkthrough/SKILL.md for the simulator rules, coordinates, the sweep script and the severity words. Check `xcrun simctl list devices booted` first; on 2026-09-09 four booted sims starved the Mac.
5. design/handoff/ (the Home handoff Home was built from) so layout changes respect the design loop: code fixes go straight in, layout changes get a Claude Design brief (design/CLAUDE-DESIGN-PREAMBLE.md + one screen) instead of freehand SwiftUI.

What is already right and must not change: "4 goals left today" as the headline, the coin chip opening the Shop, the Day 1 offer cards one at a time after the first check-off, dated and overdue tasks joining today's list, unchecking with no penalty, the mascot in the tank at the top, the tab bar.

Fix these, in this order. Each one has a file and line from the 2026-09-09 review; re-find the line, the tree has moved.
1. The paired-but-nothing-due state is blank space between the goals row and the grade calculator. Add one quiet line under the goals row: "Nothing due. Last list from your laptop 2h ago." when paired, "Nothing due today." when not. Never a card, never an illustration, never a call to action. HomeView.swift ~528 and ~611.
2. "3 stars · fully grown" draws a full yellow bar with a lightning bolt. A full meter with nothing left to do is a meter. Show the three StarPips and the words, no bar, at every stage. At 1 and 2 stars show "40 to the next" as text, still no bar. HomeView.swift ~573.
3. A "Tomorrow" line under today's list: "Tomorrow: Bio quiz, Essay outline" from dated tasks and Canvas items due tomorrow, two titles then "and 2 more". Tap opens the Calendar tab on tomorrow. Absent when tomorrow is empty, never "Nothing tomorrow". Read the same sources `GameState.tasks` reads.
4. A freshness cue on Home, not only inside Your day: "from your laptop 2h ago" in muted type under the goals row when Canvas is paired and the last list is older than an hour. Use the existing lastCanvasSyncAt. Never the word "sync".
5. First-run and preset picks read like a wellness app for 14-year-olds ("Drink a glass of water", "10 minute walk", "In bed by 11"). Keep them, but lead the pick-three and the Study ideas list with school-shaped ones: "Read for one class", "Email a professor", "Go to office hours", "Start the thing due Friday", "Laundry". Edit ios/Resources/Content presets and FirstRunView's pick list; keep the coin values in the same bands.
6. The grade calculator card is the most undergrad-specific thing in the app and it sits under the task list, below the fold on a busy day. Move it to a compact row in the header band next to the goals row, or into Calendar. Pick one, say why in the commit, and if it is a layout change, write the Claude Design brief instead of freehanding it.
7. Confirm the two chip rails above the mascot (emotes and costumes) are `-unlockAll` only and never render in a Release build. Add a test that DebugUnlock is false when the launch argument is absent.
8. The widget install card from the 2026-09-09 review: same shape as the Day 1 offers, shown once after the first coin on the second day: "Want Moss on your home screen?" with "Show me how" and "Not now". "Show me how" opens a three-step sheet with pictures. Only build the card and sheet if the widget target exists in project.yml; if it does not, leave a TODO with the card copy and skip.
9. Copy sweep on Home and Your day only: no exclamation marks, no "sync / bridge / selector / behind / streak", and every string under 40 characters where it sits on one line. Add any new string to the existing banned-words test.

Compare, once, with Mobbin (search_screens, platform ios): "Finch home screen bird with goals list", "Duolingo home path with mascot", "Headspace today screen". Look at the images. Write one line each on what they do better than Home today. Note the decor-fit finding from memory: Finch's pet takes about a fifth of the band, ours takes almost all of it. Say whether the mascot band should shrink, and do not shrink it without George; that is a Claude Design brief.

Prove it:
- Run test/ios-sweep.sh on one simulator for light, dark and accessibility-XL. Before and after contact sheets in design/screenshots/home-a-plus-<date>/.
- Walk the four Home states by hand and screenshot each: no Canvas paired; paired with nothing due; four tasks with two done; all done. Also Day 1 with the offer cards.
- Every control on Home at least 44pt; every image and button labelled. The sweep lint reports both.
- Unit tests for the Tomorrow line (two titles then "and N more", absent when empty), the nothing-due line, and the star text at each stage. Suite green.

What an A+ looks like: a student opens the app at 11 PM and in three seconds knows what is left today, what is coming tomorrow, and that the list is fresh. Nothing on the screen is a meter, a warning, or a promise. Every string is under 40 characters and true. The four states each look finished, not empty. Dark and XL text hold. Nothing that was right on 2026-09-09 has moved without a reason in the commit.

Do not touch Focus, Learn, Calendar, Friends, Kin or the Shop in this session. Another session may be editing Theme.swift for the uniformity sweep; `git diff` before touching tokens.

Finish with: the before and after contact sheets, one screenshot per state, the test count and result, the one-line Mobbin notes, and whatever you decided to hand to Claude Design instead of building.
