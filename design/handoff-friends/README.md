# Handoff: Friends tab

## Overview
Replaces `ios/Sources/FriendsView.swift` (a mock) in Prepkin Canvas. Modelled on Finch's Friends, not Duolingo's leagues: you see your friends' kins, you cheer them, nobody loses. Two artboards of one screen: **1a** zero friends (teach the friend code), **1b** four friends (kin row, "This week" board with You pinned, friend list with one Cheer per friend). No stories row, no streaks, no rank numerals, no promotion zone. Every number only goes up.

## About the design files
`Friends Tab.dc.html` (+ `support.js`) is a **design reference built in HTML**. It shows the intended look and behaviour; it is not code to ship. Recreate it in the existing SwiftUI app using the components already in the repo (listed below by name). Open the HTML in a browser to click through the states.

## Fidelity
**High-fidelity.** Colors, type, spacing and radii are final and are all existing `Theme` tokens or `DayEditorView` sheet tokens. Recreate pixel-perfectly with the existing components; do not restyle them.

## Canvas and chrome
- iPhone 402×874 pt. 59 pt status bar + 40 pt title row = 99 pt of top chrome. Do not draw a status bar.
- Content is a `ScrollView` with `.padding(.horizontal, 22)` and `.padding(.bottom, 104)` so ≥ 90 pt stays clear above the tab bar.
- Tab bar: `RootView.tabBar` unchanged (cream `Theme.tabBar`, six tabs, Friends active: `Theme.tabActiveFill` pill, `Theme.tabActiveInk` label). The HTML ports `TabIcon` coordinate for coordinate and adds highlights/shadows — see **Icons** for whether to carry those into `PrepkinIcons.swift`.
- Header: `Text("Friends")`, `Theme.font(34, .black)`, kerning −0.9, `Theme.ink`. 1b adds the existing 42 pt white circle add button (`.shadow(.black.opacity(0.06), radius: 6, y: 2)`) which pushes to the 1a add card.

## Screens

### 1a — Zero friends
Purpose: first thing every user sees. Teach the friend code, make the tab worth filling, never read as sad.

Layout, top to bottom (VStack, 22 pt gutters):
1. **Kin card** — `DayEditorView.kinCard` pattern. `HStack(spacing: 16)`: 92×92 `RoundedRectangle(24)` filled `Theme.paper` holding `SproutImage(speciesID: state.activeChibiID, level:, size: 84)` bottom-padded 6; then `VStack(spacing: 4)`: line 1 `Theme.font(17, .bold)` kerning −0.2 ink, line 2 `Theme.font(15, .semibold)` `Theme.muted` lineSpacing 2. Card padding 18, `cardBackground(28)`. 18 pt below the title.
2. **Section header** — `DayEditorView.sectionHeader("Add a friend", tint: D.coralTint)` with the SF `plus` glyph in `Theme.coral`. Padding top 26, bottom 12.
3. **Add card** — `cardBackground(26)`, padding 18:
   - Eyebrow `YOUR CODE` (`DayEditorView.eyebrow`: 12 bold, kerning 1.5, muted).
   - Code tiles: the pairing-code tile row from `DayEditorView.unpairedCard`, verbatim — 27×44 tiles radius 11 `Theme.paper`, `.system(20, .bold, .monospaced)` ink, the dash as a 12×3 `D.grabber` bar, `HStack(spacing: 4)`. Spacer. 44×44 copy button radius 15: `D.coralTint` + `doc.on.doc` in `Theme.coral`; after tap `D.mintTint` + `checkmark` in `Theme.mint` (`.easeOut(0.18)`). Copies `state.friendCode` to the pasteboard, light haptic.
   - Line under code, 15 semibold muted: "Share this by text or in person." → after copy "Copied. Send it by text, or read it out."
   - `hairline` with 18 pt vertical padding.
   - Eyebrow `THEIR CODE`.
   - Field: `DayEditorView.addCard` text field — 52 pt, radius 16, `Theme.paper`, 16 pt horizontal padding, monospaced 17 bold ink, placeholder `XXXX-XXXX` in `D.placeholder`. `.textInputAutocapitalization(.characters)`, `.autocorrectionDisabled()`, `.keyboardType(.asciiCapable)`.
   - Helper line, 14 bold muted, 12 pt above / min height 32 (see copy).
   - **Add** button: `DayEditorView.addCard` Add button verbatim — 56 pt, `RoundedRectangle(28)`, `Theme.coral`, white `Theme.font(17, .bold)`, shadow coral 30% r10 y8 when enabled; `Theme.coral.opacity(0.4)` and no shadow while disabled.
   - **Sent state** (replaces the card body): `DayEditorView.pairedCard` pattern — 11 pt `Theme.mint` dot with 4 pt 16%-mint ring, "Sent" 17 bold ink, the code in 15 monospaced muted; hairline; body line 15 semibold muted; hairline; "Add another" as a 44 pt tall plain text button, 17 bold ink.

