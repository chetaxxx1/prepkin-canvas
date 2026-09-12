# App simplify — 2026-09-12

The A− → A pass: one place for each fact, and a named screen for each change.
`before/` is the tree at `beb4cd0` (plus the other session's uncommitted emote-wheel
work); `after/` is the tree at the last commit below. Both were shot with
`test/ios-sweep.sh` on a fresh save (`prepkin-simplify`, first run walked, one dated
task typed three weeks out for the Calendar shot), light, dark and accessibility-XL.

| # | Screen | Mobbin screen copied | What was removed | Commit |
|---|---|---|---|---|
| 1 | Focus | Forest's timer: one control, one button — `bb4f30bc-843c-4c56-bb8a-214f44561588`. More sheet: Tiimo's duration picker — `1620305c-a020-4cf4-8c42-4b9040d4ec8a` | The 60 and 90 chips (behind "More"), the typed-length link, "for finishing" on the coins pill, the seven-bar week graph | `520548c` |
| 2 | Kin | Finch's home, one bubble on the bird — `18d270f7-7eb4-448f-a928-174b4a7a7aa3`. Card on tap: Finch's pet card — `b2af9c62-89dd-42c0-8704-94fa5e5483ba` | The name plate and the stage-word pill as two things; now one plate, tap for the Card, hold to rename | `8ce9947` |
| 3 | Friends | Duolingo's league tab, one entry that is the league — `3ca570fe-9e97-4e65-85eb-3e544a7eacab` (George's link had `85edd`; this is the id that resolves) | The "Swim with a pod" row (Join lives on the ladder screen); "Try L, Q" on the code hint | `8b65675` |
| 4 | Calendar | Google Calendar's schedule view, "Nothing planned. Tap to create." — `1f51ee68-947e-4ce0-b371-4d307313f77b`. Next item under a month header: Things 3 Upcoming — `590f4dd6-1a6d-45a3-91c3-3508a762b041`. One-line title: Outlook — `a6fd424b-68a6-40e5-ad65-e0257449ff2a` | The "Sat · free" fold under an empty week's one line; the kin peek; the wrapped title | `0a7739d` |
| 5 | Play | NYT Games' home, a title and tiles with no counters — `8c796715-7244-416a-8d9d-f6211323d7d2`. "Today's puzzles": Apple News Puzzles — `a2319e2f-b25d-41ff-8b15-b0f9d35dc619` | The month tally under the title; the coral dot on the switch; "banks" / "Banked" | `e608288` |
| 6 | Your day | Finch's goals header, a count and nothing else — `18d270f7-7eb4-448f-a928-174b4a7a7aa3` | The mint progress bar under "4 of 17 picked" | `3cc387f` |
| 7 | Home | Finch's home, tools behind doors — `18d270f7-7eb4-448f-a928-174b4a7a7aa3` | The Grade calculator card on the daily scroll (now a row on the Kin Card and in Calendar's export menu) | `8fecd38` (the Home hunk rode along in `7630d55`, the notifications session's commit) |
| 8 | Plus | Imprint's "your subscription includes", goods as pictures — `9036a4f7-80dd-4781-b9c3-695383698d5a`. Finch's Plus sheet, bird first, one line per perk — `0525a643-772d-4665-b5fc-b0d7d10a3a3a` | The 27-word free line; the sentence under each of the five perks | `50044c1` |
| 9 | Home | Finch's goals row, clear controls beside the count — `18d270f7-7eb4-448f-a928-174b4a7a7aa3` | The sliders glyph (now the word "Edit") | `38af2ca` |

## Counts on the after screenshots

- Focus ready screen, "25": three — the readout ("25 min"), the chip, and the coins pill ("+25 coins", as specified). As minutes it is said twice: readout and chip.
- Kin, pills over the fish: one plate ("Moss · ★☆☆ · Just met") plus the bubble.

## Tests

`ios/Tests/SimplifyTests.swift`, 16 tests, one per rule: chips are [15, 25, 45]; More holds
[60, 90, typed] and never repeats a chip; the Kin plate is "Moss · ★★★ · Buddies" in three
parts; Friends has one league row and the code hint says one thing; an empty week is
[.day(today)], a busy week still folds, the next dated thing is found three weeks out and
not past the horizon; the Play switch label has no "open", the play line says paid, the
rating explainer is the one line; the day editor's count is words; Home is not a
calculator door; the free line is one sentence; five perk titles under 40 characters;
Home's control is "Edit". Full suite after the last commit: 530 tests, 521 passed,
9 skipped, 0 failed (`xcodebuild test`, prepkin-simplify-tests).

## Lint

`test/ios-sweep.sh` lint on `after/`: no unlabeled buttons or images on any tab; no
control under 44pt except "More lengths", which reports 43.99999999999994 × 44 (a
float on a third-of-a-point y; it is a 44pt frame). Before, the lint had "Any length you
type · Plus" at 14pt, "Add a friend" at 36, the Play switch halves at 34, and "Get the
Chrome extension" at 18; all four are 44 now. Banned words (sync, bridge, selector,
behind, unlock, streak): none on any tab. Strings over 40 characters on one line: one,
pre-existing, on Your day's Canvas card — "Your Canvas login never leaves your laptop."
(43).

## Left alone, and why

- Calendar's caption "Nothing due this week" over "Today · Nothing due. Tap to add."
  says empty twice. Not on the list; flagged.
- The rating chip is hidden until the first puzzle result, so the after sweep does
  not show it. `testRatingExplainerIsOneLine` covers the string.
- The More sheet's chips report 42pt inside the sheet (they are 44 on the tab); the
  sweep lint reads tab screens only.
