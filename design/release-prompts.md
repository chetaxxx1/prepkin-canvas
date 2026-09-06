# Release walkthrough — 2026-09-03, refreshed 2026-09-05

## Where it stands on 2026-09-05

All ten items in "Seen and left alone" below are closed: the honest Friends tab, the
working flag and the quiet Ask Kin, 901 words with a dictionary check, the extension's
current-term filter, the designed clock-out sheet, Moss instead of "Slime", the Number Line
band, the Your day label, and first run walked live on `prepkin-blank`. Two scripted
shakedowns ran on 2026-09-05 (artifact "Prepkin Shakedown Two"; loop in
`.claude/skills/ios-walkthrough`). The prompts below are kept for the record.

What is left, ordered by how much it would embarrass a release:

1. **Nothing is committed.** Two days of shakedown fixes sit on top of four days of other
   uncommitted work. Review together, then commit.
2. **The tank under Reduce Motion is drift-only now** (Sprout source rebuilt into
   `ios/SproutWeb` on 2026-09-05, measured on the simulator). Confirm once on a real phone:
   Home should hold still except for a blink and a two-pixel breathe.
3. **No real phone yet.** No developer account, so no TestFlight. Install from Xcode with a
   free team and use it for one school day. The live tank, haptics and a real Canvas pair
   only exist there.
4. **Dark paper.** The app is light only (a decision, `project.yml`). The brief is queue item 7,
   `CLAUDE-DESIGN-PROMPT-DARK-PAPER.md`. A student at 11pm will ask.
5. **Text sizes.** Reading text scales to 1.3×, not the accessibility sizes. Say "large text"
   in any listing, never "Dynamic Type".
6. **Versus is off the Games rail** until friends work (`GameCard.versus` stays in code).
   When Friends goes live, put it back and re-run `test/ios-flows.sh`.
7. **The live bridge is still on the old schema.** Nothing pairs until `bridge/schema.sql`
   is re-run in Supabase. The app's Canvas card says "Showing your last list" honestly
   meanwhile.

---

Every tab and sheet was clicked through on the `prepkin-today` simulator (real Dartmouth Canvas data). This file has two parts: what was fixed in this pass, and copy-paste prompts for the work that is left.

## Fixed in this pass

| # | Where | What was wrong | Fix |
|---|-------|----------------|-----|
| 1 | Home | The tank behind Sprout went blank, or kept a stale corner of the art. iOS kills the web view's process under memory pressure and nothing reloaded it. | `SproutView` now reloads the page when the web process dies and covers it until it reports ready. |
| 2 | Home, Focus | "Sprout is cheering you on!" and "Sprout is on shift" used the species name. The kin is named Pip. | Both use `displayName`. |
| 3 | Home | The same Canvas quiz showed three times. Canvas hands back three copies of each quiz with different ids. | Rows collapse by title + course + due date. Weekly quizzes with different dates stay separate. Unit test added. |
| 4 | Your day sheet | No way to delete a custom task without a long-press. No copy for the all-off state. | Built from the handoff: EDIT / minus / Remove, and the quiet-day line. |

## Seen and left alone (needs a decision or a bigger job)

Ordered by how much it would embarrass a release.