### 1b — Four friends
Layout, top to bottom:
1. **Kin row** — `HStack(spacing: 14)`, 22 pt below the title, 2 pt inset. Per friend, `VStack(spacing: 6)`, width 64: `SproutImage(speciesID:, level:, size: 56)` in a 56×56 bottom-aligned frame, then name `Theme.font(12, .bold)` ink. Friends only, in list order. Horizontally scrollable if more than five.
2. **This week board** — 22 pt below. `cardBackground(26)`, padding 18, `VStack(spacing: 4)`: title "This week" `Theme.font(17, .bold)` ink, 8 pt below. Rows 44 pt tall, `HStack(spacing: 12)`, 10 pt horizontal padding: `SproutFace(speciesID:, size: 26)` (dark `Theme.kinChip` plate), name `Theme.font(15, .bold)` ink, Spacer, coin pair = `CoinDisc(size: 13)` + `Theme.font(13, .black)` in `Theme.coinDark` (the TaskRow pair). **You** is pinned as the first row, name `.black`, row background `RoundedRectangle(14)` filled `Theme.paper`. Friends follow in a fixed order. No numerals.
3. **Friend list** — 20 pt below. `cardBackground(26)`, padding 18/18/8. Title "Friends" 17 bold ink, 10 pt below. Per friend, `HStack(spacing: 12)` with 10 pt vertical padding: `SproutImage(size: 40)` in a 40×40 frame; `VStack(spacing: 2)`: name `Theme.font(15.5, .black)` ink + `StarPips(level:, size: 12)` in an `HStack(spacing: 8)`, then activity `Theme.font(12.5, .bold)` muted, one line, tail-truncated; Spacer; **Cheer** button. Rows separated by `Divider`-equivalent `hairline` with `.padding(.leading, 52)`, none after the last.
   - **Cheer button**: 44 pt tall capsule, padding 12 leading / 14 trailing, `HStack(spacing: 6)`: 22 pt clap glyph + label `Theme.font(14, .heavy)`. Idle: `D.coralTint` fill, `Theme.coral` glyph and label "Cheer". Cheered: `Theme.mint` fill, white glyph and label "Cheered". `.easeInOut(0.18)`. One cheer per friend per day; the cheered state persists and does nothing on further taps. Sends one fixed clap reaction; no coins change hands in this handoff.

## Interactions & behaviour
- **Copy** → clipboard, haptic, button flips to mint check, helper line changes. Stays copied while the screen is up.
- **Their code field** — as typed: uppercase, drop anything not `A–Z 0–9`, cap at 8 characters, insert `-` after the fourth. Derived state:
  - empty → helper "Eight letters and numbers, from their Friends tab."
  - partial → "{8 − n} more to go."
  - contains I, O, 0 or 1 → "Codes skip I, O, 0 and 1. Try {suggestions}." (I/1 → L, O/0 → Q). Muted text, not red; never a warning.
  - 8 valid characters → "Looks right." and Add enables.
- **Add** → request sent; card body swaps to the Sent state. **Add another** → clears field and returns to the form.
- **Cheer** → see above. Tab bar taps: `RootView` behaviour, unchanged.
- No alerts, no toasts, no error colours anywhere on this screen.

