# Handoff: First Run (Hatch · Pick three · Home Day 1)

Target: `chetaxxx1/prepkin-canvas`, SwiftUI app in `ios/Sources/`.

## About the design files
`First Run.dc.html` is a **design reference built in HTML** (a live prototype, Nunito standing in for SF Pro Rounded). Do not ship it. Recreate it in SwiftUI using the existing views and tokens named below; every colour is a `Theme` token and every component already exists in the repo. Where the prototype shows a dashed box labelled KIN, render `SproutImage` at that size.

## Fidelity
High-fidelity. Match spacing, radii, weights and copy exactly. Where the prototype and an existing SwiftUI component disagree, the SwiftUI component wins (the prototype was drawn from it).

## Overview
A brand-new user lands in a two-screen first run, then Home. No onboarding exists today (`RootView` → `HomeView` directly), so add a `firstRunDone` flag to `AppState` and show `FirstRunView` in `RootView` until it is set. Nothing is asked for until the student has checked off one task; offers then arrive as cards on Home, in order.

## Screens

### 1 · Hatch and name (`FirstRunView.name`)
- Background `Theme.paper`. Content top inset 99pt. Centered column, 28pt side padding.
- Kin well: 180×180, radius 32, fill `Theme.tile`, 1.5pt `Theme.tileRing`; `SproutImage(size: 160)` bottom-aligned, 8pt bottom padding. Enters with a 0.6s ease-out rise+scale (translateY 18 → 0, scale .94 → 1).
- 28pt gap. Title "What do you want to name your kin?" `Theme.font(26, .black)`, kerning −0.5, centered, 2 lines.
- 8pt gap. "You can change this later." `Theme.font(15, .semibold)` `Theme.muted`.
- 24pt gap. TextField: full width, 56pt, radius 18, `Theme.card`, shadow ink .05 r11 y8, text `Theme.font(20, .heavy)` centered, placeholder "Name" in DayEditorView `D.placeholder` #B6A79E. Max 14 chars (`GameState.rename`).
- 12pt gap. Row, gap 10: **Shuffle** (flex 1, 56pt, radius 28, fill `D.field` #F4EDE1, `KinIcon(.die, 18)` + "Shuffle" `Theme.font(17, .bold)` ink) and **Next** (flex 1, 56pt, radius 28, `Theme.coral`, white `Theme.font(17, .bold)`, shadow coral .3 r10 y8; disabled = opacity .4, no shadow).
- Shuffle picks the next name from `GameState.shuffleNames` and fills the field. Next enabled iff trimmed name non-empty.
- On Next: `state.rename("slime", to: name)`.

### 2 · Pick three for today (`FirstRunView.pick`)
- Background `Theme.paper`. Top inset 99pt, 22pt side padding.
- Title "Pick three for today" `Theme.font(34, .black)` kerning −0.9.
- 16pt. DayEditorView `kinCard` verbatim (92 well, `SproutImage(size: 84)`, radius 28 card), with these strings: label "Nothing picked yet" / "N of 3 picked"; coinChip "\(coins) today"; subline "Tap what fits. \(name) keeps you company."; progress = picked/3 in `Theme.mint` on `Theme.hairline`, animated .3s.
- 22pt. Eyebrow "STUDY IDEAS" (DayEditorView `eyebrow`), then the 4 study presets; 14pt; "LIFE CARE", then the 8 life presets — `TaskTemplate.presets` in file order.
- Row = DayEditorView `row` with two changes: (a) meta line is only the coin line "+20 coins" / "+10 coins" in `D.goldInk` with `CoinDisc(12.5)`, no goldTint pill, no recurrence chip; (b) the trailing `pillToggle` is replaced by a 30pt check disc: unpicked = `Theme.checkFill` with 2.5pt `Theme.checkBorder` ring; picked = `Theme.mint` fill, white checkmark (SF "checkmark", 14, black). Picked row keeps the row's existing 2.5pt `Theme.mint` border + mint .14 shadow (the selected-ring pattern).
- Tap toggles. Cap at 3: a fourth tap does nothing.
- Bottom: Continue, 56pt, radius 28, `Theme.coral`, on a paper gradient scrim, 48pt above the bottom edge. Enabled iff exactly 3 picked (opacity .4 otherwise).
- On Continue: for every preset, `state.setTemplate(id, active: picked.contains(id))`; set `firstRunDone`; show Home.

### Home · Day 1 (`HomeView`, unchanged layout)
- Land with the three rows and the bubble "Tap one when it's done." (replace `greeting` for the first session until any task is done).
- Mascot is `SproutImage`/`SproutView` at `mascotSize` (≈140 after headroom on 402×874).
- First check-off (`toggle`): existing `+N` over the coin chip and `.bounce`; add 3 `CoinDisc(16)` that fly from the row's reward to the wallet chip over 0.9s (cubic-bezier .3,.7,.3,1, staggered 80ms, fade out). Bubble: "That's 20 coins in the wallet." (or 10). On the third: "All three done. \(name) is very pleased." Replace the current "Yay! Nice work!" for these three tasks; no exclamation marks.
- 1.5s after the first check-off, insert the **Notifications card** above the task list (cardIn .35s ease, translateY 12 → 0):
  - `Theme.card`, radius 20, padding 16, shadow #281412 .07 r3 y2. Row: 44pt circle `D.mintTint` with `SproutImage(size: 34)`, title "Want \(name) to check in tomorrow evening?" `Theme.font(15.5, .black)`.
  - Preview strip: radius 14, `Theme.paper`, padding 10/12: `KinChip(size: 30)`, "From \(name)" `Theme.font(12.5, .black)`, "7:30 PM" muted, "How did today go?" `Theme.font(12.5, .semibold)`. Time = `settings.nudgeHour` formatted.
  - Buttons, gap 10, 44pt, radius 22: **Yes please** `Theme.coral`/white; **Not now** `D.field` fill, `Theme.muted` text. `Theme.font(15, .bold)`.
  - Yes please → `setRemindersEnabled(true)` fires the iOS dialog. Not now → dismiss, may return in session two. Either → show the Canvas card.
- **Canvas card**, same shell: title "Want your Canvas homework here?", subline "Takes a laptop. Canvas tasks pay 30." `Theme.font(12.5, .bold)` muted. **Show me** opens `DayEditorView` scrolled to the Canvas pairing card. **Not now** dismisses.

### Session two · Save progress (only if accounts ship with Friends)
- Second app open: sheet-style card anchored 104pt above the bottom over ink .28 scrim. Radius 24, padding 18: 44pt kin circle, "Save \(name)'s progress" `Theme.font(17, .black)`, "Everything stays on this phone either way." muted. **Save** 52pt coral; **Later** 44pt, transparent, `Theme.muted`. Never "Discard" or "Skip". Hard wall only when opening Friends (not in this handoff).

## Interactions & motion
- Kin bounce = `ChibiAnimation.bounce` (SproutImage keyframes). Bubble in: scale .9 → 1, .35s.
- +N gain: 1.6s, rises 14pt then fades (HomeView already does this).
- Coin fly: 3 discs, 0.9s, stagger 80ms.
- Row selection: .18s ease on ring and disc.

## State (add to AppState / FirstRunView)
- `firstRunDone: Bool` (persisted)
- `name: String`, `shuffleIndex: Int`, `picked: Set<String>` (max 3)
- Home: `bubble`, `coinGain`, `offer: nil | .notify | .canvas`, `notifyAnswer: nil | on | off | later`, `sessionCount`, `showSaveWall`


---

# Reference sheet (tokens, components, copy)


Source of truth: `chetaxxx1/prepkin-canvas@main`, `ios/Sources/`. Design file: `First Run.dc.html` (live prototype, 402 × 874, Nunito standing in for SF Pro Rounded).

Flow: Screen 1 (name) → Screen 2 (pick three) → Home Day 1. Nothing is asked for until the first check-off. Then, as cards from the kin on Home, in order: Notifications, Canvas. Session two: Save progress (only if accounts arrive). Hard wall only on opening Friends (not designed here).

Budget: 99pt status bar + top chrome (content starts at y = 99). 90pt clear above the tab bar (Home list padding-bottom 110).

## Colours (every one is a Theme token)

- `Theme.paper` #FAF5EC — Screen 1, Screen 2, Your day sheet background; kin card well
- `Theme.card` #FFFFFF — cards, rows, chips, bubble, text field
- `Theme.ink` #2E2622 — all body text; level band tint at .08/.14
- `Theme.muted` #96877F — helper lines, eyebrows, quiet buttons
- `Theme.dim` #B4A996 — chevron, sheet footnote
- `Theme.hairline` #F0E9DC — kin card progress track, sheet divider
- `Theme.tile` #FDF9F4 / `Theme.tileRing` #EDE1D3 — TaskRow tile; Screen 1 kin well
- `Theme.checkFill` #F4F0EB / `Theme.checkBorder` #E6DFD7 / `Theme.check` #6FC79E — TaskRow checkbox
- `Theme.coral` #FF6F61 — the one primary button per screen; Shuffle glyph; copy glyph
- DayEditorView `D.coralTint` #FDECEA — copy tile in the pairing card
- `Theme.coralDeep` #E4735F — Grade calculator disc, Home TabIcon placeholder
- `Theme.mint` #57C79B — selected-row ring, kin card progress fill, pill toggle on
- `Theme.mintSoft` #DFF3E9 — KIN box fill on Screens 1–2; `Theme.mintDark` #3E9E78 — KIN box dash/label
- `Theme.coin` #FFC24B / `Theme.coinBorder` #E8A62E — CoinDisc; `Theme.coinDark` #A8761D — "+20", row reward
- `Theme.tabBar` #FFFDF8, `Theme.tabInk` #6E5F53, `Theme.tabActiveInk` #C24A3E, `Theme.tabActiveFill` #FFE0DA, `Theme.kinChip` #3E2C28 — RootView tab bar
- `Theme.chipDivider` #E9E1D6, `Theme.bagInk` #8A7869 — Home coin chip
- `HomeView.tankFloor` #ADE2CB — Home page background
- DayEditorView sheet-only tokens: `D.field` #F4EDE1 (Shuffle / Not now fill), `D.trackOff` #E6DDCE, `D.grabber` #E2D8C6, `D.mintTint` #E8F7F0, `D.mintIcon` #3FA681, `D.goldTint` #FFF6E4, `D.goldInk` #B07A16, `D.placeholder` #B6A79E, `D.cardShadow` ink .05
- Row tile tints from `DayEditorView.rowTint`: reading #ECEFFC/#6B79D8, study #FDF0E4/#E08A3C, lifeCare #E6F3FA/#4A9CC4, walk mintTint/mintIcon, sleep #F2ECFB/#8A6FC4, meal coralTint/#E8574A
- Level band bolt: `Theme.hex(0x7A4A12)` on `Theme.coin` (HomeView.levelBand)
- iOS permission dialog: system, untouched.

## Reused components (by name, not redrawn)

- `SproutImage` — every mascot is a KIN box at its size: 160 (Screen 1), 84 (kin card, per DayEditorView.kinCard), 140 (Home scene, `mascotSize` after headroom), 34 in a 44 circle (offer cards, per DayEditorView.addCard). Bounce = `ChibiAnimation.bounce` keyframes from SproutImage (lift −14, squash .92/1.06).
- `CoinDisc`, `CoinBadge` pattern (HomeView) — wallet chip, "+N", row reward, coinChip in kin card and rows.
- `TaskRow` (HomeView) — the three Day 1 rows, incl. checkbox and .62 done opacity.
- `CategoryIcon` (PrepkinIcons) — tile placeholder labelled with the `TaskCategory` (study, reading, lifeCare, walk, sleep, meal). `TabIcon` + `KinChip` — tab bar placeholders.
- `StarPips` (KinComponents) — name chip, level 1.
- `DayEditorView`: `kinCard`, `eyebrow`, `row` (Screen 2 rows; selected ring = the row's existing 2.5pt mint border + mint shadow; trailing `pillToggle` swapped for a 30pt check disc in `Theme.checkFill`/`Theme.checkBorder` → `Theme.mint` + white check, per Finch's goal picker; recurrence chip dropped), `header` + `grabber`, `unpairedCard` (code tiles + copy), `sectionHeader`, `coinChip`.
- `HomeView`: `sceneBlock`, `chipsRow`, `coinChip`, `speechBubble`, `levelBand`, `goalsRow`, `footerLinks`.
- `RootView.tabBar` — six tabs, Home active.
- `GameState.shuffleNames` — the Shuffle list. `GameState.rename` — 14-char cap.
- Data: `TaskTemplate.presets` (4 study, 8 life, in file order), `TaskKind.reward` (Study 20, Life 10, Canvas 30), `ChibiSpecies.catalog[0]` slime (name fallback), `OwnedChibi.upgradeCost[1]` = 100 for the level band, `MockCanvasClient` untouched.

## State

- `screen`: hatch | pick | home
- `name`: String (≤14, trimmed; empty → displayName falls back to species "Slime")
- `shuffleI`: index into shuffleNames
- `picked`: [TaskTemplate.id], max 3; Continue enabled iff count == 3
- `tasks`: [DailyTask] built from picked templates on Continue
- `coins`: Int; `gain`: Int? shown 1.6s; `bounce`, `fly`: counters that retrigger the kin bounce and the 3 flying coins
- `bubble`: String
- `offer`: nil | notify | canvas — set to notify 1.5s after the first check-off; canvas after notify is answered
- `notify`: nil | on | off | later — `later` may return in session two
- `iosDialog`: Bool — true only after Yes please
- `sheet`: Bool — Your day, scrolled to the pairing card
- `session`, `saveWall`: session two soft wall (future; accounts don't exist)

## Final copy

Screen 1
- What do you want to name your kin?
- You can change this later.
- field placeholder: Name
- Shuffle · Next

Screen 2
- Pick three for today
- Nothing picked yet / 1 of 3 picked / 2 of 3 picked / 3 of 3 picked
- 0 today … 50 today (coins)
- Tap what fits. [name] keeps you company.
- STUDY IDEAS · LIFE CARE · +20 coins · +10 coins
- Continue

Home, Day 1
- Bubble: Tap one when it's done.
- Level band: 1 star · 100 to the next
- Goals: 3 goals left today / 2 goals left today / 1 goal left today / All goals done today
- After a check: +20 (or +10) over the wallet; bubble: That's 20 coins in the wallet.
- After the third: All three done. [name] is very pleased.

Notifications card
- Want [name] to check in tomorrow evening?
- Preview: From [name] · 7:30 PM · How did today go?
- Yes please · Not now

Canvas card
- Want your Canvas homework here?
- Takes a laptop. Canvas tasks pay 30.
- Show me · Not now
- Sheet: Your day · Canvas · Type this into the Prepkin extension in Chrome. · Done

Session two
- Good to see you again.
- Save [name]'s progress
- Everything stays on this phone either way.
- Save · Later

## Cut on purpose

No carousel, tour, dots, or counter. No streak, loss, or warning. No stat to type. One coral button per screen. Canvas is never in the first run.
