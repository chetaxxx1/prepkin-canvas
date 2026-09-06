# Hick's law — audit and plan, 2026-09-06

Hick's law: the time to pick goes up with the log of the number of equal options.
Each doubling of choices adds about the same delay. Three things shrink the effective
count without deleting features: a highlighted default (the student can tap nothing),
one clearly primary action (the rest read as "later"), and grouping (a group of 3
reads as 1 until you enter it). Catalogs are the exception: a shop is browsing, not
deciding, and cutting it makes it worse. Sort it so the likely pick is first instead.

Counted from source on 2026-09-06 (iOS `ios/Sources`, extension `extension/`) and the
latest sweep screenshots (`design/screenshots/sweep-final`, `design/signoff/extension-ui`).

## House rules (apply to every screen on both surfaces)

1. **One coral / one mint per screen.** Exactly one primary button (coral on the phone,
   mint press in the extension). Everything else is quiet: chips, links, icon buttons.
2. **Five equal choices, max.** A row or group of same-weight options stops at 5. A
   picker with a default stops at 3 presets.
3. **Every picker is pre-answered.** The default is already selected, so "tap nothing"
   is a valid choice. No screen asks a question it could answer itself.
4. **One door per room.** If the same place is reachable from two controls on one
   screen, one of them goes.
5. **Same choice, same options.** A choice that exists on both surfaces (focus length)
   shows the same options in the same order.
6. **Catalogs sort, never cut.** Looks, kin, scenes: keep every item, put the likely
   pick in the first row (wearing → owned → affordable → the rest).
7. **Settings are a receipt, not a panel.** Show what changed with a Put back per row.
   Toggles up front only for things that are not on the receipt.

## Where it stands

### Extension

| Surface | Now | Equal-weight? | Target | Verdict |
|---|---|---|---|---|
| Popup · Canvas card (`popup.html:257`) | 7: Quiet toggle, Paper Light/Dark/Auto, grade-on-cards, Compact, Buddy | yes, one card | 2 (Quiet, Paper) | **fix** |
| Popup · Receipt (`receipt.js:80`) | 11–17 rows, each with Put back; Show me | yes | 1 primary + list folded | **fix** |
| Panel · Next up (`content.js:311`) | 5: Start, 15, 25, 45, Go | Start is mint, rest equal | 1 (Start) + 1 chip | **fix** |
| Panel · filters (`content.js:295`) | 3: Today / This week / Overdue | segmented | 3 | ok |
| Panel · Looks grid (`content.js:566`) | 16 tiles + detail sheet with 2 actions | catalog | 16, sorted | sort only |
| Panel · banner picker (`content.js:521`) | 4 per course, only for 4 art themes | gated | 4 | ok |
| Panel · What-if (`content.js:449`) | 4 targets + weight field | sequential | 4 | ok |
| Panel · grades level (`content.js:376`) | 3 per opened course | accordion | 3 | ok |
| Panel · running focus | Extend / Stop / Clear | 3 | 2 (Extend, Stop) | small |
| Dashboard Today strip (`#pk-today`) | Start, Focus N, Grades | 3 buttons on the school page | 1 primary + 2 quiet | small |
| Onboarding | 3 steps; Connect / Skip equal buttons | 2 | 1 primary + text link | small |
| Focus presets | 15 / 25 / 45 | | phone matches this | ok |

### iOS

| Screen | Now | Equal-weight? | Target | Verdict |
|---|---|---|---|---|
| Tab bar (`RootView.swift:23`) | 6 tabs | learned, full-colour icons | 5 (Games → Learn) | **fix** |
| Home top bar (`HomeView.swift`) | 4: name pill, Tidepool pill, coins+bag, sliders | yes | 2–3 | **fix** |
| Home body | offer Yes/No, N task rows, emote wheel (4, hidden until hold) | | unchanged | ok |
| Focus ready (`FocusView.swift:97`) | 6: 25 / 45 / 60, −, +, Start | default highlighted, Start coral | 4 | small |
| Games | 1 coral + 2 tiles | | unchanged | ok |
| Learn | 1 Resume + 2 suggestions + track shelf | | unchanged | ok |
| Friends | 1 coral + 1 link | | unchanged | ok |
| Kin tab (`KinView.swift:197`) | shop, wallet, name, Pet / High five / Snack, Collection link, 9-kin strip | care row is play, not a decision | drop one door | **fix** |
| Kin Shop (`KinShopView.swift:29`) | 21: 5 picks, reroll, 9 kin, 5 scenes, honesty link; long-press to hold | picks and grids stacked, all cards look alike | 6 on open | **fix** |
| Collection (`CollectionView.swift:30`) | 9 rows, tiered | catalog | merge with shop grid | **fix** |
| Day editor (`DayEditorView.swift:75`) | 12 preset toggles (4 study, 8 life) + custom + Canvas + reminder + Done | yes | 6 visible | **fix** |
| First run | name (shuffle, next); pick 3 of N; Day 1 cards | constrained | cap N at 8 | check |
| Lesson deck | prev, next, save, close | hierarchical | unchanged | ok |

## Built 2026-09-06