1. **Friends tab shows four fake people.** Maya, Josh, Ava and Sam are hard-coded. "Add" flips to "Sent" but nothing is sent. Every real user sees this.
2. **Lesson reader has a dead button.** The flag (report) icon does nothing. "Ask Kin" opens a "can't answer yet" panel.
3. **Daily Word takes any five letters.** No dictionary check, and only 30 answers in `words.json`, so the puzzle repeats every 30 days.
4. **Canvas pulls stale work.** The extension sent undated quizzes from "Thayer Welcome and Orientation 2020". The app-side collapse hides the copies, but the course itself should not be there.
5. **Focus clock-out uses a stock iOS dialog.** The handoff wants a designed quit sheet. In the simulator the dialog also showed only one button (the cancel was not visible) — check on a device.
6. **The free kin is called "Slime"** in the Collection and Shop, but it draws as a mint Sprout.
7. **Number Line** leaves a large empty band between the slider and "Lock it in".
8. **Your day sheet:** "Nothing picked yet" truncates to "Nothing picke…" at `minimumScaleFactor(0.8)`. About 0.72 would fit.
9. **Seen once, not reproduced:** one tap on Home's coin chip opened the Shop and a Wisp detail sheet on top of it. Two tab-bar taps also landed on the wrong tab while two simulators and a test run were fighting for memory. Neither happened again.
10. **Not tested:** first run. The `prepkin-fresh` simulator is not granted to Claude. It has a clean install of this build ready to go — grant it in the simulator panel and ask for the walkthrough.

---

## Prompts for Claude Code

Paste one at a time. Each names the files, the rule to keep, and how to check it.

### 1. Friends — ship the honest empty state

```
In ios/Sources/FriendsView.swift the friend list is a hard-coded array (Maya, Josh, Ava, Sam). Real users will see fake people. There is no friend backend yet.

Make the tab honest for release:
- `friends` starts empty and is read from state (add `friends: [Friend]` to GameState, persisted like `friendCode`). Keep the Friend struct.
- With no friends, show the existing empty state ("Just us for now. That's fine by me." + "Swap codes with someone and their kin shows up here.") under the header, and hide "This week" and the "Friends" card.
- "Add a friend" keeps working. On Add, store the code locally as a pending request (`pendingFriendCodes: [String]` in GameState) and show the existing "Sent" state. Show pending codes under the empty state as "Waiting on XXXX-XXXX" rows with a remove control.
- Keep the sample data behind `#if DEBUG` and a `showSampleFriends` flag so the design can still be previewed.
- Do not redesign anything. Match the existing tokens in the file.

Verify: build, run on prepkin-today, open Friends. No names appear. Add a code, see "Sent", go back, see the waiting row. Run the unit tests.
```

### 2. Lesson reader — no dead controls

```
In ios/Sources/LessonDeckView.swift the bottom bar has a flag button with an empty action (`Button {} label:` near line 354) and an "Ask Kin" button that opens a "can't answer yet" panel.

For release:
- Flag: make it work. Tap opens a small sheet titled "Something wrong with this card?" with three tappable reasons (Typo, Wrong or misleading, Other) and a Send button. Sending appends {lessonID, cardIndex, reason, date} to a `cardReports` array in GameState (persisted) and shows a one-line toast "Thanks. We'll look at it." Use the sheet styling already in this file (the askKin panel) so it matches.
- Ask Kin: keep the button but change the panel copy to say what it does today, one sentence, no "coming soon". If the team would rather hide it, put the button behind a `showAskKin` flag defaulting to false.
- No other changes to the reader.

Verify: open any lesson, tap the flag, send a report, confirm the toast. Build and run tests.
```

### 3. Daily Word — real words only, more of them

```
ios/Sources/WordleView.swift accepts any five letters as a guess, and ios/Resources/Content/words.json has only 30 answers, so the daily word repeats every 30 days.

- Add ios/Resources/Content/guesses.json: a plain JSON array of common five-letter English words, lowercase, at least 5,000 entries. Keep it clean — no slurs, no proper nouns.
- Grow words.json to at least 365 answers. Every answer must also be in guesses.json. Prefer words a high-school or college student knows.
- On Enter, if the guess is not in guesses.json, shake the row (the shake already exists — `game.shake`) and show "Not in the word list" in the kin's speech bubble for 1.5 s. Do not consume a try.
- Load both lists through Catalog like `wordleAnswers` does (`Content.swift`). Keep the fallback list.

Verify: type "FINET" and press Enter — row shakes, no try used. Type a real word — it scores. Add a unit test that every answer is in the guess list.
```

### 4. Canvas — only current work

```
The Chrome extension (extension/) sends the phone every assignment it can find, including undated quizzes from "Thayer Welcome and Orientation 2020", a concluded course. The app now collapses duplicate copies (GameState.tasks), but stale courses should not arrive at all.

