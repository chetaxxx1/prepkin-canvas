Take the Prepkin iPhone app from an A− to an A by taking things out, in this repo (/Users/georgeshi/Desktop/app/prepkin-canvas). The 2026-09-12 review found every tab good and several tabs saying the same thing twice: Focus grew from three chips to five plus a strip, three pills stack on the fish, two Friends rows open one screen, the empty Calendar is a void, Play's header carries three signals, Your day draws a meter. This session is editing. Every change below is a copy of a named screen from a top app. If you cannot name the screen, do not make the change.

Read first, in this order:
1. PRODUCT.md and design/hicks-law-plan.md ("House rules" and "Decided 2026-09-06": 15 / 25 / 45, one coral button per screen, no meters, no streaks, say a count once).
2. The 2026-09-12 sweep in this session's record: design/screenshots/ has the latest per-tab sweeps (kin-redesign-2026-09-11, focus-a-plus-2026-09-10, calendar-redesign-2026-09-10, play-tab-2026-09-10). Run your own before you touch anything.
3. ios/Sources/FocusView.swift, KinView.swift, FriendsView.swift, CalendarView.swift, LearnView.swift (the Play tab), DayEditorView.swift, HomeView.swift, PlusSheet.swift. `git diff` before editing any of them; other sessions are live in this tree. Commit your own files only, never `git add -A`.
4. .claude/skills/ios-walkthrough/SKILL.md. Check `xcrun simctl list devices booted`, create a session-named simulator, test on one and screenshot on another (memory: simulator-contention; the test scheme sets a sticky -unlockAll on whatever simulator it runs on). Delete your simulator at the end.

The rule: one place for each fact, and a named screen for each change. Open every Mobbin link and look at it before you build.

Do these, in this order, one commit each, the suite green after each:

1. Focus: three chips and a "More". Copy Forest's timer screen, one control and one button (search Mobbin "Forest focus timer set length", platform ios, cite the id you use). Chips 15 / 25 / 45 as decided on 09-06. A small text link "More" opens a sheet with 60, 90 and a typed length for Plus, drawn like Tiimo's duration picker: https://mobbin.com/screens/1620305c-a020-4cf4-8c42-4b9040d4ec8a. Drop the seven-dot week strip; the week line already says it in words. Say "25" once on the Ready screen: the big readout keeps it, the coins pill reads "+25 coins" only, the chip is a chip. FocusView.swift chip row, coins pill

2. Kin: one plate on the fish. Copy Finch's home, where the bird has one bubble and nothing else over it: https://mobbin.com/screens/18d270f7-7eb4-448f-a928-174b4a7a7aa3. The name, the stars and the stage word become one pill under the bubble; the coin chip stays top right. Tap the pill for the Card (Finch's pet card: https://mobbin.com/screens/b2af9c62-89dd-42c0-8704-94fa5e5483ba), long-press to rename. KinView.swift:218-252

3. Friends: one row for the league. Copy Duolingo's league tab, one entry that is the league itself: https://mobbin.com/screens/3ca570fe-9e97-4e65-85eb-3e544a7eacab. Keep "The whole ladder"; "Swim with a pod" becomes the Join button inside the ladder screen. "What friends see" stays. Replace the "Try L, Q" guess in the code hint with "Codes skip I, O, 0 and 1." FriendsView.swift:571-596, 639, 1054

4. Calendar: no fish in a void. Copy Google Calendar's schedule view, "Nothing planned. Tap to create." as one inline line and nothing else: https://mobbin.com/screens/1f51ee68-947e-4ce0-b371-4d307313f77b. Then the next dated thing even if it is three weeks out, the way Things Upcoming shows the next month's items under a month header: https://mobbin.com/screens/590f4dd6-1a6d-45a3-91c3-3508a762b041. The kin peek goes. Fix the title at accessibility-XL, which wraps "Septembe / r": the month shrinks with minimumScaleFactor before it wraps, the way Outlook's header stays one line: https://mobbin.com/screens/a6fd424b-68a6-40e5-ad65-e0257449ff2a. CalendarView.swift kinPeek, title band

5. Play: one signal in the header. Copy NYT Games' home, a title and tiles with no counters above them: https://mobbin.com/screens/8c796715-7244-416a-8d9d-f6211323d7d2, and Apple News Puzzles for the "Today's puzzles" label: https://mobbin.com/screens/a2319e2f-b25d-41ff-8b15-b0f9d35dc619. Drop the coral dot on the Puzzles / Lessons switch. "Six today. First finish banks 30." becomes "Six today. First finish pays 30." and "Banked." becomes "Paid." The rating chip gets a one-line explainer sheet on tap: "Goes up when you solve a hard one, down when you miss an easy one. Chess.com's puzzle rating, for puzzles." LearnView.swift:234, 370-372, 457

6. Your day: no bar. Copy Finch's goals header, a count and nothing else: "7 goals left for today" with no progress bar, same screen as item 2. "4 of 17 picked · 50 today" stays as text; the bar goes. DayEditorView.swift kin card

7. Home: the grade calculator off the daily scroll. Copy Finch's home, where only today's goals sit under the bird and every tool lives behind a door: same screen as item 2. The calculator becomes a row on the Kin Card and a row in Calendar's export menu; the Home card goes. Nothing else on Home moves. HomeView.swift:839-861

8. Plus: pictures, not paragraphs. Copy Imprint's "your subscription includes" with the goods fanned as pictures: https://mobbin.com/screens/9036a4f7-80dd-4781-b9c3-695383698d5a, and Finch's Plus sheet with the bird first and four perks with one line each: https://mobbin.com/screens/0525a643-772d-4665-b5fc-b0d7d10a3a3a. The 27-word free line becomes "Everything else stays free." The five perk tiles become five images of the goods: a coat on the example fish, the seven shop slots, the 60 and 90 chips, a syllabus photo, a calendar. Keep the compare table one tap away. PlusSheet.swift:163-170, perk tiles

9. Home's edit-day gear gets a word. Copy Finch's goals row, where the filter and layout icons sit beside the count with clear glyphs: same screen as item 2. Ours: the gear becomes "Edit" as text, 44pt, beside "4 goals left today". HomeView.swift:598

Do not: add a card, a section, a setting, a chip, a colour, or a number. Do not touch the Shop, the Wardrobe editor, the shift screen, the Monday sheet, or anything in extension/. Do not change Theme.swift; another session owns the uniformity pass.

Prove it:
- Unit tests for every rule that changed: the chip set is exactly [15, 25, 45] for free and the More sheet holds [60, 90, custom] for Plus; the Kin plate string is "Moss · ★★★ · Buddies"; Friends has one league row; Calendar's empty week renders one line and the next dated item; the Play header has no dot; the day editor has no ProgressView; Home has no grade calculator card. Suite green.
- Before and after sweeps with test/ios-sweep.sh, light, dark and accessibility-XL, in design/screenshots/app-simplify-<date>/. Every control 44pt, every image labelled, every string under 40 characters on one line, no banned words.
- On the after screenshots, count how many times "25" appears on the Focus ready screen (answer: two, the readout and the chip) and how many pills sit over the fish on Kin (answer: one plus the bubble).
- A README in the screenshot folder with one row per item: the Mobbin screen copied, what was removed, the commit.

What an A looks like: every tab does its one job with one control. Focus is a number and a button. Kin is a fish with a name. Friends is a board and a ladder. Calendar is what is coming, and says nothing when nothing is. Play is today's puzzles. Nothing on any tab says the same thing twice, and every change traces to a screen from an app that already works.

Finish with: the before and after contact sheets, the counts above, the test count and result, the README table, and the commits, one per numbered item.