All seven fix items below are in, uncommitted, on top of the earlier uncommitted work.
Verified: extension unit tests 85/85, receipt e2e 20/20; iOS build clean, unit tests
149/149; every changed screen screenshotted on prepkin-fresh; flows 24 of 26 on
prepkin-fresh. The two misses are not from this work: the focus flow taps a "no pay
yet" button that the 03:45 commit (clock out early) renamed, and shopshort taps
whichever pick is first unaffordable, which on this save is a kin (detail sheet, not
the scene toast). Tab centres in test/ios-sweep.sh and ios-flows.sh are now
43/122/201/280/359. Note: the Focus change rode along in commit 3bd80e1 from the other
session, so it is already on main. Not done from this file:
the small ones in section 8 (onboarding Skip, panel Clear, Today strip weights, Looks
sort, first-run cap).

## The plan, in build order

Each item: what changes, why it is Hick's, size. Nothing here deletes a feature.

### 1. Extension popup · Canvas card → 2 controls (~40 lines)

Keep **Quiet Canvas, with a receipt** and **Paper** (Light / Dark / Auto). Move the other
three where they already belong:
- **Your grade on course cards** and **Buddy on Canvas pages** are already receipt rows
  (`card-grade`, `buddy`). They become Added rows with Put back / Take off. The
  toggles go.
- **Compact pages** is the one opt-in with no receipt row. Give it a row under Added
  with a "Turn on" that flips to "Put back". Then the card is 2 controls.

### 2. Extension popup · Receipt → one decision (~60 lines)

The spec's promise (every change listed, each one click from coming back) stays. What
changes is what the eye lands on first:
- A header line: **"9 changes on this page"** with one quiet button, **Put it all back**.
  That is the one decision. Put it all back sets every key on the page; a second tap
  becomes **Take it again**.
- Under it the three groups (Taken / Fixed / Added) fold to their headers with counts.
  Tap a header to open its rows. The first group opens by default so the list is
  still visible, just not all 17 rows.
- Put back per row and Show me are unchanged.

### 3. Extension panel · Next up → Start, and a length chip (~30 lines)

Today: Start, then "or focus for 15 25 45 Go". Five taps competing for one intent.
- Keep **Start** (mint press) as the only button.
- Replace the four minute controls with one chip, **25 min ▾**, that opens the three
  presets inline. The remembered length shows in the chip, so most nights it is never
  touched.
- The dashboard Today strip already uses "Focus N min"; it should read the same chip.

### 4. Focus lengths → 15 / 25 / 45 on both surfaces (~10 lines each)

Extension offers 15 / 25 / 45. The phone offers 25 / 45 / 60 plus − / + steppers. Same
choice, different menus (house rule 5). Pick one triad and use it everywhere. On the
phone, drop the − / + steppers: a triad with a highlighted default is the whole choice,
and the steppers add a second axis (nudge by 5) that the presets already cover. Focus
ready goes from 6 controls to 4.

### 5. iOS Home top bar → 2 doors (~20 lines)

Four pills across the top. The **Tidepool** pill opens Friends, which is also a tab
(house rule 4). The **name pill** is a label wearing a button's clothes. Keep the coins +
shop chip and the sliders (Your day). Move the name to the Kin tab where it already
lives. Tidepool pill: gone (Friends stays a tab).

### 6. iOS Kin → one door to the nine kin (~80 lines)

The nine kin are reachable three ways: the strip on the Kin tab, the Collection page,
and the Kin grid in the Shop. One catalog.
- The strip on the Kin tab stays (it is the browse) and opens the Collection.
- The Shop's Kin and Scenes grids move into Collection as two segments: **Kin | Scenes**.
  Buy lives on the detail sheet, where it already is.
- The Shop opens on **Today's picks** only: 5 slots + Reroll + a "See the whole
  collection" link. 21 cards on open becomes 6.
- **Hold a slot** is a hidden long-press. Add a small pin on each slot, so the gesture
  is visible. Same behaviour, one visible control.

### 7. iOS Day editor → 6 presets visible (~40 lines)

Twelve toggles in one scroll, 4 study and 8 life, all the same weight. Show 3 of each
under their labels (**Study**, **Life**) with a quiet "More" that opens the rest.
Which 3: the ones the student has used before, then the list order. Everything else
(custom, Canvas, reminder, Done) is unchanged.

### 8. Small ones (~10 lines each)

- Onboarding: **Skip for now** becomes a text link under the mint Connect / Link.
- Running focus in the panel: Extend and Stop stay; Clear folds into Stop's confirm.
- Dashboard Today strip: Start is mint; Focus and Grades are quiet text.
- Looks grid: sort wearing → owned → affordable → the rest; pin Classic Cream (dark is
  free) first. No search, sixteen tiles are browsable.
- First run pick-three: check the list is capped at 8 candidates. If Canvas syncs 20
  assignments, show the 8 soonest.

## Decided 2026-09-06 (George)

**Tabs: five.** Games folds into Learn. Learn keeps its name and gets a **Play**
section (Daily Word, Number Line, Versus) under the lesson shelf. Learn's one coral
button stays Resume (or the first suggestion when nothing is mid-way); Daily Word
becomes a tile with its +30 on it, not a second coral. The Games tab root and its icon
go. Friends stays a tab, so the Tidepool pill on Home goes (house rule 4).

**Focus triad: 15 / 25 / 45** on both surfaces. Phone drops the − / + steppers; Focus
ready is 25-highlighted, three chips, Start. Extension unchanged except the chip in
plan item 3.

## What this does not touch

Coins, prices, the Receipt's promise, the number of looks, kin, scenes, papers, or
lessons. No feature is removed; some are moved behind one more tap.