## State
1a: `copied: Bool`, `friendCode: String` (formatted), derived `codeState: empty | partial(remaining) | invalid(chars) | valid`, `requestSent: Bool`.
1b: `cheered: Set<Friend.ID>` (per day), `weekCoins` per person from the bridge (only increases), `friends: [Friend]`.

`Friend`: `name`, `speciesID` (`ChibiSpecies.id`), `level` (`OwnedChibi.level`, 1…3, drawn as `StarPips`), `weekCoins`, `lastActivity: String`.

Sample data (from `FriendsView.swift`, levels from the design brief):
- Maya · ember · 3 · 320 · "Focused 45 min"
- Josh · droplet · 1 · 280 · "Solved the word in 3"
- Ava · sprout · 2 · 210 · "Finished Compound interest"
- Sam · slime · 1 · 150 · "4 tasks done"
- You: `state.activeChibiID`, `state.week.coinsEarned` (130 in the mock), code `K4RT-9BXM` (`Core/PairingCode` alphabet A–H J–N P–Z 2–9).

## Design tokens (all existing)
Theme: `paper` #FAF5EC · `card` #FFFFFF · `ink` #2E2622 · `muted` #96877F · `hairline` #F0E9DC · `tile` #FDF9F4 · `tileRing` #EDE1D3 · `coral` #FF6F61 · `coralIcon` #FF8A7E · `coralDeep` #E4735F · `coralShade` #C4523F · `mint` #57C79B · `mintDark` #3E9E78 · `coin` #FFC24B · `coinBorder` #E8A62E · `coinDark` #A8761D · `kinChip` #3E2C28 · `onDarkWarm` #FFF3E4 · `blush` #FF9E94 · `tabBar` #FFFDF8 · `tabInk` #6E5F53 · `tabActiveInk` #C24A3E · `tabActiveFill` #FFE0DA.
DayEditorView `D`: `coralTint` #FDECEA · `mintTint` #E8F7F0 · `placeholder` #B6A79E · `grabber` #E2D8C6 · `cardShadow` ink 5% radius 11 y 8.
StarPips empty stroke #DDD3C4.
Type: `Theme.font` (SF Pro Rounded). Sizes used: 34/900, 22/800, 17/700, 15.5/900, 15/700, 15/600, 14/800, 14/700, 13/900, 12.5/700, 12/700, 10.5/900·800. Code: `.monospaced` 20 bold (tiles), 17 bold (field), 15 bold (Sent).
Radii: cards 26 (kin card 28), kin plate 24, code tile 11, copy button 15, field 16, pinned row 14, Add 28, Cheer capsule, tab pill 16. Spacing: 22 gutters, 18 card padding, 44 pt minimum hit targets.

## Reused components (by name)
`SproutImage`, `SproutFace`/`KinChip`, `CoinDisc`, `StarPips`, `DayEditorView` (kinCard, sectionHeader, eyebrow, unpairedCard tiles + copy button, addCard field + Add button, pairedCard, hairline, cardBackground), `RootView.tabBar`, `TabIcon`. Nothing here is a new component except the Cheer button.

## Icons
The HTML enriches the five `TabIcon` objects (house, hourglass, console, books, two heads) with highlights, under-shadows and an ink-8% ground ellipse, and adds four new drawn glyphs in the same palette: copy (two coral sheets), copied (mint disc, white check), add friend (apricot head + coral plus badge; stands in for SF `person.badge.plus`), and the clap (two mittens + three sparks, single colour). SVG source is inline in the HTML — port to `Canvas`/`Path` in `PrepkinIcons.swift` if the richer tab icons are approved; otherwise keep the shipped `TabIcon` and port only the clap and add-friend glyphs. No emoji.

## Assets
None beyond the `sprout-<coat>-<evo>` stills already in `Assets.xcassets`. KIN boxes in the HTML mark where `SproutImage`/`SproutFace` render and at what size.

## Files
- `Friends Tab.dc.html` — both artboards, interactive (copy, code entry, Add/Sent, Cheer). Tweaks: `yourCode`, `requestSent`, `yourCoins`, `everyoneCheered`.
- `support.js` — runtime the HTML needs to open locally.