In the extension's course sweep:
- Only include courses that are active in the current term: use the Canvas `enrollment_state=active` filter and skip courses whose `term.end_at` is in the past or whose `workflow_state` is not "available".
- Skip assignments with no due date AND no points possible, unless the course is in the current term and the assignment was created in the last 60 days.
- Keep everything else exactly as it is. Do not change the message format to the bridge.

Verify: reload the extension on the paired laptop, sync, and confirm the 2020 course's quizzes are gone from Home on prepkin-today. Keep the existing extension tests passing.
```

### 5. Focus — designed quit sheet

```
ios/Sources/FocusView.swift shows a stock `confirmationDialog` for "Clock out early?" The handoff (design/handoff/focus-shift-van/README.md) wants a designed quit sheet.

Build it as a bottom sheet in the app's own style (Theme tokens, 26pt card radius, coral primary button):
- Title: "Clock out early?"
- One line under it using the existing `paidMinutes` copy: "12 min worked. That is what the shift pays." or "The shift has not paid a minute yet."
- Primary button: the existing `payLabel` ("Clock out — keep 1 coin" etc.), coral, 56pt.
- Secondary text button: "Keep working".
- Sheet height fits content (`presentationDetents([.height(…)])`), drag indicator hidden, tapping outside dismisses as "Keep working".
- Remove the confirmationDialog. Keep `confirmingClockOut` as the toggle.

Verify: start a 25 min shift, tap Clock out early, see the sheet, both buttons work, the timer keeps running behind it.
```

### 6. Kin — rename the free species

```
The free common species is called "Slime" in ios/Sources/Models.swift (ChibiSpecies.catalog) but draws as a mint Sprout since the mascot change. It shows up as "Slime" in the Shop, Collection and adoption flow.

- Rename the display name only. Keep the id "slime" so saved games and SproutView.coat() keep working. Suggested name: "Moss". Update any copy that says "Slime" as a species name (grep for `"Slime"` in Sources/, and FriendsView sample data).
- A kin the student already named keeps their name; only the unnamed fallback changes.

Verify: Shop and Collection show the new name; a saved game with a named "slime" kin still shows its custom name. Run the tests.
```

### 7. Number Line — fill the middle

```
ios/Sources/NumberLineView.swift leaves an empty band between the slider (about y=440pt) and "Lock it in" (about y=780pt) on a 402x874 phone.

Do the smallest layout change that removes the void without moving the button:
- Move the prompt card + slider block down so it sits in the vertical centre of the space between the progress dots and the button.
- Under the slider, add one muted line of help copy that changes per round (the `hint` for the round already exists — reuse it; keep the kin bubble as is).
- Keep every size and colour. Do not add features.

Verify: screenshots of rounds 1, 4 and 7 on prepkin-today — the block is centred and nothing overlaps the button.
```

### 8. Your day sheet — the label that truncates

```
In ios/Sources/DayEditorView.swift, kinCard's `pickedLabel` shows "Nothing picke…" when nothing is picked. It has `.lineLimit(1).minimumScaleFactor(0.8)` but 0.8 is still about 10pt too wide next to the coin chip.

Lower minimumScaleFactor on that Text only until "Nothing picked yet" fits on a 402pt-wide phone (0.72 works). No other change.

Verify: toggle every task off in the sheet and confirm the full label shows.
```

### 9. First run — walkthrough

```
Run the first-run flow (ios/Sources/FirstRunView.swift) on the prepkin-fresh simulator, which has a clean install. Go through name → pick three → Day 1 cards → Home, then the two offer cards after the first check-off. Screenshot each screen. Report anything that is cut off, mis-sized, or wrong against design/handoff-first-run/README.md. Fix only clear bugs; list design questions instead of guessing.
```
